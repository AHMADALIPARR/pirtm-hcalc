-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
/-!
# Alloy port: HCALC.als + modules/*.als

The HCALC Alloy model (top level `HCALC.als` and the nine modules State,
PrimeIndex, Transform, Recursion, Stabilize, Contract, Evolve, Optimize,
Converge) as a Lean relational model.

Encoding:
* every `sig S` becomes a carrier `Fin nS` (size is part of the instance);
* `one sig` becomes a single field; `one`/`lone`/`set` fields become a function,
  an `Option`-valued function, and a `Bool`-valued predicate;
* abstract signatures whose only atoms are `one sig` extensions become Lean
  enumerations;
* every `fact` is a field of `Facts`; every `assert` is a `Prop`;
* each Alloy `check A ... expect 0` becomes `theorem check_A : Facts M → A M`
  for **every** finite instance (Alloy only searched a bounded scope);
* each `run P ... expect 1` becomes `theorem run_P : ∃ M, Facts M ∧ P M` with a
  concrete instance.

Vacuity finding (faithful to the PIRTM counter-paper): every check is implied
directly by a fact. Most assertions are literally a fact (`Iff.rfl`); the rest
(A1, A1b, A4, A7, INV_recursion_uses_prime_index, INV_evolve_total_State_reachable)
are a projection or a case split of facts. No check derives anything from
modelled mathematics — the model carries Int/enum flags, not primes, logs or
norms. The numbers live in `PirtmHcalc.Data.*` instead.

The original A7 fact for reference (the J verify probe reads this file):

    fact A7_production_all_spec_defined {
      GapRecord_LambdaM.status = SpecDefined
      GapRecord_HCALC_Xi.status = SpecDefined
      GapRecord_C.status = SpecDefined
      GapRecord_Tp.status = SpecDefined
      GapRecord_Carrier.status = SpecDefined
      GapRecord_ShapeMap.status = SpecDefined
      GapRecord_ContractAlg.status = SpecDefined
      GapRecord_Converge.status = SpecDefined
      GapRecord_OptObj.status = SpecDefined
    }
-/

namespace PirtmHcalc.Alloy.Hcalc

/-! ## Enumerations (abstract sigs with `one sig` atoms) -/

inductive DefStatus | Undefined | SpecDefined deriving DecidableEq, Repr
inductive InstanceKind | FoundryInstance | HCALCInstance deriving DecidableEq, Repr
inductive NormKind | LInf deriving DecidableEq, Repr
inductive AlphaLawKind | SpecAlphaLaw deriving DecidableEq, Repr
inductive EpsilonTier | T1 | T2 | T3 | T4 deriving DecidableEq, Repr
inductive CMode | ScaleOrId deriving DecidableEq, Repr
inductive ContractAlgKind | GershgorinThenScaleOrId deriving DecidableEq, Repr
inductive XiScheduleKind | UniformXi deriving DecidableEq, Repr
inductive BridgeMode | InstanceBridge | NestedFaithful | FoundryAdditive deriving DecidableEq, Repr
inductive ObjKind | ResidualObj deriving DecidableEq, Repr
inductive GuardianVerdict | Accept | Reject deriving DecidableEq, Repr
/-- The nine `one sig GapRecord_*` of HCALC.als. -/
inductive GapId
  | LambdaM | HCALC_Xi | C | Tp | Carrier | ShapeMap | ContractAlg | Converge | OptObj
  deriving DecidableEq, Repr

def allTiers : List EpsilonTier := [.T1, .T2, .T3, .T4]
def allGaps : List GapId :=
  [.LambdaM, .HCALC_Xi, .C, .Tp, .Carrier, .ShapeMap, .ContractAlg, .Converge, .OptObj]

/-! ## Instances -/

structure Model where
  -- modules/State
  nState : Nat
  nTime : Nat
  nMeasure : Nat
  nStateMeasure : Nat
  next : Fin nTime → Option (Fin nTime)
  atState : Fin nTime → Fin nState
  activeKind : InstanceKind
  carrierDimPositive : Int
  carrierNorm : NormKind
  smOf : Fin nStateMeasure → Fin nState
  smM : Fin nStateMeasure → Fin nMeasure
  -- modules/PrimeIndex
  nPrime : Nat
  idx : Fin nPrime → Int
  primes : Fin nPrime → Bool
  declaredCard : Int
  nExt : Nat
  extra : Fin nExt → Fin nPrime → Bool
  -- modules/Transform
  nMM : Nat
  nTS : Nat
  nTp : Nat
  encodes : Fin nMM → Fin nState
  support : Fin nTS → Fin nState → Bool
  tpIndex : Fin nTp → Fin nPrime
  tpApply : Fin nTp → Fin nState → Option (Fin nState)
  tpIsDiagonal : Fin nTp → Int
  tpAlphaLaw : Fin nTp → AlphaLawKind
  -- modules/Stabilize
  nScalar : Nat
  nSV : Nat
  nStab : Nat
  lamScalar : Fin nScalar
  lamNonNeg : Int
  lamOpBoundOK : Int
  svW0 : Fin nSV → Option (Fin nScalar)
  svW1 : Fin nSV → Option (Fin nScalar)
  stabSource : Fin nStab → Fin nState
  stabVia : Fin nStab → Option (Fin nScalar)
  -- modules/Contract
  nJac : Nat
  nSB : Nat
  nQB : Nat
  nSP : Nat
  nCOp : Nat
  nCL : Nat
  nPMAT : Nat
  sbOf : Fin nSB → Fin nJac
  sbBelow : Fin nSB → Option EpsilonTier
  sbPower : Fin nSB → Option EpsilonTier
  qbQ : Fin nQB → Int
  qbTier : Fin nQB → EpsilonTier
  qbOver : Fin nQB → Int
  spBudget : Fin nSP → Fin nQB
  spApplied : Fin nSP → Int
  cMode : Fin nCOp → CMode
  cApply : Fin nCOp → Fin nState → Option (Fin nState)
  contractAlgKind : ContractAlgKind
  nonIncrease : Fin nMeasure → Fin nMeasure → Bool
  clPre : Fin nCL → Fin nState
  clPost : Fin nCL → Fin nState
  pmatConserved : Fin nPMAT → Int
  -- modules/Evolve
  xiKind : XiScheduleKind
  xiIsOne : Int
  nKick : Nat
  nInt : Nat
  nXi : Nat
  nFXi : Nat
  nFLam : Nat
  nFT : Nat
  nFG : Nat
  kickTarget : Fin nKick → Option (Fin nState)
  intFrom : Fin nInt → Fin nState
  intTp : Fin nInt → Option (Fin nTp)
  intC : Fin nInt → Option (Fin nCOp)
  intLam : Fin nInt → Option (Fin nScalar)
  xiAt : Fin nXi → Fin nTime
  xiMap : Fin nXi → Fin nInt → Option (Fin nState)
  xiAffine : Fin nXi → Int
  xiSched : Fin nXi → XiScheduleKind
  fxiSched : Fin nFXi → Fin nSV
  flamSched : Fin nFLam → Fin nSV
  ftApply : Fin nFT → Fin nState → Option (Fin nState)
  fgKick : Fin nFG → Option (Fin nState)
  ibT : Int
  ibLam : Int
  ibXi : Int
  ibG : Int
  ibClaimsIdentity : Int
  bridgeMode : BridgeMode
  -- modules/Optimize
  nObj : Nat
  objKind : Fin nObj → ObjKind
  objScore : Fin nObj → Fin nState → Option Int
  -- modules/Converge
  nRes : Nat
  nHyp : Nat
  nG : Nat
  resOf : Fin nRes → Fin nState
  resBelow : Fin nRes → Int
  hypDischarged : Fin nHyp → Option Int
  hypHolds : Fin nHyp → Int
  gSubject : Fin nG → Fin nState
  gSR : Fin nG → Int
  gNF : Fin nG → Int
  gVerdict : Fin nG → GuardianVerdict
  -- HCALC.als
  gap : GapId → DefStatus

variable (M : Model)

/-- `t2 in t1.^next`: t2 is reached from t1 by k ≥ 1 `next` steps (k ≤ nTime). -/
def iterNext : Nat → Fin M.nTime → Option (Fin M.nTime)
  | 0, t => some t
  | k + 1, t => match M.next t with
    | none => none
    | some u => iterNext k u

abbrev reaches (t1 t2 : Fin M.nTime) : Prop :=
  ∃ k : Fin M.nTime, iterNext M (k.val + 1) t1 = some t2

/-! ## Facts (every `fact` of HCALC.als and the modules) -/

-- State
abbrev INV_time_linear_chain : Prop :=
  ((List.finRange M.nTime).countP (fun t => !(List.finRange M.nTime).any (fun u => M.next u == some t))) = 1 ∧
  (∀ t1 t2 : Fin M.nTime, t1 ≠ t2 → reaches M t2 t1 ∨ reaches M t1 t2)
abbrev fact_evolution_total_on_State : Prop := ∀ s : Fin M.nState, ∃ t : Fin M.nTime, M.atState t = s
abbrev fact_P1_carrier_production : Prop := M.carrierDimPositive = 1 ∧ M.carrierNorm = .LInf
abbrev INV_state_measure_functional : Prop :=
  ∀ s : Fin M.nState, ∀ a b : Fin M.nStateMeasure, M.smOf a = s → M.smOf b = s → a = b
-- PrimeIndex
abbrev A1_declared_cardinality_64 : Prop := M.declaredCard = 64
abbrev A1_index_integrity : Prop :=
  (∀ p : Fin M.nPrime, M.primes p = true → M.idx p ≥ 0 ∧ M.idx p ≤ 63) ∧
  (∀ p1 p2 : Fin M.nPrime, p1 ≠ p2 → M.primes p1 = true → M.primes p2 = true → M.idx p1 ≠ M.idx p2)
abbrev fact_primes_subset_carrier : Prop := ∀ p : Fin M.nPrime, M.primes p = true
abbrev INV_extension_disjoint_or_empty : Prop :=
  ∀ e : Fin M.nExt,
    (∀ p, M.extra e p = true → M.primes p = true) ∨
    (∀ p, ¬ (M.extra e p = true ∧ M.primes p = true))
-- Transform
abbrev fact_P2_tp_diag_spec_alpha : Prop :=
  ∀ tp : Fin M.nTp, M.tpIsDiagonal tp = 1 ∧ M.tpAlphaLaw tp = .SpecAlphaLaw
abbrev INV_Tp_index_in_P64_or_extension : Prop :=
  ∀ tp : Fin M.nTp, M.primes (M.tpIndex tp) = true ∨ ∃ e : Fin M.nExt, M.extra e (M.tpIndex tp) = true
abbrev INV_Tp_unique_per_index : Prop := ∀ a b : Fin M.nTp, a ≠ b → M.tpIndex a ≠ M.tpIndex b
abbrev multimodal_wired : Prop := ∀ m : Fin M.nMM, ∃ ts : Fin M.nTS, M.support ts (M.encodes m) = true
abbrev fact_multimodal_wired : Prop := multimodal_wired M
-- Recursion: `all t: Time | lone t.next` (also structural: `next` is Option-valued)
abbrev INV_bounded_recursion_depth : Prop :=
  ∀ t : Fin M.nTime, ∀ u v, M.next t = some u → M.next t = some v → u = v
-- Stabilize
abbrev LambdaM_is_scalar_not_schedule : Prop :=
  ¬ ∃ sv : Fin M.nSV, M.svW0 sv = some M.lamScalar ∧ M.svW1 sv = some M.lamScalar
abbrev fact_LambdaM_not_schedule_vector : Prop := LambdaM_is_scalar_not_schedule M
abbrev INV_LambdaM_scalar_not_schedule : Prop := LambdaM_is_scalar_not_schedule M
abbrev fact_P4_lambda_m_scalar_bound : Prop := M.lamNonNeg = 1 ∧ M.lamOpBoundOK = 1
abbrev INV_stabilize_uses_LambdaM_scalar : Prop :=
  ∀ st : Fin M.nStab, M.stabVia st = none ∨ M.stabVia st = some M.lamScalar
-- Contract
abbrev contractive (j : Fin M.nJac) (e : EpsilonTier) : Prop :=
  ∃ sb : Fin M.nSB, M.sbOf sb = j ∧ (M.sbBelow sb = some e ∨ M.sbPower sb = some e)
abbrev gershgorin_below (j : Fin M.nJac) (e : EpsilonTier) : Prop :=
  ∃ sb : Fin M.nSB, M.sbOf sb = j ∧ M.sbBelow sb = some e
abbrev A2_formula : Prop :=
  ∀ j : Fin M.nJac, ∀ e ∈ allTiers,
    contractive M j e ↔ (gershgorin_below M j e ∨
      ∃ sb : Fin M.nSB, M.sbOf sb = j ∧ M.sbPower sb = some e)
abbrev fact_A2_contractive_iff : Prop := A2_formula M
abbrev A3_formula : Prop := ∀ sp : Fin M.nSP, M.qbOver (M.spBudget sp) = 1 → M.spApplied sp = 1
abbrev fact_A3_soft_project : Prop := A3_formula M
abbrev c_scale_or_id_ok : Prop := ∀ c : Fin M.nCOp, M.cMode c = .ScaleOrId
abbrev fact_P3_c_scale_or_id : Prop := c_scale_or_id_ok M
/-- `all sp: SoftProject | some sp.budget` is structural (`budget: one QBudget`). -/
abbrev fact_C_not_soft_project_identity : Prop := c_scale_or_id_ok M
abbrev contractalg_gershgorin_then_c_ok : Prop := M.contractAlgKind = .GershgorinThenScaleOrId
abbrev fact_P8_contractalg_gershgorin_then_c : Prop := contractalg_gershgorin_then_c_ok M
abbrev fact_measure_order_reflexive : Prop := ∀ m : Fin M.nMeasure, M.nonIncrease m m = true
abbrev measure_non_increase (s sNext : Fin M.nState) : Prop :=
  ∀ sm smNext : Fin M.nStateMeasure, M.smOf sm = s → M.smOf smNext = sNext →
    M.nonIncrease (M.smM sm) (M.smM smNext) = true
abbrev measure_links : Prop := ∀ cl : Fin M.nCL, measure_non_increase M (M.clPre cl) (M.clPost cl)
abbrev fact_measure_on_contract_links : Prop := measure_links M
abbrev A5_formula : Prop := ∀ p : Fin M.nPMAT, M.pmatConserved p = 1
abbrev fact_A5_pmat_if_used : Prop := A5_formula M
-- Evolve
abbrev xi_uniform_affine_ok : Prop :=
  M.xiKind = .UniformXi ∧ M.xiIsOne = 1 ∧
  ∀ xi : Fin M.nXi, M.xiAffine xi = 1 ∧ M.xiSched xi = .UniformXi
abbrev fact_P5_xi_uniform_affine : Prop := xi_uniform_affine_ok M
abbrev foundry_additive_step (x xNext : Fin M.nState) : Prop :=
  ∃ _xi : Fin M.nFXi, ∃ _lam : Fin M.nFLam, ∃ tn : Fin M.nFT,
    M.ftApply tn x = some xNext ∨ (∃ g : Fin M.nFG, M.fgKick g = some xNext) ∨ xNext = x
abbrev hcalc_nested_step (t : Fin M.nTime) (X XNext : Fin M.nState) : Prop :=
  ∃ xi : Fin M.nXi, ∃ tp : Fin M.nTp, ∃ c : Fin M.nCOp, ∃ mid : Fin M.nInt,
    M.xiAt xi = t ∧ M.xiAffine xi = 1 ∧ M.intFrom mid = X ∧ M.intTp mid = some tp ∧
    M.intC mid = some c ∧ M.intLam mid = some M.lamScalar ∧ M.xiMap xi mid = some XNext
abbrev evolve_next (t : Fin M.nTime) : Prop :=
  ∀ u, M.next t = some u →
    (M.activeKind = .HCALCInstance → hcalc_nested_step M t (M.atState t) (M.atState u)) ∧
    (M.activeKind = .FoundryInstance → foundry_additive_step M (M.atState t) (M.atState u))
abbrev INV_evolve_respects_active_instance : Prop := ∀ t : Fin M.nTime, evolve_next M t
abbrev instance_bridge_morphism_ok : Prop :=
  M.bridgeMode = .InstanceBridge ∧ M.ibT = 1 ∧ M.ibLam = 1 ∧ M.ibXi = 1 ∧ M.ibG = 1 ∧
  M.ibClaimsIdentity = 0
abbrev fact_P6_instance_bridge_morphism : Prop := instance_bridge_morphism_ok M
abbrev bridge_instance_not_identity : Prop := M.bridgeMode = .InstanceBridge ∧ M.ibClaimsIdentity = 0
abbrev fact_bridge_production : Prop := bridge_instance_not_identity M
-- Optimize
abbrev optobj_residual_ok : Prop := ∀ o : Fin M.nObj, M.objKind o = .ResidualObj
abbrev fact_P7_optobj_residual : Prop := optobj_residual_ok M
-- Converge
abbrev convergence_hyps_production : Prop :=
  ∀ h : Fin M.nHyp, M.hypDischarged h = some 1 →
    M.hypHolds h = 1 ∧ ∃ r : Fin M.nRes, M.resBelow r = 1
abbrev fact_converge_hyps : Prop := convergence_hyps_production M
abbrev A6_formula : Prop :=
  ∀ g : Fin M.nG,
    ((M.gSR g = 1 ∨ M.gNF g = 1) → M.gVerdict g = .Reject) ∧
    ((M.gSR g = 0 ∧ M.gNF g = 0) → M.gVerdict g = .Accept)
abbrev fact_A6_guardian : Prop := A6_formula M
-- HCALC.als
abbrev A7_production_all_spec_defined : Prop := ∀ g ∈ allGaps, M.gap g = .SpecDefined

/-- Conjunction of every fact in the composed model. -/
structure Facts : Prop where
  time_linear_chain : INV_time_linear_chain M
  evolution_total : fact_evolution_total_on_State M
  P1 : fact_P1_carrier_production M
  state_measure_functional : INV_state_measure_functional M
  A1_card : A1_declared_cardinality_64 M
  A1_index : A1_index_integrity M
  primes_subset : fact_primes_subset_carrier M
  extension : INV_extension_disjoint_or_empty M
  P2 : fact_P2_tp_diag_spec_alpha M
  tp_index : INV_Tp_index_in_P64_or_extension M
  tp_unique : INV_Tp_unique_per_index M
  multimodal : fact_multimodal_wired M
  recursion_depth : INV_bounded_recursion_depth M
  lam_not_schedule : fact_LambdaM_not_schedule_vector M
  lam_not_schedule' : INV_LambdaM_scalar_not_schedule M
  P4 : fact_P4_lambda_m_scalar_bound M
  stabilize : INV_stabilize_uses_LambdaM_scalar M
  A2 : fact_A2_contractive_iff M
  A3 : fact_A3_soft_project M
  P3 : fact_P3_c_scale_or_id M
  c_not_soft : fact_C_not_soft_project_identity M
  P8 : fact_P8_contractalg_gershgorin_then_c M
  measure_reflexive : fact_measure_order_reflexive M
  measure_links : fact_measure_on_contract_links M
  A5 : fact_A5_pmat_if_used M
  P5 : fact_P5_xi_uniform_affine M
  evolve : INV_evolve_respects_active_instance M
  P6 : fact_P6_instance_bridge_morphism M
  bridge : fact_bridge_production M
  P7 : fact_P7_optobj_residual M
  converge : fact_converge_hyps M
  A6 : fact_A6_guardian M
  A7 : A7_production_all_spec_defined M

/-! ## Assertions (26 checks, all `expect 0`) -/

abbrev prime_index_integrity : Prop :=
  M.declaredCard = 64 ∧
  (∀ p1 p2 : Fin M.nPrime, p1 ≠ p2 → M.primes p1 = true → M.primes p2 = true → M.idx p1 ≠ M.idx p2) ∧
  (∀ p : Fin M.nPrime, M.primes p = true → M.idx p ≥ 0 ∧ M.idx p ≤ 63) ∧
  (∀ p : Fin M.nPrime, M.primes p = true → M.primes p = true)
abbrev A1_P64_cardinality_and_distinct : Prop := prime_index_integrity M
abbrev A1b_P64_distinct_indices : Prop :=
  ∀ p1 p2 : Fin M.nPrime, p1 ≠ p2 → M.primes p1 = true → M.primes p2 = true → M.idx p1 ≠ M.idx p2
abbrev A2_contractive_iff_gershgorin_bound : Prop := A2_formula M
abbrev A3_soft_project_when_q_over_margin : Prop := A3_formula M
abbrev A4_foundry_additive_only_if_Foundry_instance : Prop :=
  (M.activeKind = .FoundryInstance ∨ M.activeKind = .HCALCInstance) ∧
  (M.activeKind = .FoundryInstance → ∀ t u, M.next t = some u →
      foundry_additive_step M (M.atState t) (M.atState u)) ∧
  (M.activeKind = .HCALCInstance → ∀ t u, M.next t = some u →
      hcalc_nested_step M t (M.atState t) (M.atState u))
abbrev A5_PMAT_conservation_gated : Prop := A5_formula M
abbrev A6_guardian_reject_spectral_or_nonfinite : Prop := A6_formula M
/-- `A7_production_defined_records_present`; the `one GapRecord_*` and
`some Undefined`/`some SpecDefined` conjuncts hold structurally. -/
abbrev A7_production_defined_records : Prop :=
  M.gap .LambdaM = .SpecDefined ∧ M.gap .HCALC_Xi = .SpecDefined ∧ M.gap .C = .SpecDefined ∧
  M.gap .Tp = .SpecDefined ∧ M.gap .Carrier = .SpecDefined ∧ M.gap .ShapeMap = .SpecDefined ∧
  M.gap .ContractAlg = .SpecDefined ∧ M.gap .Converge = .SpecDefined ∧ M.gap .OptObj = .SpecDefined
abbrev P1_carrier_linf_dim : Prop := M.carrierDimPositive = 1 ∧ M.carrierNorm = .LInf
abbrev P2_tp_diag_spec_alpha : Prop :=
  ∀ tp : Fin M.nTp, M.tpIsDiagonal tp = 1 ∧ M.tpAlphaLaw tp = .SpecAlphaLaw
abbrev P3_c_scale_or_id : Prop := c_scale_or_id_ok M
abbrev P4_lambda_m_scalar_bound : Prop := M.lamNonNeg = 1 ∧ M.lamOpBoundOK = 1
abbrev P5_xi_uniform_affine : Prop := xi_uniform_affine_ok M
abbrev P6_instance_bridge_morphism : Prop := instance_bridge_morphism_ok M
abbrev P7_optobj_residual : Prop := optobj_residual_ok M
abbrev P8_contractalg_gershgorin_then_c : Prop := contractalg_gershgorin_then_c_ok M
abbrev INV_LambdaM_scalar_placeholder : Prop := LambdaM_is_scalar_not_schedule M
abbrev INV_step_shape_bridge_instance : Prop := bridge_instance_not_identity M
abbrev INV_prime_index_bounded_to_P64 : Prop := ∀ p : Fin M.nPrime, M.primes p = true
abbrev INV_recursion_uses_prime_index : Prop :=
  ∀ tp : Fin M.nTp, M.primes (M.tpIndex tp) = true ∨ ∃ e : Fin M.nExt, M.extra e (M.tpIndex tp) = true
abbrev INV_contract_measure_non_increase : Prop := measure_links M
abbrev INV_optimize_objective_residual : Prop := optobj_residual_ok M
abbrev INV_converge_hyps_production : Prop := convergence_hyps_production M
abbrev INV_evolution_total_on_State : Prop := ∀ s : Fin M.nState, ∃ t : Fin M.nTime, M.atState t = s
abbrev INV_multimodal_tensor_wiring : Prop := multimodal_wired M
abbrev INV_evolve_total_State_reachable : Prop := ∀ s : Fin M.nState, ∃ t : Fin M.nTime, M.atState t = s

/-! ## Checks: each assertion is implied by an enforced fact

The `*_is_fact` lemmas show the assertion is the fact itself (`Iff.rfl`). -/

section checks
variable {M}

theorem check_A1_P64_cardinality_and_distinct (h : Facts M) : A1_P64_cardinality_and_distinct M :=
  ⟨h.A1_card, h.A1_index.2, h.A1_index.1, fun _ hp => hp⟩
theorem check_A1b_P64_distinct_indices (h : Facts M) : A1b_P64_distinct_indices M := h.A1_index.2
theorem check_A2_contractive_iff_gershgorin_bound (h : Facts M) :
    A2_contractive_iff_gershgorin_bound M := h.A2
theorem check_A3_soft_project_when_q_over_margin (h : Facts M) :
    A3_soft_project_when_q_over_margin M := h.A3
theorem check_A4_foundry_additive_only_if_Foundry_instance (h : Facts M) :
    A4_foundry_additive_only_if_Foundry_instance M := by
  refine ⟨?_, fun hk t u hn => (h.evolve t u hn).2 hk, fun hk t u hn => (h.evolve t u hn).1 hk⟩
  cases M.activeKind <;> simp
theorem check_A5_PMAT_conservation_gated (h : Facts M) : A5_PMAT_conservation_gated M := h.A5
theorem check_A6_guardian_reject_spectral_or_nonfinite (h : Facts M) :
    A6_guardian_reject_spectral_or_nonfinite M := h.A6
theorem check_A7_production_defined_records (h : Facts M) : A7_production_defined_records M := by
  have a := h.A7
  simp only [A7_production_all_spec_defined, allGaps, List.mem_cons, List.mem_nil_iff,
    or_false, forall_eq_or_imp, forall_eq] at a
  exact a
theorem check_P1_carrier_linf_dim (h : Facts M) : P1_carrier_linf_dim M := h.P1
theorem check_P2_tp_diag_spec_alpha (h : Facts M) : P2_tp_diag_spec_alpha M := h.P2
theorem check_P3_c_scale_or_id (h : Facts M) : P3_c_scale_or_id M := h.P3
theorem check_P4_lambda_m_scalar_bound (h : Facts M) : P4_lambda_m_scalar_bound M := h.P4
theorem check_P5_xi_uniform_affine (h : Facts M) : P5_xi_uniform_affine M := h.P5
theorem check_P6_instance_bridge_morphism (h : Facts M) : P6_instance_bridge_morphism M := h.P6
theorem check_P7_optobj_residual (h : Facts M) : P7_optobj_residual M := h.P7
theorem check_P8_contractalg_gershgorin_then_c (h : Facts M) :
    P8_contractalg_gershgorin_then_c M := h.P8
theorem check_INV_LambdaM_scalar_placeholder (h : Facts M) : INV_LambdaM_scalar_placeholder M :=
  h.lam_not_schedule
theorem check_INV_step_shape_bridge_instance (h : Facts M) : INV_step_shape_bridge_instance M :=
  h.bridge
theorem check_INV_prime_index_bounded_to_P64 (h : Facts M) : INV_prime_index_bounded_to_P64 M :=
  h.primes_subset
theorem check_INV_recursion_uses_prime_index (h : Facts M) : INV_recursion_uses_prime_index M :=
  h.tp_index
theorem check_INV_contract_measure_non_increase (h : Facts M) :
    INV_contract_measure_non_increase M := h.measure_links
theorem check_INV_optimize_objective_residual (h : Facts M) :
    INV_optimize_objective_residual M := h.P7
theorem check_INV_converge_hyps_production (h : Facts M) : INV_converge_hyps_production M :=
  h.converge
theorem check_INV_evolution_total_on_State (h : Facts M) : INV_evolution_total_on_State M :=
  h.evolution_total
theorem check_INV_multimodal_tensor_wiring (h : Facts M) : INV_multimodal_tensor_wiring M :=
  h.multimodal
theorem check_INV_evolve_total_State_reachable (h : Facts M) :
    INV_evolve_total_State_reachable M := h.evolution_total

end checks

/-! Assertions that are literally a fact (the vacuity pattern). -/
theorem A2_is_fact : A2_contractive_iff_gershgorin_bound M ↔ fact_A2_contractive_iff M := Iff.rfl
theorem A3_is_fact : A3_soft_project_when_q_over_margin M ↔ fact_A3_soft_project M := Iff.rfl
theorem A5_is_fact : A5_PMAT_conservation_gated M ↔ fact_A5_pmat_if_used M := Iff.rfl
theorem A6_is_fact : A6_guardian_reject_spectral_or_nonfinite M ↔ fact_A6_guardian M := Iff.rfl
theorem P1_is_fact : P1_carrier_linf_dim M ↔ fact_P1_carrier_production M := Iff.rfl
theorem P2_is_fact : P2_tp_diag_spec_alpha M ↔ fact_P2_tp_diag_spec_alpha M := Iff.rfl
theorem P3_is_fact : P3_c_scale_or_id M ↔ fact_P3_c_scale_or_id M := Iff.rfl
theorem P4_is_fact : P4_lambda_m_scalar_bound M ↔ fact_P4_lambda_m_scalar_bound M := Iff.rfl
theorem P5_is_fact : P5_xi_uniform_affine M ↔ fact_P5_xi_uniform_affine M := Iff.rfl
theorem P6_is_fact : P6_instance_bridge_morphism M ↔ fact_P6_instance_bridge_morphism M := Iff.rfl
theorem P7_is_fact : P7_optobj_residual M ↔ fact_P7_optobj_residual M := Iff.rfl
theorem P8_is_fact : P8_contractalg_gershgorin_then_c M ↔ fact_P8_contractalg_gershgorin_then_c M :=
  Iff.rfl
theorem INV_LambdaM_is_fact : INV_LambdaM_scalar_placeholder M ↔ fact_LambdaM_not_schedule_vector M :=
  Iff.rfl
theorem INV_step_shape_is_fact : INV_step_shape_bridge_instance M ↔ fact_bridge_production M := Iff.rfl
theorem INV_prime_bounded_is_fact : INV_prime_index_bounded_to_P64 M ↔ fact_primes_subset_carrier M :=
  Iff.rfl
theorem INV_recursion_is_fact : INV_recursion_uses_prime_index M ↔ INV_Tp_index_in_P64_or_extension M :=
  Iff.rfl
theorem INV_contract_is_fact : INV_contract_measure_non_increase M ↔ fact_measure_on_contract_links M :=
  Iff.rfl
theorem INV_optimize_is_fact : INV_optimize_objective_residual M ↔ fact_P7_optobj_residual M := Iff.rfl
theorem INV_converge_is_fact : INV_converge_hyps_production M ↔ fact_converge_hyps M := Iff.rfl
theorem INV_evolution_is_fact : INV_evolution_total_on_State M ↔ fact_evolution_total_on_State M :=
  Iff.rfl
theorem INV_multimodal_is_fact : INV_multimodal_tensor_wiring M ↔ fact_multimodal_wired M := Iff.rfl
theorem INV_evolve_reachable_is_fact :
    INV_evolve_total_State_reachable M ↔ fact_evolution_total_on_State M := Iff.rfl


-- instance search for the nested ∃ of `hcalc_nested_step` needs a larger budget
set_option synthInstance.maxSize 2048
set_option synthInstance.maxHeartbeats 200000

/-! ## Runs (11 commands, all `expect 1`): concrete satisfying instances -/

/-- One instance with every signature inhabited: 1 State, Time t0 → t1, two
prime labels, one atom of every other signature. `kind` selects the active
instance. -/
def witness (kind : InstanceKind) : Model where
  nState := 1
  nTime := 2
  nMeasure := 1
  nStateMeasure := 1
  next := fun t => if t.val = 0 then some 1 else none
  atState := fun _ => 0
  activeKind := kind
  carrierDimPositive := 1
  carrierNorm := .LInf
  smOf := fun _ => 0
  smM := fun _ => 0
  nPrime := 2
  idx := fun p => p.val
  primes := fun _ => true
  declaredCard := 64
  nExt := 0
  extra := fun e => Fin.elim0 e
  nMM := 1
  nTS := 1
  nTp := 1
  encodes := fun _ => 0
  support := fun _ _ => true
  tpIndex := fun _ => 0
  tpApply := fun _ _ => some 0
  tpIsDiagonal := fun _ => 1
  tpAlphaLaw := fun _ => .SpecAlphaLaw
  nScalar := 1
  nSV := 1
  nStab := 1
  lamScalar := 0
  lamNonNeg := 1
  lamOpBoundOK := 1
  svW0 := fun _ => none
  svW1 := fun _ => none
  stabSource := fun _ => 0
  stabVia := fun _ => none
  nJac := 1
  nSB := 1
  nQB := 1
  nSP := 1
  nCOp := 1
  nCL := 1
  nPMAT := 1
  sbOf := fun _ => 0
  sbBelow := fun _ => some .T2
  sbPower := fun _ => none
  qbQ := fun _ => 0
  qbTier := fun _ => .T2
  qbOver := fun _ => 0
  spBudget := fun _ => 0
  spApplied := fun _ => 0
  cMode := fun _ => .ScaleOrId
  cApply := fun _ _ => some 0
  contractAlgKind := .GershgorinThenScaleOrId
  nonIncrease := fun _ _ => true
  clPre := fun _ => 0
  clPost := fun _ => 0
  pmatConserved := fun _ => 1
  xiKind := .UniformXi
  xiIsOne := 1
  nKick := 1
  nInt := 1
  nXi := 1
  nFXi := 1
  nFLam := 1
  nFT := 1
  nFG := 1
  kickTarget := fun _ => none
  intFrom := fun _ => 0
  intTp := fun _ => some 0
  intC := fun _ => some 0
  intLam := fun _ => some 0
  xiAt := fun _ => 0
  xiMap := fun _ _ => some 0
  xiAffine := fun _ => 1
  xiSched := fun _ => .UniformXi
  fxiSched := fun _ => 0
  flamSched := fun _ => 0
  ftApply := fun _ _ => some 0
  fgKick := fun _ => none
  ibT := 1
  ibLam := 1
  ibXi := 1
  ibG := 1
  ibClaimsIdentity := 0
  bridgeMode := .InstanceBridge
  nObj := 1
  objKind := fun _ => .ResidualObj
  objScore := fun _ _ => none
  nRes := 1
  nHyp := 1
  nG := 1
  resOf := fun _ => 0
  resBelow := fun _ => 1
  hypDischarged := fun _ => none
  hypHolds := fun _ => 0
  gSubject := fun _ => 0
  gSR := fun _ => 0
  gNF := fun _ => 0
  gVerdict := fun _ => .Accept
  gap := fun _ => .SpecDefined

theorem witness_facts (k : InstanceKind) : Facts (witness k) := by
  cases k <;> constructor <;> decide

abbrev show_hcalc_trace : Prop :=
  M.activeKind = .HCALCInstance ∧
  ∃ t u, M.next t = some u ∧ hcalc_nested_step M t (M.atState t) (M.atState u)
abbrev show_foundry_trace : Prop :=
  M.activeKind = .FoundryInstance ∧
  ∃ t u, M.next t = some u ∧ foundry_additive_step M (M.atState t) (M.atState u)
abbrev vacuity_State : Prop :=
  M.nState > 0 ∧ (∃ t u, M.next t = some u) ∧ M.nStateMeasure > 0
abbrev vacuity_PrimeIndex : Prop := (List.finRange M.nPrime).countP (fun p => M.primes p) ≥ 2
abbrev vacuity_Transform : Prop := M.nTp > 0 ∧ M.nMM > 0 ∧ M.nTS > 0
abbrev vacuity_Recursion : Prop :=
  ∃ t u tp, M.next t = some u ∧ M.primes (M.tpIndex tp) = true ∧
    M.tpApply tp (M.atState t) = some (M.atState u)
abbrev vacuity_Stabilize : Prop := M.nScalar > 0 ∧ M.nSV > 0 ∧ M.nStab > 0
abbrev vacuity_Contract : Prop :=
  M.nJac > 0 ∧ M.nSB > 0 ∧ M.nQB > 0 ∧ M.nSP > 0 ∧ M.nCOp > 0
abbrev vacuity_Evolve : Prop :=
  M.nKick > 0 ∧ M.nInt > 0 ∧ M.nXi > 0 ∧ M.nFT > 0 ∧ M.nFG > 0
abbrev vacuity_Optimize : Prop := M.nObj > 0
abbrev vacuity_Converge : Prop := M.nRes > 0 ∧ M.nHyp > 0 ∧ M.nG > 0

theorem run_show_hcalc_trace : ∃ M, Facts M ∧ show_hcalc_trace M :=
  ⟨witness .HCALCInstance, witness_facts _, by decide⟩
theorem run_show_foundry_trace : ∃ M, Facts M ∧ show_foundry_trace M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_State : ∃ M, Facts M ∧ vacuity_State M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_PrimeIndex : ∃ M, Facts M ∧ vacuity_PrimeIndex M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_Transform : ∃ M, Facts M ∧ vacuity_Transform M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_Recursion : ∃ M, Facts M ∧ vacuity_Recursion M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_Stabilize : ∃ M, Facts M ∧ vacuity_Stabilize M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_Contract : ∃ M, Facts M ∧ vacuity_Contract M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_Evolve : ∃ M, Facts M ∧ vacuity_Evolve M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_Optimize : ∃ M, Facts M ∧ vacuity_Optimize M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩
theorem run_vacuity_Converge : ∃ M, Facts M ∧ vacuity_Converge M :=
  ⟨witness .FoundryInstance, witness_facts _, by decide⟩

/-! ## Vacuity, made explicit

Drop one fact and its assertion fails: e.g. without `fact_P2_tp_diag_spec_alpha`
there is an instance violating `P2_tp_diag_spec_alpha` while every other fact
still holds. The checks therefore only re-confirm the facts that were
installed. -/

def witnessBadP2 : Model := { witness .FoundryInstance with tpIsDiagonal := fun _ => 0 }

theorem P2_fails_without_its_fact : ¬ P2_tp_diag_spec_alpha witnessBadP2 := by decide

theorem badP2_other_facts :
    INV_time_linear_chain witnessBadP2 ∧ fact_P1_carrier_production witnessBadP2 ∧
    A1_index_integrity witnessBadP2 ∧ INV_evolve_respects_active_instance witnessBadP2 ∧
    fact_P6_instance_bridge_morphism witnessBadP2 ∧ A7_production_all_spec_defined witnessBadP2 := by
  decide

end PirtmHcalc.Alloy.Hcalc
