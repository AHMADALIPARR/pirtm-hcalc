 J verb to MLIR op lowering

Every row is a real J verb from `j/foundry/*.ijs`, lowered to one op in
`mlir/dialect/FoundryDialect.td` (dialect `foundry`). No op is invented:
where a J verb has no dialect op, the row says so and gives the real
lowering. Verified against the `.ijs` files by grep (see STATUS.md).

Constants are not ops. `GOLDILOCKS_PRIME`, `p`, `EPSILON_FOLD`, `TWO64`,
`TWO32`, `K_MAX`, `MAX_DRIFT`, `PIRTM_MAGIC`, `PHI`, `GENESIS_HASH_SIZE`,
`P64`, `P_64`, `T1`–`T4`, `WP_UNIFORM`, `WP_HARMONIC`, `WP_LOGDECAY`,
`GP_PASSTHROUGH`, `GP_SUPPRESS`, `GP_HOLD`, `GP_ATTENUATE`, `CSL_PASS`,
`CSL_FAIL_NEUTRALITY`, `CSL_FAIL_BENEFICENCE`, `CSL_FAIL_COMMUTATION`
(types.ijs) lower to module-level constants or attributes, not ops.

## Goldilocks field — goldilocks.ijs

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| `fp_reduce` | `foundry.fp_reduce` | `!foundry.fp -> !foundry.fp` | monadic |
| `fp_mulmod` | `foundry.fp_mulmod` | `!foundry.fp, !foundry.fp -> !foundry.fp` | Goldilocks fold |
| `fp_add` | `foundry.fp_add` | `!foundry.fp, !foundry.fp -> !foundry.fp` | |
| `fp_sub` | `foundry.fp_sub` | `!foundry.fp, !foundry.fp -> !foundry.fp` | +p on underflow |
| `fp_mul` | `foundry.fp_mul` | `!foundry.fp, !foundry.fp -> !foundry.fp` | same as fp_mulmod |
| `fp_pow` | `foundry.fp_pow` | `!foundry.fp, i64 -> !foundry.fp` | square-and-multiply |
| `fp_inv` | `foundry.fp_inv` | `!foundry.fp -> !foundry.fp` | Fermat a^(p-2) |
| `fp_add_batch` | `foundry.fp_add_batch` | `tensor, tensor -> tensor` | fp_add at rank 0, elementwise |
| `fp_mul_batch` | `foundry.fp_mul_batch` | `tensor, tensor -> tensor` | fp_mul at rank 0, elementwise |

## Types — types.ijs

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| `tier_eps` | `foundry.tier_eps` | `i64 -> f64` | T1 0.10, T2 0.05, T3 0.02, T4 0.01, default 0.10 |
| `tier_epsilon` | `foundry.tier_eps` | `i64 -> f64` | alias for tier_eps, same op |
| `sig_sub` | no dialect op | — | plain `-`; lowers to `arith.subi` |
| `sig_eq` | no dialect op | — | match `-:`; lowers to `arith.cmpi eq` |

## Loader — foundry.ijs

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| `foundry_export` | no dialect op | — | J-side convenience: copies selected names into base; not a computation |

## PMat — pmat.ijs

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| `pmat_new` | `foundry.pmat_new` | `i64, i64 -> !foundry.pmat` | rows, cols -> empty PMat |
| `pmat_rows` | `foundry.pmat_rows` | `!foundry.pmat -> i64` | accessor |
| `pmat_cols` | `foundry.pmat_cols` | `!foundry.pmat -> i64` | accessor |
| `pmat_entries` | `foundry.pmat_entries` | `!foundry.pmat -> tensor` | accessor, n x 5 table |
| `pmat_shape` | `foundry.pmat_shape` | `!foundry.pmat -> tensor` | (rows, cols) |
| `pmat_insert` | `foundry.pmat_insert` | `!foundry.pmat, i64 x 5 -> !foundry.pmat, i1` | m, row, col, sign, ds, dt -> new PMat, ok |
| `pmat_validate_grading` | `foundry.pmat_validate_grading` | `!foundry.pmat -> i1` | always 1; the C++ stub, mirrored as-is |
| `pmat_conservation` | `foundry.pmat_conservation` | `!foundry.pmat -> tensor` | summed signature (ds, dt) |
| `pmat_compose` | `foundry.pmat_compose` | `!foundry.pmat, !foundry.pmat -> !foundry.pmat` | ds from left, dt from right only |
| `pmat_frobenius` | `foundry.pmat_frobenius` | `!foundry.pmat -> f64` | sqrt of entry count |

## Spectral governor — spectral.ijs

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| `gershgorin_bound` | `foundry.gershgorin_bound` | `tensor -> f64` | Jacobian -> bound |
| `gershgorin_check` | `foundry.gershgorin_check` | `tensor, f64 -> !foundry.spectral_result` | J, epsilon |
| `power_iteration` | `foundry.power_iteration` | `tensor, i64, f64 -> f64` | J, max_iters, tol |
| `power_iteration_check` | `foundry.power_iteration_check` | `tensor, f64, i64 -> !foundry.spectral_result` | J, epsilon, max_iters |
| `spectral_analyze` | `foundry.spectral_analyze` | `tensor, f64 -> !foundry.spectral_result` | Gershgorin first, power iteration near the boundary |
| `sr_radius` | `foundry.sr_radius` | `!foundry.spectral_result -> f64` | accessor |
| `sr_contractive` | `foundry.sr_contractive` | `!foundry.spectral_result -> i1` | accessor |
| `sr_gersh` | `foundry.sr_gersh` | `!foundry.spectral_result -> f64` | accessor |
| `sr_power` | `foundry.sr_power` | `!foundry.spectral_result -> f64` | accessor |
| `sr_used_pi` | `foundry.sr_used_pi` | `!foundry.spectral_result -> i1` | accessor |
| `sr_open` | no dialect op | — | unbox `>`; boxing is implicit in the MLIR type |
| `sr_fields` | no dialect op | — | normalize-to-open helper; boxing is implicit in the MLIR type |

## Recurrence — recurrence.ijs

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| `apply_hook` | `foundry.apply_hook` | `tensor, symbol -> tensor` | hook is a symbol reference |
| `synth_weights` | `foundry.synth_weights` | `i64, i64, i64 -> tensor, tensor` | max_steps, tier, profile -> xi, lambda schedules |
| `soft_project` | `foundry.soft_project` | `tensor, tensor, f64, f64 -> tensor, tensor` | xi, lam, q, eps |
| `q_estimate` | `foundry.q_estimate` | `tensor x 4 -> f64` | xi, lam, x, Tx |
| `residual_l2` | `foundry.residual_l2` | `tensor, tensor -> f64` | x_next, x |
| `wt_at` | `foundry.wt_at` | `tensor, i64 -> f64` | weights, index clamped to 1 |
| `rec_step` | `foundry.rec_step` | `tensor x 4, symbol x 2, i64, i64 -> tensor, !foundry.step_info` | x, xi, lam, g, T hook, P hook, step_idx, tier |
| `rec_run` | `foundry.rec_run` | `tensor, i64 x 3, f64, symbol x 2 -> tensor, tensor, i1` | x0, max_steps, tier, profile, tol, T hook, P hook -> history, x_current, converged |
| `rec_state_x` | no dialect op | — | projection of a `rec_run` result, not an op |
| `rec_state_converged` | no dialect op | — | projection of a `rec_run` result, not an op |
| `rec_state_history` | no dialect op | — | projection of a `rec_run` result, not an op |

J keeps the run state in the `REC_STATE` global (`x_current ;
converged ; <history>`). The MLIR op returns those three values
directly instead of setting a global.

## Emission gate and CSL checks — gate.ijs

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| `emit_apply` | `foundry.emit_apply` | `tensor, tensor, f64, i64, f64 -> tensor` | out, prev, q, policy, epsilon |
| `csl_neutrality` | `foundry.csl_neutrality` | `tensor, tensor, f64 -> i32` | x, Tx, epsilon; verdict 0 pass, 1 fail |
| `csl_beneficence` | `foundry.csl_beneficence` | `tensor, tensor, f64, f64 -> i32` | x, Tx, residual, epsilon; verdict 0 pass, 2 fail |
| `csl_commutation` | `foundry.csl_commutation` | `tensor, symbol, symbol, f64 -> i32` | x, T hook, filter hook, epsilon; verdict 0 pass, 3 fail |

## Ace certification — certify.ijs

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| `ace_safety_margin` | `foundry.ace_safety_margin` | `f64, f64 -> f64` | max_q, epsilon -> (1-eps) - max_q |
| `ace_tail_bound` | `foundry.ace_tail_bound` | `f64, f64 -> f64` | tail_norm, max_q -> tail / (1 - max_q) |
| `ace_certify` | `foundry.ace_certify` | `tensor, f64 -> !foundry.ace_cert` | history of StepInfo, delta |

## Mask gate — mlir/mask-gate/sha256.asm

| J verb | MLIR op | Operands -> results | Notes |
|---|---|---|---|
| (none; the gate is NASM, not J) | `foundry.sha256_mask` | `tensor -> tensor` | byte string -> 32-byte digest; lowers to a call to `sha256_hash` through the SysV-to-Windows adapter in `mlir/harness/mask_gate/call_gate.asm` |

## Types

| MLIR type | J record | Fields (BOXING.md order) |
|---|---|---|
| `!foundry.fp` | field element | a 64-bit value, 0 <= v < p |
| `!foundry.pmat` | PMat | rows ; cols ; entries |
| `!foundry.spectral_result` | SpectralResult | spectral_radius ; contractive ; gershgorin_bound ; power_iter_bound ; used_power_iteration |
| `!foundry.step_info` | StepInfo | step ; q ; epsilon ; n_xi ; n_lam ; projected ; residual |
| `!foundry.ace_cert` | AceCert | lipschitz_upper ; safety_margin ; tail_bound ; certified |
