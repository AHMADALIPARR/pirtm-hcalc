// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
// Must be REJECTED by --irdl-file=mlir/dialects/pirtm.irdl.mlir: cnot needs (state, nq, control, target).
func.func @f(%s: memref<?xcomplex<f64>>, %n: index) -> memref<?xcomplex<f64>> {
  %r = "pirtm.cnot"(%s, %n, %n) : (memref<?xcomplex<f64>>, index, index) -> memref<?xcomplex<f64>>
  return %r : memref<?xcomplex<f64>>
}
