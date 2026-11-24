// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// custom/hcalc_pipeline.mlir — the HCALC pipeline written with `hcalc` dialect ops.
// Verified against mlir/dialects/hcalc.irdl.mlir, lowered to func.call by
// `lake script run mlir`, then run. Every printed line must also appear in
// the J output of j/demo.ijs.

llvm.mlir.global internal constant @k_lam("lam_m\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_tp("tp_from_p64\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_step("step\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_rc("run_converged\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_rs("run_steps\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_rx("run_x\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_rr("run_last_residual\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_mul("mul\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_inv("inv_a\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_pow("pow_7_100\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @k_ai("a_times_inv_a\00") {addr_space = 0 : i32}

func.func @main() -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c5 = arith.constant 5 : index
  %c80 = arith.constant 80 : index
  %eps = arith.constant 0.05 : f64
  %xi = arith.constant 1.0 : f64
  %tol = arith.constant 1.0e-6 : f64
  %zf = arith.constant 0.0 : f64
  %onef = arith.constant 1.0 : f64
  %x = memref.alloc(%c5) : memref<?xf64>
  %g = memref.alloc(%c5) : memref<?xf64>
  scf.for %i = %c0 to %c5 step %c1 {
    %ii = arith.index_cast %i : index to i64
    %fi = arith.sitofp %ii : i64 to f64
    %v = arith.addf %fi, %onef : f64
    memref.store %v, %x[%i] : memref<?xf64>
    memref.store %zf, %g[%i] : memref<?xf64>
  }
  %lam = "hcalc.lambda_m"(%c5, %eps) : (index, f64) -> f64
  %l1 = llvm.mlir.addressof @k_lam : !llvm.ptr
  func.call @j_print_num(%l1, %lam) : (!llvm.ptr, f64) -> ()
  %tp = "hcalc.tp"(%x) : (memref<?xf64>) -> memref<?xf64>
  %l2 = llvm.mlir.addressof @k_tp : !llvm.ptr
  func.call @j_print_vec(%l2, %tp) : (!llvm.ptr, memref<?xf64>) -> ()
  %st = "hcalc.step"(%x, %eps, %xi, %g) : (memref<?xf64>, f64, f64, memref<?xf64>) -> memref<?xf64>
  %l3 = llvm.mlir.addressof @k_step : !llvm.ptr
  func.call @j_print_vec(%l3, %st) : (!llvm.ptr, memref<?xf64>) -> ()
  %r:4 = "hcalc.run"(%x, %c80, %tol, %eps, %xi, %g) : (memref<?xf64>, index, f64, f64, f64, memref<?xf64>) -> (memref<?xf64>, i1, index, f64)
  %conv = arith.uitofp %r#1 : i1 to f64
  %l4 = llvm.mlir.addressof @k_rc : !llvm.ptr
  func.call @j_print_num(%l4, %conv) : (!llvm.ptr, f64) -> ()
  %ns = arith.index_cast %r#2 : index to i64
  %nsf = arith.sitofp %ns : i64 to f64
  %l5 = llvm.mlir.addressof @k_rs : !llvm.ptr
  func.call @j_print_num(%l5, %nsf) : (!llvm.ptr, f64) -> ()
  %l6 = llvm.mlir.addressof @k_rx : !llvm.ptr
  func.call @j_print_vec(%l6, %r#0) : (!llvm.ptr, memref<?xf64>) -> ()
  %l7 = llvm.mlir.addressof @k_rr : !llvm.ptr
  func.call @j_print_num(%l7, %r#3) : (!llvm.ptr, f64) -> ()
  // Goldilocks: a = 12345678901234567890, b = 9876543210987654321
  %a = arith.constant 0xAB54A98CEB1F0AD2 : i64
  %b = arith.constant 0x891087B8E3B70CB1 : i64
  %m = "hcalc.gl_mul"(%a, %b) : (i64, i64) -> i64
  %l8 = llvm.mlir.addressof @k_mul : !llvm.ptr
  func.call @j_print_u64(%l8, %m) : (!llvm.ptr, i64) -> ()
  %seven = arith.constant 7 : i64
  %hundred = arith.constant 100 : i64
  %pw = "hcalc.gl_pow"(%seven, %hundred) : (i64, i64) -> i64
  %l9 = llvm.mlir.addressof @k_pow : !llvm.ptr
  func.call @j_print_u64(%l9, %pw) : (!llvm.ptr, i64) -> ()
  %ia = "hcalc.gl_inv"(%a) : (i64) -> i64
  %l10 = llvm.mlir.addressof @k_inv : !llvm.ptr
  func.call @j_print_u64(%l10, %ia) : (!llvm.ptr, i64) -> ()
  %one = "hcalc.gl_mul"(%a, %ia) : (i64, i64) -> i64
  %l11 = llvm.mlir.addressof @k_ai : !llvm.ptr
  func.call @j_print_u64(%l11, %one) : (!llvm.ptr, i64) -> ()
  %ret = arith.constant 0 : i32
  return %ret : i32
}
