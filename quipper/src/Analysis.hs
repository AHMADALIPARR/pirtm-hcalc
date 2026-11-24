-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
--
-- Post-processing of Quipper simulator output: the measurement-side math of
-- pirtm/quantum/hilbert11.py (fidelity, partial trace, trace-distance bound,
-- norm, probabilities) on amplitude maps returned by sim_amps.

module Analysis where

import qualified Data.Map as Map
import Quantum.Synthesis.Ring (Cplx(..))

type Amps = Map.Map [Bool] (Cplx Double)

basisKey :: Int -> Int -> [Bool]
basisKey n idx = [ (idx `div` (2 ^ (n - 1 - q))) `mod` 2 == 1 | q <- [0 .. n - 1] ]

keyIndex :: [Bool] -> Int
keyIndex = foldl (\acc b -> 2 * acc + (if b then 1 else 0)) 0

re, im :: Cplx Double -> Double
re (Cplx a _) = a
im (Cplx _ b) = b

cmul :: Cplx Double -> Cplx Double -> Cplx Double
cmul (Cplx a b) (Cplx c d) = Cplx (a * c - b * d) (a * d + b * c)

cadd :: Cplx Double -> Cplx Double -> Cplx Double
cadd (Cplx a b) (Cplx c d) = Cplx (a + c) (b + d)

cconj :: Cplx Double -> Cplx Double
cconj (Cplx a b) = Cplx a (negate b)

czero :: Cplx Double
czero = Cplx 0 0

isZero :: Cplx Double -> Bool
isZero (Cplx a b) = a == 0 && b == 0

-- | Dense amplitude list in basis-index order (absent entries are 0).
dense :: Int -> Amps -> [Cplx Double]
dense n m = [ Map.findWithDefault czero (basisKey n i) m | i <- [0 .. 2 ^ n - 1] ]

-- | Nonzero amplitudes as (index, amplitude), in index order.
nonzero :: Amps -> [(Int, Cplx Double)]
nonzero m = [ (keyIndex k, a) | (k, a) <- Map.toList m, not (isZero a) ]

normSquared :: Int -> Amps -> Double
normSquared n m = foldl (\acc a -> acc + (re a * re a + im a * im a)) 0 (dense n m)

-- | state_fidelity |<s1|s2>|^2
fidelity :: Int -> Amps -> Amps -> Double
fidelity n a b =
  let dot = foldl cadd czero (zipWith (\x y -> cmul (cconj x) y) (dense n a) (dense n b))
  in re dot * re dot + im dot * im dot

-- | partial_trace(state, accessible qubits) -> rho_A as a row-major list
partialTrace :: Int -> [Int] -> Amps -> [[Cplx Double]]
partialTrace n acc m =
  let k = length acc
      da = 2 ^ k :: Int
      amps = filter (not . isZero . snd) (zip [0 ..] (dense n m))
      bit i q = (i `div` (2 ^ (n - 1 - q))) `mod` 2 :: Int
      sub i = sum [ bit i q * 2 ^ (k - 1 - b) | (b, q) <- zip [0 ..] acc ]
      env i = [ bit i q | q <- [0 .. n - 1], q `notElem` acc ]
      contrib = [ ((sub i, sub j), cmul ai (cconj aj))
                | (i, ai) <- amps, (j, aj) <- amps, env i == env j ]
      table = Map.fromListWith (flip cadd) contrib
  in [ [ Map.findWithDefault czero (r, c) table | c <- [0 .. da - 1] ] | r <- [0 .. da - 1] ]

-- | density_matrix_trace_distance: 0.5 * Frobenius norm of the difference
traceDistanceBound :: [[Cplx Double]] -> [[Cplx Double]] -> Double
traceDistanceBound r1 r2 =
  let d = [ (re x - re y) ^ (2 :: Int) + (im x - im y) ^ (2 :: Int)
          | (row1, row2) <- zip r1 r2, (x, y) <- zip row1 row2 ]
  in sqrt (foldl (+) 0 d) * 0.5

probabilities :: Int -> Amps -> [Double]
probabilities n m = [ re a * re a + im a * im a | a <- dense n m ]
