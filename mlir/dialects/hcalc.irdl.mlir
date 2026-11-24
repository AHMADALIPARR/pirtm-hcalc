// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// IRDL definition of the custom `hcalc` dialect: the HCALC nested pipeline
// X_{t+1} = Xi(t, LambdaM * C(Tp(X_t))) and the Goldilocks field.
// Load with: mlir-opt --irdl-file=mlir/dialects/hcalc.irdl.mlir
// Each op lowers to a func.call of the function named in its comment
// (mlir/lib/hcalc.mlir, mlir/lib/goldilocks.mlir); the lowering is the
// `lowerCustom` table in lakefile.lean.

irdl.dialect @hcalc {
  // tp_alpha(n) -> alpha_j = 1/(1 + ln p_{j mod 64})           => @tp_alpha
  irdl.operation @tp_alpha {
    %i = irdl.is index
    %v = irdl.base "!builtin.memref"
    irdl.operands(%i)
    irdl.results(%v)
  }
  // tp(x) = diag(alpha) x                                      => @tp_from_p64
  irdl.operation @tp {
    %v = irdl.base "!builtin.memref"
    irdl.operands(%v)
    irdl.results(%v)
  }
  // c(x, eps) = soft-project scale-or-id                        => @c_wrap
  irdl.operation @c {
    %v = irdl.base "!builtin.memref"
    %f = irdl.is f64
    irdl.operands(%v, %f)
    irdl.results(%v)
  }
  // lambda_m(n, eps) = min(1, (1-eps)/(||C Tp||_op + delta))    => @lam_m
  irdl.operation @lambda_m {
    %i = irdl.is index
    %f = irdl.is f64
    irdl.operands(%i, %f)
    irdl.results(%f)
  }
  // step(x, eps, xi, g) -> x'                                  => @hcalc_step
  irdl.operation @step {
    %v = irdl.base "!builtin.memref"
    %f = irdl.is f64
    irdl.operands(%v, %f, %f, %v)
    irdl.results(%v)
  }
  // residual(a, b) = ||a - b||_inf                              => @residual_linf
  irdl.operation @residual {
    %v = irdl.base "!builtin.memref"
    %f = irdl.is f64
    irdl.operands(%v, %v)
    irdl.results(%f)
  }
  // run(x0, max_steps, tol, eps, xi, g) -> (x, converged, steps, last_residual)  => @hcalc_run
  irdl.operation @run {
    %v = irdl.base "!builtin.memref"
    %i = irdl.is index
    %f = irdl.is f64
    %b = irdl.is i1
    irdl.operands(%v, %i, %f, %f, %f, %v)
    irdl.results(%v, %b, %i, %f)
  }
  // Goldilocks field p = 2^64 - 2^32 + 1 (values as i64 bit patterns)
  // gl_add / gl_sub / gl_mul / gl_pow                           => @gl_add @gl_sub @gl_mul @gl_pow
  irdl.operation @gl_add {
    %i = irdl.is i64
    irdl.operands(%i, %i)
    irdl.results(%i)
  }
  irdl.operation @gl_sub {
    %i = irdl.is i64
    irdl.operands(%i, %i)
    irdl.results(%i)
  }
  irdl.operation @gl_mul {
    %i = irdl.is i64
    irdl.operands(%i, %i)
    irdl.results(%i)
  }
  irdl.operation @gl_pow {
    %i = irdl.is i64
    irdl.operands(%i, %i)
    irdl.results(%i)
  }
  // gl_inv(a) = a^(p-2)                                         => @gl_inv
  irdl.operation @gl_inv {
    %i = irdl.is i64
    irdl.operands(%i)
    irdl.results(%i)
  }
}
