// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// main/hilbert11.mlir — port of pirtm/quantum/hilbert11.py
// run_central_adversarial_experiment() and tests/test_hilbert11.py.

llvm.mlir.global internal constant @h_title("== hilbert11: central adversarial experiment (11 qubits, 2048 amplitudes)\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_dim("state_dimension\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_n1("psi1_norm_squared\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_n2("psi2_norm_squared\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_fid("global_overlap_fidelity\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_gd("global_distinguishable\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_td("reduced_trace_distance\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_sd("subsystem_distinguishable\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_p10("psi1_p0\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_p11("psi1_p1\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_p20("psi2_p0\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_p21("psi2_p1\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_rho01("psi1_rho01_re\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_t2("== hilbert11: test_11qubit_reversible_roundtrip (basis 7)\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_fn("forward_norm_squared\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_ff("forward_fidelity_vs_initial\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_bf("roundtrip_fidelity\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_amp("forward_amplitude\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h_fmt_amp("forward_amplitude[%lld] = (%.17g, %.17g) bits (%lld, %lld)\0A\00") {addr_space = 0 : i32}

func.func @adversarial() {
  %t = llvm.mlir.addressof @h_title : !llvm.ptr
  %b0 = func.call @s_new() : () -> memref<?xi8>
  %c0 = arith.constant 0 : index
  %lt = func.call @s_cstr(%b0, %c0, %t) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @s_print(%b0, %lt) : (memref<?xi8>, index) -> ()
  %nq = arith.constant 11 : index
  %one_i = arith.constant 1 : index
  %r = func.call @sqrt2_inv() : () -> f64
  %z = arith.constant 0.0 : f64
  %i0 = arith.constant 0 : index
  %i1025 = arith.constant 1025 : index
  %i512 = arith.constant 512 : index
  %i1537 = arith.constant 1537 : index
  %s1a = func.call @sv_alloc(%nq) : (index) -> memref<?xcomplex<f64>>
  %s1b = func.call @sv_set(%s1a, %i0, %r, %z) : (memref<?xcomplex<f64>>, index, f64, f64) -> memref<?xcomplex<f64>>
  %psi1 = func.call @sv_set(%s1b, %i1025, %r, %z) : (memref<?xcomplex<f64>>, index, f64, f64) -> memref<?xcomplex<f64>>
  %s2a = func.call @sv_alloc(%nq) : (index) -> memref<?xcomplex<f64>>
  %s2b = func.call @sv_set(%s2a, %i512, %r, %z) : (memref<?xcomplex<f64>>, index, f64, f64) -> memref<?xcomplex<f64>>
  %psi2 = func.call @sv_set(%s2b, %i1537, %r, %z) : (memref<?xcomplex<f64>>, index, f64, f64) -> memref<?xcomplex<f64>>
  %dim = memref.dim %psi1, %c0 : memref<?xcomplex<f64>>
  %dim64 = arith.index_cast %dim : index to i64
  %ld = llvm.mlir.addressof @h_dim : !llvm.ptr
  func.call @print_i64(%ld, %dim64) : (!llvm.ptr, i64) -> ()
  %n1 = func.call @sv_norm2(%psi1) : (memref<?xcomplex<f64>>) -> f64
  %n2 = func.call @sv_norm2(%psi2) : (memref<?xcomplex<f64>>) -> f64
  %ln1 = llvm.mlir.addressof @h_n1 : !llvm.ptr
  %ln2 = llvm.mlir.addressof @h_n2 : !llvm.ptr
  func.call @print_f64(%ln1, %n1) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%ln2, %n2) : (!llvm.ptr, f64) -> ()
  %fid = func.call @sv_fidelity(%psi1, %psi2) : (memref<?xcomplex<f64>>, memref<?xcomplex<f64>>) -> f64
  %lf = llvm.mlir.addressof @h_fid : !llvm.ptr
  func.call @print_f64(%lf, %fid) : (!llvm.ptr, f64) -> ()
  %tol6 = arith.constant 1.0e-6 : f64
  %gd = arith.cmpf olt, %fid, %tol6 : f64
  %gd64 = arith.extui %gd : i1 to i64
  %lgd = llvm.mlir.addressof @h_gd : !llvm.ptr
  func.call @print_i64(%lgd, %gd64) : (!llvm.ptr, i64) -> ()
  %acc = memref.alloc(%one_i) : memref<?xindex>
  memref.store %c0, %acc[%c0] : memref<?xindex>
  %rho1 = func.call @sv_partial_trace(%psi1, %nq, %acc) : (memref<?xcomplex<f64>>, index, memref<?xindex>) -> memref<?x?xcomplex<f64>>
  %rho2 = func.call @sv_partial_trace(%psi2, %nq, %acc) : (memref<?xcomplex<f64>>, index, memref<?xindex>) -> memref<?x?xcomplex<f64>>
  %td = func.call @trace_distance_bound(%rho1, %rho2) : (memref<?x?xcomplex<f64>>, memref<?x?xcomplex<f64>>) -> f64
  %ltd = llvm.mlir.addressof @h_td : !llvm.ptr
  func.call @print_f64(%ltd, %td) : (!llvm.ptr, f64) -> ()
  %tol4 = arith.constant 1.0e-4 : f64
  %sd = arith.cmpf ogt, %td, %tol4 : f64
  %sd64 = arith.extui %sd : i1 to i64
  %lsd = llvm.mlir.addressof @h_sd : !llvm.ptr
  func.call @print_i64(%lsd, %sd64) : (!llvm.ptr, i64) -> ()
  %r100 = memref.load %rho1[%c0, %c0] : memref<?x?xcomplex<f64>>
  %r111 = memref.load %rho1[%one_i, %one_i] : memref<?x?xcomplex<f64>>
  %r200 = memref.load %rho2[%c0, %c0] : memref<?x?xcomplex<f64>>
  %r211 = memref.load %rho2[%one_i, %one_i] : memref<?x?xcomplex<f64>>
  %r101 = memref.load %rho1[%c0, %one_i] : memref<?x?xcomplex<f64>>
  %p10 = complex.re %r100 : complex<f64>
  %p11 = complex.re %r111 : complex<f64>
  %p20 = complex.re %r200 : complex<f64>
  %p21 = complex.re %r211 : complex<f64>
  %o01 = complex.re %r101 : complex<f64>
  %l1 = llvm.mlir.addressof @h_p10 : !llvm.ptr
  %l2 = llvm.mlir.addressof @h_p11 : !llvm.ptr
  %l3 = llvm.mlir.addressof @h_p20 : !llvm.ptr
  %l4 = llvm.mlir.addressof @h_p21 : !llvm.ptr
  %l5 = llvm.mlir.addressof @h_rho01 : !llvm.ptr
  func.call @print_f64(%l1, %p10) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%l2, %p11) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%l3, %p20) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%l4, %p21) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%l5, %o01) : (!llvm.ptr, f64) -> ()
  return
}

func.func @roundtrip7() {
  %t = llvm.mlir.addressof @h_t2 : !llvm.ptr
  %b0 = func.call @s_new() : () -> memref<?xi8>
  %c0 = arith.constant 0 : index
  %lt = func.call @s_cstr(%b0, %c0, %t) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @s_print(%b0, %lt) : (memref<?xi8>, index) -> ()
  %nq = arith.constant 11 : index
  %i7 = arith.constant 7 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %c4 = arith.constant 4 : index
  %c5 = arith.constant 5 : index
  %c6 = arith.constant 6 : index
  %c10 = arith.constant 10 : index
  %seven = arith.constant 7 : index
  %true = arith.constant true
  %st = func.call @sv_basis(%nq, %i7) : (index, index) -> memref<?xcomplex<f64>>
  %orig = func.call @sv_copy(%st) : (memref<?xcomplex<f64>>) -> memref<?xcomplex<f64>>
  // H0, CNOT0-1, S1, CNOT1-5, H5, CNOT5-10, X10
  %circ = memref.alloc(%seven) : memref<?x3xindex>
  func.call @set_gate(%circ, %c0, %c0, %c0, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @set_gate(%circ, %c1, %c6, %c0, %c1) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @set_gate(%circ, %c2, %c4, %c1, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @set_gate(%circ, %c3, %c6, %c1, %c5) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @set_gate(%circ, %c4, %c0, %c5, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @set_gate(%circ, %c5, %c6, %c5, %c10) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @set_gate(%circ, %c6, %c1, %c10, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  %fw = func.call @sv_evolve(%st, %nq, %circ) : (memref<?xcomplex<f64>>, index, memref<?x3xindex>) -> memref<?xcomplex<f64>>
  %fmt = llvm.mlir.addressof @h_fmt_amp : !llvm.ptr
  %dim = memref.dim %fw, %c0 : memref<?xcomplex<f64>>
  %z = arith.constant 0.0 : f64
  scf.for %i = %c0 to %dim step %c1 {
    %a = memref.load %fw[%i] : memref<?xcomplex<f64>>
    %re = complex.re %a : complex<f64>
    %im = complex.im %a : complex<f64>
    %rz = arith.cmpf oeq, %re, %z : f64
    %iz = arith.cmpf oeq, %im, %z : f64
    %bz = arith.andi %rz, %iz : i1
    %nz = arith.xori %bz, %true : i1
    scf.if %nz {
      %i64 = arith.index_cast %i : index to i64
      %rb = arith.bitcast %re : f64 to i64
      %ib = arith.bitcast %im : f64 to i64
      %x = llvm.call @printf(%fmt, %i64, %re, %im, %rb, %ib) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, i64, f64, f64, i64, i64) -> i32
    }
  }
  %n = func.call @sv_norm2(%fw) : (memref<?xcomplex<f64>>) -> f64
  %ln = llvm.mlir.addressof @h_fn : !llvm.ptr
  func.call @print_f64(%ln, %n) : (!llvm.ptr, f64) -> ()
  %ff = func.call @sv_fidelity(%orig, %fw) : (memref<?xcomplex<f64>>, memref<?xcomplex<f64>>) -> f64
  %lff = llvm.mlir.addressof @h_ff : !llvm.ptr
  func.call @print_f64(%lff, %ff) : (!llvm.ptr, f64) -> ()
  %bk = func.call @sv_evolve_inverse(%fw, %nq, %circ) : (memref<?xcomplex<f64>>, index, memref<?x3xindex>) -> memref<?xcomplex<f64>>
  %bf = func.call @sv_fidelity(%orig, %bk) : (memref<?xcomplex<f64>>, memref<?xcomplex<f64>>) -> f64
  %lbf = llvm.mlir.addressof @h_bf : !llvm.ptr
  func.call @print_f64(%lbf, %bf) : (!llvm.ptr, f64) -> ()
  return
}

func.func @main() -> i32 {
  func.call @adversarial() : () -> ()
  func.call @roundtrip7() : () -> ()
  %r = arith.constant 0 : i32
  return %r : i32
}
