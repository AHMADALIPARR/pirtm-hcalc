-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
import PirtmHcalc.Quantum.Exact
/-!
# Experimental results as theorems (exact arithmetic)

Each circuit below is the gate list used by `pirtm/agents/workers.py`,
`pirtm/quantum/hilbert11.py` or `tests/`, the same list that
`mlir/main/*.mlir` and `quipper/src/PirtmCircuits.hs` run in floating point.
Here every quantity is computed exactly (`z / √2^k`, `z ∈ ℤ[i]`) and the
theorems are proved by `decide` (kernel evaluation).

The second half relates the exact values to the decimal strings logged by
the float runs (`logs/mlir/*.log`, `logs/quipper/*.log`,
`logs/reference/python-ref-dump.txt`): each logged decimal is within the stated
distance of the exact value.
-/

namespace PirtmHcalc.Data
open PirtmHcalc.Quantum

/-! ## Circuits -/

def bellGates : List Gate := [.H 0, .CNOT 0 1]
def a02Gates : List Gate := [.H 0, .CNOT 0 5, .S 5, .CNOT 5 10, .X 10]
def a03Gates : List Gate := (List.range 11).map Gate.H
def a04Gates : List Gate := [.H 0, .CNOT 0 1, .CNOT 1 2]
def a05Gates : List Gate := [.H 0, .CNOT 0 4, .X 7]
def a08Gates : List Gate := [.H 0, .CNOT 0 10]
def psi1Gates : List Gate := [.H 0, .CNOT 0 10]
def psi2Gates : List Gate := [.X 1, .H 0, .CNOT 0 10]
def roundtrip7Gates : List Gate :=
  [.H 0, .CNOT 0 1, .S 1, .CNOT 1 5, .H 5, .CNOT 5 10, .X 10]

def bell : State := (State.basis 2 0).evolve bellGates
def psi1 : State := (State.basis 11 0).evolve psi1Gates
def psi2 : State := (State.basis 11 0).evolve psi2Gates

/-- A01: three temporal transitions; step i applies H i then CNOT i (i+1) and
records the fidelity with the previous state. -/
def a01Fidelities : List Dy :=
  let rec go : Nat → State → List Dy
    | 0, _ => []
    | f + 1, s =>
      let i := 3 - (f + 1)
      let s' := s.evolve [.H i, .CNOT i (i + 1)]
      State.fidelity s s' :: go f s'
  go 3 (State.basis 11 0)

def half : Dy := ⟨1, 1⟩
def one : Dy := ⟨1, 0⟩
def zero : Dy := ⟨0, 0⟩
def eighth : Dy := ⟨1, 3⟩

/-! ## Bell state (tests/test_quantum.py) -/

theorem bell_amplitudes :
    bell.k = 1 ∧ QT.leaves bell.amp = [⟨1, 0⟩, ⟨0, 0⟩, ⟨0, 0⟩, ⟨1, 0⟩] := by decide

theorem bell_probabilities :
    ((List.range 4).map bell.prob).map (fun p => p.eqv half || p.eqv zero) = [true, true, true, true] ∧
    (bell.prob 0).eqv half ∧ (bell.prob 3).eqv half ∧
    (bell.prob 1).eqv zero ∧ (bell.prob 2).eqv zero := by decide

/-! ## Central adversarial experiment (hilbert11.run_central_adversarial_experiment, A11) -/

/-- Ψ₁ = (|0⟩ + |1025⟩)/√2 and Ψ₂ = (|512⟩ + |1537⟩)/√2, exactly as the Python
constructs them amplitude by amplitude. -/
theorem psi_support :
    psi1.k = 1 ∧ QT.get 11 psi1.amp 0 = GInt.one ∧ QT.get 11 psi1.amp 1025 = GInt.one ∧
    psi1.support = 2 ∧
    psi2.k = 1 ∧ QT.get 11 psi2.amp 512 = GInt.one ∧ QT.get 11 psi2.amp 1537 = GInt.one ∧
    psi2.support = 2 := by decide

theorem psi_normalized : psi1.normSq.eqv one ∧ psi2.normSq.eqv one := by decide

/-- Global observer: ⟨Ψ₁|Ψ₂⟩ = 0, so the global fidelity is exactly 0. -/
theorem global_fidelity_zero : (State.fidelity psi1 psi2).eqv zero := by decide

/-- Restricted observer on qubit 0: both reduced states are exactly I/2
(numerators over 2^1). -/
theorem reduced_states_equal :
    psi1.rho0 = [[⟨1, 0⟩, ⟨0, 0⟩], [⟨0, 0⟩, ⟨1, 0⟩]] ∧ psi2.rho0 = psi1.rho0 ∧
    psi1.k = psi2.k := by decide

/-- Hence the (Frobenius) trace-distance bound between the reduced states is
exactly 0 and the observer's outcome probabilities are both 1/2. -/
theorem reduced_trace_distance_zero :
    (List.zipWith (List.zipWith (· - ·)) psi1.rho0 psi2.rho0).all (·.all (· == GInt.zero)) = true := by
  decide

theorem adversarial_conclusion :
    (State.fidelity psi1 psi2).eqv zero = true ∧ psi1.rho0 = psi2.rho0 := by decide

/-! ## Workers A01–A08 -/

theorem A01_transition_fidelities :
    a01Fidelities.length = 3 ∧
    (a01Fidelities.zip [half, eighth, eighth]).all (fun p => p.1.eqv p.2) = true := by decide

theorem A02_norm_and_roundtrip :
    let s0 := State.basis 11 42
    let s := s0.evolve a02Gates
    s.normSq.eqv one ∧ (State.fidelity s0 (s.evolveInverse a02Gates)).eqv one := by decide

/-- A03: after H on all 11 qubits every one of the 2048 amplitudes equals
exactly 1/√2^11 (so the exact max error is 0). -/
theorem A03_uniform_superposition :
    let s := (State.basis 11 0).evolve a03Gates
    s.k = 11 ∧ s.amp.all (· == GInt.one) = true ∧ s.support = 2048 := by decide

theorem A04_born_probabilities :
    let s := (State.basis 11 0).evolve a04Gates
    s.normSq.eqv one ∧ s.support = 2 ∧ (s.prob 0).eqv half ∧ (s.prob 1792).eqv half := by decide

theorem A05_encoding :
    let s0 := State.basis 11 100
    let s := s0.evolve a05Gates
    (State.fidelity s0 (s.evolveInverse a05Gates)).eqv one ∧
    s.k = 1 ∧ (s.rho0.head!.head!) = ⟨1, 0⟩ := by decide

/-- A08: ρ_A = I/2, purity = (1/2)² + (1/2)² + 2·|0|² = 1/2. -/
theorem A08_purity :
    let s := (State.basis 11 0).evolve a08Gates
    s.k = 1 ∧ s.rho0 = [[⟨1, 0⟩, ⟨0, 0⟩], [⟨0, 0⟩, ⟨1, 0⟩]] := by decide

/-- A08 purity value from the exact ρ: (1² + 1² + 2·0)/(2^1)² = 1/2. -/
theorem A08_purity_value : (1 * 1 + 1 * 1 + 2 * 0 : Nat) * 2 = 2 ^ (2 * 1) := by decide

/-! ## Reversible roundtrip on basis 7 (tests/test_hilbert11.py) -/

theorem roundtrip7_forward :
    let s0 := State.basis 11 7
    let s := s0.evolve roundtrip7Gates
    s.k = 2 ∧ s.support = 4 ∧
    QT.get 11 s.amp 6 = ⟨1, 0⟩ ∧ QT.get 11 s.amp 39 = ⟨1, 0⟩ ∧
    QT.get 11 s.amp 1542 = ⟨0, 1⟩ ∧ QT.get 11 s.amp 1575 = ⟨0, -1⟩ ∧
    (State.fidelity s0 s).eqv zero := by decide

theorem roundtrip7_back :
    let s0 := State.basis 11 7
    (State.fidelity s0 ((s0.evolve roundtrip7Gates).evolveInverse roundtrip7Gates)).eqv one ∧
    (s0.evolve roundtrip7Gates).normSq.eqv one := by decide

/-! ## Classical reversible baseline (tests/test_quantum.py) -/

def notGate (b : Nat) (s : List Bool) : List Bool := s.set b (!s.getD b false)
def toffoli (c1 c2 t : Nat) (s : List Bool) : List Bool :=
  if s.getD c1 false && s.getD c2 false then notGate t s else s
def toInt (s : List Bool) : Nat := s.foldl (fun v b => 2 * v + if b then 1 else 0) 0

theorem classical_baseline :
    let s := notGate 1 [true, false, true]
    s = [true, true, true] ∧ toffoli 0 1 2 s = [true, true, false] ∧ toInt (toffoli 0 1 2 s) = 6 := by
  decide

/-! ## Logged float values vs exact values

`near d e x u`: the logged decimal `d / 10^e` is within `2^-u` of the exact
dyadic `x`. -/

def near (d e : Nat) (x : Dy) (u : Nat) : Bool :=
  let lhs : Int := (d * 2 ^ x.exp : Nat)
  let rhs : Int := (x.num * 10 ^ e : Nat)
  ((lhs - rhs).natAbs * 2 ^ u) ≤ 10 ^ e * 2 ^ x.exp

/-- A01 `transition_fidelities=[0.4999999999999999, 0.12499999999999994, 0.1249999999999999]`
(identical in the Python reference, MLIR and Quipper logs) are within 2^-52 of
the exact 1/2, 1/8, 1/8. -/
theorem A01_logged_near_exact :
    near 4999999999999999 16 half 52 ∧ near 12499999999999994 17 eighth 52 ∧
    near 1249999999999999 16 eighth 52 := by decide

/-- A03 `max_err=1.73e-17` (float) against exact error 0: the logged value
1.734723475976807e-17 is below 2^-55. -/
theorem A03_logged_max_err : near 1734723475976807 32 zero 55 := by decide

/-- observer probabilities / ρ₀₀ logged as 0.4999999999999999. -/
theorem rho_logged_near_half : near 4999999999999999 16 half 52 := by decide

/-- roundtrip7: forward norm 0.9999999999999996, back fidelity 0.9999999999999993. -/
theorem roundtrip7_logged_near_one :
    near 9999999999999996 16 one 51 ∧ near 9999999999999993 16 one 50 := by decide

end PirtmHcalc.Data
