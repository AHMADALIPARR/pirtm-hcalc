-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
/-!
# Agda port: PIRTM.Core

Lean port of `agda/PIRTM/Core.agda`. Agda's hand-rolled `≡`, `⊥`, `⊤`, `⊎`,
`×`, `ℕ`, `Bool`, `List`, `Dec` map to Lean's `Eq`, `False`, `True`, `Sum`,
`Prod`, `Nat`, `Bool`, `List`, `Decidable`. The strict order `_<_` is kept as
its own inductive (constructors `z<s`, `s<s`) so the I02 proofs follow the
Agda proofs constructor for constructor.
-/

namespace PirtmHcalc.Agda

/-- Agda `data _<_ : ℕ → ℕ → Set`. -/
inductive Lt : Nat → Nat → Prop
  | zs {n : Nat} : Lt 0 (n + 1)
  | ss {m n : Nat} : Lt m n → Lt (m + 1) (n + 1)

/-- `<-irrefl`. -/
theorem lt_irrefl : ∀ n : Nat, ¬ Lt n n
  | 0, h => nomatch h
  | n + 1, Lt.ss p => lt_irrefl n p

/-- `<-trans`. -/
theorem lt_trans : ∀ {i j k : Nat}, Lt i j → Lt j k → Lt i k
  | _, _, _, Lt.zs, Lt.ss _ => Lt.zs
  | _, _, _, Lt.ss p, Lt.ss q => Lt.ss (lt_trans p q)

/-- `Lt` agrees with Lean's `<` on `Nat` (not in the Agda source; links the
port to the standard order). -/
theorem lt_iff (m n : Nat) : Lt m n ↔ m < n := by
  constructor
  · intro h
    induction h with
    | zs => exact Nat.succ_pos _
    | ss _ ih => exact Nat.succ_lt_succ ih
  · intro h
    induction m generalizing n with
    | zero =>
      cases n with
      | zero => exact absurd h (Nat.lt_irrefl 0)
      | succ n => exact Lt.zs
    | succ m ih =>
      cases n with
      | zero => exact absurd h (Nat.not_lt_zero _)
      | succ n => exact Lt.ss (ih n (Nat.lt_of_succ_lt_succ h))

end PirtmHcalc.Agda
