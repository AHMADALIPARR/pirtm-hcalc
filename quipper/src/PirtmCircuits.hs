-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
--
-- Quipper circuits for every quantum computation in PIRTM
-- (pirtm/quantum/gates.py, circuit.py, hilbert11.py, agents/workers.py and the
-- central adversarial experiment). Qubit 0 is the most significant bit, as in
-- the source; a register is a list of qubits [q0, q1, ..].

module PirtmCircuits where

import Quipper

-- | PIRTM gate alphabet (hilbert11.GateOp names plus T and a phase gate).
data Gate
  = H Int | X Int | Y Int | Z Int | S Int | Sdg Int | T Int
  | Phase Double Int
  | CNOT Int Int
  deriving (Show, Eq)

-- | GateOp.dagger from hilbert11.py (extended to T and Phase).
dagger :: Gate -> Gate
dagger (S q) = Sdg q
dagger (Sdg q) = S q
dagger (Phase phi q) = Phase (negate phi) q
dagger g = g

-- | Hilbert11Simulator.evolve_inverse: reversed list of daggers.
inverseCircuit :: [Gate] -> [Gate]
inverseCircuit = map dagger . reverse

-- | Apply one PIRTM gate to a register.
applyGate :: [Qubit] -> Gate -> Circ ()
applyGate qs g = case g of
  H q       -> hadamard_at (qs !! q)
  X q       -> qnot_at (qs !! q)
  Y q       -> gate_Y_at (qs !! q)
  Z q       -> gate_Z_at (qs !! q)
  S q       -> gate_S_at (qs !! q)
  Sdg q     -> gate_S_inv_at (qs !! q)
  T q       -> gate_T_at (qs !! q)
  -- diag(1, e^{i phi}) = e^{i phi/2} * expZt(-phi/2); global_phase t = e^{i pi t}
  Phase phi q -> do
    expZt_at (negate phi / 2) (qs !! q)
    global_phase (phi / (2 * pi))
  CNOT c t  -> qnot_at (qs !! t) `controlled` (qs !! c)

-- | A gate list as a Quipper circuit on an n-qubit register.
circuitOf :: [Gate] -> [Qubit] -> Circ [Qubit]
circuitOf gates qs = do
  mapM_ (applyGate qs) gates
  return qs

-- | Prepare a computational basis state |idx> on n qubits from |0..0>
-- (X on every set bit; qubit 0 = MSB).
prepareBasis :: Int -> Int -> [Qubit] -> Circ [Qubit]
prepareBasis n idx qs = do
  mapM_ (\q -> qnot_at (qs !! q)) [ q | q <- [0 .. n - 1], testBitMSB n idx q ]
  return qs

testBitMSB :: Int -> Int -> Int -> Bool
testBitMSB n idx q = (idx `div` (2 ^ (n - 1 - q))) `mod` 2 == 1

-- ------------------------------------------------------------ the circuits

-- | tests/test_quantum.py::test_bell_state_generation (2 qubits).
bellGates :: [Gate]
bellGates = [H 0, CNOT 0 1]

-- | tests/test_hilbert11.py::test_11qubit_reversible_roundtrip (applied to |7>).
roundtripGates :: [Gate]
roundtripGates = [H 0, CNOT 0 1, S 1, CNOT 1 5, H 5, CNOT 5 10, X 10]

-- | A01 temporal-causality worker: H(q), CNOT(q,q+1) for q = 0,1,2.
a01Gates :: Int -> [Gate]
a01Gates k = concat [ [H q, CNOT q (q + 1)] | q <- [0 .. k - 1] ]

-- | A02 reversible worker circuit (applied to |42>).
a02Gates :: [Gate]
a02Gates = [H 0, CNOT 0 5, S 5, CNOT 5 10, X 10]

-- | A03: Hadamard on all 11 coordinates.
a03Gates :: [Gate]
a03Gates = [ H q | q <- [0 .. 10] ]

-- | A04: 3-qubit GHZ inside the 11-qubit register.
a04Gates :: [Gate]
a04Gates = [H 0, CNOT 0 1, CNOT 1 2]

-- | A05 historical encoding circuit (applied to |100>).
a05Gates :: [Gate]
a05Gates = [H 0, CNOT 0 4, X 7]

-- | A08 restricted observer: entangle qubit 0 with qubit 10.
a08Gates :: [Gate]
a08Gates = [H 0, CNOT 0 10]

-- | Central adversarial experiment, state preparation from |0^11>.
-- |Psi_1> = (|0>|0..0> + |1>|0..01>)/sqrt2   (indices 0 and 1025)
-- |Psi_2> = (|0>|10..0> + |1>|10..01>)/sqrt2 (indices 512 and 1537)
psi1Gates, psi2Gates :: [Gate]
psi1Gates = [H 0, CNOT 0 10]
psi2Gates = [X 1, H 0, CNOT 0 10]

-- | ClassicalReversibleBaseline test as a Quipper circuit on basis states:
-- not(1) then toffoli(0,1,2), starting from |101>.
classicalBaseline :: [Qubit] -> Circ [Qubit]
classicalBaseline qs@[a, b, c] = do
  qnot_at b
  qnot_at c `controlled` (a .&&. b)
  return qs
classicalBaseline qs = return qs
