<!--
  SPDX-License-Identifier: AGPL-3.0-only
  Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
  Copyright (C) 2026 Ahmad Parr
-->

## Concrete code examples

Snippets taken from the tree (trimmed). Same objects the Lake scripts build and compare.

### Lean — exact Bell + adversarial pair (`PirtmHcalc/Data/Experiments.lean`)

```lean
def bellGates : List Gate := [.H 0, .CNOT 0 1]
def bell : State := (State.basis 2 0).evolve bellGates

theorem bell_amplitudes :
    bell.k = 1 ∧ QT.leaves bell.amp = [⟨1, 0⟩, ⟨0, 0⟩, ⟨0, 0⟩, ⟨1, 0⟩] := by decide

theorem bell_probabilities :
    (bell.prob 0).eqv half ∧ (bell.prob 3).eqv half ∧
    (bell.prob 1).eqv zero ∧ (bell.prob 2).eqv zero := by decide

def psi1Gates : List Gate := [.H 0, .CNOT 0 10]
def psi2Gates : List Gate := [.X 1, .H 0, .CNOT 0 10]
def psi1 : State := (State.basis 11 0).evolve psi1Gates
def psi2 : State := (State.basis 11 0).evolve psi2Gates

theorem global_fidelity_zero : (State.fidelity psi1 psi2).eqv zero := by decide
theorem reduced_states_equal :
    psi1.rho0 = [[⟨1, 0⟩, ⟨0, 0⟩], [⟨0, 0⟩, ⟨1, 0⟩]] ∧ psi2.rho0 = psi1.rho0 := by decide
```

Amplitudes are Gaussian integers over √2ᵏ; probabilities are exact dyadics. Global fidelity is 0; restricted observer on qubit 0 sees identical `I/2`.

### Lean — nested HCALC step (`Hcalc/Pipeline.lean`)

```lean
-- X_{t+1} = Ξ(t, Λm · C(Tp(X_t)))
noncomputable def step {n : Nat} (ε δ : Scalar) (t : Time) (x : Carrier n) : Carrier n :=
  hcalcStepCore (n := n) ε δ t x (gDefault n)

theorem step_eq {n : Nat} (ε δ : Scalar) (t : Time) (x : Carrier n) :
    step (n := n) ε δ t x =
      Xi (n := n) t (vsmul (LambdaM n ε δ) (C (n := n) ε (Tp x))) (gDefault n) :=
  rfl
```

### J — production verbs (`j/hcalc.ijs`)

```j
EPS_DEFAULT =: 0.05
tp_alpha =: 3 : 0
  primes =. (64 | i. n) { P64_cite_
  1 % (1 + ^. primes)          NB. α_j = 1/(1+ln p_{j mod 64})
)
hcalc_step =: 3 : 0            NB. X' = ξ·(Λm·C(Tp(X)))+g
  TpX =. tp_from_p64 xv
  CX  =. eps c_wrap TpX
  lam =. eps lam_m_from_bound n
  (xi ; g) hcalc_xi_apply (lam * CX)
)
```

Demo oracle (`logs/j/demo.out`) that MLIR must match digit-for-digit:

```
== hcalc: x = 1 2 3 4 5, eps = 0.05, tol = 1e_6, max_steps = 80
lam_m 1
step 0.59061610914964124 0.95301071608100862 1.149672880011765 1.357814664266902 1.4714991483190121
run_converged 1
run_steps 26
run_last_residual 7.8480715779981436e_7
== goldilocks
p 18446744069414584321
a_times_inv_a 1
```

### MLIR — custom `hcalc` dialect (`mlir/custom/hcalc_pipeline.mlir`)

```mlir
%lam = "hcalc.lambda_m"(%c5, %eps) : (index, f64) -> f64
%tp  = "hcalc.tp"(%x) : (memref<?xf64>) -> memref<?xf64>
%st  = "hcalc.step"(%x, %eps, %xi, %g)
     : (memref<?xf64>, f64, f64, memref<?xf64>) -> memref<?xf64>
%r:4 = "hcalc.run"(%x, %c80, %tol, %eps, %xi, %g)
     : (memref<?xf64>, index, f64, f64, f64, memref<?xf64>)
     -> (memref<?xf64>, i1, index, f64)
%m   = "hcalc.gl_mul"(%a, %b) : (i64, i64) -> i64   // Goldilocks
```

IRDL-verified against `mlir/dialects/hcalc.irdl.mlir`, lowered via `lowerCustom` to `func.call`, run, every printed line must appear in the J section above.

### Quipper — same circuits (`quipper/src/PirtmCircuits.hs`)

```haskell
bellGates = [H 0, CNOT 0 1]
psi1Gates = [H 0, CNOT 0 10]            -- |Ψ₁⟩ support {0, 1025}
psi2Gates = [X 1, H 0, CNOT 0 10]       -- |Ψ₂⟩ support {512, 1537}
roundtripGates = [H 0, CNOT 0 1, S 1, CNOT 1 5, H 5, CNOT 5 10, X 10]
a03Gates = [ H q | q <- [0 .. 10] ]
```

### Float ↔ exact bridge

```lean
/-- logged decimal d/10^e is within 2^{-u} of exact dyadic x */
theorem A01_logged_near_exact :
    near 4999999999999999 16 half 52 ∧
    near 12499999999999994 17 eighth 52 := by decide
```

A float log of `0.4999999999999999` is certified within one ulp of the exact `1/2` the kernel decided.
