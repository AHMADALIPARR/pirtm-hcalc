-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
/-!
# Alloy port: hcalc-mirror.als (Exhibit B)

Structural mirror of two HCALC checks (A7 and P2) plus the "non-vacuous"
generator example. Names follow the Alloy file.
-/

namespace PirtmHcalc.Alloy.HcalcMirror

/-! ## Mirror of HCALC A7 -/

/-- `abstract sig DefStatus {}  one sig SpecDefined extends DefStatus {}`:
the mirror declares only one status atom. -/
inductive DefStatus where
  | SpecDefined
  deriving DecidableEq, Repr

/-- `one sig GapRecord_Tp { status: one DefStatus }` -/
structure A7Model where
  GapRecord_Tp_status : DefStatus

def hcalc_A7_fact (m : A7Model) : Prop := m.GapRecord_Tp_status = DefStatus.SpecDefined
def hcalc_A7_assert (m : A7Model) : Prop := m.GapRecord_Tp_status = DefStatus.SpecDefined

theorem check_hcalc_A7_assert : ∀ m, hcalc_A7_fact m → hcalc_A7_assert m := fun _ h => h

/-- Faithful-port finding: because the mirror's `DefStatus` has a single atom,
the A7 assertion holds in every instance even without the fact. -/
theorem hcalc_A7_assert_without_fact : ∀ m, hcalc_A7_assert m := by
  intro m
  cases h : m.GapRecord_Tp_status
  exact h

/-! ## Mirror of HCALC P2 -/

inductive AlphaLawKind where
  | SpecAlphaLaw
  deriving DecidableEq, Repr

/-- `sig TpMap { isDiagonal: Int, alphaLaw: one AlphaLawKind }`; an instance is a
finite list of TpMap atoms. -/
structure TpMap where
  isDiagonal : Int
  alphaLaw : AlphaLawKind
  deriving DecidableEq, Repr

def hcalc_P2_fact (ts : List TpMap) : Prop :=
  ∀ tp ∈ ts, tp.isDiagonal = 1 ∧ tp.alphaLaw = AlphaLawKind.SpecAlphaLaw
def hcalc_P2_assert (ts : List TpMap) : Prop :=
  ∀ tp ∈ ts, tp.isDiagonal = 1 ∧ tp.alphaLaw = AlphaLawKind.SpecAlphaLaw

theorem check_hcalc_P2_assert : ∀ ts, hcalc_P2_fact ts → hcalc_P2_assert ts := fun _ h => h
theorem hcalc_P2_assert_iff_fact (ts : List TpMap) : hcalc_P2_assert ts ↔ hcalc_P2_fact ts :=
  Iff.rfl

/-- Without the fact the assertion is refutable (one TpMap with isDiagonal = 0). -/
theorem hcalc_P2_countermodel : ∃ ts, ¬ hcalc_P2_assert ts :=
  ⟨[⟨0, AlphaLawKind.SpecAlphaLaw⟩], by simp [hcalc_P2_assert]⟩

/-! ## What a non-vacuous check looks like -/

/-- `sig Cell { w: Int }` -/
structure Cell where
  w : Int
  deriving DecidableEq, Repr

/-- `fact generator { all c: Cell | c.w = 2 }` generalised to any generator value. -/
def generator (k : Int) (cs : List Cell) : Prop := ∀ c ∈ cs, c.w = k
/-- `assert weights_positive { all c: Cell | c.w > 0 }` -/
def weights_positive (cs : List Cell) : Prop := ∀ c ∈ cs, c.w > 0

/-- `check weights_positive` with the generator `c.w = 2`: it follows. -/
theorem check_weights_positive : ∀ cs, generator 2 cs → weights_positive cs := by
  intro cs h c hc
  rw [h c hc]
  decide

/-- Falsifiability: with the generator `c.w = -5` the same check has a
counterexample. -/
theorem weights_positive_falsifiable :
    ∃ cs, generator (-5) cs ∧ ¬ weights_positive cs :=
  ⟨[⟨-5⟩], by simp [generator], by simp [weights_positive]⟩

end PirtmHcalc.Alloy.HcalcMirror
