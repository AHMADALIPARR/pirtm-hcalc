// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
// Must be REJECTED: hcalc.run has four results (x, converged, steps, last_residual).
func.func @f(%x: memref<?xf64>, %n: index, %t: f64) -> memref<?xf64> {
  %r = "hcalc.run"(%x, %n, %t, %t, %t, %x) : (memref<?xf64>, index, f64, f64, f64, memref<?xf64>) -> memref<?xf64>
  return %r : memref<?xf64>
}
