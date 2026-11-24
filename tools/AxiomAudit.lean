-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
import PirtmHcalc
import Lean
/-!
Axiom audit (run by `lake script run axioms`). For every declaration in the
project's modules it prints
* every `axiom` declared in the project, and
* the axioms each theorem depends on, grouped by axiom set.
-/
open Lean Elab Command

def projectModule (m : Name) : Bool :=
  let r := m.getRoot
  r == `PIRTM || r == `Hcalc || r == `PirtmHcalc

#eval show CommandElabM Unit from do
  let env ← getEnv
  let mut declared : Array Name := #[]
  let mut thms : Array Name := #[]
  for (n, ci) in env.constants.toList do
    let some idx := env.getModuleIdxFor? n | continue
    let mod := env.header.moduleNames[idx.toNat]!
    unless projectModule mod do continue
    if n.isInternal then continue
    match ci with
    | .axiomInfo _ => declared := declared.push n
    | .thmInfo _ => thms := thms.push n
    | _ => pure ()
  let declaredS := declared.qsort (·.toString < ·.toString)
  IO.println s!"declared axioms in project modules: {declaredS.size}"
  for a in declaredS do IO.println s!"  axiom {a}"
  let thmsS := thms.qsort (·.toString < ·.toString)
  let mut groups : Std.HashMap String (Array Name) := {}
  for t in thmsS do
    let axs ← liftCoreM (collectAxioms t)
    let key := toString ((axs.map toString).qsort (· < ·)).toList
    groups := groups.insert key ((groups.getD key #[]).push t)
  IO.println s!"theorems: {thmsS.size}"
  let keys := (groups.toArray.map (·.1)).qsort (· < ·)
  for k in keys do
    let ts := groups.getD k #[]
    IO.println s!"axioms {k}: {ts.size} theorems"
    for t in ts do IO.println s!"    {t}"
