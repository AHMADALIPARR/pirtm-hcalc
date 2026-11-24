<!--
  SPDX-License-Identifier: AGPL-3.0-only
  Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
  Copyright (C) 2026 Ahmad Parr
-->

# Port map

Provenance: ported from PIRTM@e9caa0d / HCALC@4854e7b.

Each file of both source trees is listed below with the file it became, or the reason it was dropped.

## PIRTM@e9caa0d

| Source file | Port | Notes |
|---|---|---|
| `pirtm/quantum/hilbert11.py` | `mlir/lib/qsim.mlir`, `mlir/main/hilbert11.mlir`; `quipper/src/{PirtmCircuits,Analysis}.hs`; `PirtmHcalc/Quantum/Exact.lean`, `PirtmHcalc/Data/Experiments.lean` | simulator is generalised to n qubits |
| `pirtm/quantum/gates.py` | `mlir/lib/qmat.mlir` | the T gate exists in MLIR but not in the exact Lean simulator (GAPS) |
| `pirtm/quantum/circuit.py` | `mlir/lib/qmat.mlir`, `mlir/main/quantum.mlir`; Quipper `bell`/`classical` sections | `sample_measurement` takes an explicit r (GAPS) |
| `pirtm/quantum/__init__.py` | — | package marker, nothing to port |
| `pirtm/oracle/cas.py` | `mlir/lib/sha256.mlir`, `mlir/lib/oracle.mlir` | CAS is kept in memory (the Python used a dict, plus an optional directory) |
| `pirtm/oracle/retrieval.py` | `mlir/lib/oracle.mlir`, `mlir/main/oracle.mlir` | embed hash is FNV-1a instead of Python's salted `hash()` (GAPS) |
| `pirtm/oracle/__init__.py` | — | package marker |
| `pirtm/recursive/engine.py` | `mlir/main/engine.mlir` | |
| `pirtm/recursive/__init__.py` | — | package marker |
| `pirtm/agents/base.py` | `mlir/main/agents.mlir` (report records, ledger check) | |
| `pirtm/agents/workers.py` | `mlir/main/agents.mlir` (workers A01–A11); Quipper `workers`; `PirtmHcalc/Data/Agents.lean`, `Experiments.lean` | |
| `pirtm/agents/boundaries.py` | `mlir/main/agents.mlir` (status strings) | |
| `pirtm/agents/__init__.py` | — | package marker |
| `pirtm/scheduler/concurrent_runner.py` | `mlir/main/agents.mlir` (dispatch + deterministic merge) | thread pool becomes a sequential run in sorted order (GAPS) |
| `pirtm/scheduler/__init__.py` | — | package marker |
| `pirtm/__init__.py` | — | package marker |
| `experiments/run_adversarial_experiment.py` | `mlir/main/hilbert11.mlir`; Quipper `adversarial`; `Data/Experiments.lean` | its output is kept as `logs/reference/python-experiment.txt` |
| `tests/test_hilbert11.py` | `mlir/main/hilbert11.mlir`, Quipper `roundtrip`, `Data/Experiments.lean` (`roundtrip7_*`) | |
| `tests/test_quantum.py` | `mlir/main/quantum.mlir`, Quipper `bell`/`classical`, `Data/Experiments.lean` (`bell_*`, `classical_baseline`) | |
| `tests/test_oracle.py` | `mlir/main/oracle.mlir` | |
| `tests/test_recursive_engine.py` | `mlir/main/engine.mlir` | |
| `tests/test_agents.py` | `mlir/main/agents.mlir`, `Data/Agents.lean` | unittest output is kept as `logs/reference/python-unittest.txt` |
| `PIRTM.lean`, `PIRTM/Core.lean`, `PIRTM/Invariants.lean`, `PIRTM/Quantum11.lean` | same paths | copied; new header; one unsupported "verified" claim removed |
| `lakefile.lean`, `lean-toolchain`, `lake-manifest.json` | `lakefile.lean`, `lean-toolchain`, `lake-manifest.json` | merged into one package; the toolchain is still v4.34.1 |
| `agda/PIRTM/Core.agda` | `PirtmHcalc/Agda/Core.lean` | |
| `agda/PIRTM/Assumptions.agda` | `PirtmHcalc/Agda/Assumptions.lean` | |
| `agda/PIRTM/Invariants.agda` | `PirtmHcalc/Agda/Invariants.lean` | I05 termination now takes an explicit fixpoint hypothesis (GAPS) |
| `agda/README.md` | — | its instructions applied only to Agda |
| `alloy/hcalc-mirror.als` | `PirtmHcalc/Alloy/HcalcMirror.lean` | |
| `alloy/vacuity-demo.als` | `PirtmHcalc/Alloy/VacuityDemo.lean` | |
| `alloy.jar` | — | binary Alloy analyzer, not needed after the port to Lean |
| `hcalc-mirror/receipt.json`, `vacuity-demo/receipt.json`, `verification_manifest.json` | — | run receipts of the old pipeline; the new runs log to `logs/` |
| `paper/counter-paper.md` | `PirtmHcalc/Alloy/*.lean` (vacuity theorems) | its argument is now stated as theorems |
| `docs/SCIENTIFIC_DETERMINATION.md` | `README.md` (what is checked), `GAPS.md` | |
| `docs/architecture.svg`, `docs/quantum_experiment.svg` | — | images |
| `README.md`, `AGENTS.md` | `README.md` | rewritten |
| `LICENSE` | `LICENSE` | copied |
| `.gitignore` | `.gitignore` | rewritten |

## HCALC@4854e7b

| Source file | Port | Notes |
|---|---|---|
| `lean/Hcalc.lean`, `lean/Hcalc/{Axioms,Carrier,Convergence,Foundry,Invariants,Pipeline,Production,RealStub}.lean` | `Hcalc.lean`, `Hcalc/*.lean` | copied with a new header. `native_decide` in `Foundry.lean` was replaced by `decide +kernel`, so no native-code axioms remain. False "Mathlib ℝ" claims in comments were corrected. The Spec GapId axioms were kept (listed in GAPS.md). |
| `lean/lakefile.toml`, `lean/lean-toolchain`, `lean/lake-manifest.json` | `lakefile.lean`, `lean-toolchain` | merged |
| `lean/build.log` | `logs/lean/build.log` | regenerated |
| `lean/README.md`, `lean/LICENSE`, `lean/.gitignore` | `README.md`, `LICENSE`, `.gitignore` | merged |
| `j/hcalc.ijs` | `j/hcalc.ijs` | loads `j/cite.ijs`, a local rewrite of the spectral helpers it used to load from a sibling repo; locale `_foundry_` became `_cite_` |
| `j/README.md` | `README.md` | merged |
| — | `j/cite.ijs`, `j/goldilocks.ijs`, `j/demo.ijs` | new: written here (P64, Gershgorin, power iteration, spectral analysis; the Goldilocks field; the demo) |
| `verify/run.ijs`, `verify/harness.ijs`, `verify/core_load.ijs`, `verify/tests/props.ijs` | same paths | paths are now relative to the project root; the Alloy probe reads `PirtmHcalc/Alloy/Hcalc.lean` |
| `verify/run.sh` | `lakefile.lean` script `j` | the run/log logic moved into Lake |
| `verify/logs/run-*.log` | `logs/j/verify.out` | regenerated |
| `verify/README.md`, `verify/PROPERTY_MAP.md`, `verify/LICENSE` | `README.md`, `verify/tests/props.ijs` (the property ids), `LICENSE` | |
| `alloy/HCALC.als`, `alloy/modules/{State,PrimeIndex,Transform,Recursion,Stabilize,Contract,Evolve,Optimize,Converge}.als` | `PirtmHcalc/Alloy/Hcalc.lean` | every fact, assert, check and run is ported |
| `alloy/expectations.tsv` | `PirtmHcalc/Alloy/Hcalc.lean` | "expect 0" checks became `check_*` theorems; "expect 1" runs became `run_*` theorems |
| `alloy/check.sh`, `alloy/run.sh`, `alloy/run-production.sh` | `lake build` | the Alloy runs are now Lean theorems |
| `alloy/logs/*.txt` | — | old Alloy analyzer and Java logs |
| `alloy/README.md`, `alloy/INVARIANTS.md` | `PirtmHcalc/Alloy/Hcalc.lean` (docstrings) | |
| `spec/PRODUCTION.md` | `spec/PRODUCTION.md` | the definitions; ownership/status lines removed |
| `spec/AXIOMS.md` | `GAPS.md` (axiom list) | |
| `spec/PROPERTIES.md`, `spec/INTERFACES.md`, `spec/COHERENCE.md`, `spec/FOUNDRY_J_CROSSLINKS.md`, `spec/FOUNDRY_J_PRODUCTION_REVIEW.md`, `spec/HANDOFF_PRODUCTION.md` | — | dropped: process notes and cross-repo references (GAPS) |
| `docs/INVARIANTS.md`, `docs/REMAINING.md`, `docs/.gitkeep` | `GAPS.md` | |
| `README.md` | `README.md` | rewritten |
| `LICENSE` | `LICENSE` | |
| `.gitignore` | `.gitignore` | |

## New in this project

| File | Purpose |
|---|---|
| `mlir/dialects/{pirtm,hcalc}.irdl.mlir` | custom dialects (IRDL) |
| `mlir/custom/*.mlir`, `mlir/custom/invalid/*.mlir` | programs written with the custom dialects, plus the negative tests |
| `mlir/lib/{io,jfmt}.mlir` | printing: `%.17g` plus IEEE bits, Python `repr` style, and J display |
| `mlir/lib/goldilocks.mlir`, `mlir/lib/hcalc.mlir`, `mlir/main/{hcalc,goldilocks}.mlir` | MLIR ports of the J core |
| `quipper/` | Quipper circuits |
| `PirtmHcalc/Quantum/Exact.lean`, `PirtmHcalc/Data/*.lean` | exact semantics and the data theorems |
| `tools/AxiomAudit.lean` | axiom listing (Lean) |
| `logs/reference/*` | reference output of the original Python, captured outside the project from PIRTM@e9caa0d |
