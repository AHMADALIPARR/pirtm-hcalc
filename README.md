<div align="center">

# PIRTM × HCALC

### Formal semantics · Quantum-state algebra · Contractive dynamics · Compiler infrastructure

[![Lean](https://img.shields.io/badge/Lean-4.34.1-4444aa)](lean-toolchain)
[![MLIR](https://img.shields.io/badge/MLIR-IRDL-6936a5)](mlir/)
[![J](https://img.shields.io/badge/J-array%20computing-0077aa)](j/)
[![Quipper](https://img.shields.io/badge/Quipper-quantum%20circuits-006666)](quipper/)
[![License](https://img.shields.io/badge/License-AGPL--3.0-blue)](LICENSE)
[![CI](https://github.com/AHMADALIPARR/pirtm-hcalc/actions/workflows/ci.yml/badge.svg)](https://github.com/AHMADALIPARR/pirtm-hcalc/actions/workflows/ci.yml)
[![j](https://img.shields.io/badge/j-PASS-brightgreen)](logs/j/SUMMARY.txt)
[![mlir](https://img.shields.io/badge/mlir-PASS-brightgreen)](logs/mlir/SUMMARY.txt)
[![cpp](https://img.shields.io/badge/cpp-PASS-brightgreen)](logs/cpp/SUMMARY.txt)
[![irdl](https://img.shields.io/badge/irdl-PASS-brightgreen)](logs/mlir/IRDL.txt)
[![quipper](https://img.shields.io/badge/quipper-PASS-brightgreen)](logs/quipper/SUMMARY.txt)
[![lean](https://img.shields.io/badge/lean-PASS-brightgreen)](logs/lean/SUMMARY.txt)
[![foundry](https://img.shields.io/badge/foundry-PASS-brightgreen)](foundry/README.md)

**Ahmad Parr · Version 1.0.0**

</div>

```text
PIRTM causal semantics ──→ Lean and Lake
HCALC recurrence ──→ Lean and Lake
Exact quantum and field data ──→ Lean and Lake
Lean and Lake ──→ Axiom audit
J numerical backend ──→ Reference comparison
MLIR and IRDL ──→ Reference comparison
Quipper circuits ──→ Reference comparison
Axiom audit ──→ Evidence logs
Reference comparison ──→ Evidence logs
```


---

PIRTM–HCALC is a unified production package for causal and reversible computation, exact finite quantum-state simulation, prime-indexed contraction dynamics, and cross-language numerical verification. It brings two source baselines into one Lake package, retaining their mathematical boundaries while introducing exact computational models and custom compiler operations. The package additionally includes the Foundry F1 J stack, a TableGen dialect, native C++ field arithmetic and NASM digest interfaces.

| 461 audited theorems | 2,048 quantum amplitudes | 27 historical IRDL operations | 5 verification subsystems |
|:---:|:---:|:---:|:---:|
| 313 empty axiom sets | 11 qubits | 2 IRDL dialects + Foundry TableGen | 55 declared project axioms |

**Production verification baseline:** full pipeline run at revision [`63dffec`](https://github.com/AHMADALIPARR/pirtm-hcalc/tree/63dffec650a9781f94d8120f92cdb1bca45fb7ba) — `lake script run all` exit 0 on November 25, 2026, all five stages PASS (j, mlir, irdl, quipper, lean); GitHub Actions CI run [45509935546](https://github.com/AHMADALIPARR/pirtm-hcalc/actions/runs/45509935546) completed success on the same commit. Counts below are from that measured run and the recorded audit. The 46 Foundry operations are documented separately.

## Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
   - [Four-surface evidence contract](#four-surface-semantics-and-evidence-contract)
3. [Repository layout](#repository-layout)
4. [PIRTM: causal and reversible computation](#pirtm-causal-and-reversible-computation)
5. [Quantum semantics](#quantum-semantics)
   - [Observer comparison](#global-observer-versus-restricted-observer)
6. [HCALC: nested contraction dynamics](#hcalc-nested-contraction-dynamics)
   - [Deterministic pipeline atlas](#deterministic-pipeline-atlas)
7. [Goldilocks arithmetic](#goldilocks-arithmetic)
8. [MLIR and IRDL](#mlir-and-irdl)
9. [J array backend](#j-array-backend)
10. [Quipper circuit backend](#quipper-circuit-backend)
11. [Worker and oracle subsystem](#worker-and-oracle-subsystem)
12. [Formal model ports](#formal-model-ports)
13. [Build and reproduce](#build-and-reproduce)
14. [Verification evidence](#verification-evidence)
15. [Trust boundaries](#trust-boundaries)
16. [Exact quantum implementation: representation-level reference](#exact-quantum-implementation-representation-level-reference)
    - [Folded amplitude tree](#folded-amplitude-tree-illustration)
17. [HCALC numerical reference: a complete worked trajectory](#hcalc-numerical-reference-a-complete-worked-trajectory)
    - [ASCII residual profile](#nested-iteration--ascii-residual-profile)
18. [Goldilocks: reduction mathematics and concrete test vectors](#goldilocks-reduction-mathematics-and-concrete-test-vectors)
19. [MLIR implementation atlas](#mlir-implementation-atlas)
20. [Oracle, retrieval and bounded reasoning: detailed subsystem reference](#oracle-retrieval-and-bounded-reasoning-detailed-subsystem-reference)
21. [Formal model ports: obligation-by-obligation interpretation](#formal-model-ports-obligation-by-obligation-interpretation)
22. [J array computing: numerical implementation reference](#j-array-computing-numerical-implementation-reference)
23. [Quipper circuit representation and cross-backend comparison](#quipper-circuit-representation-and-cross-backend-comparison)
24. [Verification driver: exact acceptance semantics](#verification-driver-exact-acceptance-semantics)
25. [Axiom audit: quantitative and qualitative interpretation](#axiom-audit-quantitative-and-qualitative-interpretation)
26. [Assurance matrix: established scope and remaining obligations](#assurance-matrix-established-scope-and-remaining-obligations)
27. [Foundry F1: J, TableGen and native kernels](#foundry-f1-j-tablegen-and-native-kernels)
28. [Current tracked file inventory](#current-tracked-file-inventory)
29. [Figure provenance](#figure-provenance)
30. [Provenance and licensing](#provenance-and-licensing)

## Overview

PIRTM–HCALC brings two codebases into a single Lake package. PIRTM models causal histories, reversible transformations, finite quantum experiments, observation boundaries and worker aggregation. HCALC models a nested state recurrence driven by prime-indexed diagonal weights, contraction control and stabilization. The combined package includes exact Lean computations, numerical MLIR and J programs, and Quipper circuit descriptions.

The central design is to expose several distinct kinds of evidence: kernel-checked propositions, exact finite computations, numerical reference comparisons, and IR structural validation. Each has a different scope. In particular, HCALC's abstract real-number assumptions remain explicit, and matching backend output is separate from a universal equivalence proof.

| Layer | Representation | Responsibility |
|---|---|---|
| PIRTM | Lean inductive types and structures | Causality, reversibility, observation boundaries |
| HCALC | Abstract real carrier and operators | Recurrence, stabilization, conditional fixed-point properties |
| Combined semantics | Lean exact arithmetic | Quantum examples, field calculations, worker data |
| Compiler | MLIR and IRDL | Typed operations and lowering to callable numerical kernels |
| Array computing | J | Spectral helpers, contraction and field calculations |
| Quantum circuits | Haskell / Quipper | Circuit construction and simulation comparison |
| Orchestration | Lake | Build, run, compare and record evidence |

## Architecture

```text
PIRTM core ──→ PirtmHcalc umbrella
HCALC core ──→ PirtmHcalc umbrella
Exact quantum semantics ──→ PirtmHcalc umbrella
Agda and Alloy model ports ──→ PirtmHcalc umbrella
Exact data theorems ──→ PirtmHcalc umbrella
PirtmHcalc umbrella ──→ Lean kernel and axiom audit
J numerical backend ──→ Evidence comparison
MLIR numerical backend ──→ Evidence comparison
Quipper circuit backend ──→ Evidence comparison
Archived reference outputs ──→ Evidence comparison
Lean kernel and axiom audit ──→ Recorded summaries
Evidence comparison ──→ Recorded summaries
```

The diagram describes the package and evidence relationships; it does not assert that the Lean compiler verifies the MLIR or Quipper implementation.

### Four-surface semantics and evidence contract

```text
exact semantics contract  (same numbers, four surfaces)
quantities: amplitudes, fidelities, HCALC step

 +--------+      +--------+    +--------+      +--------+
 | Lean   |      | J      |    | MLIR   |      | Quipper |
 +--------+      +--------+    +--------+      +--------+

       =====           =====           =====
    decide          hcalc_step     dialect       circuits

agreement: near(float_log, exact, 2^-52)
no float on the Real / decide path
-------------------------------------------------------------------
pirtm-hcalc  multi-surface contract  seed=11
```

The supplied diagram expresses the cross-surface design. Its equality markers are schematic, not a universal equivalence theorem. Exact quantum and field values are computed in Lean; the HCALC real-number path instead uses abstract noncomputable operations. J and MLIR compare HCALC numerics, while Quipper supplies quantum circuits and associated numerical results. The exact experiment module uses individual decimal proximity bounds with an exponent parameter, rather than a single blanket bound for all outputs.

```text
│d/10ᵉ − m/2ᵏ│ ≤ 2⁻ᵘ
```

Here d/10^(e) is a logged decimal interpreted as a rational, m/2^(k) is an exact dyadic observable, and u is the precision parameter of the relevant bound. This is the mathematical form of an absolute error bound; the particular theorem controls which values and exponent are admitted.

| Surface | Exact quantum observables | HCALC step | Evidence mechanism |
|---|---|---|---|
| Lean | Exact finite examples | Abstract scalar model | Kernel proofs and axiom audit |
| J | Outside the documented J scope | Numerical implementation | Property harness and demo |
| MLIR | Numerical simulation | Numerical implementation | Reference output comparison and IRDL checks |
| Quipper | Circuit simulation | Outside the documented Quipper scope | Circuit output and reference comparison |

## Repository layout

```text
pirtm-hcalc/
├── .github/workflows/         CI configuration
├── PIRTM/
│   ├── Core.lean              Causal paths and bounded inference
│   ├── Invariants.lean        Reversibility and observation boundaries
│   └── Quantum11.lean         Gate alphabet and worker roles
├── Hcalc/
│   ├── RealStub.lean          Abstract scalar assumptions
│   ├── Carrier.lean           Finite-dimensional carrier
│   ├── Foundry.lean           Foundry interfaces and helper laws
│   ├── Axioms.lean            Mathematical operator definitions
│   ├── Pipeline.lean          Nested recurrence
│   ├── Convergence.lean       Conditional fixed-point results
│   ├── Invariants.lean        HCALC invariants
│   └── Production.lean        Production-level definitions
├── PirtmHcalc/
│   ├── Agda/                  Lean ports of Agda models
│   ├── Alloy/                 Lean ports of relational models
│   ├── Quantum/Exact.lean     Exact state simulation
│   └── Data/
│       ├── Experiments.lean   Quantum experiment propositions
│       ├── Goldilocks.lean    Modular arithmetic propositions
│       └── Agents.lean        Worker report propositions
├── j/                         HCALC and Foundry F1 J implementations
│   ├── foundry.ijs            Foundry package loader
│   ├── foundry_harness.ijs    Foundry record driver
│   ├── types.ijs              Constants and tier definitions
│   ├── pmat.ijs               Prime monomial matrices
│   ├── recurrence.ijs         Additive contraction recurrence
│   ├── gate.ijs               Emission and CSL
│   └── certify.ijs            Ace certification
├── mlir/
│   ├── dialects/              IRDL and Foundry TableGen definitions
│   │   ├── FoundryDialect.td
│   │   └── goldilocks_add_mul_mlir
│   ├── lib/                   Computational kernels
│   ├── main/                  Numerical programs
│   └── custom/                Dialect examples and negative tests
│       └── Goldilocks/        Native C++ field and NASM mask gate
│           ├── goldilocks.cpp
│           ├── goldilocks.h
│           ├── test_goldilocks.cpp
│           └── mask_gate/     SHA-256, adapters, drivers and lowering map
├── quipper/                   Haskell circuit implementation
├── spec/PRODUCTION.md         Canonical HCALC mathematics
├── tools/                     Audit and Foundry orchestration
│   ├── AxiomAudit.lean
│   ├── run.sh
│   └── script_instructions.md
├── verify/                    J property harness
├── logs/                      Recorded and reference output
├── PIRTM.lean                 PIRTM import root
├── Hcalc.lean                 HCALC import root
├── PirtmHcalc.lean            Combined import root
├── lakefile.lean              Build and comparison driver
├── lake-manifest.json         Dependency manifest
├── lean-toolchain             Pinned compiler
└── LICENSE
```

## PIRTM: causal and reversible computation

### Causal paths

The causal relation is indexed by natural-number endpoints. Each edge carries a strict ordering witness. A path can be a direct edge or an edge followed by another path. Consequently, every path from `a` to `b` establishes `a < b`, and a path returning to its starting point is impossible in this model.

| Declaration | Meaning |
|---|---|
| `PIRTM.Core.CausalPath` | Indexed causal path |
| `causal_strict` | Every path respects strict order |
| `causal_acyclic` | Self-returning paths imply contradiction |
| `SystemState` | Version and well-formedness flag |
| `ValidTransition` | Admissible successor transition |
| `state_preservation` | Transition preserves well-formedness |
| `FuelBoundedExecution` | Inductive relation for bounded inference |

The following is a client-side example using the existing theorem, rather than a new implementation of the relation:

```lean
import PIRTM.Core

open PIRTM.Core

example (n : Nat) (h : CausalPath n n) : False :=
  causal_acyclic n h
```

The bounded inference model distinguishes a fixed-point stop from exhaustion of fuel. Exhaustion alone does not establish arrival at a fixed point.

### Reversible operators

A reversible codec carries an encoding, decoding and left-inverse witness. The invertible operator structure requires inverse laws in both directions. Composition uses reverse order for the inverse.

```text
(g ∘ f)⁻¹ = f⁻¹ ∘ g⁻¹.
```

| Declaration in `PIRTM.Invariants` | Contract |
|---|---|
| `ReversibleCodec` | Decode after encode recovers the input |
| `codec_roundtrip_lemma` | Exposes the codec's witness |
| `bit_flip_involutive` | Two Boolean flips recover the original value |
| `InvertibleOp` | Left and right inverse laws |
| `compose_ops` | Composition preserves those inverse laws |
| `observation_non_unique` | A witnessed non-injective projection has no universal left inverse |
| `worker_isolation_lemma` | Different identifiers imply different worker records |

### Observation boundaries

For a projection P : B → O, suppose b₁ ≠ b₂ and P(b₁) = P(b₂). A reconstruction function cannot be a left inverse on all of B: it would map the same observation to two distinct objects. This is the mathematical structure represented by `NonInjectiveMap`.

```text
Global state one ──→ Restricted projection
Global state two ──→ Restricted projection
Restricted projection ──→ Identical observation
Global state one ── (full observation)→ Distinguishable states
Global state two ── (full observation)→ Distinguishable states
```

## Quantum semantics

### Eleven-coordinate model

```text
ℋ = (ℂ²)^(⊗11),   dim ℋ = 2048.
```

`PIRTM.Quantum11` represents coordinates using `Fin 11`, defines a discrete gate alphabet, and establishes an involution law for the syntactic inverse of a circuit. The separate exact simulator in `PirtmHcalc/Quantum/Exact.lean` evaluates the concrete experiments.

| Quantity | Exact value |
|---|---:|
| Qubits | 11 |
| Basis states | 2048 |
| Uniform-superposition probability per basis state | 1/2048 |
| Uniform amplitude | 1/√2048 |

The exact representation uses Gaussian-integer numerators with a shared power of √2 in the denominator. Probabilities and squared norms can therefore be compared through integer/dyadic arithmetic for the supported gates.

```text
ψⱼ = (aⱼ + i bⱼ)/(√2)ᵏ,   aⱼ, bⱼ ∈ ℤ.
```

### Bell-state experiment

```text
q0: |0> ── H ──●──
               │
q1: |0> ───────X──
```

```text
│Φ⁺⟩ = (│00⟩ + │11⟩)/√2.
```

| Measurement outcome | Probability |
|---|---:|
| 00 | 1/2 |
| 01 | 0 |
| 10 | 0 |
| 11 | 1/2 |

The named results `bell_amplitudes` and `bell_probabilities` in `PirtmHcalc/Data/Experiments.lean` establish the corresponding exact computations.

### Globally distinct, locally indistinguishable states

The central experiment constructs two 11-qubit states:

```text
│ψ₁⟩ = (│0⟩ + │1025⟩)/√2
│ψ₂⟩ = (│512⟩ + │1537⟩)/√2
```

Their basis supports are disjoint. Their global fidelity is zero, while the reduced state on qubit zero is the same for both:

```text
ρ₀⁽¹⁾ = ρ₀⁽²⁾ = ½ I₂.
```

| Basis index | First state amplitude | Second state amplitude |
|---:|---:|---:|
| 0 | 1/√2 | 0 |
| 512 | 0 | 1/√2 |
| 1025 | 1/√2 | 0 |
| 1537 | 0 | 1/√2 |

```text
State one ──→ Global overlap
State two ──→ Global overlap
Global overlap ──→ Fidelity equals zero
State one ──→ Reduce to qubit zero
State two ──→ Reduce to qubit zero
Reduce to qubit zero ──→ Both reduced states equal I over 2
Reduce to qubit zero ──→ Both reduced states equal I over 2
```

| Exact theorem | Established result |
|---|---|
| `psi_support` | Two nonzero amplitudes in each state at specified indices |
| `psi_normalized` | Both squared norms equal one |
| `global_fidelity_zero` | Orthogonality in the experiment |
| `reduced_states_equal` | Identical reduced density matrices |
| `reduced_trace_distance_zero` | Zero difference in the represented matrices |
| `adversarial_conclusion` | Joint global and local result |

#### Global observer versus restricted observer

```text
global observer vs restricted observer (qubit 0)
Psi1 = (|0> + |1025>)/sqrt(2)
Psi2 = (|512> + |1537>)/sqrt(2)

   global  <Psi1|Psi2> = 0         restricted  rho0

       Psi1                        +-----------+
         ^                         | 1/2     0 |
         |                         | 0     1/2 |
         +----> Psi2               +-----------+
         orthogonal                I/2 exact

fidelity_global = 0
rho0(Psi1) = rho0(Psi2) = I/2
trace distance of reduced states = 0
---------------------------------------------------------------
pirtm-hcalc  adversarial pair  seed=11
```

The axes are schematic: orthogonality is a property of the inner product in the full Hilbert space, not a physical direction in three-dimensional space. Write ρ^((i)) = |ψ_(i)⟩⟨ψ_(i)| for the pure-state density operator. The observer retains qubit zero and traces out the ten remaining qubits:

```text
ρ₀⁽ⁱ⁾ = Tr₁,…,₁₀(ρ⁽ⁱ⁾) = ½ [[1, 0], [0, 1]].
```

```text
F(ψ₁, ψ₂) = │⟨ψ₁│ψ₂⟩│² = 0
½ ∥ρ₀⁽¹⁾ − ρ₀⁽²⁾∥₁ = 0
```

The usual trace distance vanishes here because the two matrices are equal. The numerical implementation uses a Frobenius-based quantity; equality in this experiment makes both quantities zero without establishing general equivalence between the norms.

#### Exact adversarial basis support


| State | Index | 11-bit basis (q0 is MSB) | Exact amplitude | Probability |
|---|---:|---|---|---|
| Psi1 | 0 | `00000000000` | 1/√2 | 1/2 |
| Psi1 | 1025 | `10000000001` | 1/√2 | 1/2 |
| Psi2 | 512 | `01000000000` | 1/√2 | 1/2 |
| Psi2 | 1537 | `11000000001` | 1/√2 | 1/2 |

The supports are disjoint; the global inner product is zero. Tracing out qubits 1–10 gives the same reduced density matrix I/2 for both states. See `PirtmHcalc/Data/Experiments.lean`.

### Reversible experiments and uniform superposition

| Result | Evidence in `Data/Experiments.lean` |
|---|---|
| Temporal fidelities | `A01_transition_fidelities`: 1/2, 1/8, 1/8 |
| Inverse circuit | `A02_norm_and_roundtrip`: norm and recovered fidelity equal one |
| Full superposition | `A03_uniform_superposition`: all 2048 amplitudes have equal numerator |
| Born probabilities | `A04_born_probabilities`: two outcomes of probability 1/2 |
| Encoding | `A05_encoding`: recovered fidelity equals one |
| Restricted observer | `A08_purity`, `A08_purity_value`: purity 1/2 |
| Seven-gate roundtrip | `roundtrip7_forward`, `roundtrip7_back` |
| Classical baseline | `classical_baseline`: Boolean NOT and Toffoli example |

## HCALC: nested contraction dynamics

HCALC defines a recurrence on a finite-dimensional scalar carrier. The production mathematical specification is [spec/PRODUCTION.md](spec/PRODUCTION.md).

```text
X_(t + 1) = Ξ(t, Λ_(m)C(T_(p)(X_(t)))).
```

### Prime-indexed diagonal transform

Let p_(j) denote an entry in the first-64-primes table, indexed cyclically.

```text
αⱼ = 1/(1 + ln(p[j mod 64]))
(Tₚ x)ⱼ = αⱼ xⱼ
```

The transformation is diagonal. It assigns weights to existing coordinates rather than permuting them. The weight law is a definition of the HCALC specification.

### Contraction governor

For an operator-norm estimate q and margin ε, the state scaling is

```text
C(x) = ((1 − ε)/q) x   when q > 1 − ε
C(x) = x               otherwise
```

The specification uses Gershgorin estimates and a power-iteration fallback. For a diagonal matrix, the absolute diagonal maximum gives its induced infinity norm.

### Stabilization and evolution

```text
Λₘ = min(1, (1 − ε)/(∥C ∘ Tₚ∥ₒₚ + δ))
Ξ(t,y) = ξₜ y + gₜ
```

| Parameter | Production default |
|---|---:|
| Contraction margin | 0.05 (T2) |
| Denominator guard | 10⁻¹² |
| Residual tolerance | 10⁻⁶ |
| Schedule | Uniform, ξ_(t) = 1 |
| Affine kick | Zero vector |

```text
Current state ──→ Prime diagonal transform
Prime diagonal transform ──→ Contraction governor
Contraction governor ──→ Scalar stabilization
Scalar stabilization ──→ Time schedule and affine kick
Time schedule and affine kick ──→ Next state
Current state ──→ Infinity norm residual
Next state ──→ Infinity norm residual
Infinity norm residual ──→ Within tolerance?
Within tolerance? ── (Yes)→ Stop
Within tolerance? ── (No)→ Next iteration
Next iteration ──→ Current state
```

### Deterministic pipeline atlas

#### Seeded visualization (illustrative, not a numerical oracle)

The supplied generator uses modular pseudo-prime values and a synthetic per-row q. Its output is reproducible for seed 11 but does not represent the production prime table or global contraction norm. The exact quantum support panel is independent of those synthetic magnitudes.

```text
 X' = Xi(t, Lambda_m * C(Tp(X)))
 eps=0.05  n=11  bridge=InstanceBridge
     Tp         C          Lm         Xi        exact support
 0  ..... ->  ..... ->  @@@@@ ->  .....         Psi1
 1  ----- ->  ----- ->  @@@@@ ->  -----           |0>
 2  ..... ->  ..... ->  @@@@@ ->  .....           |1025>
 3  ..... ->  ..... ->  @@@@@ ->  .....
 4  ::::: ->  ::::: ->  @@@@@ ->  :::::         Psi2
 5  ..... ->  ..... ->  @@@@@ ->  .....           |512>
 6  ::::: ->  ::::: ->  @@@@@ ->  :::::           |1537>
 7  ..... ->  ..... ->  @@@@@ ->  .....
 8  ..... ->  ..... ->  @@@@@ ->  .....         <P1|P2>=0
 9  ::::: ->  ::::: ->  @@@@@ ->  :::::         rho0 = I/2
10  ..... ->  ..... ->  @@@@@ ->  .....

 amplitudes: z / sqrt(2)^k   z in Z[i]
 Lean: decide   J: hcalc_step   MLIR: dialect
 no native_decide on Real path

-------------------------------------------------------------------
 pirtm-hcalc  nested faithful step
 seed=11  width=68
```

#### Seeded generator numerical trace

| Coordinate | Synthetic p | alpha | synthetic q | C scale | Lambda | output weight | Density |
|---:|---:|---:|---:|---:|---:|---:|:---:|
| 0 | 56 | 0.198991048098 | 0.619646866834 | 1.000000000000 | 1.000000000000 | 0.198991048098 | `.....` |
| 1 | 4 | 0.419059784196 | 0.696670924469 | 1.000000000000 | 1.000000000000 | 0.419059784196 | `-----` |
| 2 | 41 | 0.212153327847 | 0.624253664747 | 1.000000000000 | 1.000000000000 | 0.212153327847 | `.....` |
| 3 | 78 | 0.186681791442 | 0.615338627005 | 1.000000000000 | 1.000000000000 | 0.186681791442 | `.....` |
| 4 | 26 | 0.234846718732 | 0.632196351556 | 1.000000000000 | 1.000000000000 | 0.234846718732 | `:::::` |
| 5 | 63 | 0.194433949954 | 0.618051882484 | 1.000000000000 | 1.000000000000 | 0.194433949954 | `.....` |
| 6 | 11 | 0.294299829664 | 0.653004940382 | 1.000000000000 | 1.000000000000 | 0.294299829664 | `:::::` |
| 7 | 48 | 0.205288182064 | 0.621850863723 | 1.000000000000 | 1.000000000000 | 0.205288182064 | `.....` |
| 8 | 85 | 0.183733984206 | 0.614306894472 | 1.000000000000 | 1.000000000000 | 0.183733984206 | `.....` |
| 9 | 33 | 0.222394822277 | 0.627838187797 | 1.000000000000 | 1.000000000000 | 0.222394822277 | `:::::` |
| 10 | 70 | 0.190530800521 | 0.616685780182 | 1.000000000000 | 1.000000000000 | 0.190530800521 | `.....` |

#### Production formula — first eleven prime coordinates

Computed independently using the documented prime weights, with one global q = 0.590616109149641, C scale = 1, Lambda = 1, uniform Xi and zero kick. These are derived numerical values, not new Lean proofs or backend test results.

| Coordinate | Prime | Tp weight | C(Tp) weight | Lambda C(Tp) weight | Xi output weight |
|---:|---:|---:|---:|---:|---:|
| 0 | 2 | 0.590616109150 | 0.590616109150 | 0.590616109150 | 0.590616109150 |
| 1 | 3 | 0.476505358041 | 0.476505358041 | 0.476505358041 | 0.476505358041 |
| 2 | 5 | 0.383224293337 | 0.383224293337 | 0.383224293337 | 0.383224293337 |
| 3 | 7 | 0.339453666067 | 0.339453666067 | 0.339453666067 | 0.339453666067 |
| 4 | 11 | 0.294299829664 | 0.294299829664 | 0.294299829664 | 0.294299829664 |
| 5 | 13 | 0.280508893600 | 0.280508893600 | 0.280508893600 | 0.280508893600 |
| 6 | 17 | 0.260877731095 | 0.260877731095 | 0.260877731095 | 0.260877731095 |
| 7 | 19 | 0.253521478031 | 0.253521478031 | 0.253521478031 | 0.253521478031 |
| 8 | 23 | 0.241809067499 | 0.241809067499 | 0.241809067499 | 0.241809067499 |
| 9 | 29 | 0.228974642188 | 0.228974642188 | 0.228974642188 | 0.228974642188 |
| 10 | 31 | 0.225530646320 | 0.225530646320 | 0.225530646320 | 0.225530646320 |

### Fixed points and residuals

The abstract contraction hypothesis bundles a strict Lipschitz constant and a margin condition. Given that hypothesis and the scalar assumptions, `unique_fixed_point` establishes that two fixed points must coincide. For the default zero-kick stabilized map, zero is a fixed point, yielding the conditional existence-and-uniqueness statement.

The residual is

```text
J(x) = ∥x − F(x)∥_(∞).
```

| Lean declaration | Scope |
|---|---|
| `HypContractive` | Explicit contraction hypotheses |
| `unique_fixed_point` | At most one fixed point under those hypotheses |
| `residual_at_fixed_point` | Fixed point has zero residual |
| `stabilized_fixes_zero` | Zero is fixed by the stabilized map |
| `unique_fp_stabilized_of_hyp` | Zero is the unique fixed point under the hypothesis |
| `unique_fp_step_of_hyp` | Corresponding nested-step result |
| `J_at_zero` | Residual at zero |

These theorems use the HCALC scalar abstraction. They do not constitute a machine-checked analysis of the floating-point implementation over Mathlib's real numbers.

### Nested versus additive evolution

The production recurrence and the Foundry-shaped diagnostic are explicitly distinguished:

```text
F_(nested)(x) = ξ_(t)Λ_(m)C(T_(p)x) + g_(t),
```

```text
F_(additive)(x) = ξ_(t)x + Λ_(m)C(T_(p)x) + g_(t).
```

The `InstanceBridge` relates their parameterization without identifying the two formulas. This distinction matters when importing results about schedule scaling into state scaling.

## Goldilocks arithmetic

The modular arithmetic backend uses

```text
p = 2⁶⁴ − 2³² + 1 = 18446744069414584321.
```

Two useful reduction identities are

```text
2⁶⁴ ≡ 2³² − 1 (mod  p),   2⁹⁶ ≡ −1 (mod  p).
```

For canonical residues, split a product into a low 64-bit word and a high word, then split the high word into 32-bit pieces. The congruences reduce the product using smaller shifts and arithmetic before the final modular reduction. `foldMul` represents this strategy using exact Lean natural-number arithmetic.

| Operation | Recorded exact result |
|---|---:|
| a + b (mod  p) | 3775478042807637890 |
| a − b (mod  p) | 2469135690246913569 |
| b − a (mod  p) | 15977608379167670752 |
| ab (mod  p) | 7432351747408847865 |
| (p − 1)² (mod  p) | 1 |
| 7¹⁰⁰ (mod  p) | 2335214203647002900 |
| Inverse of a in the recorded example | 16343323056350712102 |

Here a = 12345678901234567890 and b = 9876543210987654321.

```lean
import PirtmHcalc.Data.Goldilocks

open PirtmHcalc.Data.Goldilocks

example : p = 2 ^ 64 - 2 ^ 32 + 1 := p_def
example : foldMul (p - 1) (p - 1) = 1 := logged_mul_pm1_sq
```

`fold_vs_ref_200` establishes agreement for the 200 deterministic sample pairs defined in the source. It is a finite computation theorem, rather than a universal multiplication-refinement proof. The bounded exponentiation routine likewise requires adequate fuel for the intended exponent.

## MLIR and IRDL

The compiler subsystem contains custom `pirtm` and `hcalc` dialect descriptions, supporting libraries and programs. The Lake driver validates custom operations using IRDL and rewrites recognized generic-form operation names to function calls. Standard MLIR conversion passes then lower the program toward LLVM dialect operations for the CPU runner.

```text
Custom generic MLIR ──→ IRDL validation
IRDL validation ──→ Text-based operation mapping
Text-based operation mapping ──→ Function calls
Function calls ──→ MLIR conversion passes
MLIR conversion passes ──→ CPU runner
CPU runner ──→ Reference comparison
```

| PIRTM operation | Function target |
|---|---|
| `pirtm.basis` | `sv_basis` |
| `pirtm.copy` | `sv_copy` |
| `pirtm.h` | `sv_h` |
| `pirtm.x` | `sv_x` |
| `pirtm.y` | `sv_y` |
| `pirtm.z` | `sv_z` |
| `pirtm.s` | `sv_s` |
| `pirtm.sdg` | `sv_sdg` |
| `pirtm.cnot` | `sv_cnot` |
| `pirtm.circuit` | `circ_new` |
| `pirtm.gate` | `set_gate` |
| `pirtm.evolve` | `sv_evolve` |
| `pirtm.evolve_inverse` | `sv_evolve_inverse` |
| `pirtm.fidelity` | `sv_fidelity` |
| `pirtm.norm2` | `sv_norm2` |
| `pirtm.sha256` | `sha256` |

| HCALC operation | Function target |
|---|---|
| `hcalc.tp_alpha` | `tp_alpha` |
| `hcalc.tp` | `tp_from_p64` |
| `hcalc.c` | `c_wrap` |
| `hcalc.lambda_m` | `lam_m` |
| `hcalc.step` | `hcalc_step` |
| `hcalc.residual` | `residual_linf` |
| `hcalc.run` | `hcalc_run` |
| `hcalc.gl_add` | `gl_add` |
| `hcalc.gl_sub` | `gl_sub` |
| `hcalc.gl_mul` | `gl_mul` |
| `hcalc.gl_pow` | `gl_pow` |
| `hcalc.gl_inv` | `gl_inv` |

### Libraries and entry points

| Library | Functionality |
|---|---|
| `lib/qsim.mlir` | State-vector operations |
| `lib/qmat.mlir` | Quantum matrix and gate routines |
| `lib/sha256.mlir` | SHA-256 digest implementation |
| `lib/oracle.mlir` | Content-addressed storage and retrieval |
| `lib/hcalc.mlir` | Numerical contraction recurrence |
| `lib/goldilocks.mlir` | Modular arithmetic |
| `lib/io.mlir`, `lib/jfmt.mlir` | Numeric and textual output |

The `main/` programs cover `hilbert11`, `quantum`, `oracle`, `engine`, `agents`, `hcalc`, and `goldilocks`. The custom dialect examples are `custom/hcalc_pipeline.mlir` and `custom/pirtm_roundtrip.mlir`.

### Negative structural tests

The `irdl` Lake script checks that the custom examples require their dialect registration and that three malformed inputs are rejected:

- `hcalc_bad_operand_type.mlir`
- `hcalc_bad_result_count.mlir`
- `pirtm_bad_operand_count.mlir`

Structural IR validation and successful lowering establish different properties from semantic preservation. The current lowering is a textual operation-name mapping, not a certified general-purpose compiler pass.

## J array backend

| Source | Responsibility |
|---|---|
| `j/hcalc.ijs` | HCALC state recurrence |
| `j/cite.ijs` | Prime table and spectral helper implementation |
| `j/goldilocks.ijs` | Modular arithmetic |
| `j/demo.ijs` | Numerical demonstration and reference output |
| `verify/run.ijs` | Property harness entry point |
| `verify/tests/props.ijs` | Property definitions |

J supplies a separate array-oriented numerical path for the HCALC and Goldilocks examples. Its demo output is split into sections and compared against MLIR output by Lake. The HCALC run recorded in the gap ledger uses 26 steps. The floating-point path and abstract Lean real-number path have distinct assurance boundaries.

## Quipper circuit backend

The Haskell backend builds circuit descriptions and provides numerical simulation output. The port map identifies `quipper/src/PirtmCircuits.hs` and `quipper/src/Analysis.hs` as part of the quantum model migration. The driver builds the `pirtm-quipper` target with Cabal and compares its numeric lines with archived PIRTM reference output after filtering circuit-printing lines.

This comparison includes circuit experiments and reversible baselines. It is a software circuit model rather than evidence of physical quantum hardware operation.

## Worker and oracle subsystem

### Worker roles

| Worker | Role | Passed | Failed | Not run |
|---|---|---:|---:|---:|
| A01 | Temporal | 3 | 0 | 0 |
| A02 | Reversible | 2 | 0 | 0 |
| A03 | Coordinates | 1 | 0 | 0 |
| A04 | Measurement | 2 | 0 | 0 |
| A05 | Encoding | 2 | 0 | 0 |
| A06 | Ambiguity | 1 | 0 | 0 |
| A07 | Recursive | 1 | 0 | 0 |
| A08 | Restricted observer | 1 | 0 | 0 |
| A09 | Entropy | 2 | 0 | 0 |
| A10 | Agda | 0 | 0 | 11 |
| A11 | Adversarial | 2 | 0 | 0 |
| **Total** | **11 workers** | **17** | **0** | **11** |

The role enumeration and indexing appear in `PIRTM/Quantum11.lean`. The report data and exact aggregate-count proposition appear in `PirtmHcalc/Data/Agents.lean`. That module also establishes the lexical sample's token counts and properties of the sorted invariant list.

These are recorded software worker roles, not evidence of eleven independently trained AI systems. The current MLIR scheduler visits workers sequentially in sorted order; its reference implementation used a thread pool.

### Oracle and storage

The MLIR oracle subsystem includes content-addressed storage, retrieval and digest functionality. Its current CAS uses fixed-capacity in-memory storage. Its deterministic FNV-1a embedding fallback differs from Python's process-salted hash. Matching reference cases therefore do not imply equal retrieval rankings on arbitrary inputs.

## Formal model ports

The combined Lean import root incorporates Agda-derived and Alloy-derived models. The current source paths are listed in the tracked file inventory; the historical port ledger is no longer tracked.

| Module | Migration target |
|---|---|
| `PirtmHcalc/Agda/Core.lean` | Core model |
| `PirtmHcalc/Agda/Assumptions.lean` | Assumptions |
| `PirtmHcalc/Agda/Invariants.lean` | Invariant propositions |
| `PirtmHcalc/Alloy/VacuityDemo.lean` | Vacuity example |
| `PirtmHcalc/Alloy/HcalcMirror.lean` | HCALC mirror model |
| `PirtmHcalc/Alloy/Hcalc.lean` | HCALC relational model |

The termination proposition derived from Agda takes an explicit fixed-point hypothesis. The Alloy-derived vacuity analysis addresses checks that already follow from model facts. The original Agda analyzer run was recorded as `NOT_RUN`; the current project represents those models in Lean instead of claiming a separate Agda type-check.

## Build and reproduce

### Toolchain

| Component | Requirement or configuration |
|---|---|
| Lean | `leanprover/lean4:v4.34.1` |
| Lake | From the pinned Lean toolchain |
| MLIR | Driver defaults target LLVM 19 tools |
| J | Driver defaults target J 9.7 console |
| Quipper | Cabal dependencies and GHC 8.8.4, per gap ledger |

```bash
git clone https://github.com/AHMADALIPARR/pirtm-hcalc.git
cd pirtm-hcalc
lake build
```

Set local tool locations as necessary. The paths below are driver defaults from the recorded environment, not portable installation instructions.

| Environment variable | Driver default |
|---|---|
| `LLVM_BIN` | `/usr/lib/llvm-19/bin` |
| `MLIR_RUNNER_LIB` | `/usr/lib/llvm-19/lib/libmlir_c_runner_utils.so` |
| `JCONSOLE` | `/home/box/j/j9.7/bin/jconsole` |
| `GHCUP_BIN` | `$HOME/.ghcup/bin` |
| `TINFO5_DIR` | `$HOME/.local/lib/tinfo5` |
| `LAKE` | `lake` |

### Individual gates

```bash
lake script run lean
lake script run j
lake script run mlir
lake script run irdl
lake script run quipper
```

Run the J gate before the MLIR gate to generate the numerical reference sections. For a complete run:

```bash
lake script run all
```

The combined driver visits J, MLIR, IRDL, Quipper and Lean in that order and reports failure if any subsystem returns a failing result. Generated MLIR intermediates are stored under `.lake/mlir/`.

### Measured build and pipeline timings

Measured November 25, 2026, at repository revision `63dffec`, on the build machine: 4 CPUs, 7.7 GiB RAM, Ubuntu; Lean 4.34.1, J 9.7, LLVM 19.1.1 (`mlir-opt`, `mlir-cpu-runner`), GHC 8.8.4, cabal 3.16.1.0. These are measured timings of the pipeline as shipped. The repository has no benchmark suite, so these are presented as pipeline timings and verification results, not as a benchmark suite. The GitHub Actions workflow runs the Lean job only; the full five-stage pipeline runs locally with `lake script run all`.

| Stage | Result | Measured time | Evidence |
|---|---|---|---|
| j | PASS | 3.8 s | [logs/j/SUMMARY.txt](logs/j/SUMMARY.txt) |
| mlir | PASS | 6.3 s | [logs/mlir/SUMMARY.txt](logs/mlir/SUMMARY.txt) |
| irdl | PASS | 1.8 s | [logs/mlir/IRDL.txt](logs/mlir/IRDL.txt) |
| quipper | PASS | 3 m 46 s cold build; seconds once cached | [logs/quipper/SUMMARY.txt](logs/quipper/SUMMARY.txt) |
| lean | PASS | about 48 s in the combined run; clean build 1 m 19.31 s | [logs/lean/SUMMARY.txt](logs/lean/SUMMARY.txt) |
| `lake script run all` | PASS — all five stages | 57.2 s wall | [logs/SUMMARY.txt](logs/SUMMARY.txt) |

The stage times were measured on the individual stage runs. The combined run reuses warm build caches: the Quipper stage, whose first `cabal build` on this host took 3 m 46 s, finished within a second (stamps 15:56:58 → 15:56:59 UTC), and the lean stage took about 48 s (stamps 15:56:59 → 15:57:47 UTC) for the incremental build, the escape-word scan and the axiom audit.

The clean `lake build` (28 jobs, exit 0) took 1 m 19.31 s wall, with maximum resident set size 936,152 KB (about 914 MiB) and 0 swaps, measured with `/usr/bin/time -v`; the per-module times are in [`logs/lean/build-clean.log`](logs/lean/build-clean.log). The Quipper cold build needed `libgmp-dev` and `libffi-dev` installed on the build host — a host-only fix, not a change to this repository.

## Verification evidence

The following results are from the full pipeline run on November 25, 2026, at repository revision `63dffec` — a fresh local run of this checkout, with the logs below. The GitHub Actions workflow covers the Lean job on the same commit (run 45509935546, completed success); the J, MLIR, IRDL and Quipper stages run locally.

| Subsystem | Recorded result | Evidence |
|---|---|---|
| Lean | PASS | [Summary](logs/lean/SUMMARY.txt) |
| J | PASS | [Summary](logs/j/SUMMARY.txt) |
| MLIR | PASS | [Summary](logs/mlir/SUMMARY.txt) |
| IRDL | PASS | [IRDL log](logs/mlir/IRDL.txt) |
| Quipper | PASS | [Summary](logs/quipper/SUMMARY.txt) |

### MLIR comparison matrix

| Program | Comparison predicate | Recorded match |
|---|---|---:|
| `hilbert11` | Exact output equality | 21 lines |
| `quantum` | Exact output equality | 19 lines |
| `oracle` | Exact output equality | 17 lines |
| `engine` | Ordered subsequence | 18 reference lines |
| `agents` | Exact output equality | 25 lines |
| `hcalc` | Exact J section equality | 18 lines |
| `goldilocks` | Exact J section equality | 13 lines |
| `hcalc_pipeline` | Output-line membership | 11 lines |
| `pirtm_roundtrip` | Output-line membership | 4 lines |

The subsequence predicate permits extra lines; the membership predicate does not enforce order or coverage of the entire reference pool. These distinctions are part of the evidence contract.

### J and Quipper

The J harness reports 15 passed properties, zero failures, three skips and zero blocked properties. Its demo contains 31 lines. The Quipper log reports successful build and run, with 242 output lines including 53 printed gate lines, and exact equality of the filtered numerical output with the archived reference.

### Lean audit

The Lean summary records build exit code zero, zero whole-word occurrences of `sorry` and `admit`, and 55 project-declared axioms. The driver scans source text and invokes an axiom inspection tool. Its pass condition does not enforce a zero-axiom policy.

```text
Source and pinned toolchain ──→ Lake build
Source and pinned toolchain ──→ Proof escape word scan
Lake build ──→ Axiom inspection
Proof escape word scan ──→ Driver verdict
Axiom inspection ──→ Driver verdict
Driver verdict ──→ Build and audit logs
```

## Trust boundaries

| Evidence class | Meaning | Boundary |
|---|---|---|
| Kernel proof | A Lean proposition is accepted | Depends on its hypotheses and transitive axioms |
| Finite exact computation | A specified concrete computation is established | Does not generalize automatically to all inputs |
| Numeric comparison | Recorded outputs satisfy a comparison predicate | Does not prove all-input equivalence |
| IRDL validation | Declared operation structure is accepted or rejected | Does not prove runtime semantics |
| Recorded log | Historical driver outcome | Must be regenerated for current-revision assurance |

### HCALC scalar assumptions

The audit lists 55 project axioms, including declarations in `Hcalc/RealStub.lean`, `Hcalc/Carrier.lean` and `Hcalc/Foundry.lean`. These include the abstract scalar type and operations, scalar and order laws, norms, Foundry state operations, finite maximum properties, and soft-scaling parameters. In particular, `real_contract_force_zero` is a declared assumption used by the fixed-point uniqueness argument. The inventory is in [`logs/lean/axioms.txt`](logs/lean/axioms.txt).

The exact quantum, modular arithmetic and worker propositions form a separate computational layer. The absence of admitted proofs in the current scan is compatible with the presence of explicitly declared axioms.


### Gaussian integer arithmetic

The representation eliminates floating-point rounding from the exact examples by keeping Gaussian integer numerators and a shared normalization exponent. Multiplication of two numerators uses the ordinary complex multiplication rule:

```text
(a + bi)(c + di) = (ac − bd) + (ad + bc)i.
```

The actual declarations in [`Exact.lean`](PirtmHcalc/Quantum/Exact.lean) are:

```lean
structure GInt where
  re : Int
  im : Int
  deriving DecidableEq, Repr, Inhabited

namespace GInt
def zero : GInt := ⟨0, 0⟩
def one : GInt := ⟨1, 0⟩
instance : Add GInt := ⟨fun a b => ⟨a.re + b.re, a.im + b.im⟩⟩
instance : Sub GInt := ⟨fun a b => ⟨a.re - b.re, a.im - b.im⟩⟩
instance : Neg GInt := ⟨fun a => ⟨-a.re, -a.im⟩⟩
instance : Mul GInt := ⟨fun a b => ⟨a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re⟩⟩
def conj (a : GInt) : GInt := ⟨a.re, -a.im⟩
def mulI (a : GInt) : GInt := ⟨-a.im, a.re⟩
def normSq (a : GInt) : Nat := (a.re * a.re + a.im * a.im).toNat
end GInt
```

| Operation | Numerator transformation | Use |
|---|---|---|
| Addition | (a + c, b + d) | Hadamard upper branch |
| Subtraction | (a − c, b − d) | Hadamard lower branch |
| Negation | (−a, −b) | Z and phase transformations |
| Conjugation | (a, −b) | Inner product and density matrix |
| Multiplication by i | (−b, a) | Y and S gates |
| Squared magnitude | a² + b² | Norm and probability |

### Binary-tree state storage

```lean
inductive QT where
  | leaf (z : GInt)
  | node (l r : QT)
  deriving DecidableEq, Repr

structure State where
  n : Nat
  k : Nat
  amp : QT
  deriving DecidableEq, Repr
```

A depth-n perfect binary tree contains 2^(n) leaves and 2^(n) − 1 internal nodes. For the 11-qubit experiments that means 2,048 amplitude leaves and 2,047 branch nodes. These are mathematical counts for a perfect tree, rather than measured heap allocation counts. The constructor `QT.node` itself does not enforce perfectness through dependent types.

```text
Qubit 0 ──→ Qubit 1: prefix 0
Qubit 0 ──→ Qubit 1: prefix 1
Qubit 1: prefix 0 ──→ 00
Qubit 1: prefix 0 ──→ 01
Qubit 1: prefix 1 ──→ 10
Qubit 1: prefix 1 ──→ 11
```

| Tree function | Behavior | Boundary |
|---|---|---|
| `QT.map` | Apply a function to each leaf | Preserves existing shape |
| `QT.zipWith` | Combine corresponding leaves | Shape mismatch returns first tree |
| `QT.basis` | Construct a basis-state tree | Caller must supply valid index for a normalized basis state |
| `QT.get` | Follow index bits | Not a dependent bounds-checked index API |
| `QT.atQubit` | Transform subtree pairs at a depth | Unmatched cases return the existing tree |
| `QT.sumBy` | Sum integer values over leaves | Structural recursion |
| `QT.inner` | Conjugate-product sum | Mismatched shapes yield zero for that branch |
| `QT.all` | Test every leaf | Boolean conjunction |
| `QT.leaves` | Flatten tree | Left subtree precedes right subtree |

The fallback branches are part of the current implementation and matter when considering a future universal correctness theorem. The experiment circuits use valid inputs; the public representation admits other values. A general proof should either restrict the domain with an explicit well-formedness predicate or change the representation under an authorized API revision.

#### Folded amplitude-tree illustration

```text
exact amplitude tree  depth=4  z in Z[i]
leaves fold 11-qubit support of Psi1/Psi2

                             o
                            / \
                   o                   o
                  / \                 / \
           o               o       o               o
          / \   / \     / \   / \

 @   @                           @   @
 *   *                           *   *
 0   1                           8   9

non-zero leaves = folded support of Psi1/Psi2
all other amplitudes exactly 0 (exact tree)
---------------------------------------------------------------
pirtm-hcalc  amplitude tree  seed=11
```

The four-bit display retains basis-index bits 10, 9, 1 and 0 in that order. For these states the projection preserves the four distinct support locations. It is a display projection, not an injective map on the full basis.

| Full index | Retained bits | Folded index | State |
|---:|---|---:|---|
| 0 | `0000` | 0 | Ψ₁ |
| 1025 | `1001` | 9 | Ψ₁ |
| 512 | `0100` | 4 | Ψ₂ |
| 1537 | `1101` | 13 | Ψ₂ |

The ASCII sketch above is artistic; the table defines the actual projection. The actual eleven-qubit tree has depth eleven and 2,048 leaves. The exact indices are 0 and 1025 for the first state, and 512 and 1537 for the second.

```text
ℤ[i] = {a + bi ∣ a, b ∈ ℤ},   i² = −1.
```

```text
aⱼ = zⱼ/(√2)ᵏ
∥ψ∥₂² = (Σ[j=0 to 2ⁿ−1] │zⱼ│²)/2ᵏ
```

| Quantity | Depth-four sketch | Actual eleven-qubit state |
|---|---:|---:|
| Depth | 4 | 11 |
| Full binary leaf count | 16 | 2,048 |
| Nonzero indices per state | 2 | 2 |
| Zero amplitudes per state | 14 unoccupied display locations | 2,046 |
| Shared denominator exponent for the pair | 1 (inherited) | 1 |

### Exact gate action

For a pair of amplitude subtrees (l, r) the gate rules can be read directly from `State.apply`.

| Gate | Upper subtree | Lower subtree | Change in exponent k |
|---|---|---|---:|
| H | l + r | l − r | +1 |
| X | r | l | 0 |
| Y | −ir | il | 0 |
| Z | l | −r | 0 |
| S | l | ir | 0 |
| S† | l | −ir | 0 |
| CNOT | Control-zero branch unchanged | Target flipped inside control-one branch | 0 |

The CNOT branch requires `c < t`. When the condition fails, the exact implementation returns the input state unchanged. This is a deliberate domain restriction of the port, rather than a universal implementation of CNOT for arbitrary ordered pairs.

The exact inverse sequence is defined as follows:

```lean
def Gate.dagger : Gate → Gate
  | .S q => .Sdg q
  | .Sdg q => .S q
  | g => g
```

```lean
def evolve (s : State) (gs : List Gate) : State := gs.foldl apply s
def evolveInverse (s : State) (gs : List Gate) : State := (gs.reverse.map Gate.dagger).foldl apply s
```

The inverse order follows the algebraic identity (U_(m)⋯U₁)^(†) = U₁^(†)⋯U_(m)^(†). The representation may have different normalization exponents after a forward/inverse roundtrip even when it represents the same physical vector. The concrete roundtrip propositions use fidelity, rather than requiring structural equality of the numerator tree and exponent.

### Dyadic equality and observable values

```lean
structure Dy where
  num : Nat
  exp : Nat
  deriving DecidableEq, Repr

def Dy.eqv (a b : Dy) : Bool := a.num * 2 ^ b.exp == b.num * 2 ^ a.exp
```

Structural equality of dyadic records is stronger than value equality. For example, `⟨1, 1⟩` and `⟨2, 2⟩` represent the same rational number. Cross multiplication compares the values without division or floating-point conversion.

| Observable | Exact numerator | Denominator |
|---|---|---|
| Basis probability | │z_(j)│² | 2^(k) |
| State norm squared | ∑_(j)│z_(j)│² | 2^(k) |
| Fidelity | │∑_(j)ā_(j)b_(j)│² | 2^(k_(a) + k_(b)) |
| Reduced matrix entry | ∑_(e)a_(i, e)ā_(j, e) | 2^(k) |
| Support | Number of nonzero Gaussian numerators | 1 |

### Concrete experiment catalogue

The gate lists below are taken from `PirtmHcalc/Data/Experiments.lean`. The listed initial indices and qubit counts are those used by its experiment definitions and theorems.

| Experiment | Register | Initial basis | Gate sequence |
|---|---:|---:|---|
| Bell | 2 | 0 | H0, CNOT0→1 |
| A02 | 11 | 42 | H0, CNOT0→5, S5, CNOT5→10, X10 |
| A03 | 11 | 0 | H0 through H10 |
| A04 | 11 | 0 | H0, CNOT0→1, CNOT1→2 |
| A05 | 11 | 100 | H0, CNOT0→4, X7 |
| A08 | 11 | 0 | H0, CNOT0→10 |
| Ψ₁ | 11 | 0 | H0, CNOT0→10 |
| Ψ₂ | 11 | 0 | X1, H0, CNOT0→10 |
| Roundtrip 7 | 11 | 7 | H0, CNOT0→1, S1, CNOT1→5, H5, CNOT5→10, X10 |

#### Bell-state circuit

```text
q0: |0> ── H ── ● ──
                │
q1: |0> ─────── ⊕ ──
```

| Basis | Exact amplitude | Exact probability |
|---|---|---:|
| 00 | 1/√2 | 1/2 |
| 01 | 0 | 0 |
| 10 | 0 | 0 |
| 11 | 1/√2 | 1/2 |

The recorded MLIR matrix path returns sample index 0 for `r=0.3` and index 3 for `r=0.7`. Passing `r` explicitly separates sampling selection from random-number generation. This is a deterministic test of two supplied variates, rather than a statistical test of an RNG.

#### Global versus local observability


```text
Psi 1: indices 0 and 1025 ──→ Global fidelity = 0
Psi 2: indices 512 and 1537 ──→ Global fidelity = 0
Psi 1: indices 0 and 1025 ──→ Partial trace
Psi 2: indices 512 and 1537 ──→ Partial trace
Partial trace ──→ Reduced state I / 2
```


*Figure: computed from the exact support and probabilities in `psi_support`, `psi_normalized` and `reduced_states_equal`.*

| Property | Ψ₁ | Ψ₂ |
|---|---|---|
| Nonzero index 1 | 0 | 512 |
| Nonzero index 2 | 1025 | 1537 |
| Support size | 2 | 2 |
| Norm squared | 1 | 1 |
| Reduced state of qubit 0 | I/2 | I/2 |
| Probability of observing qubit 0 as zero | 1/2 | 1/2 |
| Probability of observing qubit 0 as one | 1/2 | 1/2 |

The supports are disjoint, so every term in their inner product vanishes. Taking the partial trace removes the environmental distinction. The exact result establishes an information boundary for these prepared states, without claiming that every pair of orthogonal global states is locally indistinguishable.

#### Roundtrip experiment: forward state

The seven-gate circuit applied to basis 7 has four nonzero amplitudes. `roundtrip7_forward` establishes the numerator values and shared exponent k = 2.

| Basis index | Gaussian numerator | Amplitude | Probability |
|---:|---|---|---:|
| 6 | 1 | 1/2 | 1/4 |
| 39 | 1 | 1/2 | 1/4 |
| 1542 | i | i/2 | 1/4 |
| 1575 | −i | −i/2 | 1/4 |

The original basis index 7 is absent from the forward support, which explains the exact zero forward fidelity. Reversing the gate sequence and applying daggers gives exact unit fidelity in `roundtrip7_back`.

#### Floating-point comparison of the exact experiments

| Quantity | Exact Lean value | Recorded MLIR decimal | Recorded IEEE bits (decimal) |
|---|---:|---:|---:|
| Ψ₁ norm squared | 1 | 0.99999999999999978 | 4607182418800017406 |
| Ψ₂ norm squared | 1 | 0.99999999999999978 | 4607182418800017406 |
| Global fidelity | 0 | 0 | 0 |
| Reduced distance | 0 | 0 | 0 |
| Ψ₁ probability zero | 0.5 | 0.49999999999999989 | 4602678819172646910 |
| Ψ₂ probability one | 0.5 | 0.49999999999999989 | 4602678819172646910 |
| Forward roundtrip norm | 1 | 0.99999999999999956 | 4607182418800017404 |
| Inverse roundtrip fidelity | 1 | 0.99999999999999933 | 4607182418800017402 |

Source: [`logs/mlir/hilbert11.out`](logs/mlir/hilbert11.out). These small discrepancies are floating-point effects, and are explicitly distinguished from the exact values in the Lean model.

### Theorem index for the exact experiments

| Declaration | Scope |
|---|---|
| `bell_amplitudes` | Four concrete Gaussian numerators |
| `bell_probabilities` | Four concrete dyadic probabilities |
| `psi_support` | Two exact sparse supports |
| `psi_normalized` | Both prepared states have unit norm |
| `global_fidelity_zero` | Orthogonality of the two states |
| `reduced_states_equal` | Equality of reduced matrix numerators and exponent |
| `reduced_trace_distance_zero` | All matrix-entry differences vanish |
| `adversarial_conclusion` | Joint global/local conclusion |
| `A01_transition_fidelities` | Three transitions: 1/2, 1/8, 1/8 |
| `A02_norm_and_roundtrip` | Concrete five-gate reversible experiment |
| `A03_uniform_superposition` | 2,048 equal Gaussian numerators, exponent 11 |
| `A04_born_probabilities` | Two outcomes at indices 0 and 1792 |
| `A05_encoding` | Concrete historical encoding roundtrip |
| `A08_purity` | Reduced matrix of restricted observer |
| `A08_purity_value` | Exact rational purity identity |
| `roundtrip7_forward` | Four nonzero amplitudes and zero initial fidelity |
| `roundtrip7_back` | Unit inverse fidelity and forward norm |
| `classical_baseline` | NOT and Toffoli on three Boolean bits |

## HCALC numerical reference: a complete worked trajectory


```text
Input state ──→ Prime diagonal transform
Prime diagonal transform ──→ Scale or identity
Scale or identity ──→ Guarded Lambda scalar
Guarded Lambda scalar ──→ Affine evolution
Affine evolution ──→ Next state
```


The production specification chooses a diagonal prime-indexed transform. For the recorded five-coordinate example, the first five primes are sufficient; modulo-64 reuse does not occur until larger carrier dimensions.

### Parameters and first step

| Parameter | Value | Source |
|---|---:|---|
| Dimension | 5 | J demo |
| Initial vector | (1, 2, 3, 4, 5) | J demo |
| Margin ε | 0.05 | Production tier T2 |
| Guard δ | 10⁻¹² | Production specification |
| Tolerance | 10⁻⁶ | Production specification |
| Maximum steps | 80 | J demo |
| Schedule ξ | 1 | Uniform production mode |
| Kick | zero | Production default |

| Coordinate | Prime | Weight α_(j) | First-step value |
|---:|---:|---:|---:|
| 0 | 2 | 0.59061610914964124 | 0.59061610914964124 |
| 1 | 3 | 0.47650535804050431 | 0.95301071608100862 |
| 2 | 5 | 0.383224293337255 | 1.149672880011765 |
| 3 | 7 | 0.3394536660667255 | 1.357814664266902 |
| 4 | 11 | 0.29429982966380241 | 1.4714991483190121 |

The largest weight is approximately 0.590616, below the permitted margin 0.95. The governor scale and stabilization scalar both equal one in the recorded example. Consequently the nested production step is the diagonal transform itself for these inputs.

The additive diagnostic is visibly different:

| Coordinate | Nested output | Additive diagnostic output |
|---:|---:|---:|
| 0 | 0.59061610914964124 | 1.5906161091496411 |
| 1 | 0.95301071608100862 | 2.9530107160810086 |
| 2 | 1.149672880011765 | 4.1496728800117655 |
| 3 | 1.357814664266902 | 5.3578146642669022 |
| 4 | 1.4714991483190121 | 6.4714991483190119 |

Source: [`logs/j/demo.out`](logs/j/demo.out). This is a useful numerical counterexample to any claim that the two maps are identical under the default parameters.

### Derived recurrence and convergence behavior

For this diagonal, zero-kick, unit-scale case the ideal mathematical recurrence has the closed form

```text
x_(j)^((t)) = α_(j)^(t)x_(j)⁽⁰⁾.
```

The residual evaluated at x^((t)) is

```text
R_(t) = max_(j)|1 − α_(j)| |x_(j)⁽⁰⁾| α_(j)^(t).
```


```text
Initial vector 1 2 3 4 5 ──→ Repeated diagonal step
Repeated diagonal step ──→ 26 steps
26 steps ──→ Residual 7.848e-7
Residual 7.848e-7 ──→ Tolerance 1e-6 satisfied
```


*Figure: mathematical reconstruction using the logged weights and initial vector. Intermediate points are calculated for documentation; they are not additional measured log entries.*

| Recorded final coordinate | Value |
|---:|---:|
| 0 | 1.1322373946119545e-6 |
| 1 | 8.5269260029813364e-9 |
| 2 | 4.4350660105861813e-11 |
| 3 | 2.5255331828250893e-12 |
| 4 | 7.7180979075464377e-14 |

| Stop evidence | Recorded value |
|---|---:|
| Converged flag | 1 |
| Steps | 26 |
| Last residual | 7.8480715779981436e-7 |
| Tolerance | 1e-6 |

The stopping rule concerns the residual, not a direct requirement that every coordinate be below the tolerance. In particular, the first final coordinate exceeds 10⁻⁶ while the reported residual is below it. The distinction matters for any API that promises an error bound on distance to a fixed point.

#### Nested iteration — ASCII residual profile

```text
nested iteration  residual_inf vs step
X <- Xi(Lm * C(Tp(X)))   tol ~ 1e-6

r
   #
   #
   #
   #
   #
   #  +
   #  +
   #  +  :
   #  +  :
   #  +  :  .
   #  +  :  .
   0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
t ->
contraction from soft-scale + Lambda_m
---------------------------------------------------------------
pirtm-hcalc  iteration residual  seed=11
```

The supplied ASCII profile illustrates decay qualitatively. Its glyph heights are not calibrated measurements. The table below reconstructs the ideal default recurrence for the logged five-coordinate initial vector, using the actual first five prime weights. The recorded run remains the authority for its own stopping residual.

```text
X_(t + 1) = DX_(t),   D = diag (α₀, …, α₄),   X_(t) = D^(t)X₀.
```

```text
R_(t) = ∥X_(t) − X_(t + 1)∥_(∞),   R_(t + 1) ≤ ∥D∥_(∞)R_(t).
```

| Iteration t | Reconstructed ∥X_(t)∥_(∞) | Reconstructed R_(t) |
|---:|---:|---:|
| 0 | 5.000000000000e+00 | 3.528500851681e+00 |
| 1 | 1.471499148319e+00 | 1.038437199618e+00 |
| 2 | 4.609151656246e-01 | 3.056118909642e-01 |
| 3 | 2.163880936630e-01 | 1.132780076164e-01 |
| 4 | 1.216805468889e-01 | 5.397757757737e-02 |
| 5 | 7.186649116274e-02 | 2.942098377397e-02 |
| 6 | 4.244550738878e-02 | 1.737650696394e-02 |
| 7 | 2.506900042484e-02 | 1.026284493365e-02 |
| 8 | 1.480615549119e-02 | 6.061401543519e-03 |
| 9 | 8.744753947672e-03 | 3.579961395627e-03 |
| 10 | 5.164792552045e-03 | 2.114382870391e-03 |
| 11 | 3.050409681654e-03 | 1.248788584163e-03 |
| 12 | 1.801621097491e-03 | 7.375546547289e-04 |
| 13 | 1.064066442762e-03 | 4.356116604612e-04 |
| 14 | 6.284547823007e-04 | 2.572792640018e-04 |
| 15 | 3.711755182989e-04 | 1.519532778696e-04 |
| 16 | 2.192222404293e-04 | 8.974605374789e-05 |
| 17 | 1.294761866814e-04 | 5.300546507611e-05 |
| 18 | 7.647072160532e-05 | 3.130588154692e-05 |
| 19 | 4.516484005840e-05 | 1.848975795274e-05 |
| 20 | 2.667508210566e-05 | 1.092034890117e-05 |
| 21 | 1.575473320449e-05 | 6.449733978564e-06 |
| 22 | 9.304999225927e-06 | 3.809316787470e-06 |
| 23 | 5.495682438458e-06 | 2.249843859534e-06 |
| 24 | 3.245838578924e-06 | 1.328794026512e-06 |
| 25 | 1.917044552412e-06 | 7.848071577998e-07 |
| 26 | 1.132237394612e-06 | 4.635197499725e-07 |

### Fixed-point error bound: mathematical context

For a contraction F with Lipschitz constant 0 ≤ q < 1 and a fixed point x^(*), the triangle inequality gives

```text
∥x − x^(*)∥ ≤ ∥x − F(x)∥ + q∥x − x^(*)∥.
```

Hence

```text
∥x − x*∥ ≤ ∥x − F(x)∥/(1 − q).
```

This is a mathematical explanation of why a residual can be useful. It is not a claim that the repository has a Lean theorem proving this general a posteriori bound. The present `Hcalc.Convergence` file proves uniqueness under `HypContractive` and zero fixed-point properties for the stabilized default path, using its abstract scalar assumptions.

### Scalar and carrier API

```lean
abbrev Carrier (n : Nat) : Type := Fin n → Real
abbrev Time : Type := Nat
abbrev Intermediate (n : Nat) : Type := Carrier n
abbrev State (n : Nat) : Type := Carrier n
```

| Declaration in `Hcalc.Carrier` | Mathematical operation |
|---|---|
| `vzero` | Zero vector |
| `vadd` | Pointwise sum |
| `vneg` | Pointwise negation |
| `vsub` | Pointwise difference |
| `vsmul` | Scalar multiplication |
| `linf` | Finite maximum of absolute coordinates |
| `carrier_ext_of_linf_sub_eq_zero` | Zero difference norm implies equality |
| `linf_vzero` | Zero vector has zero norm |
| `vsmul_zero_left` | Zero scalar gives zero vector |
| `vsmul_vadd` | Scalar multiplication distributes over addition |

The carrier uses `Hcalc.Real`, not Mathlib's real-number implementation. The type-level finite index protects the coordinate access pattern, but does not independently prove the scalar field laws. Those laws are provided by the declared assumptions.

### Production operator reference

| Definition in `Hcalc.Axioms` | Inputs | Output / role |
|---|---|---|
| `primeAt` | `Fin n` | Natural prime from P64 |
| `alpha` | `Fin n` | Abstract scalar weight |
| `Tp` | Carrier | Diagonal transform |
| `qEstTp` | Dimension | Maximum absolute weight |
| `cScale` | Dimension, margin | Governor scalar |
| `C` | Margin, carrier | Scaled carrier |
| `contractAlg_q` | Dimension | Norm estimate |
| `contractAlg_applyC` | Margin, carrier | Governor application |
| `opNorm_C_circ_Tp` | Dimension, margin | Estimated diagonal operator norm |
| `LambdaM` | Dimension, margin, guard | Stabilization scalar |
| `LambdaM_prod` | Dimension | Default stabilization scalar |
| `xi` | Time | Uniform schedule |
| `gDefault` | Dimension, time | Zero kick |
| `Xi` | Time, carrier, kick function | Affine evolution |
| `C_circ_Tp` | Margin, carrier | Contracted transform |
| `stabilized` | Margin, guard, carrier | Scaled contracted transform |

### Pipeline API and theorem reference

```lean
noncomputable def step {n : Nat} (ε δ : Scalar) (t : Time) (x : Carrier n) : Carrier n :=
  hcalcStepCore (n := n) ε δ t x (gDefault n)
```

| Declaration in `Hcalc.Pipeline` | Contract |
|---|---|
| `step` | Nested evolution with default kick |
| `stepProd` | Evolution using production parameters |
| `step_eq` | Definitional equality with nested expression |
| `step_eq_stabilized` | Uniform, zero-kick reduction |
| `contracted` | Stabilized intermediate |
| `step_eq_Xi_contracted` | Explicit composition through intermediate |
| `J` | Residual objective |
| `optimize` | Iterate a fixed number of times |
| `done` | Residual-below-tolerance predicate |

```lean
structure HypContractive {n : Nat} (ε : Scalar) (F : Carrier n → Carrier n) where
  q : Scalar
  q_lt_margin : q <ᵣ ((1 : Scalar) - ε)
  q_lt_one : q <ᵣ (1 : Scalar)
  lip : ∀ x y : Carrier n, ‖vsub (F x) (F y)‖∞ ≤ᵣ q * ‖vsub x y‖∞
```

| Declaration in `Hcalc.Convergence` | Established property |
|---|---|
| `HypContractive.q_lt_one_sub_eps` | Extract margin hypothesis |
| `unique_fixed_point` | At most one fixed point under bundled contraction assumptions |
| `residual_at_fixed_point` | Fixed point has zero residual |
| `stabilized_fixes_zero` | Zero is a fixed point of stabilized branch |
| `unique_fp_stabilized_of_hyp` | Zero is the unique fixed point under hypothesis |
| `step_fixes_zero` | Default nested step fixes zero |
| `unique_fp_step_of_hyp` | Unique zero fixed point under hypothesis |
| `J_at_zero` | Residual objective at zero is zero |
| `contractiveG_from_bound` | Extract definitional contraction predicate |

The uniqueness proof substitutes the fixed-point equalities into the Lipschitz inequality and invokes `real_contract_force_zero`. This is an explicit axiom of the scalar model, rather than a derived theorem of a complete ordered field in this checkout.

### Structural invariants and the production surface

`Hcalc.Invariants.IsInvariant` quantifies over all margins, guards, times and states. The file proves that the always-true predicate is invariant and that conjunction preserves invariance when both component predicates are invariant. It also proves that the general invariant contract implies the production-default contract.

These are compositional lemmas. `true_invariant` is intentionally trivial; it is not a substitute for a domain-specific invariant about actual state values.

`Hcalc.Production` re-exports the carrier, nested operators, bridge, residual, definition records, production step, optimization and fixed-point theorem. It is the stable import surface for readers who do not need the individual implementation namespaces.

## Goldilocks: reduction mathematics and concrete test vectors


```text
Wide product ──→ Split at 64 bits
Split at 64 bits ──→ Split high word at 32 bits
Split high word at 32 bits ──→ Fold using modular identities
Fold using modular identities ──→ Reduce modulo p
```


Let B = 2³² and p = B² − B + 1. Then B² ≡ B − 1 (mod  p), and multiplication by B gives B³ ≡ −1 (mod  p).

For canonical 64-bit residues a, b, split the product t = ab into t = lo + B²hi and hi = hl + Bhh. Substitution gives

```text
t ≡ lo + hl(B − 1) − hh (mod  p).
```

The implementation uses a nonnegative adjustment before the final modulus. The following is the exact Lean source from [`Data/Goldilocks.lean`](PirtmHcalc/Data/Goldilocks.lean):

```lean
def foldMul (a b : Nat) : Nat :=
  let t := a * b
  let lo := t % 2 ^ 64
  let hi := t / 2 ^ 64
  let hl := hi % 2 ^ 32
  let hh := hi / 2 ^ 32
  let f := lo + hl * (2 ^ 32 - 1)
  let r := if f ≥ hh then f - hh else f + p - hh
  r % p
```

The mathematical derivation explains the folding identity. The current Lean file establishes concrete vectors and a deterministic 200-pair comparison, not an all-input correctness theorem for `foldMul` or the MLIR implementation. In particular, arbitrary `Nat` inputs extend beyond the canonical 64-bit residue domain.

### Complete recorded field vectors

| Quantity | Value |
|---|---:|
| Modulus | 18446744069414584321 |
| Input a | 12345678901234567890 |
| Input b | 9876543210987654321 |
| a+b modulo p | 3775478042807637890 |
| a−b modulo p | 2469135690246913569 |
| b−a modulo p | 15977608379167670752 |
| ab modulo p | 7432351747408847865 |
| (p − 1)² modulo p | 1 |
| 7¹⁰⁰ modulo p | 2335214203647002900 |
| Inverse of a | 16343323056350712102 |
| a times inverse modulo p | 1 |
| a^(p − 1) modulo p | 1 |

### Square-and-multiply

```lean
def powMod : Nat → Nat → Nat → Nat
  | 0, _, _ => 1
  | fuel + 1, b, e =>
    if e = 0 then 1
    else
      let r := powMod fuel (foldMul b b) (e / 2)
      if e % 2 = 1 then foldMul b r else r
```

The exponent decreases by division by two; recursion is structurally bounded by fuel. A fuel value of 128 is used in the concrete exponentiation theorems. A general specification would require a sufficient-fuel condition, because the zero-fuel branch returns one even if the exponent is nonzero.

| Lean theorem | Concrete obligation |
|---|---|
| `p_def` | Decimal modulus equals 2⁶⁴ − 2³² + 1 |
| `fold_identities` | Two modular powers establish reduction identities |
| `logged_add` | Addition vector |
| `logged_sub` | Forward subtraction vector |
| `logged_sub_rev` | Reverse subtraction vector |
| `logged_mul` | Direct modulus and folded multiplication agree on a,b |
| `logged_mul_pm1_sq` | Boundary square gives one |
| `logged_pow_7_100` | Direct and folded exponentiation agree |
| `logged_inv_a` | Inverse product equals one |
| `logged_inv_is_fermat` | Fuel-bounded exponentiation yields recorded inverse |
| `logged_fermat_a` | Concrete Fermat result |
| `fold_vs_ref_200` | Deterministic set of 200 multiplication pairs |

### MLIR arithmetic interface

| Function | Input | Output |
|---|---|---|
| `gl_p` | None | `i64` modulus bit pattern |
| `gl_add` | Two `i64` | `i64` residue |
| `gl_sub` | Two `i64` | `i64` residue |
| `gl_mul` | Two `i64` | Folded product |
| `gl_mul_ref` | Two `i64` | Reference product |
| `gl_pow` | Base, exponent | Modular power |
| `gl_inv` | Residue | Inverse routine result |



## MLIR implementation atlas


```text
Custom operations ──→ IRDL validation
IRDL validation ──→ Map to func.call
Map to func.call ──→ Standard MLIR lowering
Standard MLIR lowering ──→ CPU runner
CPU runner ──→ Reference comparison
```


The custom dialects describe typed operation signatures. Their current lowering is implemented by the Lake driver as textual replacement of generic-form operation names with `func.call` names, followed by standard MLIR passes. It is not a registered C++ dialect conversion pass and does not provide a formally verified compiler refinement.

### State-vector kernel catalogue

Source: [`mlir/lib/qsim.mlir`](mlir/lib/qsim.mlir).

| Function | Responsibility |
|---|---|
| `sv_alloc` | Allocate state-vector storage |
| `sv_basis` | Construct computational basis vector |
| `sv_copy` | Copy state storage |
| `sv_set` | Set a complex amplitude |
| `sv_apply1` | Apply single-qubit matrix |
| `cplx` | Construct complex scalar |
| `sqrt2_inv` | Hadamard normalization constant |
| `sv_h` | Hadamard gate |
| `sv_x` | Pauli X |
| `sv_y` | Pauli Y |
| `sv_z` | Pauli Z |
| `sv_s` | Phase S |
| `sv_sdg` | Adjoint S |
| `sv_cnot` | Controlled NOT |
| `sv_apply_op` | Dispatch operation code |
| `sv_evolve` | Apply circuit table |
| `op_dagger` | Map opcode to adjoint |
| `sv_evolve_inverse` | Reverse and apply adjoints |
| `sv_norm2` | State squared norm |
| `sv_fidelity` | Squared overlap |
| `sv_probabilities` | Basis probabilities |
| `sub_index` | Extract subsystem index |
| `env_mask` | Environment bit mask |
| `sv_partial_trace` | Reduced density matrix |
| `trace_distance_bound` | Frobenius-based comparison bound |
| `set_gate` | Write circuit table row |
| `circ_new` | Allocate circuit table |

Circuit storage uses `memref<?x3xindex>`: one row per gate, with opcode and two coordinate fields. This is a different representation from the inductive gate list in Lean. The experiments compare observable outputs across these representations.

### Matrix and classical reversible kernel catalogue

Source: [`mlir/lib/qmat.mlir`](mlir/lib/qmat.mlir).

| Function | Responsibility |
|---|---|
| `mat_new` | Allocate complex matrix |
| `mat_set` | Set complex entry |
| `mat_identity` | Identity matrix |
| `c_is_zero` | Complex zero test |
| `mat_mult` | Matrix product |
| `mat_dagger` | Conjugate transpose |
| `mat_tensor` | Tensor product |
| `mat_is_unitary` | Numerical unitarity check with tolerance |
| `gate_matrix` | Matrix for gate kind |
| `phase_gate` | Parameterized phase matrix |
| `qc_full_gate` | Lift local gate to full register |
| `qc_to_unitary` | Build circuit unitary matrix |
| `qc_run` | Apply circuit to input vector |
| `qs_probabilities` | Outcome probability vector |
| `qs_sample` | Select outcome using explicit variate |
| `cr_not` | Classical NOT |
| `cr_cnot` | Classical controlled NOT |
| `cr_toffoli` | Classical doubly controlled NOT |
| `cr_state_int` | Interpret bit vector as integer |

A dense 2^(n) × 2^(n) matrix has 4^(n) entries. For 11 qubits that is 4,194,304 complex entries, versus 2,048 entries in a state vector. This is a representation-size comparison, not a benchmark of either implementation. The separate state-vector and matrix paths allow small matrix-level tests without requiring dense full-register matrices for every experiment.

### HCALC numerical kernel catalogue

Source: [`mlir/lib/hcalc.mlir`](mlir/lib/hcalc.mlir).

| Function | Responsibility |
|---|---|
| `nsum_step` | Compensated summation step |
| `vec_new` | Allocate vector |
| `tp_alpha` | Prime-indexed weights |
| `diag_from_alpha` | Diagonal matrix |
| `gershgorin_bound` | Spectral bound estimate |
| `dot` | Dot product |
| `matvec` | Matrix-vector product |
| `power_iteration` | Iterative spectral estimate |
| `spectral_analyze` | Spectral analysis path |
| `soft_project_scale` | Margin-dependent scale |
| `q_of_tp` | Estimate for prime transform |
| `c_op_norm` | Norm of contracted transform |
| `lam_m` | Stabilization scalar |
| `tp_from_p64` | Apply prime transform |
| `c_wrap` | Apply governor |
| `hcalc_step` | Nested state update |
| `to_foundry_step_diagnostic` | Additive diagnostic |
| `residual_linf` | Maximum absolute difference |
| `hcalc_run` | Bounded iterative driver |

The run signature exposes the state, convergence flag, step count and last residual as four separate results:

```mlir
func.func @hcalc_run(%x0: !vec, %maxs: index, %tol: f64, %eps: f64, %xi: f64, %g: !vec) -> (!vec, i1, index, f64)
```

This is the source signature reproduced as an interface excerpt; its body lives in the linked file.

### Output formatting and bit-level comparisons

Source: [`mlir/lib/io.mlir`](mlir/lib/io.mlir).

| Function | Purpose |
|---|---|
| `buf_ptr` | Obtain buffer pointer |
| `s_new` | Allocate string buffer |
| `s_print` | Print buffer |
| `print_f64` | Print floating value with bit evidence |
| `print_i64` | Print integer |
| `s_byte` | Append byte |
| `s_cstr` | Append C string |
| `s_slice` | Append buffer slice |
| `s_bool` | Append Boolean text |
| `s_u128` | Format unsigned wide integer |
| `s_uint` | Format unsigned 64-bit integer |
| `s_int` | Format signed integer |
| `s_hex` | Format digest words |
| `f_decomp` | Decompose floating value |
| `pow10_i128` | Wide integer power of ten |
| `round_scaled` | Scaled rounding |
| `s_fixed` | Fixed decimal formatting |
| `sig_digits` | Significant digit extraction |
| `s_sci` | Scientific notation |
| `s_repr` | Reference-compatible float representation |
| `s_jfloat` | J-compatible float display |

The historical documentation restricted the formatting guarantees to the magnitudes and precision conditions used by the programs. The bitwise output comparisons are useful precisely because decimal text can conceal last-bit differences. They do not prove a general-purpose correctly rounded formatter.

### IRDL operation contract: example from the source

```mlir
irdl.operation @run {
  %v = irdl.base "!builtin.memref"
  %i = irdl.is index
  %f = irdl.is f64
  %b = irdl.is i1
  irdl.operands(%v, %i, %f, %f, %f, %v)
  irdl.results(%v, %b, %i, %f)
}
```

This fragment is from [`hcalc.irdl.mlir`](mlir/dialects/hcalc.irdl.mlir), inside the `hcalc` dialect. It constrains operand and result types and arity. It does not encode the mathematical meaning of convergence, require a positive tolerance, or establish that the result state has the correct numerical values.

### Negative validation fixtures

| Fixture | Intended defect | Recorded diagnostic |
|---|---|---|
| `hcalc_bad_operand_type.mlir` | Wrong operand type | expected `i64` but got `f64` |
| `hcalc_bad_result_count.mlir` | Wrong result arity | expects exactly 4 results, but got 1 |
| `pirtm_bad_operand_count.mlir` | Wrong operand arity | expects exactly 4 operands, but got 3 |

Both valid custom programs are also rejected without their IRDL registration. These five program checks and two schema parses are the seven recorded IRDL checks in [`IRDL.txt`](logs/mlir/IRDL.txt).

### Lowering pass order

The `lowerFlags` array in `lakefile.lean` defines the following sequence:

| Order | Flag |
|---:|---|
| 1 | `--convert-complex-to-standard` |
| 2 | `--arith-expand` |
| 3 | `--convert-math-to-llvm` |
| 4 | `--convert-scf-to-cf` |
| 5 | `--finalize-memref-to-llvm` |
| 6 | `--convert-complex-to-llvm` |
| 7 | `--convert-arith-to-llvm` |
| 8 | `--convert-func-to-llvm` |
| 9 | `--convert-cf-to-llvm` |
| 10 | `--reconcile-unrealized-casts` |


## Oracle, retrieval and bounded reasoning: detailed subsystem reference


```text
Payload and metadata ──→ SHA-256
SHA-256 ──→ In-memory CAS
In-memory CAS ──→ Integrity check
Payload and metadata ──→ Tokenization and FNV-1a
Tokenization and FNV-1a ──→ 64-dimensional embedding
64-dimensional embedding ──→ Retrieval ranking
```

### Content-addressed store API

Source: [`mlir/lib/oracle.mlir`](mlir/lib/oracle.mlir).

| Function | Role |
|---|---|
| `cas_reset` | Reset in-memory store |
| `cas_count` | Number of stored entries |
| `cas_digest` | Read digest for slot |
| `cas_find` | Locate digest |
| `store_cstr` | Store metadata string |
| `cas_put` | Insert payload with creator and domain |
| `cas_get` | Retrieve bytes and length |
| `cas_verify` | Check payload integrity |
| `cas_creator_is` | Compare creator metadata |
| `record_document` | Record document and digest |

| Retrieval helper | Role |
|---|---|
| `buf_eq_cstr` | Compare byte slice and string |
| `buf_contains` | Search buffer |
| `buf_prefix_cstr` | Prefix comparison |
| `is_word` | Word character test |
| `is_tokch` | Token character test |
| `word_at` | Word-position check |
| `boundary` | Token boundary check |
| `lower` | Lowercase buffer |
| `tokenize` | Extract token ranges |
| `tok_eq` | Compare tokens |
| `tok_in` | Membership |
| `tok_unique` | Unique token processing |
| `fnv1a` | Deterministic token hash |
| `embed` | 64-element embedding |
| `retrieve` | Query and domain-filtered retrieval |



### SHA-256 recorded test vectors

The SHA-256 module exposes `rotr`, `sha256` and `digest_eq`. Its output buffer is `memref<8xi32>`: eight 32-bit words, or 256 bits.

| Input | Recorded digest |
|---|---|
| ASCII `abc` | `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` |
| Empty byte sequence | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |


### Retrieval observations

| Query | Filter | Recorded score sequence |
|---|---|---|
| `unitary transformation` | None | 0.4, 0.0 |
| `transformation` | `domain=causality` | 0.0 |
| `quantum unitarity` | None | 0.0, 0.0 |


### Recursive engine API

Source: [`mlir/main/engine.mlir`](mlir/main/engine.mlir).

| Function | Role |
|---|---|
| `gget`, `gset` | Access scalar global state |
| `status_lit` | Map status code to text |
| `eng_reset` | Reset engine with fuel |
| `id_eq` | Compare hypothesis digest |
| `propose` | Register hypothesis |
| `append_id` | Format hypothesis identifier |
| `append_stmt` | Format hypothesis statement |
| `seen_or_add` | Track evidence digest |
| `step_round` | Advance one reasoning round |
| `run_until_convergence` | Bounded round loop |
| `print_hypo` | Print hypothesis |
| `print_summary` | Print round results |
| `title` | Print scenario heading |
| `main` | Run recorded scenarios |

### Recorded scenario matrix

| Scenario | Hypotheses | Evaluated | Contradictions | Rounds | Remaining fuel |
|---|---:|---:|---:|---:|---:|
| Causal graph claim | 1 | 1 | 0 | 1 | 3 |
| Moon claim | 1 | 1 | 1 | 1 | 3 |
| Combined claims | 3 | 3 | 1 | 1 | 3 |

| Hypothesis | Recorded status |
|---|---|
| Causal graphs are acyclic | `TESTED` |
| Moon.madeOfCheese is asserted as true | `COUNTERMODEL_FOUND` |
| Unitary gates preserve inner products | `TESTED` |



## Formal model ports: obligation-by-obligation interpretation

### Agda-derived invariants

Source: [`PirtmHcalc/Agda/Invariants.lean`](PirtmHcalc/Agda/Invariants.lean).

| ID | Lean declaration | What the statement actually establishes |
|---|---|---|
| I01 | `I01_state_preservation` | Valid successor constructor preserves true well-formed flag |
| I02 | `I02_causal_ordering` | Strictly ordered path cannot return to origin |
| I03 | `I03_provenance_integrity` | Certificate field entails entry-presence flag |
| I04 | `I04_immutability` | Equal artifact records have equal digest field |
| I05 | `I05_termination` | Total bounded runner has relation witness under fixed-point payload contract |
| I06 | `I06_unitarity_preservation` | Identity implication on a Boolean flag |
| I07 | `I07_probability_normalization` | Extract normalization witness stored in record |
| I08 | `I08_encoding_integrity` | Extract codec reconstruction law |
| I09 | `I09_observation_boundary_lossy` | Noninjective projection has no universal left inverse |
| I10 | `I10_agent_isolation` | Different agent identifiers imply different records |
| I11 | `I11_evidence_classification` | No certificate implies status differs from Verified in this model |



### Bounded termination contract


```text
Current state and fuel ──→ Fuel remains?
Fuel remains? ── (No)→ Exhausted
Fuel remains? ── (Yes)→ Fixed point?
Fixed point? ── (Yes)→ Return current state
Fixed point? ── (No)→ Next state and reduced fuel
Next state and reduced fuel ──→ Fuel remains?
```


```lean
def runFuel {A : Type} (step : A → InferenceStep A) : Nat → A → A
  | 0, x => x
  | fuel + 1, x =>
    match step x with
    | InferenceStep.fixedPoint _ => x
    | InferenceStep.continue y => runFuel step fuel y
```

The runner returns the current state when it encounters a fixed-point result. The relation's fixed-point constructor requires that the payload equal that current state. The `hfix` hypothesis is therefore substantive: it rules out a mismatch between the operational branch and the relational rule.

```lean
(hfix : ∀ x y, step x = InferenceStep.fixedPoint y → y = x)
```

The theorem proves bounded-runner relational correctness for this contract. It does not establish that an arbitrary step function reaches a fixed point before its fuel expires.

### Alloy-derived vacuity analysis

The vacuity demonstration makes a distinction between an assertion following from a model fact and an assertion providing independent discrimination among models.

```lean
def claim_as_fact (m : Moon) : Prop := m.madeOfCheese = 1
def MoonIsCheese (m : Moon) : Prop := m.madeOfCheese = 1

theorem check_MoonIsCheese : ∀ m : Moon, claim_as_fact m → MoonIsCheese m :=
  fun _ h => h
```

```lean
theorem control_countermodel : ∃ m : Moon, ¬ MoonIsCheese m :=
  ⟨⟨0⟩, by simp [MoonIsCheese]⟩
```

The first theorem is valid for every model satisfying the fact. The second exhibits a model outside that fact in which the assertion fails. Both statements are useful when auditing what a successful bounded model check actually means.

| Mirror declaration | Interpretation |
|---|---|
| `check_hcalc_A7_assert` | A7 assertion follows from identical fact |
| `hcalc_A7_assert_without_fact` | Single-constructor status type makes assertion universal |
| `check_hcalc_P2_assert` | P2 assertion follows from identical fact |
| `hcalc_P2_assert_iff_fact` | Fact and assertion are equivalent by definition |
| `hcalc_P2_countermodel` | A non-diagonal record refutes assertion without fact |
| `check_weights_positive` | Generator assigning 2 implies positivity |
| `weights_positive_falsifiable` | Generator assigning −5 supplies a countermodel |

The full HCALC Alloy port uses finite carriers, explicit model records, and a `Facts` bundle. Its `check_*` theorems correspond to checks in the source model, while `run_*` theorems correspond to satisfiability witnesses. The port map identifies the nine source model modules: State, PrimeIndex, Transform, Recursion, Stabilize, Contract, Evolve, Optimize and Converge.

## J array computing: numerical implementation reference

J is the array-language numerical path. The code uses named verbs and boxed state records, while the MLIR backend uses explicit memrefs and typed functions. The comparison harness tests agreement on the demo outputs, not equivalence of the two languages.

### Core files

| File | Responsibility |
|---|---|
| [`j/cite.ijs`](j/cite.ijs) | Prime list and spectral helper verbs |
| [`j/hcalc.ijs`](j/hcalc.ijs) | HCALC nested recurrence and diagnostic path |
| [`j/goldilocks.ijs`](j/goldilocks.ijs) | Goldilocks modular arithmetic |
| [`j/demo.ijs`](j/demo.ijs) | Numerical demo producing comparison sections |
| [`verify/core_load.ijs`](verify/core_load.ijs) | Load production core |
| [`verify/harness.ijs`](verify/harness.ijs) | Verification reporting helpers |
| [`verify/run.ijs`](verify/run.ijs) | Verification entry point |
| [`verify/tests/props.ijs`](verify/tests/props.ijs) | H-property checks |

### J verb inventory

| Verb | Responsibility |
|---|---|
| `tp_alpha` | Prime-indexed weight vector |
| `diag_from_alpha` | Diagonal matrix |
| `soft_project_scale` | Governor scale |
| `q_of_tp` | Spectral estimate |
| `c_op_norm` | Contracted operator norm |
| `residual_linf` | Maximum absolute vector difference |
| `tp_from_p64` | Apply prime transform |
| `c_wrap` | Apply state governor |
| `lam_m_from_bound` | Stabilization scalar |
| `hcalc_xi_apply` | Affine evolution |
| `hcalc_step` | Nested recurrence |
| `hcalc_step_info` | Step with diagnostic information |
| `hcalc_run` | Bounded iterative computation |
| `hcalc_state_x` | Extract final state |
| `hcalc_state_converged` | Extract convergence flag |
| `hcalc_state_steps` | Extract step count |
| `hcalc_state_history` | Extract history |
| `to_foundry_step_diagnostic` | Additive diagnostic |

Actual concise array expressions from the source:

```j
P64 =: p: i. 64
```

```j
residual_linf =: 4 : '>./ | (,x) - ,y'
```

The first generates the first 64 primes in J. The second ravels the two arguments, subtracts them, takes absolute values and reduces by maximum. Its semantics correspond to the infinity-norm residual for equal-length vectors.

### Recorded property ledger

| Check | Result |
|---|---|
| H-A1 | PASS |
| H-A2 | PASS |
| H-A3 | PASS |
| H-A4 | PASS |
| H-A5 | SKIP — PMAT absent from core path |
| H-A6 | SKIP — no guardian verb |
| H-A7 | PASS |
| H-SHAPE | PASS |
| H-L5 | PASS |
| H-NEST | PASS |
| SKIP-ShapeBridge | PASS |
| SKIP-Λm-formula | PASS |
| SKIP-C-instep | PASS |
| SKIP-Tp-law | PASS |
| SKIP-Ξ-op | PASS |
| SKIP-OptObj | PASS |
| SKIP-L5-proof | PASS |
| SKIP-Goldilocks16 | SKIP — measured in demo and MLIR |

The labels beginning with `SKIP-` are retained from the source harness. Their recorded verdict is taken from the actual line, not inferred from the prefix. See [`logs/j/verify.out`](logs/j/verify.out).

## Quipper circuit representation and cross-backend comparison

The Haskell source uses a gate algebra and maps each gate to Quipper operations on a register. `prepareBasis` interprets qubit zero as the most significant bit, matching the exact Lean and state-vector experiment convention.

```haskell
data Gate
  = H Int | X Int | Y Int | Z Int | S Int | Sdg Int | T Int
  | Phase Double Int
  | CNOT Int Int
  deriving (Show, Eq)
```

```haskell
inverseCircuit :: [Gate] -> [Gate]
inverseCircuit = map dagger . reverse
```

| Function | Responsibility |
|---|---|
| `dagger` | Map gate to its recorded inverse representation |
| `inverseCircuit` | Reverse gate list and map dagger |
| `applyGate` | Dispatch Quipper gate on register |
| `circuitOf` | Apply gate list to register |
| `prepareBasis` | Prepare basis state from zero register |
| `testBitMSB` | Test coordinate bit in MSB convention |
| `bellGates` | Bell preparation |
| `roundtripGates` | Seven-gate roundtrip sequence |
| `a01Gates` | Parameterized temporal circuit |
| `a02Gates` | Reversible worker circuit |
| `a03Gates` | Hadamard on all eleven coordinates |
| `a04Gates` | GHZ-like three-coordinate circuit |
| `a05Gates` | Historical encoding circuit |
| `a08Gates` | Restricted observer circuit |
| `psi1Gates`, `psi2Gates` | Adversarial preparations |
| `classicalBaseline` | NOT and Toffoli baseline |


## Verification driver: exact acceptance semantics


```text
Source ──→ Build
Source ──→ Proof escape scan
Build ──→ Axiom audit
Backend outputs ──→ Comparison predicates
Proof escape scan ──→ Recorded verdict
Axiom audit ──→ Recorded verdict
Comparison predicates ──→ Recorded verdict
```


The Lake driver contains three different output comparison predicates. They are intentionally not interchangeable.

```lean
inductive Check where
  | exact (expected : List String)
  | subseq (expected : List String)
  | linesIn (pool : List String)
```

| Predicate | Order required | All expected lines required | Extra lines permitted |
|---|---|---|---|
| `exact` | Yes | Yes | No |
| `subseq` | Yes, for expected lines | Yes | Yes |
| `linesIn` | No | No | Only if each belongs to pool |


### Driver function index

| Function | Responsibility |
|---|---|
| `envOr` | Read environment variable or default |
| `proc` | Run subprocess, return output and exit code |
| `stamp` | Obtain timestamp |
| `writeLog` | Create parent directory and write log |
| `say` | Print and accumulate log |
| `linesOf` | Split output into lines |
| `dropRunnerResult` | Remove CPU runner result line |
| `sectionOf` | Extract named reference section |
| `isSubseq` | Ordered subsequence predicate |
| `firstDiff` | Report first output mismatch |
| `lowerText` | Replace generic custom op names |
| `concatFiles` | Combine MLIR library and main text |
| `lowerAndRun` | Lower to LLVM dialect and run |
| `judge` | Apply comparison predicate |
| `readLines` | Load reference lines |
| `mainPrograms` | Register seven ordinary MLIR programs |
| `customPrograms` | Register two custom dialect programs |
| `runJ` | Demo and property harness |
| `runMlir` | Numerical and custom program comparisons |
| `runIrdl` | Schema and negative fixtures |
| `runQuipper` | Cabal build/run and numeric comparison |
| `leanFiles` | Recursive Lean file discovery |
| `wordCount` | Whole-word source scan |
| `runLean` | Build, scan, axiom inspection |

### Local gate versus CI gate

The GitHub Actions workflow runs on pushes and pull requests to `main`, plus manual dispatch. It installs Lean through elan, caches toolchain/build files, runs `lake build`, scans for proof escape words and invokes the axiom audit. It covers the Lean job only; the local `all` script covers the other backends.

| Condition | Local `lake script run lean` | GitHub Actions workflow |
|---|---|---|
| Lean build failure | Fails gate | Fails build step |
| Escape-word hits | Fails gate | Fails scan step |
| Axiom audit nonzero exit | Fails gate | Audit command has `\|\| true` |
| Nonzero project axiom count | Reported | Reported |
| J / MLIR / Quipper checks | Separate local gates | Outside this workflow |



### Reproducible inspection commands

From the repository root, the following commands are useful for inspecting the actual current checkout:

```bash
git rev-parse HEAD
git status --short
cat lean-toolchain
lake --version
lake build
lake env lean tools/AxiomAudit.lean
```

To regenerate the local backend evidence, use the repository's own Lake driver:

```bash
lake script run j
lake script run mlir
lake script run irdl
lake script run quipper
lake script run lean
```

For a clean Lean build, `lake clean` followed by `lake build` discards prior build products. Preserve earlier logs separately if they are required for comparison, because the driver writes its new results to the same log paths.

## Axiom audit: quantitative and qualitative interpretation


```text
461 theorem declarations ──→ 313 empty axiom closures
461 theorem declarations ──→ 91 foundational axioms only
461 theorem declarations ──→ 57 project-specific axioms
57 project-specific axioms ──→ 55 project axioms declared in total
```


The current [`logs/lean/axioms.txt`](logs/lean/axioms.txt) enumerates 461 theorem declarations and 55 project axioms. Grouping its exact dependency sets into disjoint categories gives the following totals.

| Dependency category | Theorems | Share of 461 |
|---|---:|---:|
| Empty axiom set | 313 | 67.90% |
| `propext` only | 70 | 15.18% |
| `Quot.sound` and `propext` | 19 | 4.12% |
| `Classical.choice`, `Quot.sound`, `propext` | 2 | 0.43% |
| At least one project-specific axiom | 57 | 12.36% |
| Total | 461 | 100% (rounding) |

The count is from the audit run on November 25, 2026, on this checkout. The audit iterates declarations in project-root modules, excludes internal names, selects theorem declarations and uses `collectAxioms` to group them by dependency set. A theorem count is not a measure of mathematical difficulty, coverage or independence.

### Project axiom inventory

The table below reproduces the names reported by the audit, grouped by their semantic role. It includes axioms declared in `Hcalc.Carrier` as well as the abstract scalar and Foundry modules.

| Group | Declaration | Role |
|---|---|---|
| Foundry | `Hcalc.Foundry.State` | Abstract state type |
| Foundry | `Hcalc.Foundry.State.add` | State addition |
| Foundry | `Hcalc.Foundry.State.smul` | State scalar multiplication |
| Foundry | `Hcalc.Foundry.State.zero` | Zero state |
| Foundry | `Hcalc.Foundry.nonlinearNorm` | Nonlinear norm |
| Foundry | `Hcalc.Foundry.weightNorm` | Weight norm |
| Scalar | `Hcalc.Real` | Abstract scalar carrier |
| Parameter | `Hcalc.deltaGuard` | Guard value |
| Parameter | `Hcalc.deltaGuard_pos` | Guard positivity |
| Norm | `Hcalc.finMax` | Finite maximum |
| Norm | `Hcalc.finMax_abs_eq_zero_of` | Zero maximum implication |
| Norm | `Hcalc.linf_all_zero_eq_zero` | All-zero norm property |
| Norm | `Hcalc.linf_nonneg` | Norm nonnegativity |
| Scalar | `Hcalc.natToReal` | Natural embedding |
| Scalar | `Hcalc.natToReal_one` | Embedding of one |
| Scalar | `Hcalc.natToReal_pos` | Embedding positivity |
| Scalar | `Hcalc.natToReal_zero` | Embedding of zero |
| Scalar | `Hcalc.realAbs` | Absolute value |
| Scalar | `Hcalc.realAdd` | Addition |
| Scalar | `Hcalc.realDiv` | Division |
| Scalar | `Hcalc.realLog` | Logarithm |
| Scalar | `Hcalc.realLt` | Strict order |
| Scalar | `Hcalc.realMin` | Minimum |
| Scalar | `Hcalc.realMin_le_left` | Left minimum bound |
| Scalar | `Hcalc.realMin_le_right` | Right minimum bound |
| Scalar | `Hcalc.realMul` | Multiplication |
| Scalar | `Hcalc.realNeg` | Negation |
| Scalar | `Hcalc.realOne` | Multiplicative identity |
| Scalar | `Hcalc.realZero` | Additive identity |
| Scalar law | `Hcalc.real_abs_abs` | Absolute-value idempotence |
| Scalar law | `Hcalc.real_abs_eq_zero_iff` | Zero absolute value characterization |
| Scalar law | `Hcalc.real_abs_mul` | Absolute value of product |
| Scalar law | `Hcalc.real_abs_nonneg` | Absolute-value nonnegativity |
| Scalar law | `Hcalc.real_abs_zero` | Absolute value of zero |
| Scalar law | `Hcalc.real_add_assoc` | Addition associativity |
| Scalar law | `Hcalc.real_add_comm` | Addition commutativity |
| Scalar law | `Hcalc.real_add_zero` | Right additive identity |
| Scalar law | `Hcalc.real_contract_force_zero` | Strict contraction forces zero distance |
| Scalar law | `Hcalc.real_le_of_eq` | Equality implies weak order |
| Scalar law | `Hcalc.real_lt_asymm` | Strict-order asymmetry |
| Scalar law | `Hcalc.real_lt_irrefl` | Strict-order irreflexivity |
| Scalar law | `Hcalc.real_mul_add` | Distributivity |
| Scalar law | `Hcalc.real_mul_assoc` | Multiplication associativity |
| Scalar law | `Hcalc.real_mul_comm` | Multiplication commutativity |
| Scalar law | `Hcalc.real_mul_one` | Right multiplicative identity |
| Scalar law | `Hcalc.real_mul_zero` | Right multiplication by zero |
| Scalar law | `Hcalc.real_neg_add_cancel` | Additive cancellation |
| Scalar law | `Hcalc.real_one_mul` | Left multiplicative identity |
| Scalar law | `Hcalc.real_zero_add` | Left additive identity |
| Scalar law | `Hcalc.real_zero_mul` | Left multiplication by zero |
| Governor | `Hcalc.softScaleFactor` | Scale function |
| Governor | `Hcalc.softScaleFactor_of_gt` | Above-margin branch law |
| Governor | `Hcalc.softScaleFactor_of_le` | Within-margin branch law |
| Parameter | `Hcalc.tolDefault` | Default tolerance |
| Parameter | `Hcalc.tolDefault_pos` | Tolerance positivity |



The local driver also contains `partial def leanFiles` for filesystem traversal. 

## Assurance matrix: established scope and remaining obligations


| Area | Established in inspected revision | Stronger obligation |
|---|---|---|
| Causal ordering | Strict natural-index paths are acyclic | Relate actual event histories to the indexed relation |
| Reversible syntax | Inverse mapping is involutive for symbolic alphabet | Universal semantic inverse theorem on valid states |
| Exact quantum experiments | Concrete amplitudes, norms and fidelities | Prove gate-level norm preservation for every valid state |
| Quantum shape | Tree-based implementation | Dependent shape and index invariants |
| CNOT | Supported ordered coordinate pairs | All distinct control/target pairs |
| HCALC recurrence | Abstract operator definitions and conditional uniqueness | Concrete real model and convergence-rate proof |
| HCALC numerics | J/MLIR recorded output agreement | Verified floating-point error bounds |
| Goldilocks | Concrete vectors and 200 comparisons | All canonical residues and sufficient-fuel theorem |
| IRDL | Valid schemas and negative fixtures | Semantic refinement of lowering |
| SHA-256 | Reference digest comparisons | All-input functional correctness against formal spec |
| CAS | In-memory example behavior | Capacity, collision policy, durability and access contracts |
| Retrieval | Reference ranking cases | Defined cross-platform ranking contract |
| Engine | Bounded scenarios and contradiction records | General transition refinement and evidence semantics |
| Worker aggregation | Concrete report totals and sorted invariant set | General merge correctness under scheduler permutations |
| Alloy port | Faithful model facts, checks and witnesses | Independent, non-vacuous domain assertions |
| CI | Lean build and source scan | Fail-closed audit and complete multi-backend CI |


## Foundry F1: J, TableGen and native kernels

The package extends the original PIRTM–HCALC libraries with Foundry F1: prime-field arithmetic, signed monomial matrices, spectral analysis, additive recurrence, emission policies, numerical certification, and native SHA-256 interfaces. The original nested HCALC model remains distinct from the additive Foundry recurrence.

```text
                    PIRTM × HCALC × Foundry F1
                               |
          +--------------------+----------------------+
          |                    |                      |
       Lean 4              Pure J                 MLIR
          |                    |                      |
   causal semantics        types.ijs          IRDL + TableGen
   quantum algebra             |                      |
   field evidence          Goldilocks           foundry dialect
                               |                      |
                              PMat              generic IR example
                               |
                           spectral            Native C++ field
                               |                      |
                          recurrence            wide integer oracle
                               |
                          emission gate
                               |
                          Ace certificate
                               |
                          harness record
                               |
                       C driver / NASM adapter
                               |
                           SHA-256 digest


### Pure-J package and module reference

| Module | Responsibility | Representative interface |
|---|---|---|
| [foundry.ijs](j/foundry.ijs) | Seven-module package loader | `foundry_export` |
| [types.ijs](j/types.ijs) | Prime constants, tiers, policies and verdicts | `tier_eps`, `tier_epsilon` |
| [goldilocks.ijs](j/goldilocks.ijs) | Field operations and batches | `fp_reduce`, `fp_mulmod`, `fp_inv` |
| [pmat.ijs](j/pmat.ijs) | Signed sparse monomial matrices | `pmat_new`, `pmat_insert`, `pmat_compose` |
| [spectral.ijs](j/spectral.ijs) | Gershgorin and power iteration | `spectral_analyze`, `sr_radius` |
| [recurrence.ijs](j/recurrence.ijs) | Schedules, projection and iteration | `synth_weights`, `rec_step`, `rec_run` |
| [gate.ijs](j/gate.ijs) | Output and numerical CSL checks | `emit_apply`, `csl_commutation` |
| [certify.ijs](j/certify.ijs) | Margin, tail estimate and certificate | `ace_certify` |
| [foundry_harness.ijs](j/foundry_harness.ijs) | Named checks and serialized record | `check`, `RECORD`, `OKS` |
| [cite.ijs](j/cite.ijs) | Separate HCALC numeric hooks | `P64`, `gershgorin_bound` |

The Foundry loader orders its dependencies as types → Goldilocks → PMat → spectral → recurrence → gate → certify. The `cite` locale supplies the original HCALC numerical helper interface separately.

### Additive contraction dynamics

```text
x(t+1) = Ξ(t)x(t) + Λ(t)T(x(t)) + g(t)
q_est  = max|Ξ| + max|Λ| × r
r      = max|T(x)| / max|x|   if max|x| > 10⁻¹⁵
       = max|T(x)|            otherwise

target = 1 − ε
scale  = target / q_est       if q_est > target
       = 1                    otherwise
```

The implementation accepts transform and projection hooks. `synth_weights` assigns 0.7 and 0.3 portions of the target to the two schedules, with uniform, harmonic or logarithmic decay. `soft_project` scales both weight vectors when the estimated contraction exceeds the target. `residual_l2` measures the Euclidean distance between successive states. The pointwise norm ratio is not automatically a global Lipschitz bound, and projection to the target does not establish strict inequality at that boundary.

| Tier | Epsilon | Target |
|---|---:|---:|
| T1 | 0.10 | 0.90 |
| T2 | 0.05 | 0.95 |
| T3 | 0.02 | 0.98 |
| T4 | 0.01 | 0.99 |

### Record representation

| Record | Ordered fields |
|---|---|
| PMat | rows; cols; entries (sign, delta_source, delta_target, row, col) |
| SpectralResult | spectral_radius; contractive; gershgorin_bound; power_iter_bound; used_power_iteration |
| StepInfo | step; q; epsilon; n_xi; n_lam; projected; residual |
| REC_STATE | x_current; converged; history |
| AceCert | lipschitz_upper; safety_margin; tail_bound; certified |


### Emission policies and CSL

| Policy | Output |
|---|---|
| PassThrough | Proposed output |
| Suppress | Zero vector when q ≥ 1 − ε; proposed output otherwise |
| Hold | Previous output when q ≥ 1 − ε; proposed output otherwise |
| Attenuate | Proposed output multiplied by max(0, 1 − ε − q) |


```text
neutrality:  |T(x)i − T(x)j| / |xi − xj| ≤ 1 + ε
             for coordinate differences above the guard
beneficence: ‖T(x)‖₂ ≤ (1 + ε)‖x‖₂
             residual ≤ (1 + ε)‖x‖₂
commutation: ‖F(T(x)) − T(F(x))‖∞ ≤ ε
```

The beneficence transform-norm test includes a small-norm guard in the implementation. 

### Ace certificate arithmetic

```text
q_max = max of recorded q values
r_max = max of recorded residuals
M     = (1 − ε) − q_max
B     = r_max / (1 − q_max)    if q_max < 1
      = infinity              otherwise
certified = (M ≥ delta)
```

### Foundry TableGen dialect

[FoundryDialect.td](mlir/dialects/FoundryDialect.td) declares 46 operations and five named types, in addition to the historical 27 operations in the two IRDL dialects. Its generic assembly syntax expresses typed operations without claiming a completed native lowering pipeline.

| Type | Representation contract |
|---|---|
| `!foundry.fp` | Canonical Goldilocks residue, runtime range invariant |
| `!foundry.pmat` | Prime monomial matrix |
| `!foundry.spectral_result` | Spectral analysis record |
| `!foundry.step_info` | Recurrence step record |
| `!foundry.ace_cert` | Numerical certificate record |

| Family | Count | Mnemonics in the `foundry` namespace |
|---|---:|---|
| Field | 9 | `fp_reduce`, `fp_mulmod`, `fp_add`, `fp_sub`, `fp_mul`, `fp_pow`, `fp_inv`, `fp_add_batch`, `fp_mul_batch` |
| Tier | 1 | `tier_eps` |
| PMat | 10 | `pmat_new`, `pmat_rows`, `pmat_cols`, `pmat_entries`, `pmat_shape`, `pmat_insert`, `pmat_validate_grading`, `pmat_conservation`, `pmat_compose`, `pmat_frobenius` |
| Spectral | 10 | `gershgorin_bound`, `gershgorin_check`, `power_iteration`, `power_iteration_check`, `spectral_analyze`, `sr_radius`, `sr_contractive`, `sr_gersh`, `sr_power`, `sr_used_pi` |
| Recurrence | 8 | `apply_hook`, `synth_weights`, `soft_project`, `q_estimate`, `residual_l2`, `wt_at`, `rec_step`, `rec_run` |
| Emission / CSL | 4 | `emit_apply`, `csl_neutrality`, `csl_beneficence`, `csl_commutation` |
| Certification | 3 | `ace_safety_margin`, `ace_tail_bound`, `ace_certify` |
| Digest | 1 | `sha256_mask` |
| **Total** | **46** | |

The tracked example is [goldilocks_add_mul_mlir](mlir/dialects/goldilocks_add_mul_mlir), without a `.mlir` suffix in the current tree. Its field function is represented as follows:

```mlir
func.func @goldilocks_add_mul(%a: !foundry.fp, %b: !foundry.fp, %c: !foundry.fp) -> !foundry.fp {
  %s = "foundry.fp_add"(%a, %b) : (!foundry.fp, !foundry.fp) -> !foundry.fp
  %m = "foundry.fp_mul"(%s, %c) : (!foundry.fp, !foundry.fp) -> !foundry.fp
  %r = "foundry.fp_reduce"(%m) : (!foundry.fp) -> !foundry.fp
  func.return %r : !foundry.fp
}
```

The same file contains a `certify_record` function mapping a dynamic byte tensor to a 32-byte digest using `foundry.sha256_mask`. The [lowering reference](mlir/custom/Goldilocks/mask_gate/Lowering.md) describes the verb-to-operation correspondence and the cases where no separate dialect operation exists. The new TableGen and example sources explicitly distinguish their structural inspection from compilation with MLIR tools.

### Native C++ Goldilocks arithmetic

| Source | Responsibility |
|---|---|
| [goldilocks.h](mlir/custom/Goldilocks/goldilocks.h) | `pmc::Goldilocks` and 64-bit `Elem` interface |
| [goldilocks.cpp](mlir/custom/Goldilocks/goldilocks.cpp) | Reduction, add, sub, mul, pow, inv, batches and feature queries |
| [test_goldilocks.cpp](mlir/custom/Goldilocks/test_goldilocks.cpp) | Independent wide-integer remainder oracle, deterministic test values |

```text
p = 2⁶⁴ − 2³² + 1 = 18446744069414584321
ab = lo + 2⁶⁴ hi
hi = hi_lo + 2³² hi_hi
2⁶⁴ ≡ 2³² − 1 (mod p)
2⁹⁶ ≡ −1 (mod p)
ab ≡ lo + (2³² − 1)hi_lo − hi_hi (mod p)
```

### Native mask gate and SHA-256 interfaces

| File | Responsibility |
|---|---|
| [sha256.asm](mlir/custom/Goldilocks/mask_gate/sha256.asm) | Native SHA-256 routine and state |
| [cell_gate.asm](mlir/custom/Goldilocks/mask_gate/cell_gate.asm) | `hash_via_gate` adapter |
| [wrapper.asm](mlir/custom/Goldilocks/mask_gate/wrapper.asm) | `sha256_hash_linux` adapter |
| [hash_file.c](mlir/custom/Goldilocks/mask_gate/hash_file.c) | File-to-digest driver |
| [main.c](mlir/custom/Goldilocks/mask_gate/main.c) | Reference-vector driver |

```text
System V arguments            Windows x64 arguments
RDI = data                 →  RCX = data
RSI = length               →  RDX = length
RDX = output               →  R8  = output
```

| Input | Bytes | Expected SHA-256 |
|---|---:|---|
| Empty | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| abc | 3 | `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` |
| Standard long56 vector | 56 | `248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1` |



### Harness relocation and source-level integration boundaries

| Historical path in source or comments | Current tracked path |
|---|---|
| `j/foundry/foundry.ijs` | [j/foundry.ijs](j/foundry.ijs) |
| `j/foundry/*.ijs` | [j/](j/) |
| `mlir/dialect/FoundryDialect.td` | [mlir/dialects/FoundryDialect.td](mlir/dialects/FoundryDialect.td) |
| `mlir/lowering/LOWERING.md` | [mlir/custom/Goldilocks/mask_gate/Lowering.md](mlir/custom/Goldilocks/mask_gate/Lowering.md) |
| `mlir/mask-gate/sha256.asm` | [mlir/custom/Goldilocks/mask_gate/sha256.asm](mlir/custom/Goldilocks/mask_gate/sha256.asm) |
| `mlir/harness/run.sh` | [tools/run.sh](tools/run.sh) |
| `mlir/harness/foundry_harness.ijs` | [j/foundry_harness.ijs](j/foundry_harness.ijs) |
| `mask_gate/call_gate.asm` | [mlir/custom/Goldilocks/mask_gate/cell_gate.asm](mlir/custom/Goldilocks/mask_gate/cell_gate.asm) |



| Historical driver exit code | Meaning |
|---|---|
| 0 | J stage and digest stage passed |
| 1 | J stage or gate build failure |
| 2 | J interpreter not found |
| 3 | Native gate blocked |

See [tools/script_instructions.md](tools/script_instructions.md) for the original driver contract. Archived Lean, J, MLIR and Quipper logs retain their original evidence scope and do not attest to the new native or Foundry harness.

## Current tracked file inventory

The 120 tracked files in the inspected Git tree are listed below. Directories are implicit in their paths.

```text
.github/workflows/ci.yml
.gitignore
Hcalc.lean
Hcalc/Axioms.lean
Hcalc/Carrier.lean
Hcalc/Convergence.lean
Hcalc/Foundry.lean
Hcalc/Invariants.lean
Hcalc/Pipeline.lean
Hcalc/Production.lean
Hcalc/RealStub.lean
LICENSE
PIRTM.lean
PIRTM/Core.lean
PIRTM/Invariants.lean
PIRTM/Quantum11.lean
PirtmHcalc.lean
PirtmHcalc/Agda/Assumptions.lean
PirtmHcalc/Agda/Core.lean
PirtmHcalc/Agda/Invariants.lean
PirtmHcalc/Alloy/Hcalc.lean
PirtmHcalc/Alloy/HcalcMirror.lean
PirtmHcalc/Alloy/VacuityDemo.lean
PirtmHcalc/Data/Agents.lean
PirtmHcalc/Data/Experiments.lean
PirtmHcalc/Data/Goldilocks.lean
PirtmHcalc/Quantum/Exact.lean
README.md
j/certify.ijs
j/cite.ijs
j/demo.ijs
j/foundry.ijs
j/foundry_harness.ijs
j/gate.ijs
j/goldilocks.ijs
j/hcalc.ijs
j/pmat.ijs
j/recurrence.ijs
j/spec.md
j/spectral.ijs
j/types.ijs
lake-manifest.json
lakefile.lean
lean-toolchain
logs/SUMMARY.txt
logs/j/SUMMARY.txt
logs/j/demo.out
logs/j/verify.out
logs/lean/SUMMARY.txt
logs/lean/axioms.txt
logs/lean/build-clean.log
logs/lean/build.log
logs/mlir/IRDL.txt
logs/mlir/SUMMARY.txt
logs/mlir/agents.out
logs/mlir/engine.out
logs/mlir/goldilocks.out
logs/mlir/hcalc.out
logs/mlir/hcalc_pipeline.out
logs/mlir/hilbert11.out
logs/mlir/oracle.out
logs/mlir/pirtm_roundtrip.out
logs/mlir/quantum.out
logs/quipper/SUMMARY.txt
logs/quipper/run.out
logs/reference/expected/agents.txt
logs/reference/expected/engine.subseq.txt
logs/reference/expected/hilbert11.txt
logs/reference/expected/oracle.txt
logs/reference/expected/quantum.txt
logs/reference/expected/quipper.txt
logs/reference/python-experiment.txt
logs/reference/python-ref-dump.txt
logs/reference/python-unittest.txt
mlir/custom/Goldilocks/goldilocks.cpp
mlir/custom/Goldilocks/goldilocks.h
mlir/custom/Goldilocks/mask_gate/Lowering.md
mlir/custom/Goldilocks/mask_gate/cell_gate.asm
mlir/custom/Goldilocks/mask_gate/hash_file.c
mlir/custom/Goldilocks/mask_gate/main.c
mlir/custom/Goldilocks/mask_gate/sha256.asm
mlir/custom/Goldilocks/mask_gate/wrapper.asm
mlir/custom/Goldilocks/test_goldilocks.cpp
mlir/custom/hcalc_pipeline.mlir
mlir/custom/invalid/hcalc_bad_operand_type.mlir
mlir/custom/invalid/hcalc_bad_result_count.mlir
mlir/custom/invalid/pirtm_bad_operand_count.mlir
mlir/custom/pirtm_roundtrip.mlir
mlir/dialects/FoundryDialect.td
mlir/dialects/goldilocks_add_mul_mlir
mlir/dialects/hcalc.irdl.mlir
mlir/dialects/pirtm.irdl.mlir
mlir/lib/goldilocks.mlir
mlir/lib/hcalc.mlir
mlir/lib/io.mlir
mlir/lib/jfmt.mlir
mlir/lib/oracle.mlir
mlir/lib/qmat.mlir
mlir/lib/qsim.mlir
mlir/lib/sha256.mlir
mlir/main/agents.mlir
mlir/main/engine.mlir
mlir/main/goldilocks.mlir
mlir/main/hcalc.mlir
mlir/main/hilbert11.mlir
mlir/main/oracle.mlir
mlir/main/quantum.mlir
quipper/cabal.project
quipper/pirtm-quipper.cabal
quipper/src/Analysis.hs
quipper/src/Main.hs
quipper/src/PirtmCircuits.hs
spec/PRODUCTION.md
tools/AxiomAudit.lean
tools/run.sh
tools/script_instructions.md
verify/core_load.ijs
verify/harness.ijs
verify/run.ijs
verify/tests/props.ijs
```

## Figure provenance


| Figure | Source basis |
|---|---|
| Architecture diagram | Import roots, Lake driver and backend structure |
| Causal inference diagram | CausalPath and runFuel definitions |
| Hcalc pipeline diagram | Canonical nested recurrence |
| Hcalc trajectory diagram | Derived trajectory using recorded demo weights |
| Quantum support diagram | Exact experiment support and probabilities |
| Goldilocks fold diagram | Modular fold identities and foldMul |
| Compiler lowering diagram | IRDL checks and Lake lowering driver |
| Oracle diagram | Oracle and engine source interfaces |
| Evidence flow diagram | Distinct verification predicates and logs |
| Axiom distribution diagram | Recorded theorem dependency group counts |


## Provenance and licensing


The repository includes an [AGPL-3.0 license](LICENSE). Source headers additionally reference `LicenseRef-SnapKitty-Opaque-1.0`; consult the applicable license terms before relying on that alternative. The present source inspection did not establish the full text of that alternative license.

Copyright (C) 2026 Ahmad Parr.

**PIRTM × HCALC — mathematical structure, computational representation, and explicit evidence boundaries.**
