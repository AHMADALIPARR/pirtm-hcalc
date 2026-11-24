-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
/-!
# Goldilocks field results as theorems

p = 2^64 − 2^32 + 1. The values are the ones printed by `j/demo.ijs` and
`mlir/main/goldilocks.mlir` (logs/j/demo.log, logs/mlir/goldilocks.log); here
they are recomputed with Lean `Nat` arithmetic and checked by `decide`.
-/

namespace PirtmHcalc.Data.Goldilocks

def p : Nat := 18446744069414584321

theorem p_def : p = 2 ^ 64 - 2 ^ 32 + 1 := by decide

/-- The fold identities behind `gl_mul`: 2^64 ≡ 2^32 − 1 and 2^96 ≡ −1 (mod p). -/
theorem fold_identities : 2 ^ 64 % p = 2 ^ 32 - 1 ∧ 2 ^ 96 % p = p - 1 := by decide

/-- `gl_mul` as in mlir/lib/goldilocks.mlir and j/goldilocks.ijs. -/
def foldMul (a b : Nat) : Nat :=
  let t := a * b
  let lo := t % 2 ^ 64
  let hi := t / 2 ^ 64
  let hl := hi % 2 ^ 32
  let hh := hi / 2 ^ 32
  let f := lo + hl * (2 ^ 32 - 1)
  let r := if f ≥ hh then f - hh else f + p - hh
  r % p

/-- square-and-multiply with an explicit bound on the number of rounds -/
def powMod : Nat → Nat → Nat → Nat
  | 0, _, _ => 1
  | fuel + 1, b, e =>
    if e = 0 then 1
    else
      let r := powMod fuel (foldMul b b) (e / 2)
      if e % 2 = 1 then foldMul b r else r

def a : Nat := 12345678901234567890
def b : Nat := 9876543210987654321

theorem logged_add : (a + b) % p = 3775478042807637890 := by decide
theorem logged_sub : (a + p - b) % p = 2469135690246913569 := by decide
theorem logged_sub_rev : (b + p - a) % p = 15977608379167670752 := by decide
theorem logged_mul : a * b % p = 7432351747408847865 ∧ foldMul a b = 7432351747408847865 := by decide
theorem logged_mul_pm1_sq : foldMul (p - 1) (p - 1) = 1 := by decide
theorem logged_pow_7_100 : 7 ^ 100 % p = 2335214203647002900 ∧ powMod 128 7 100 = 2335214203647002900 := by
  decide +kernel
theorem logged_inv_a : a * 16343323056350712102 % p = 1 := by decide
theorem logged_inv_is_fermat : powMod 128 a (p - 2) = 16343323056350712102 := by decide +kernel
theorem logged_fermat_a : powMod 128 a (p - 1) = 1 := by decide +kernel

/-- `fold_vs_ref_200`: on the deterministic sample s_i = 6364136223846793005·(i+1) mod p
the fold agrees with (a·b) mod p for every pair (s_i, s_{199−i}). -/
theorem fold_vs_ref_200 :
    (List.range 200).all (fun i =>
      let x := 6364136223846793005 * (i + 1) % p
      let y := 6364136223846793005 * (200 - i) % p
      foldMul x y == x * y % p) = true := by decide

end PirtmHcalc.Data.Goldilocks
