//===- FoundryDialect.td - Foundry F1 dialect --------------*- tablegen -*-===//
//
// Foundry F1 dialect: the MLIR layer the Pure-J Core feeds into.
//
// Source of truth for every op here is the J stack in j/foundry/*.ijs.
// Each J verb lowers to one dialect op; the verb-to-op table lives in
// mlir/lowering/LOWERING.md. Types follow the record boxing contracts in
// j/foundry/BOXING.md. No op is invented: a J verb with no MLIR equivalent
// is recorded in LOWERING.md as "no dialect op" with its real lowering.
//
// Form choice: TableGen (.td), the standard MLIR dialect definition form.
// Ops use the default generic assembly format (no assemblyFormat is set),
// so the textual form is "foundry.<op>"(%operands) : (types) -> type.
// A custom assembly format can be added per op later.
//
// Validation state: UNVALIDATED on this box. No MLIR toolchain is installed
// here (no mlir-tblgen, no mlir-opt), so this file has not been compiled by
// mlir-tblgen and the example in mlir/examples/ has not been run through
// mlir-opt. Structural checks only: balanced braces and brackets, every
// def closed, every referenced type and op defined in this file.
// Validate with: mlir-tblgen -gen-dialect-decls FoundryDialect.td
//                mlir-tblgen -gen-op-defs FoundryDialect.td
//
//===----------------------------------------------------------------------===//

#ifndef FOUNDRY_DIALECT_TD
#define FOUNDRY_DIALECT_TD

include "mlir/IR/OpBase.td"

def Foundry_Dialect : Dialect {
  let name = "foundry";
  let summary = "Foundry F1 dialect";
  let description = [{
    The Foundry F1 dialect is the MLIR layer the Pure-J Core
    (j/foundry/*.ijs) feeds into. The J stack is the source: Goldilocks
    field arithmetic over F_p with p = 2^64 - 2^32 + 1, prime monomial
    matrices (PMat), the spectral governor, the Banach contraction
    recurrence, the emission gate with CSL checks, and Ace certification.
    Every J verb lowers to one dialect op; see mlir/lowering/LOWERING.md.
    The NASM mask gate (mlir/mask-gate/sha256.asm) is the certification
    step and appears here as foundry.sha256_mask, which lowers to a call
    to the gate.
  }];
  let cppNamespace = "::mlir::foundry";
  let useDefaultTypePrinterParser = 1;
}

//===----------------------------------------------------------------------===//
// Types
//===----------------------------------------------------------------------===//
// Record types follow j/foundry/BOXING.md. Schedules and Jacobians are
// plain f64 tensors and need no distinct type.

class Foundry_Type<string cppName, string summary> :
    DialectType<Foundry_Dialect, CPred<"true">, cppName> {
  let summary = summary;
}

def Fp : Foundry_Type<"FpType",
    "Goldilocks field element: a 64-bit value v with 0 <= v < p, "
    "p = 2^64 - 2^32 + 1. The bound is a runtime invariant, not a "
    "TableGen predicate."> {
  let mnemonic = "fp";
}

def PMat : Foundry_Type<"PMatType",
    "Prime monomial matrix. Open fields rows ; cols ; entries, where "
    "entries is an n x 5 table of (sign, delta_source, delta_target, "
    "row, col). See j/foundry/BOXING.md."> {
  let mnemonic = "pmat";
}

def SpectralResult : Foundry_Type<"SpectralResultType",
    "Spectral governor result. Open fields: spectral_radius ; "
    "contractive ; gershgorin_bound ; power_iter_bound ; "
    "used_power_iteration. See j/foundry/BOXING.md."> {
  let mnemonic = "spectral_result";
}

def StepInfo : Foundry_Type<"StepInfoType",
    "One recurrence step. Open fields: step ; q ; epsilon ; n_xi ; "
    "n_lam ; projected ; residual. See j/foundry/BOXING.md."> {
  let mnemonic = "step_info";
}

def AceCert : Foundry_Type<"AceCertType",
    "Ace certificate. Open fields: lipschitz_upper ; safety_margin ; "
    "tail_bound ; certified. See j/foundry/BOXING.md."> {
  let mnemonic = "ace_cert";
}

//===----------------------------------------------------------------------===//
// Ops
//===----------------------------------------------------------------------===//

class Foundry_Op<string mnemonic, list<Trait> traits = []> :
    Op<Foundry_Dialect, mnemonic, traits> {
  // No assemblyFormat is set: ops use the default generic assembly format.
}

class Foundry_FieldOp<string mnemonic> :
    Foundry_Op<mnemonic, [Pure]>;

//--- Goldilocks field (j/foundry/goldilocks.ijs) --------------------------//

def FpReduceOp : Foundry_FieldOp<"fp_reduce"> {
  let summary = "Reduce a value mod p: (y >= p) ? y - p : y.";
  let description = [{
    Lowers J `fp_reduce y` (goldilocks.ijs). Single-limb reduction;
    the operand is already below 2^64.
  }];
  let arguments = (ins Fp:$value);
  let results = (outs Fp:$result);
}

def FpMulmodOp : Foundry_FieldOp<"fp_mulmod"> {
  let summary = "Goldilocks fold: (a * b) mod p via 2^64 == 2^32 - 1 (mod p).";
  let description = [{
    Lowers J `a fp_mulmod b` (goldilocks.ijs). The 128-bit product is
    folded as lo + hi_lo * (2^32 - 1) - hi_hi, then reduced once.
  }];
  let arguments = (ins Fp:$lhs, Fp:$rhs);
  let results = (outs Fp:$result);
}

def FpAddOp : Foundry_FieldOp<"fp_add"> {
  let summary = "Field addition: (a + b) mod p.";
  let description = [{ Lowers J `a fp_add b` (goldilocks.ijs). }];
  let arguments = (ins Fp:$lhs, Fp:$rhs);
  let results = (outs Fp:$result);
}

def FpSubOp : Foundry_FieldOp<"fp_sub"> {
  let summary = "Field subtraction: (a - b) mod p, with +p on underflow.";
  let description = [{ Lowers J `a fp_sub b` (goldilocks.ijs). }];
  let arguments = (ins Fp:$lhs, Fp:$rhs);
  let results = (outs Fp:$result);
}

def FpMulOp : Foundry_FieldOp<"fp_mul"> {
  let summary = "Field multiplication: (a * b) mod p (same as fp_mulmod).";
  let description = [{ Lowers J `a fp_mul b` (goldilocks.ijs). }];
  let arguments = (ins Fp:$lhs, Fp:$rhs);
  let results = (outs Fp:$result);
}

def FpPowOp : Foundry_FieldOp<"fp_pow"> {
  let summary = "Square-and-multiply: a^e mod p.";
  let description = [{ Lowers J `a fp_pow e` (goldilocks.ijs). }];
  let arguments = (ins Fp:$base, I64:$exp);
  let results = (outs Fp:$result);
}

def FpInvOp : Foundry_FieldOp<"fp_inv"> {
  let summary = "Fermat inverse: a^(p-2) mod p.";
  let description = [{ Lowers J `fp_inv a` (goldilocks.ijs). }];
  let arguments = (ins Fp:$value);
  let results = (outs Fp:$result);
}

def FpAddBatchOp : Foundry_FieldOp<"fp_add_batch"> {
  let summary = "Elementwise field addition over a tensor of elements.";
  let description = [{
    Lowers J `a fp_add_batch b` (goldilocks.ijs), which is fp_add at
    rank 0 applied elementwise.
  }];
  let arguments = (ins AnyTensor:$lhs, AnyTensor:$rhs);
  let results = (outs AnyTensor:$result);
}

def FpMulBatchOp : Foundry_FieldOp<"fp_mul_batch"> {
  let summary = "Elementwise field multiplication over a tensor of elements.";
  let description = [{
    Lowers J `a fp_mul_batch b` (goldilocks.ijs), which is fp_mul at
    rank 0 applied elementwise.
  }];
  let arguments = (ins AnyTensor:$lhs, AnyTensor:$rhs);
  let results = (outs AnyTensor:$result);
}

//--- Tier (j/foundry/types.ijs) -------------------------------------------//

def TierEpsOp : Foundry_Op<"tier_eps", [Pure]> {
  let summary = "Tier epsilon: T1 0.10, T2 0.05, T3 0.02, T4 0.01, default 0.10.";
  let description = [{
    Lowers J `tier_eps tier` (types.ijs). `tier_epsilon` is an alias for
    the same verb and lowers to this same op.
  }];
  let arguments = (ins I64:$tier);
  let results = (outs F64:$epsilon);
}

//--- PMat (j/foundry/pmat.ijs) --------------------------------------------//

def PMatNewOp : Foundry_Op<"pmat_new", []> {
  let summary = "Empty PMat with the given rows and columns.";
  let description = [{ Lowers J `rows pmat_new cols` (pmat.ijs). }];
  let arguments = (ins I64:$rows, I64:$cols);
  let results = (outs PMat:$result);
}

def PMatRowsOp : Foundry_Op<"pmat_rows", [Pure]> {
  let summary = "PMat rows accessor.";
  let description = [{ Lowers J `pmat_rows m` (pmat.ijs). }];
  let arguments = (ins PMat:$m);
  let results = (outs I64:$rows);
}

def PMatColsOp : Foundry_Op<"pmat_cols", [Pure]> {
  let summary = "PMat columns accessor.";
  let description = [{ Lowers J `pmat_cols m` (pmat.ijs). }];
  let arguments = (ins PMat:$m);
  let results = (outs I64:$cols);
}

def PMatEntriesOp : Foundry_Op<"pmat_entries", [Pure]> {
  let summary = "PMat entries accessor: the n x 5 monomial table.";
  let description = [{ Lowers J `pmat_entries m` (pmat.ijs). }];
  let arguments = (ins PMat:$m);
  let results = (outs AnyTensor:$entries);
}

def PMatShapeOp : Foundry_Op<"pmat_shape", [Pure]> {
  let summary = "PMat shape as a length-2 list (rows, cols).";
  let description = [{ Lowers J `pmat_shape m` (pmat.ijs). }];
  let arguments = (ins PMat:$m);
  let results = (outs AnyTensor:$shape);
}

def PMatInsertOp : Foundry_Op<"pmat_insert", []> {
  let summary = "Insert a monomial; returns the new PMat and an ok flag.";
  let description = [{
    Lowers J `m pmat_insert (row ; col ; sign ; signature)` (pmat.ijs).
    ok is 0 on bounds or sign failure only; the PMat is unchanged then.
  }];
  let arguments = (ins PMat:$m, I64:$row, I64:$col, I64:$sign,
                       I64:$delta_source, I64:$delta_target);
  let results = (outs PMat:$result, I1:$ok);
}

def PMatValidateGradingOp : Foundry_Op<"pmat_validate_grading", [Pure]> {
  let summary = "Grading validation. Always 1: the C++ stub, mirrored as-is.";
  let description = [{
    Lowers J `pmat_validate_grading m` (pmat.ijs). Always true; no
    invented checks. See j/foundry/BOXING.md.
  }];
  let arguments = (ins PMat:$m);
  let results = (outs I1:$valid);
}

def PMatConservationOp : Foundry_Op<"pmat_conservation", [Pure]> {
  let summary = "Sum of monomial signatures: (sum delta_source, sum delta_target).";
  let description = [{ Lowers J `pmat_conservation m` (pmat.ijs). }];
  let arguments = (ins PMat:$m);
  let results = (outs AnyTensor:$signature);
}

def PMatComposeOp : Foundry_Op<"pmat_compose", []> {
  let summary = "Compose two PMats: signs multiply, ds from the left, dt from the right.";
  let description = [{
    Lowers J `a pmat_compose b` (pmat.ijs). Per GAP_DECISIONS: not the
    full both-signature sum; ds comes from the left factor only and dt
    from the right factor only.
  }];
  let arguments = (ins PMat:$lhs, PMat:$rhs);
  let results = (outs PMat:$result);
}

def PMatFrobeniusOp : Foundry_Op<"pmat_frobenius", [Pure]> {
  let summary = "Frobenius norm: sqrt of the entry count.";
  let description = [{ Lowers J `pmat_frobenius m` (pmat.ijs). }];
  let arguments = (ins PMat:$m);
  let results = (outs F64:$norm);
}

//--- Spectral governor (j/foundry/spectral.ijs) ---------------------------//

def GershgorinBoundOp : Foundry_Op<"gershgorin_bound", [Pure]> {
  let summary = "Gershgorin bound of a Jacobian: max row (diag + off-diag).";
  let description = [{ Lowers J `gershgorin_bound J` (spectral.ijs). }];
  let arguments = (ins AnyTensor:$jacobian);
  let results = (outs F64:$bound);
}

def GershgorinCheckOp : Foundry_Op<"gershgorin_check", []> {
  let summary = "Gershgorin contractivity check; returns a SpectralResult.";
  let description = [{
    Lowers J `J gershgorin_check epsilon` (spectral.ijs). Contractive
    iff bound < 1 - epsilon.
  }];
  let arguments = (ins AnyTensor:$jacobian, F64:$epsilon);
  let results = (outs SpectralResult:$result);
}

def PowerIterationOp : Foundry_Op<"power_iteration", []> {
  let summary = "Power iteration on a Jacobian; returns the dominant eigenvalue magnitude.";
  let description = [{
    Lowers J `J power_iteration (max_iters , tol)` (spectral.ijs).
    Defaults max_iters 100, tol 1e-12.
  }];
  let arguments = (ins AnyTensor:$jacobian, I64:$max_iters, F64:$tol);
  let results = (outs F64:$eigenvalue);
}

def PowerIterationCheckOp : Foundry_Op<"power_iteration_check", []> {
  let summary = "Power-iteration contractivity check; returns a SpectralResult.";
  let description = [{
    Lowers J `J power_iteration_check (epsilon , max_iters)`
    (spectral.ijs). used_power_iteration is 1 in the result.
  }];
  let arguments = (ins AnyTensor:$jacobian, F64:$epsilon, I64:$max_iters);
  let results = (outs SpectralResult:$result);
}

def SpectralAnalyzeOp : Foundry_Op<"spectral_analyze", []> {
  let summary = "Gershgorin first, power iteration when close to the boundary.";
  let description = [{
    Lowers J `J spectral_analyze epsilon` (spectral.ijs). Power iteration
    runs only when contractive and the bound exceeds 0.95 * (1 - epsilon).
  }];
  let arguments = (ins AnyTensor:$jacobian, F64:$epsilon);
  let results = (outs SpectralResult:$result);
}

def SrRadiusOp : Foundry_Op<"sr_radius", [Pure]> {
  let summary = "SpectralResult spectral_radius accessor.";
  let description = [{ Lowers J `sr_radius res` (spectral.ijs). }];
  let arguments = (ins SpectralResult:$result);
  let results = (outs F64:$radius);
}

def SrContractiveOp : Foundry_Op<"sr_contractive", [Pure]> {
  let summary = "SpectralResult contractive accessor.";
  let description = [{ Lowers J `sr_contractive res` (spectral.ijs). }];
  let arguments = (ins SpectralResult:$result);
  let results = (outs I1:$contractive);
}

def SrGershOp : Foundry_Op<"sr_gersh", [Pure]> {
  let summary = "SpectralResult gershgorin_bound accessor.";
  let description = [{ Lowers J `sr_gersh res` (spectral.ijs). }];
  let arguments = (ins SpectralResult:$result);
  let results = (outs F64:$bound);
}

def SrPowerOp : Foundry_Op<"sr_power", [Pure]> {
  let summary = "SpectralResult power_iter_bound accessor.";
  let description = [{ Lowers J `sr_power res` (spectral.ijs). }];
  let arguments = (ins SpectralResult:$result);
  let results = (outs F64:$bound);
}

def SrUsedPiOp : Foundry_Op<"sr_used_pi", [Pure]> {
  let summary = "SpectralResult used_power_iteration accessor.";
  let description = [{ Lowers J `sr_used_pi res` (spectral.ijs). }];
  let arguments = (ins SpectralResult:$result);
  let results = (outs I1:$used);
}

//--- Recurrence (j/foundry/recurrence.ijs) --------------------------------//

def ApplyHookOp : Foundry_Op<"apply_hook", []> {
  let summary = "Invoke a rank-1 to rank-1 transform hook by symbol reference.";
  let description = [{
    Lowers J `x apply_hook boxed_fn` (recurrence.ijs). The hook is a
    boxed verb-name string or gerund in J; here it is a symbol reference
    to a function taking a tensor and returning a tensor.
  }];
  let arguments = (ins AnyTensor:$x, SymbolRefAttr:$hook);
  let results = (outs AnyTensor:$result);
}

def SynthWeightsOp : Foundry_Op<"synth_weights", []> {
  let summary = "Synthesize xi and lambda schedules for a run.";
  let description = [{
    Lowers J `synth_weights max_steps;tier;profile` (recurrence.ijs).
    Returns the xi schedule and the lambda schedule, each a table.
  }];
  let arguments = (ins I64:$max_steps, I64:$tier, I64:$profile);
  let results = (outs AnyTensor:$xi_schedule, AnyTensor:$lambda_schedule);
}

def SoftProjectOp : Foundry_Op<"soft_project", []> {
  let summary = "Scale xi and lambda by (1-eps)/q when q exceeds 1-eps.";
  let description = [{
    Lowers J `(xi ; lam) soft_project (q ; eps)` (recurrence.ijs).
  }];
  let arguments = (ins AnyTensor:$xi, AnyTensor:$lam, F64:$q, F64:$epsilon);
  let results = (outs AnyTensor:$xi_out, AnyTensor:$lam_out);
}

def QEstimateOp : Foundry_Op<"q_estimate", [Pure]> {
  let summary = "Contraction estimate q = ||xi|| + ||lam|| * ||T||.";
  let description = [{
    Lowers J `q_estimate xi;lam;x;Tx` (recurrence.ijs). Norms are
    max-abs; ||T|| is ||Tx|| / ||x|| when ||x|| is above 1e-15.
  }];
  let arguments = (ins AnyTensor:$xi, AnyTensor:$lam, AnyTensor:$x, AnyTensor:$tx);
  let results = (outs F64:$q);
}

def ResidualL2Op : Foundry_Op<"residual_l2", [Pure]> {
  let summary = "L2 residual ||x_next - x||_2.";
  let description = [{ Lowers J `x_next residual_l2 x` (recurrence.ijs). }];
  let arguments = (ins AnyTensor:$x_next, AnyTensor:$x);
  let results = (outs F64:$residual);
}

def WtAtOp : Foundry_Op<"wt_at", [Pure]> {
  let summary = "Weight at component i, with the index clamped to 1.";
  let description = [{ Lowers J `weights wt_at i` (recurrence.ijs). }];
  let arguments = (ins AnyTensor:$weights, I64:$index);
  let results = (outs F64:$weight);
}

def RecStepOp : Foundry_Op<"rec_step", []> {
  let summary = "One Banach contraction step; returns x_next and a StepInfo.";
  let description = [{
    Lowers J `x rec_step xi;lam;g;T_hook;p_hook;[step_idx];[tier]`
    (recurrence.ijs). The T and P hooks are symbol references. If q
    exceeds 1 - epsilon the weights are soft-projected first and q is
    re-estimated; projected records whether that happened.
  }];
  let arguments = (ins AnyTensor:$x, AnyTensor:$xi, AnyTensor:$lam,
                       AnyTensor:$g, SymbolRefAttr:$t_hook,
                       SymbolRefAttr:$p_hook, I64:$step_idx, I64:$tier);
  let results = (outs AnyTensor:$x_next, StepInfo:$info);
}

def RecRunOp : Foundry_Op<"rec_run", []> {
  let summary = "Run the recurrence to tolerance; returns history, state, and convergence.";
  let description = [{
    Lowers J `x0 rec_run max_steps;tier;profile;tol;T_hook;p_hook`
    (recurrence.ijs). J keeps the state in the REC_STATE global
    (x_current ; converged ; <history>); the op returns those three
    values directly instead, so rec_state_x, rec_state_converged, and
    rec_state_history are projections of the results, not ops.
  }];
  let arguments = (ins AnyTensor:$x0, I64:$max_steps, I64:$tier,
                       I64:$profile, F64:$tol, SymbolRefAttr:$t_hook,
                       SymbolRefAttr:$p_hook);
  let results = (outs AnyTensor:$history, AnyTensor:$x_current, I1:$converged);
}

//--- Emission gate and CSL checks (j/foundry/gate.ijs) --------------------//

def EmitApplyOp : Foundry_Op<"emit_apply", []> {
  let summary = "Apply the emission policy: passthrough, suppress, hold, or attenuate.";
  let description = [{
    Lowers J `out emit_apply (prev ; q ; policy ; epsilon)` (gate.ijs).
    Suppress zeroes the output and Hold returns the previous output when
    q >= 1 - epsilon; Attenuate scales by max(0, (1 - epsilon) - q).
  }];
  let arguments = (ins AnyTensor:$out, AnyTensor:$prev, F64:$q,
                       I64:$policy, F64:$epsilon);
  let results = (outs AnyTensor:$result);
}

def CslNeutralityOp : Foundry_Op<"csl_neutrality", [Pure]> {
  let summary = "CSL neutrality check; returns a verdict code (0 pass, 1 fail).";
  let description = [{
    Lowers J `x csl_neutrality (Tx ; epsilon)` (gate.ijs). Fails when
    some pair has |Ti - Tj| / |xi - xj| > 1 + epsilon.
  }];
  let arguments = (ins AnyTensor:$x, AnyTensor:$tx, F64:$epsilon);
  let results = (outs I32:$verdict);
}

def CslBeneficenceOp : Foundry_Op<"csl_beneficence", [Pure]> {
  let summary = "CSL beneficence check; returns a verdict code (0 pass, 2 fail).";
  let description = [{
    Lowers J `x csl_beneficence (Tx ; residual ; epsilon)` (gate.ijs).
    Fails when ||T(x)||_2 or the residual exceeds (1 + epsilon) * ||x||_2.
  }];
  let arguments = (ins AnyTensor:$x, AnyTensor:$tx, F64:$residual, F64:$epsilon);
  let results = (outs I32:$verdict);
}

def CslCommutationOp : Foundry_Op<"csl_commutation", [Pure]> {
  let summary = "CSL commutation check; returns a verdict code (0 pass, 3 fail).";
  let description = [{
    Lowers J `x csl_commutation (T_hook ; filter_hook ; epsilon)`
    (gate.ijs). Fails when ||filter(T(x)) - T(filter(x))||_inf > epsilon.
  }];
  let arguments = (ins AnyTensor:$x, SymbolRefAttr:$t_hook,
                       SymbolRefAttr:$filter_hook, F64:$epsilon);
  let results = (outs I32:$verdict);
}

//--- Ace certification (j/foundry/certify.ijs) ----------------------------//

def AceSafetyMarginOp : Foundry_Op<"ace_safety_margin", [Pure]> {
  let summary = "Safety margin: (1 - epsilon) - max_q.";
  let description = [{ Lowers J `max_q ace_safety_margin epsilon` (certify.ijs). }];
  let arguments = (ins F64:$max_q, F64:$epsilon);
  let results = (outs F64:$margin);
}

def AceTailBoundOp : Foundry_Op<"ace_tail_bound", [Pure]> {
  let summary = "Tail bound: tail / (1 - max_q), or infinity when max_q >= 1.";
  let description = [{ Lowers J `tail_norm ace_tail_bound max_q` (certify.ijs). }];
  let arguments = (ins F64:$tail_norm, F64:$max_q);
  let results = (outs F64:$bound);
}

def AceCertifyOp : Foundry_Op<"ace_certify", []> {
  let summary = "Certify a run history; returns an AceCert.";
  let description = [{
    Lowers J `steps ace_certify delta` (certify.ijs). The history is a
    tensor of StepInfo. certified is 1 when the safety margin is at
    least delta.
  }];
  let arguments = (ins AnyTensor:$history, F64:$delta);
  let results = (outs AceCert:$cert);
}

//--- NASM mask gate -------------------------------------------------------//

def Sha256MaskOp : Foundry_Op<"sha256_mask", []> {
  let summary = "Mask gate: SHA-256 of a byte string, the certification step.";
  let description = [{
    The NASM mask gate (mlir/mask-gate/sha256.asm) as an op. It lowers
    to a call to sha256_hash through the SysV-to-Windows convention
    adapter in mlir/harness/mask_gate/call_gate.asm. Input is a byte
    string; the result is the 32-byte digest. The gate's current status
    is recorded in STATUS.md; the harness (mlir/harness/) runs this op
    last over the J run record.
  }];
  let arguments = (ins AnyTensor:$input);
  let results = (outs AnyTensor:$digest);
}

#endif // FOUNDRY_DIALECT_TD
