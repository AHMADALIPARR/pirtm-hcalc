// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// main/hcalc.mlir — prints the same lines as the HCALC section of j/demo.ijs
// (same labels, J number display) so the two outputs diff directly.

llvm.mlir.global internal constant @l_title("== hcalc: x = 1 2 3 4 5, eps = 0.05, tol = 1e_6, max_steps = 80\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_alpha("alpha\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_tp("tp_from_p64\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_gb("gershgorin_bound\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_q("q_of_tp\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_s("soft_project_scale\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_op("c_op_norm\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_lam("lam_m\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_step("step\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_diag("diagnostic\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_rc("run_converged\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_rs("run_steps\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_rx("run_x\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_rr("run_last_residual\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_pi("power_iteration_2x2\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_sr("spectral_2x2_radius\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_sr2("spectral_refined_radius\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @l_cw("c_wrap_check\00") {addr_space = 0 : i32}

func.func @jvec(%label: !llvm.ptr, %v: memref<?xf64>) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %sp = arith.constant 32 : i8
  %b = func.call @s_new() : () -> memref<?xi8>
  %l0 = func.call @s_cstr(%b, %c0, %label) : (memref<?xi8>, index, !llvm.ptr) -> index
  %n = memref.dim %v, %c0 : memref<?xf64>
  %l = scf.for %i = %c0 to %n step %c1 iter_args(%acc = %l0) -> (index) {
    %a = func.call @s_byte(%b, %acc, %sp) : (memref<?xi8>, index, i8) -> index
    %x = memref.load %v[%i] : memref<?xf64>
    %r = func.call @s_jfloat(%b, %a, %x) : (memref<?xi8>, index, f64) -> index
    scf.yield %r : index
  }
  func.call @s_print(%b, %l) : (memref<?xi8>, index) -> ()
  return
}

func.func @jnum(%label: !llvm.ptr, %x: f64) {
  %c1 = arith.constant 1 : index
  %v = memref.alloc(%c1) : memref<?xf64>
  %c0 = arith.constant 0 : index
  memref.store %x, %v[%c0] : memref<?xf64>
  func.call @jvec(%label, %v) : (!llvm.ptr, memref<?xf64>) -> ()
  return
}

func.func @mat2x2(%a: f64, %b: f64, %c: f64, %d: f64) -> memref<?x?xf64> {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %m = memref.alloc(%c2, %c2) : memref<?x?xf64>
  memref.store %a, %m[%c0, %c0] : memref<?x?xf64>
  memref.store %b, %m[%c0, %c1] : memref<?x?xf64>
  memref.store %c, %m[%c1, %c0] : memref<?x?xf64>
  memref.store %d, %m[%c1, %c1] : memref<?x?xf64>
  return %m : memref<?x?xf64>
}

func.func @main() -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c5 = arith.constant 5 : index
  %c80 = arith.constant 80 : index
  %eps = arith.constant 0.05 : f64
  %tol = arith.constant 1.0e-6 : f64
  %xi = arith.constant 1.0 : f64
  %zf = arith.constant 0.0 : f64
  %t = llvm.mlir.addressof @l_title : !llvm.ptr
  %tb = func.call @s_new() : () -> memref<?xi8>
  %tl = func.call @s_cstr(%tb, %c0, %t) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @s_print(%tb, %tl) : (memref<?xi8>, index) -> ()
  %x = memref.alloc(%c5) : memref<?xf64>
  %g = memref.alloc(%c5) : memref<?xf64>
  scf.for %i = %c0 to %c5 step %c1 {
    %i1 = arith.addi %i, %c1 : index
    %i64 = arith.index_cast %i1 : index to i64
    %f = arith.sitofp %i64 : i64 to f64
    memref.store %f, %x[%i] : memref<?xf64>
    memref.store %zf, %g[%i] : memref<?xf64>
  }
  %a = func.call @tp_alpha(%c5) : (index) -> memref<?xf64>
  %la = llvm.mlir.addressof @l_alpha : !llvm.ptr
  func.call @jvec(%la, %a) : (!llvm.ptr, memref<?xf64>) -> ()
  %tp = func.call @tp_from_p64(%x) : (memref<?xf64>) -> memref<?xf64>
  %ltp = llvm.mlir.addressof @l_tp : !llvm.ptr
  func.call @jvec(%ltp, %tp) : (!llvm.ptr, memref<?xf64>) -> ()
  %dm = func.call @diag_from_alpha(%a) : (memref<?xf64>) -> memref<?x?xf64>
  %gb = func.call @gershgorin_bound(%dm) : (memref<?x?xf64>) -> f64
  %lgb = llvm.mlir.addressof @l_gb : !llvm.ptr
  func.call @jnum(%lgb, %gb) : (!llvm.ptr, f64) -> ()
  %q = func.call @q_of_tp(%c5, %eps) : (index, f64) -> f64
  %lq = llvm.mlir.addressof @l_q : !llvm.ptr
  func.call @jnum(%lq, %q) : (!llvm.ptr, f64) -> ()
  %s = func.call @soft_project_scale(%q, %eps) : (f64, f64) -> f64
  %ls = llvm.mlir.addressof @l_s : !llvm.ptr
  func.call @jnum(%ls, %s) : (!llvm.ptr, f64) -> ()
  %op = func.call @c_op_norm(%c5, %eps) : (index, f64) -> f64
  %lop = llvm.mlir.addressof @l_op : !llvm.ptr
  func.call @jnum(%lop, %op) : (!llvm.ptr, f64) -> ()
  %lam = func.call @lam_m(%c5, %eps) : (index, f64) -> f64
  %llam = llvm.mlir.addressof @l_lam : !llvm.ptr
  func.call @jnum(%llam, %lam) : (!llvm.ptr, f64) -> ()
  %st = func.call @hcalc_step(%x, %eps, %xi, %g) : (memref<?xf64>, f64, f64, memref<?xf64>) -> memref<?xf64>
  %lst = llvm.mlir.addressof @l_step : !llvm.ptr
  func.call @jvec(%lst, %st) : (!llvm.ptr, memref<?xf64>) -> ()
  %dg = func.call @to_foundry_step_diagnostic(%x, %eps, %xi, %g) : (memref<?xf64>, f64, f64, memref<?xf64>) -> memref<?xf64>
  %ldg = llvm.mlir.addressof @l_diag : !llvm.ptr
  func.call @jvec(%ldg, %dg) : (!llvm.ptr, memref<?xf64>) -> ()
  %run:4 = func.call @hcalc_run(%x, %c80, %tol, %eps, %xi, %g) : (memref<?xf64>, index, f64, f64, f64, memref<?xf64>) -> (memref<?xf64>, i1, index, f64)
  %cv = arith.uitofp %run#1 : i1 to f64
  %lrc = llvm.mlir.addressof @l_rc : !llvm.ptr
  func.call @jnum(%lrc, %cv) : (!llvm.ptr, f64) -> ()
  %ns64 = arith.index_cast %run#2 : index to i64
  %nsf = arith.sitofp %ns64 : i64 to f64
  %lrs = llvm.mlir.addressof @l_rs : !llvm.ptr
  func.call @jnum(%lrs, %nsf) : (!llvm.ptr, f64) -> ()
  %lrx = llvm.mlir.addressof @l_rx : !llvm.ptr
  func.call @jvec(%lrx, %run#0) : (!llvm.ptr, memref<?xf64>) -> ()
  %lrr = llvm.mlir.addressof @l_rr : !llvm.ptr
  func.call @jnum(%lrr, %run#3) : (!llvm.ptr, f64) -> ()
  %h = arith.constant 0.5 : f64
  %qq = arith.constant 0.25 : f64
  %m1 = func.call @mat2x2(%h, %qq, %qq, %h) : (f64, f64, f64, f64) -> memref<?x?xf64>
  %c100 = arith.constant 100 : index
  %t12 = arith.constant 1.0e-12 : f64
  %pi = func.call @power_iteration(%m1, %c100, %t12) : (memref<?x?xf64>, index, f64) -> f64
  %lpi = llvm.mlir.addressof @l_pi : !llvm.ptr
  func.call @jnum(%lpi, %pi) : (!llvm.ptr, f64) -> ()
  %sr = func.call @spectral_analyze(%m1, %eps) : (memref<?x?xf64>, f64) -> f64
  %lsr = llvm.mlir.addressof @l_sr : !llvm.ptr
  func.call @jnum(%lsr, %sr) : (!llvm.ptr, f64) -> ()
  // Gershgorin bound 0.95 > 0.95*(1-0.01): spectral_analyze refines by power iteration
  %e9 = arith.constant 0.9 : f64
  %e05 = arith.constant 0.05 : f64
  %e02 = arith.constant 0.02 : f64
  %e8 = arith.constant 0.8 : f64
  %m2 = func.call @mat2x2(%e9, %e05, %e02, %e8) : (f64, f64, f64, f64) -> memref<?x?xf64>
  %eps2 = arith.constant 0.01 : f64
  %sr2 = func.call @spectral_analyze(%m2, %eps2) : (memref<?x?xf64>, f64) -> f64
  %lsr2 = llvm.mlir.addressof @l_sr2 : !llvm.ptr
  func.call @jnum(%lsr2, %sr2) : (!llvm.ptr, f64) -> ()
  // c_wrap_check_hcalc_: s(2,0.05) = 0.95/2, s(0.5,0.05) = 1, C∘Tp on 1 1 1 1 is the identity scale
  %two = arith.constant 2.0 : f64
  %half = arith.constant 0.5 : f64
  %k95 = arith.constant 0.95 : f64
  %s1 = func.call @soft_project_scale(%two, %eps) : (f64, f64) -> f64
  %e1 = arith.divf %k95, %two : f64
  %ok1 = arith.cmpf oeq, %s1, %e1 : f64
  %s2 = func.call @soft_project_scale(%half, %eps) : (f64, f64) -> f64
  %onef = arith.constant 1.0 : f64
  %ok2 = arith.cmpf oeq, %s2, %onef : f64
  %c4 = arith.constant 4 : index
  %ones = memref.alloc(%c4) : memref<?xf64>
  scf.for %i = %c0 to %c4 step %c1 {
    memref.store %onef, %ones[%i] : memref<?xf64>
  }
  %tp1 = func.call @tp_from_p64(%ones) : (memref<?xf64>) -> memref<?xf64>
  %cw = func.call @c_wrap(%tp1, %eps) : (memref<?xf64>, f64) -> memref<?xf64>
  %true = arith.constant true
  %ok3 = scf.for %i = %c0 to %c4 step %c1 iter_args(%acc = %true) -> (i1) {
    %u = memref.load %cw[%i] : memref<?xf64>
    %w = memref.load %tp1[%i] : memref<?xf64>
    %e = arith.cmpf oeq, %u, %w : f64
    %n = arith.andi %acc, %e : i1
    scf.yield %n : i1
  }
  %ok12 = arith.andi %ok1, %ok2 : i1
  %ok = arith.andi %ok12, %ok3 : i1
  %okf = arith.uitofp %ok : i1 to f64
  %lcw = llvm.mlir.addressof @l_cw : !llvm.ptr
  func.call @jnum(%lcw, %okf) : (!llvm.ptr, f64) -> ()
  %r = arith.constant 0 : i32
  return %r : i32
}
