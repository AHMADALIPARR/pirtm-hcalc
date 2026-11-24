-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
--
-- pirtm-quipper: builds every PIRTM circuit in Quipper, prints it (ASCII and
-- gate counts), runs Quipper's quantum simulator (sim_amps) on it and prints the
-- resulting amplitudes and derived quantities. Usage:
--   pirtm-quipper            all sections
--   pirtm-quipper <section>  one of: bell roundtrip workers adversarial classical

module Main (main) where

import Quipper
import Quipper.Libraries.Simulation (sim_amps)
import qualified Data.Map as Map
import Quantum.Synthesis.Ring (Cplx(..))
import System.Environment (getArgs)
import System.Random (mkStdGen)
import Text.Printf (printf)

import PirtmCircuits
import Analysis

simulate :: Int -> ([Qubit] -> Circ [Qubit]) -> Int -> Amps
simulate n circ idx =
  sim_amps (mkStdGen 0) circ (Map.fromList [(basisKey n idx, Cplx 1.0 0.0)])

shape :: Int -> [Qubit]
shape n = replicate n qubit

banner :: String -> IO ()
banner s = putStrLn ("== quipper: " ++ s)

showCircuit :: String -> Int -> ([Qubit] -> Circ [Qubit]) -> IO ()
showCircuit name n circ = do
  putStrLn ("-- circuit " ++ name ++ " (ASCII)")
  print_generic ASCII circ (shape n)
  putStrLn ("-- circuit " ++ name ++ " (GateCount)")
  print_generic GateCount circ (shape n)

showAmps :: String -> Amps -> IO ()
showAmps name m =
  mapM_ (\(i, Cplx a b) -> printf "%s amp[%d] = (%.17g, %.17g)\n" name i a b) (nonzero m)

bell :: IO ()
bell = do
  banner "bell (tests/test_quantum.py)"
  showCircuit "bell" 2 (circuitOf bellGates)
  let out = simulate 2 (circuitOf bellGates) 0
  showAmps "bell" out
  let ps = probabilities 2 out
      tot = sum ps
  mapM_ (\(i, p) -> printf "bell prob[%d] = %.17g\n" (i :: Int) (p / tot)) (zip [0 ..] ps)
  printf "bell norm_squared = %.17g\n" (normSquared 2 out)

roundtrip :: IO ()
roundtrip = do
  banner "roundtrip (tests/test_hilbert11.py, basis |7>)"
  showCircuit "roundtrip" 11 (circuitOf roundtripGates)
  let fwd = simulate 11 (circuitOf roundtripGates) 7
      orig = simulate 11 (\qs -> return qs) 7
  showAmps "roundtrip forward" fwd
  printf "roundtrip forward norm_squared = %.17g\n" (normSquared 11 fwd)
  printf "roundtrip forward fidelity_vs_initial = %.17g\n" (fidelity 11 orig fwd)
  -- inverse two ways: PIRTM's dagger list, and Quipper's own circuit reversal
  let viaDagger = simulate 11 (\qs -> circuitOf roundtripGates qs >>= circuitOf (inverseCircuit roundtripGates)) 7
      viaReverse = simulate 11 (\qs -> circuitOf roundtripGates qs >>= reverse_generic_endo (circuitOf roundtripGates)) 7
  printf "roundtrip fidelity (dagger list) = %.17g\n" (fidelity 11 orig viaDagger)
  printf "roundtrip fidelity (Quipper reverse_generic_endo) = %.17g\n" (fidelity 11 orig viaReverse)
  showCircuit "roundtrip_inverse_by_reverse_generic_endo" 11 (reverse_generic_endo (circuitOf roundtripGates))

workers :: IO ()
workers = do
  banner "agent worker circuits (pirtm/agents/workers.py)"
  -- A01: fidelity between consecutive temporal states
  let states = [ simulate 11 (circuitOf (a01Gates k)) 0 | k <- [0 .. 3] ]
  showCircuit "A01" 11 (circuitOf (a01Gates 3))
  mapM_ (\(k, (a, b)) -> printf "A01 transition_fidelity[%d] = %.17g\n" (k :: Int) (fidelity 11 a b))
        (zip [0 ..] (zip states (tail states)))
  -- A02
  let a02init = simulate 11 (\qs -> return qs) 42
      a02fwd = simulate 11 (circuitOf a02Gates) 42
      a02back = simulate 11 (\qs -> circuitOf a02Gates qs >>= circuitOf (inverseCircuit a02Gates)) 42
  showCircuit "A02" 11 (circuitOf a02Gates)
  printf "A02 norm_after_evolve = %.17g\n" (normSquared 11 a02fwd)
  printf "A02 roundtrip_fidelity = %.17g\n" (fidelity 11 a02init a02back)
  -- A03
  let a03 = simulate 11 (circuitOf a03Gates) 0
      expected = 1.0 / sqrt 2048 :: Double
      maxErr = maximum [ abs (re a - expected) | a <- dense 11 a03 ]
  showCircuit "A03" 11 (circuitOf a03Gates)
  printf "A03 support = %d\n" (length (nonzero a03))
  printf "A03 max_err = %.17g\n" maxErr
  -- A04
  let a04 = simulate 11 (circuitOf a04Gates) 0
      ps = probabilities 11 a04
  showCircuit "A04" 11 (circuitOf a04Gates)
  showAmps "A04" a04
  printf "A04 total_prob = %.17g\n" (foldl (+) 0 ps)
  printf "A04 active_outcomes = %d\n" (length (filter (> 1e-5) ps))
  -- A05
  let a05init = simulate 11 (\qs -> return qs) 100
      a05 = simulate 11 (circuitOf a05Gates) 100
      a05back = simulate 11 (\qs -> circuitOf a05Gates qs >>= circuitOf (inverseCircuit a05Gates)) 100
      rho05 = partialTrace 11 [0] a05
  showCircuit "A05" 11 (circuitOf a05Gates)
  showAmps "A05" a05
  printf "A05 full_recovery_fidelity = %.17g\n" (fidelity 11 a05init a05back)
  printf "A05 rho00 = %.17g\n" (re (head (head rho05)))
  -- A08
  let a08 = simulate 11 (circuitOf a08Gates) 0
      rho = partialTrace 11 [0] a08
      r00 = re (rho !! 0 !! 0); r11 = re (rho !! 1 !! 1); r01 = rho !! 0 !! 1
      purity = r00 ^ (2 :: Int) + r11 ^ (2 :: Int) + 2 * (re r01 ^ (2 :: Int) + im r01 ^ (2 :: Int))
  showCircuit "A08" 11 (circuitOf a08Gates)
  printf "A08 purity = %.17g\n" purity

adversarial :: IO ()
adversarial = do
  banner "central adversarial experiment (hilbert11.run_central_adversarial_experiment)"
  showCircuit "prepare_psi1" 11 (circuitOf psi1Gates)
  showCircuit "prepare_psi2" 11 (circuitOf psi2Gates)
  let p1 = simulate 11 (circuitOf psi1Gates) 0
      p2 = simulate 11 (circuitOf psi2Gates) 0
      r1 = partialTrace 11 [0] p1
      r2 = partialTrace 11 [0] p2
      fid = fidelity 11 p1 p2
      td = traceDistanceBound r1 r2
  showAmps "psi1" p1
  showAmps "psi2" p2
  printf "state_dimension = %d\n" (length (dense 11 p1))
  printf "psi1 norm_squared = %.17g\n" (normSquared 11 p1)
  printf "psi2 norm_squared = %.17g\n" (normSquared 11 p2)
  printf "global_overlap_fidelity = %.17g\n" fid
  printf "global_distinguishable = %s\n" (show (fid < 1e-6))
  printf "reduced_trace_distance = %.17g\n" td
  printf "subsystem_distinguishable = %s\n" (show (td > 1e-4))
  printf "psi1 rho_A = [[%.17g, %.17g], [%.17g, %.17g]] (real parts)\n"
    (re (r1 !! 0 !! 0)) (re (r1 !! 0 !! 1)) (re (r1 !! 1 !! 0)) (re (r1 !! 1 !! 1))
  printf "psi2 rho_A = [[%.17g, %.17g], [%.17g, %.17g]] (real parts)\n"
    (re (r2 !! 0 !! 0)) (re (r2 !! 0 !! 1)) (re (r2 !! 1 !! 0)) (re (r2 !! 1 !! 1))

classical :: IO ()
classical = do
  banner "classical reversible baseline (ClassicalReversibleBaseline test)"
  showCircuit "classical_baseline" 3 classicalBaseline
  let out = simulate 3 classicalBaseline 5
  showAmps "classical |101> ->" out

main :: IO ()
main = do
  args <- getArgs
  let sections = [("bell", bell), ("roundtrip", roundtrip), ("workers", workers),
                  ("adversarial", adversarial), ("classical", classical)]
  case args of
    [] -> mapM_ snd sections
    (s : _) -> maybe (putStrLn ("unknown section " ++ s)) id (lookup s sections)
