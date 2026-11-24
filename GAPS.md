<!--
  SPDX-License-Identifier: AGPL-3.0-only
  Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
  Copyright (C) 2026 Ahmad Parr
-->

# Gaps

This file lists everything that is approximated, axiomatised, replaced, or not ported.

## Lean axioms

The project uses no `sorry`, `admit` or `native_decide`. The theorems use the standard Lean axioms `propext`, `Quot.sound` and `Classical.choice`, plus the project axioms listed below. All of the project axioms come from the HCALC Lean library (`Hcalc/RealStub.lean`, `Hcalc/Foundry.lean`), which has no Mathlib. `lake script run lean` regenerates this list in `logs/lean/axioms.txt`, together with the axioms each theorem depends on. The modules `PIRTM.*`, `PirtmHcalc.*` and `tools/` declare no axioms.

Declared axioms (55), grouped by Spec GapId:

* **Gap-Real-arith** (the `Real` stub and its field and order laws):
  `Hcalc.Real`, `Hcalc.natToReal`, `Hcalc.natToReal_one`, `Hcalc.natToReal_pos`, `Hcalc.natToReal_zero`, `Hcalc.realAbs`, `Hcalc.realAdd`, `Hcalc.realDiv`, `Hcalc.realLog`, `Hcalc.realLt`, `Hcalc.realMin`, `Hcalc.realMin_le_left`, `Hcalc.realMin_le_right`, `Hcalc.realMul`, `Hcalc.realNeg`, `Hcalc.realOne`, `Hcalc.realZero`, `Hcalc.real_abs_abs`, `Hcalc.real_abs_eq_zero_iff`, `Hcalc.real_abs_mul`, `Hcalc.real_abs_nonneg`, `Hcalc.real_abs_zero`, `Hcalc.real_add_assoc`, `Hcalc.real_add_comm`, `Hcalc.real_add_zero`, `Hcalc.real_contract_force_zero`, `Hcalc.real_le_of_eq`, `Hcalc.real_lt_asymm`, `Hcalc.real_lt_irrefl`, `Hcalc.real_mul_add`, `Hcalc.real_mul_assoc`, `Hcalc.real_mul_comm`, `Hcalc.real_mul_one`, `Hcalc.real_mul_zero`, `Hcalc.real_neg_add_cancel`, `Hcalc.real_one_mul`, `Hcalc.real_zero_add`, `Hcalc.real_zero_mul`
* **Gap-Foundry-StateOps / Gap-Foundry-Norm** (the Foundry carrier and its norms):
  `Hcalc.Foundry.State`, `Hcalc.Foundry.State.add`, `Hcalc.Foundry.State.smul`, `Hcalc.Foundry.State.zero`, `Hcalc.Foundry.nonlinearNorm`, `Hcalc.Foundry.weightNorm`
* **Gap-Foundry-FinMax** (ℓ∞ max):
  `Hcalc.finMax`, `Hcalc.finMax_abs_eq_zero_of`, `Hcalc.linf_all_zero_eq_zero`, `Hcalc.linf_nonneg`
* **Gap-Foundry-SoftScale** and the parameters:
  `Hcalc.deltaGuard`, `Hcalc.deltaGuard_pos`, `Hcalc.softScaleFactor`, `Hcalc.softScaleFactor_of_gt`, `Hcalc.softScaleFactor_of_le`, `Hcalc.tolDefault`, `Hcalc.tolDefault_pos`

Note on `Hcalc.real_contract_force_zero`: like every other axiom in the list it is an unproved assumption about the stub `Real`. The HCALC convergence theorems (L5) depend on it.

## Numerics

* **HCALC numbers are not proved in Lean.** HCALC's float results (α = 1/(1+ln p), the run of 26 steps, residuals) are computed in J and MLIR, and the two agree digit for digit. They are not proved in Lean, because `Real` there is an axiomatised stub and `realLog` is an uninterpreted axiom. The exact Lean theorems cover Goldilocks, the quantum experiments and the agent data. Logged float decimals are tied to exact values only by `near` theorems, which bound the difference by 2^-u.
* **Sums.** The MLIR programs sum with Neumaier compensation, to match J's `+/` and Python's results to the last bit. Python's own `sum` is not compensated. Every output compared in this project agrees bit for bit, but other inputs could differ in the last ulp.
* **Number printing.** `s_repr` in `mlir/lib/io.mlir` reproduces Python `repr` only for the magnitudes these programs print. `s_sci` needs precision ≥ exponent.
* **Trace distance.** `trace_distance_bound` in MLIR and Quipper is the Frobenius bound used by the PIRTM source, not the nuclear norm. It is kept as in the source.
* **SHA-256.** SHA-256 is implemented in MLIR and checked against Python digests. It is not proved in Lean.

## PIRTM behaviour

* **Embedding hash.** Python's embedding fallback uses `hash()`, which is salted per process. MLIR uses FNV-1a instead. The retrieval results compared here match Python under PYTHONHASHSEED 0, 1 and 12345, but other documents could rank differently.
* **Scheduler.** The scheduler's thread pool is replaced by a sequential run in sorted worker order. The merge is the same deterministic sort.
* **Retrieval filters.** Retrieval filters support only `domain`, the only key the tests use.
* **Measurement sampling.** `sample_measurement` takes the random number r as an argument instead of drawing it from an RNG.
* **Exact simulator.** The exact Lean simulator supports CNOT only with control < target, and has no T gate. All PIRTM circuits satisfy both limits. T is supported in MLIR (`qmat.mlir`).
* **CAS.** The CAS lives in memory, with a fixed number of slots. There is no storage directory.
* **Agda.**
  * The original Agda was never type-checked by its own pipeline: worker A10 reported `NOT_RUN`, and the MLIR port reproduces that report verbatim.
  * The Lean port states I05 (termination) with an explicit fixpoint hypothesis (`hfix`), stated as a hypothesis of the theorem rather than as an axiom.

## HCALC behaviour

* **J verify SKIPs.** The J verify harness reports 3 SKIPs, exactly as designed:
  * H-A5: PMAT is unused on the Core path.
  * H-A6: there is no guardian verb in J.
  * SKIP-Goldilocks16: Goldilocks is measured by `j/demo.ijs` and the MLIR port, not by an H-* property.
* **Rewritten J helpers.** `j/cite.ijs` and `j/goldilocks.ijs` are rewrites written for this project. They replace helpers that HCALC loaded from a sibling repository, which is not included.
* **Alloy.**
  * The Alloy models are no longer run by the Alloy analyzer. They exist only as Lean theorems, which cover every finite instance instead of a bounded scope.
  * The vacuity result holds over all instances: every `check` follows from a fact.

## Not ported / not kept

* **Python reference generators.** `logs/reference/expected/*.txt` were produced by small Python scripts that called the original PIRTM code. Those scripts ran outside the project and are not kept, because Python is not part of the deliverable. Their output is kept, along with the raw Python logs `python-experiment.txt`, `python-unittest.txt` and `python-ref-dump.txt`.
* **Spec and process documents.** `spec/PROPERTIES.md`, `INTERFACES.md`, `COHERENCE.md`, `FOUNDRY_J_*.md` and `HANDOFF_PRODUCTION.md` were not carried over. Neither were PIRTM's `docs/*.svg`, its receipts and `alloy.jar`. See `PORT_MAP.md`.
* **Quipper dependency.** The Quipper build needs the `quipper` packages from the cabal store or Hackage, plus GHC 8.8.4. These are external toolchains, not part of the project or the zip.
* **`tools/`.** It contains only `AxiomAudit.lean`, which is Lean. The project contains no Python, C++, JS/TS or shell files. All driver logic is in `lakefile.lean`.
