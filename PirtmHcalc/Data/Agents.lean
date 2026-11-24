-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
/-!
# Scheduler / worker results as theorems

Values from one `dispatch_cycle(round=1)` (logs/mlir/agents.log, identical to
logs/reference/python-ref-dump.txt): per-agent test counts, the merged totals,
the A06 lexical statistics, and the sorted invariant set.
-/

namespace PirtmHcalc.Data.Agents

/-- (agent, block, passed, failed, not_run) as logged. -/
def reports : List (String × Nat × Nat × Nat × Nat) :=
  [("A01", 1, 3, 0, 0), ("A02", 1, 2, 0, 0), ("A03", 1, 1, 0, 0), ("A04", 4, 2, 0, 0),
   ("A05", 5, 2, 0, 0), ("A06", 6, 1, 0, 0), ("A07", 5, 1, 0, 0), ("A08", 6, 1, 0, 0),
   ("A09", 1, 2, 0, 0), ("A10", 2, 0, 0, 11), ("A11", 1, 2, 0, 0)]

theorem totals :
    reports.length = 11 ∧ (reports.map (·.2.2.1)).sum = 17 ∧ (reports.map (·.2.2.2.1)).sum = 0 ∧
    (reports.map (·.2.2.2.2)).sum = 11 := by decide

def quatrain : String :=
  "Quand le fourchu sera soustenus de deux paux, avec six demy cors, & six cizeaux ouvers..."

/-- `str.split()` on single-space text: maximal runs of non-space characters. -/
def splitSpaces : List Char → List (List Char)
  | [] => []
  | c :: cs =>
    match splitSpaces cs with
    | [] => if c = ' ' then [] else [[c]]
    | w :: ws => if c = ' ' then (if w = [] then w :: ws else [] :: w :: ws) else (c :: w) :: ws

def tokens : List (List Char) :=
  (splitSpaces (quatrain.toList.map Char.toLower)).filter (· ≠ [])

/-- A06: 16 tokens, 15 distinct (`six` repeats), ratio 15/16 = 0.9375 exactly. -/
theorem A06_lexical :
    tokens.length = 16 ∧ tokens.eraseDups.length = 15 ∧ 15 * 10000 = 9375 * 16 := by decide +kernel

/-- invariants asserted by the 11 workers, in worker order (with repeats). -/
def asserted : List String :=
  ["I02 — Causal ordering", "I01 — State preservation", "I06 — Quantum unitarity",
   "I01 — State preservation", "I07 — Probability normalization", "I08 — Encoding integrity",
   "I11 — Evidence classification", "I05 — Termination", "I09 — Observation boundaries",
   "I08 — Encoding integrity",
   "I01", "I02", "I03", "I04", "I05", "I06", "I07", "I08", "I09", "I10", "I11",
   "I09 — Observation boundaries", "I11 — Evidence classification"]

/-- `invariants_asserted` as logged by mlir/main/agents.mlir and the Python reference. -/
def loggedSorted : List String :=
  ["I01", "I01 — State preservation", "I02", "I02 — Causal ordering", "I03", "I04", "I05",
   "I05 — Termination", "I06", "I06 — Quantum unitarity", "I07", "I07 — Probability normalization",
   "I08", "I08 — Encoding integrity", "I09", "I09 — Observation boundaries", "I10", "I11",
   "I11 — Evidence classification"]

/-- The logged list is exactly `sorted(set(asserted))`. -/
theorem invariants_sorted_set :
    loggedSorted.length = 19 ∧
    (asserted.all (· ∈ loggedSorted)) = true ∧ (loggedSorted.all (· ∈ asserted)) = true ∧
    loggedSorted.eraseDups = loggedSorted ∧
    (loggedSorted.zip loggedSorted.tail).all (fun p => decide (p.1 < p.2)) = true := by decide

end PirtmHcalc.Data.Agents
