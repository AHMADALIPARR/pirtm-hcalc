-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
/-!
# Alloy port: vacuity-demo.als (Exhibit A)

`one sig Moon { madeOfCheese: Int }` — a model is just the value of the field.
The Alloy file installs the (false) claim as a fact and then "checks" the
identical formula as an assertion; the check is UNSAT ("PASS") because the
assertion is the fact. In Lean the same observation is a one-line proof, and
the control experiment (drop the fact) is an explicit countermodel.
-/

namespace PirtmHcalc.Alloy.VacuityDemo

/-- An Alloy instance: the single `Moon` atom's `madeOfCheese` value. -/
structure Moon where
  madeOfCheese : Int
  deriving DecidableEq, Repr

/-- `fact claim_as_fact { Moon.madeOfCheese = 1 }` -/
def claim_as_fact (m : Moon) : Prop := m.madeOfCheese = 1

/-- `assert MoonIsCheese { Moon.madeOfCheese = 1 }` -/
def MoonIsCheese (m : Moon) : Prop := m.madeOfCheese = 1

/-- `check MoonIsCheese` under the fact: no counterexample exists, for every
instance (not only scope 3). The proof is the identity function, which is the
whole content of the "PASS". -/
theorem check_MoonIsCheese : ∀ m : Moon, claim_as_fact m → MoonIsCheese m :=
  fun _ h => h

/-- The assertion is literally the fact. -/
theorem MoonIsCheese_iff_fact (m : Moon) : MoonIsCheese m ↔ claim_as_fact m := Iff.rfl

/-- Control experiment: without the fact the same assertion has a
counterexample (`madeOfCheese = 0`). -/
theorem control_countermodel : ∃ m : Moon, ¬ MoonIsCheese m :=
  ⟨⟨0⟩, by simp [MoonIsCheese]⟩

/-- So the "verification" separates nothing: whatever value the fact installs,
the matching assertion "passes". -/
theorem any_claim_passes (v : Int) :
    ∀ m : Moon, m.madeOfCheese = v → m.madeOfCheese = v := fun _ h => h

end PirtmHcalc.Alloy.VacuityDemo
