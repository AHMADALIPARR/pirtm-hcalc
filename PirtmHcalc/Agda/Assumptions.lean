-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
import PirtmHcalc.Agda.Core
/-!
# Agda port: PIRTM.Assumptions

Lean port of `agda/PIRTM/Assumptions.agda`: isolated idealised assumptions,
kept as structures (no axioms). A proof about one of these toy models is not
experimental confirmation of a physical theory.
-/

namespace PirtmHcalc.Agda

/-- `record ComplexInnerSpace` (discrete ℕ proxy inner product).
The Agda field `positiveDefinite` concludes `v ≡ v`, which is trivially true;
it is ported unchanged, so it constrains nothing. -/
structure ComplexInnerSpace where
  Carrier : Type
  inner : Carrier → Carrier → Nat
  positiveDefinite : ∀ v : Carrier, inner v v = 0 → v = v

/-- `record HolographicBoundAssumption`. -/
structure HolographicBoundAssumption where
  BulkDimension : Nat
  BoundaryDimension : Nat
  boundDimensionLe : Lt BoundaryDimension (BulkDimension + 1)

/-- The Agda `positiveDefinite` field is vacuous: any carrier and inner product
satisfy it. -/
def ComplexInnerSpace.ofAny (C : Type) (f : C → C → Nat) : ComplexInnerSpace :=
  ⟨C, f, fun _ _ => rfl⟩

end PirtmHcalc.Agda
