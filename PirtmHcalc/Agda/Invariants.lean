-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
import PirtmHcalc.Agda.Core
import PirtmHcalc.Agda.Assumptions
/-!
# Agda port: PIRTM.Invariants (I01–I11)

Lean port of `agda/PIRTM/Invariants.agda`. Every definition is total and
every theorem is proved; there are no axioms. The Agda source was never
type-checked by its own pipeline (worker A10 reports NOT_RUN); this port is
checked by `lake build`.
-/

namespace PirtmHcalc.Agda

/-! ## I01: State preservation -/

structure SystemState where
  version : Nat
  wellFormed : Bool

inductive ValidTransition : SystemState → SystemState → Prop
  | stepValid {v : Nat} : ValidTransition ⟨v, true⟩ ⟨v + 1, true⟩

theorem I01_state_preservation (s1 s2 : SystemState) :
    s1.wellFormed = true → ValidTransition s1 s2 → s2.wellFormed = true := by
  intro _ h
  cases h
  rfl

/-! ## I02: Causal ordering -/

inductive CausalPath : Nat → Nat → Prop
  | direct {a b : Nat} : Lt a b → CausalPath a b
  | step {a b c : Nat} : Lt a b → CausalPath b c → CausalPath a c

theorem causal_strict : ∀ {a b : Nat}, CausalPath a b → Lt a b
  | _, _, CausalPath.direct p => p
  | _, _, CausalPath.step p rest => lt_trans p (causal_strict rest)

theorem I02_causal_ordering (n : Nat) : ¬ CausalPath n n :=
  fun path => lt_irrefl n (causal_strict path)

/-! ## I03: Provenance integrity -/

structure ArtifactReference where
  hashId : Nat
  hasEntry : Bool

structure ProvenanceCertificate (ref : ArtifactReference) where
  provenanceHash : Nat
  provenanceValid : ref.hasEntry = true

theorem I03_provenance_integrity (ref : ArtifactReference) :
    ProvenanceCertificate ref → ref.hasEntry = true :=
  fun c => c.provenanceValid

/-! ## I04: Immutability -/

structure PublishedArtifact where
  sha256 : Nat
  payloadVersion : Nat

theorem I04_immutability (a b : PublishedArtifact) : a = b → a.sha256 = b.sha256 := by
  intro h
  rw [h]

/-! ## I05: Termination -/

inductive InferenceStep (A : Type) where
  | continue : A → InferenceStep A
  | fixedPoint : A → InferenceStep A

inductive FuelBoundedExecution {A : Type} (step : A → InferenceStep A) : Nat → A → A → Prop
  | haltFixed {fuel : Nat} {x : A} : step x = InferenceStep.fixedPoint x →
      FuelBoundedExecution step fuel x x
  | haltExhausted {x : A} : FuelBoundedExecution step 0 x x
  | recurse {fuel : Nat} {x y z : A} : step x = InferenceStep.continue y →
      FuelBoundedExecution step fuel y z → FuelBoundedExecution step (fuel + 1) x z

/-- The bounded runner the I05 comment describes: at most `fuel` steps. -/
def runFuel {A : Type} (step : A → InferenceStep A) : Nat → A → A
  | 0, x => x
  | fuel + 1, x =>
    match step x with
    | InferenceStep.fixedPoint _ => x
    | InferenceStep.continue y => runFuel step fuel y

/-- The Agda file only claims termination in a comment ("By construction,
FuelBoundedExecution terminates in at most `fuel` steps"). Stated here: for a
step whose `fixedPoint` results carry the current state (the PIRTM contract),
the total runner `runFuel` produces a `FuelBoundedExecution` witness for every
fuel and start state. Without that contract the Agda relation has no rule for
`step x = fixedPoint y` with `y ≠ x`, so the hypothesis is necessary. -/
theorem I05_termination {A : Type} (step : A → InferenceStep A)
    (hfix : ∀ x y, step x = InferenceStep.fixedPoint y → y = x) :
    ∀ (fuel : Nat) (x : A), FuelBoundedExecution step fuel x (runFuel step fuel x)
  | 0, x => FuelBoundedExecution.haltExhausted
  | fuel + 1, x => by
    unfold runFuel
    cases h : step x with
    | fixedPoint y =>
      have hy := hfix x y h
      subst hy
      exact FuelBoundedExecution.haltFixed h
    | «continue» y =>
      exact FuelBoundedExecution.recurse h (I05_termination step hfix fuel y)

/-! ## I06: Quantum unitarity -/

structure ExactGate (n : Nat) where
  isUnitaryFlag : Bool
  dimension : Nat

/-- Ported as written: the Agda theorem restates its hypothesis (a tautology).
The real unitarity facts are proved in `PirtmHcalc.Quantum.Exact`. -/
theorem I06_unitarity_preservation (g : ExactGate 2) :
    g.isUnitaryFlag = true → g.isUnitaryFlag = true := id

/-! ## I07: Probability normalization -/

structure ProbabilityDistribution where
  numOutcomes : Nat
  sumProbNumerator : Nat
  sumProbDenominator : Nat
  isNormalized : sumProbNumerator = sumProbDenominator

theorem I07_probability_normalization (d : ProbabilityDistribution) :
    d.sumProbNumerator = d.sumProbDenominator := d.isNormalized

/-! ## I08: Encoding integrity -/

structure ReversibleCodec (A B : Type) where
  encode : A → B
  decode : B → A
  reconstruct : ∀ x : A, decode (encode x) = x

theorem I08_encoding_integrity {A B : Type} (codec : ReversibleCodec A B) (x : A) :
    codec.decode (codec.encode x) = x := codec.reconstruct x

/-! ## I09: Observation boundaries -/

structure NonInjectiveObservation (Bulk Boundary : Type) where
  project : Bulk → Boundary
  witnessA : Bulk
  witnessB : Bulk
  distinct : witnessA ≠ witnessB
  collapse : project witnessA = project witnessB

theorem I09_observation_boundary_lossy {Bulk Boundary : Type}
    (obs : NonInjectiveObservation Bulk Boundary) (reconstruct : Boundary → Bulk) :
    ¬ (∀ b : Bulk, reconstruct (obs.project b) = b) := by
  intro all
  apply obs.distinct
  have ra := all obs.witnessA
  have rb := all obs.witnessB
  rw [obs.collapse] at ra
  exact ra.symm.trans rb

/-! ## I10: Agent isolation -/

structure AgentResult where
  agentId : Nat
  timestamp : Nat
  content : Nat

theorem I10_agent_isolation (r1 r2 : AgentResult) :
    r1.agentId ≠ r2.agentId → r1 ≠ r2 := by
  intro h e
  exact h (congrArg AgentResult.agentId e)

/-! ## I11: Evidence classification -/

inductive VerificationStatus where
  | Unverified
  | Verified
  deriving DecidableEq

structure Claim where
  claimId : Nat
  status : VerificationStatus

inductive Certificate : Claim → Prop
  | certified {id : Nat} : Certificate ⟨id, VerificationStatus.Verified⟩

theorem I11_evidence_classification (c : Claim) :
    ¬ Certificate c → c.status ≠ VerificationStatus.Verified := by
  intro noCert h
  cases c with
  | mk id st =>
    cases st with
    | Verified => exact noCert Certificate.certified
    | Unverified => exact VerificationStatus.noConfusion h

end PirtmHcalc.Agda
