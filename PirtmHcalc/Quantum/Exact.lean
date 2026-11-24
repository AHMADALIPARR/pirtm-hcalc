-- SPDX-License-Identifier: AGPL-3.0-only
-- Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
-- Copyright (C) 2026 Ahmad Parr
/-!
# Exact state-vector simulation over ℤ[i] / √2^k

Every circuit in PIRTM uses only H, X, Y, Z, S, S† and CNOT. Starting from a
basis state, every amplitude then has the form `z / √2^k` with `z ∈ ℤ[i]` and
one global `k` (H is the only gate that introduces `1/√2`, and it touches every
amplitude). A state is a pair `(k, tree)` where `tree` is a perfect binary
tree of Gaussian integers of depth `n`; qubit 0 is the most significant index
bit (the root split), as in `pirtm/quantum/hilbert11.py`.

Exact quantities are dyadic rationals `num / 2^exp` (`Dy`):
* `normSq s = Σ |z|² / 2^k`
* `fidelity a b = |Σ conj(a_j) b_j|² / 2^(ka+kb)`
* `rho0 s` = reduced density matrix of qubit 0 (2×2 Gaussian numerators / 2^k).

Everything is computable, so the experiment theorems in `PirtmHcalc.Data`
are proved by `decide` (kernel evaluation, no extra axioms).
-/

namespace PirtmHcalc.Quantum

/-- Gaussian integer `re + im·i`. -/
structure GInt where
  re : Int
  im : Int
  deriving DecidableEq, Repr, Inhabited

namespace GInt
def zero : GInt := ⟨0, 0⟩
def one : GInt := ⟨1, 0⟩
instance : Add GInt := ⟨fun a b => ⟨a.re + b.re, a.im + b.im⟩⟩
instance : Sub GInt := ⟨fun a b => ⟨a.re - b.re, a.im - b.im⟩⟩
instance : Neg GInt := ⟨fun a => ⟨-a.re, -a.im⟩⟩
instance : Mul GInt := ⟨fun a b => ⟨a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re⟩⟩
def conj (a : GInt) : GInt := ⟨a.re, -a.im⟩
/-- multiplication by i -/
def mulI (a : GInt) : GInt := ⟨-a.im, a.re⟩
def normSq (a : GInt) : Nat := (a.re * a.re + a.im * a.im).toNat
end GInt

/-- Perfect binary tree of amplitudes; `node l r` splits on the current qubit
(`l`: bit 0, `r`: bit 1). -/
inductive QT where
  | leaf (z : GInt)
  | node (l r : QT)
  deriving DecidableEq, Repr

namespace QT

def map (f : GInt → GInt) : QT → QT
  | leaf z => leaf (f z)
  | node l r => node (map f l) (map f r)

def zipWith (f : GInt → GInt → GInt) : QT → QT → QT
  | leaf a, leaf b => leaf (f a b)
  | node l r, node l' r' => node (zipWith f l l') (zipWith f r r')
  | t, _ => t

/-- basis state `|idx⟩` on `n` qubits (idx bit n-1 = qubit 0). -/
def basis : Nat → Nat → QT
  | 0, idx => leaf (if idx = 0 then GInt.one else GInt.zero)
  | n + 1, idx =>
    if idx < 2 ^ n then node (basis n idx) (basis n 0 |>.map (fun _ => GInt.zero))
    else node (basis n 0 |>.map (fun _ => GInt.zero)) (basis n (idx - 2 ^ n))

/-- amplitude numerator at index `idx` (tree of depth `n`). -/
def get : Nat → QT → Nat → GInt
  | _, leaf z, _ => z
  | n + 1, node l r, idx => if idx < 2 ^ n then get n l idx else get n r (idx - 2 ^ n)
  | 0, node _ _, _ => GInt.zero

/-- apply `f` to the pair of subtrees split by the qubit at depth `q`. -/
def atQubit (f : QT → QT → QT × QT) : Nat → QT → QT
  | 0, node l r => let p := f l r; node p.1 p.2
  | q + 1, node l r => node (atQubit f q l) (atQubit f q r)
  | _, t => t

def sumBy (f : GInt → Int) : QT → Int
  | leaf z => f z
  | node l r => sumBy f l + sumBy f r

def inner (a b : QT) : GInt :=
  let rec go : QT → QT → GInt
    | leaf x, leaf y => GInt.conj x * y
    | node l r, node l' r' => go l l' + go r r'
    | _, _ => GInt.zero
  go a b

def all (f : GInt → Bool) : QT → Bool
  | leaf z => f z
  | node l r => all f l && all f r

def leaves : QT → List GInt
  | leaf z => [z]
  | node l r => leaves l ++ leaves r

end QT

/-- Exact dyadic rational `num / 2^exp`. -/
structure Dy where
  num : Nat
  exp : Nat
  deriving DecidableEq, Repr

/-- value equality of dyadics -/
def Dy.eqv (a b : Dy) : Bool := a.num * 2 ^ b.exp == b.num * 2 ^ a.exp

/-- Gates of `pirtm/quantum/hilbert11.py` (`GateOp`) on the exact state. -/
inductive Gate where
  | H (q : Nat)
  | X (q : Nat)
  | Y (q : Nat)
  | Z (q : Nat)
  | S (q : Nat)
  | Sdg (q : Nat)
  | CNOT (c t : Nat)
  deriving DecidableEq, Repr

/-- `GateOp.dagger`. -/
def Gate.dagger : Gate → Gate
  | .S q => .Sdg q
  | .Sdg q => .S q
  | g => g

/-- n-qubit state `z / √2^k`. -/
structure State where
  n : Nat
  k : Nat
  amp : QT
  deriving DecidableEq, Repr

namespace State

def basis (n idx : Nat) : State := ⟨n, 0, QT.basis n idx⟩

/-- X on the qubit at relative depth `d` inside a subtree. -/
def xAt (d : Nat) (t : QT) : QT := QT.atQubit (fun l r => (r, l)) d t

def apply (s : State) : Gate → State
  | .H q => ⟨s.n, s.k + 1, QT.atQubit (fun l r => (QT.zipWith (· + ·) l r, QT.zipWith (· - ·) l r)) q s.amp⟩
  | .X q => ⟨s.n, s.k, xAt q s.amp⟩
  | .Y q => ⟨s.n, s.k, QT.atQubit (fun l r => (r.map (fun z => -(GInt.mulI z)), l.map GInt.mulI)) q s.amp⟩
  | .Z q => ⟨s.n, s.k, QT.atQubit (fun l r => (l, r.map (fun z => -z))) q s.amp⟩
  | .S q => ⟨s.n, s.k, QT.atQubit (fun l r => (l, r.map GInt.mulI)) q s.amp⟩
  | .Sdg q => ⟨s.n, s.k, QT.atQubit (fun l r => (l, r.map (fun z => -(GInt.mulI z)))) q s.amp⟩
  | .CNOT c t =>
    -- control above target (c < t): flip the target inside the control=1 subtree.
    -- (Every PIRTM circuit has c < t; c ≥ t is left unchanged and never used.)
    if c < t then ⟨s.n, s.k, QT.atQubit (fun l r => (l, xAt (t - c - 1) r)) c s.amp⟩ else s

def evolve (s : State) (gs : List Gate) : State := gs.foldl apply s
def evolveInverse (s : State) (gs : List Gate) : State := (gs.reverse.map Gate.dagger).foldl apply s

/-- ⟨s|s⟩ as `Σ|z|² / 2^k`. -/
def normSq (s : State) : Dy := ⟨(QT.sumBy (fun z => z.re * z.re + z.im * z.im) s.amp).toNat, s.k⟩

/-- `state_fidelity`: |⟨a|b⟩|² = |Σ conj(a)b|² / 2^(ka+kb). -/
def fidelity (a b : State) : Dy := ⟨(QT.inner a.amp b.amp).normSq, a.k + b.k⟩

/-- probability of basis outcome `idx`: |z|² / 2^k. -/
def prob (s : State) (idx : Nat) : Dy := ⟨(QT.get s.n s.amp idx).normSq, s.k⟩

/-- `partial_trace(state, [0])`: ρ[i][j] = Σ_env a(i,env)·conj(a(j,env)), as 2×2
Gaussian numerators over 2^k. Since `inner x y = Σ conj(x)·y`,
ρ[i][j] = conj(inner a_i a_j). -/
def rho0 (s : State) : List (List GInt) :=
  match s.amp with
  | QT.node l r =>
      [[GInt.conj (QT.inner l l), GInt.conj (QT.inner l r)],
       [GInt.conj (QT.inner r l), GInt.conj (QT.inner r r)]]
  | _ => []

/-- number of nonzero amplitudes -/
def support (s : State) : Nat :=
  let rec go : QT → Nat
    | QT.leaf z => if z = GInt.zero then 0 else 1
    | QT.node l r => go l + go r
  go s.amp

end State

end PirtmHcalc.Quantum
