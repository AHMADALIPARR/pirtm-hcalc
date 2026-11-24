// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
// Must be REJECTED by --irdl-file=mlir/dialects/hcalc.irdl.mlir: gl_mul takes i64 operands.
func.func @f(%a: i64, %e: f64) -> i64 {
  %z = "hcalc.gl_mul"(%a, %e) : (i64, f64) -> i64
  return %z : i64
}
