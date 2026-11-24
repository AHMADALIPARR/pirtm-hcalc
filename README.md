<!--
  SPDX-License-Identifier: AGPL-3.0-only
  Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
  Copyright (C) 2026 Ahmad Parr
-->

# pirtm-hcalc

This is the home of two former projects, merged into one self-contained Lake project:

* **PIRTM**: an 11-qubit state-vector model (2048 amplitudes) and an adversarial
  "restricted observer" experiment. It also includes a content-addressed store
  and retrieval oracle, a bounded recursive hypothesis engine, eleven worker
  agents with a scheduler, and the formal invariants I01–I11.
* **HCALC**: a nested contraction recurrence
  `X_{t+1} = Ξ(t, Λm · C(Tp(X_t)))` on a finite real carrier, together with its
  definitions (`spec/PRODUCTION.md`), its relational model, its Lean library,
  its J core and its J verification harness. The Goldilocks field
  (p = 2^64 − 2^32 + 1) is also here.

The project uses only these languages:

* **Lean 4**: proofs, the experiment data as theorems, and the build/run driver (`lakefile.lean`).
* **MLIR**: custom IRDL dialects plus executable programs, lowered to LLVM and run.
* **J**: the HCALC core and its verification harness.
* **Quipper (Haskell)**: the quantum circuits.

## Layout

| Path | Contents |
|---|---|
| `PIRTM/`, `PIRTM.lean` | PIRTM Lean library (core definitions, invariants, 11-coordinate model) |
| `Hcalc/`, `Hcalc.lean` | HCALC Lean library (carrier, Tp, C, Λm, Ξ, pipeline, convergence, Foundry layer, Real stub) |
| `PirtmHcalc/Agda/` | the PIRTM Agda development ported to Lean (Core, Assumptions, Invariants I01–I11) |
| `PirtmHcalc/Alloy/` | every Alloy model of both projects ported to Lean (`Hcalc`, `HcalcMirror`, `VacuityDemo`), including the vacuity analysis |
| `PirtmHcalc/Quantum/Exact.lean` | exact state-vector semantics over ℤ[i]/√2^k (perfect binary tree of amplitudes) |
| `PirtmHcalc/Data/` | experiment results as theorems proved by computation (`decide`) |
| `tools/AxiomAudit.lean` | lists every axiom declared in the project and the axioms each theorem uses |
| `mlir/dialects/` | IRDL definitions of the custom `pirtm` and `hcalc` dialects |
| `mlir/lib/` | MLIR libraries: I/O and number formatting, SHA-256, state-vector simulator, matrix circuits, CAS/oracle, HCALC, Goldilocks |
| `mlir/main/` | executable MLIR programs (one per experiment / test suite) |
| `mlir/custom/` | programs written with the custom dialect ops (IRDL-verified, lowered, run); `invalid/` holds programs the verifier must reject |
| `quipper/` | Quipper circuits for every PIRTM circuit, with a simulator and printed circuits |
| `j/` | HCALC J core (`hcalc.ijs`), its spectral helpers (`cite.ijs`), Goldilocks (`goldilocks.ijs`), demo |
| `verify/` | J verification harness (H-* properties, fail-open) |
| `spec/PRODUCTION.md` | the HCALC definitions document (the J harness reads it) |
| `logs/` | output of the last runs; `logs/reference/` holds reference outputs captured from the original Python |

## Running

```
lake build                    # Lean libraries (PIRTM, Hcalc, PirtmHcalc)
lake script run j             # J demo + verify harness       -> logs/j/
lake script run mlir          # lower + run every MLIR program, compare with references -> logs/mlir/
lake script run irdl          # IRDL verification of the custom dialects -> logs/mlir/IRDL.txt
lake script run quipper       # cabal build + run the Quipper circuits, compare -> logs/quipper/
lake script run lean          # lake build, sorry/admit scan, axiom audit -> logs/lean/
lake script run all           # all of the above              -> logs/SUMMARY.txt
```

Run `j` before `mlir`, because the HCALC and Goldilocks MLIR programs are compared
against J's output in `logs/j/demo.out`.

Tools these scripts expect (override them with environment variables):

| Tool | Default path | Variable |
|---|---|---|
| Lean | `leanprover/lean4:v4.34.1` (`lean-toolchain`) | — |
| LLVM/MLIR 19 | `/usr/lib/llvm-19/bin` | `LLVM_BIN` |
| MLIR runner library | `/usr/lib/llvm-19/lib/libmlir_c_runner_utils.so` | `MLIR_RUNNER_LIB` |
| J 9.7 | `/home/box/j/j9.7/bin/jconsole` | `JCONSOLE` |
| GHC 8.8.4 + cabal, with the `quipper` packages from Hackage | `~/.ghcup/bin` | `GHCUP_BIN` |
| libtinfo.so.5, needed by GHC 8.8 | `~/.local/lib/tinfo5` | `TINFO5_DIR` |

## What is checked, and against what

* **MLIR vs Python.** `logs/reference/expected/*.txt` were rendered from the
  original Python code, in the same line format the MLIR programs print. The
  comparison is exact for floats, using 17 significant digits plus the IEEE bit
  pattern. Engine output is checked as an ordered subsequence, because the MLIR
  program prints extra lines.
* **MLIR vs J (HCALC, Goldilocks).** These programs print J's number display.
  Their output must equal the corresponding section of `logs/j/demo.out`
  exactly.
* **Custom dialects.**
  * `mlir/custom/*.mlir` must verify under `mlir-opt --irdl-file=…`.
  * They must be rejected without the IRDL file.
  * They are lowered by the `lowerCustom` table in `lakefile.lean`, which
    rewrites each op to a `func.call`.
  * They are then run, and every printed line must occur in the reference.
* **Quipper.**
  * The circuits are built with Quipper and printed (ASCII and gate counts).
  * They are simulated by `quipper/src/Analysis.hs`.
  * Every numeric line is compared exactly with Python values rendered in the
    same format.
  * The inverse of the roundtrip circuit is computed two ways: with PIRTM's
    dagger list and with Quipper's `reverse_generic_endo`.
* **Lean data theorems.** These are proved by `decide` over exact
  representations: ℤ[i] numerators over a power of √2, dyadic rationals, and
  naturals mod p. The `near` theorems state that a decimal logged by a float run
  is within 2^-u of the exact value. `native_decide` is not used anywhere.
* **Alloy port.**
  * Every Alloy `check` becomes a theorem `Facts M → A M` over all finite
    instances.
  * Every `run` becomes an explicit witness instance.
  * For each assertion, the port records which fact implies it (most are
    `Iff.rfl`). This is the vacuity critique: the checks pass because the facts
    state them.
  * Countermodels show that removing the matching fact falsifies the assertion
    (`P2_fails_without_its_fact`, `hcalc_A7_assert_without_fact`,
    `control_countermodel`).

See `PORT_MAP.md` for where every original file went, and `GAPS.md` for
everything that is approximated, axiomatised or not ported.

## Results of the last full run

See `logs/SUMMARY.txt` and the per-area `SUMMARY.txt` files. Nothing in this
README counts as a result unless a log backs it.
