// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// main/quantum.mlir — port of tests/test_quantum.py on top of lib/qmat.mlir.

llvm.mlir.global internal constant @q_t("== quantum: gates.py / circuit.py tests\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_u("is_unitary[H,X,Y,Z,S,T,CNOT,HxX]\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_bu("bell_to_unitary_is_unitary\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_bn("bell_norm_squared\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_ba("bell_amp0_re\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_p0("bell_prob0\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_p1("bell_prob1\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_p2("bell_prob2\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_p3("bell_prob3\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_xx("xx_00_re,xx_01_re,xx_10_re,xx_11_re\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_hx("hxx_rows\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_s1("bell_sample(r=0.3)\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_s2("bell_sample(r=0.7)\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_cr1("classical_after_not1\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_cr2("classical_after_toffoli012\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_crc("classical_cnot02_from_110\00") {addr_space = 0 : i32}

func.func @bit64(%b: i1) -> i64 {
  %r = arith.extui %b : i1 to i64
  return %r : i64
}

func.func @main() -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %c4 = arith.constant 4 : index
  %c5 = arith.constant 5 : index
  %c6 = arith.constant 6 : index
  %c7 = arith.constant 7 : index
  %tol = arith.constant 1.0e-9 : f64
  %t = llvm.mlir.addressof @q_t : !llvm.ptr
  %b = func.call @s_new() : () -> memref<?xi8>
  %l0 = func.call @s_cstr(%b, %c0, %t) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @s_print(%b, %l0) : (memref<?xi8>, index) -> ()
  // unitarity bitmask: bit i set iff gate i passes
  %mH = func.call @gate_matrix(%c0) : (index) -> memref<?x?xcomplex<f64>>
  %mX = func.call @gate_matrix(%c1) : (index) -> memref<?x?xcomplex<f64>>
  %mY = func.call @gate_matrix(%c2) : (index) -> memref<?x?xcomplex<f64>>
  %mZ = func.call @gate_matrix(%c3) : (index) -> memref<?x?xcomplex<f64>>
  %mS = func.call @gate_matrix(%c4) : (index) -> memref<?x?xcomplex<f64>>
  %mT = func.call @gate_matrix(%c7) : (index) -> memref<?x?xcomplex<f64>>
  %mC = func.call @gate_matrix(%c6) : (index) -> memref<?x?xcomplex<f64>>
  %mHX = func.call @mat_tensor(%mH, %mX) : (memref<?x?xcomplex<f64>>, memref<?x?xcomplex<f64>>) -> memref<?x?xcomplex<f64>>
  %u0 = func.call @mat_is_unitary(%mH, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  %u1 = func.call @mat_is_unitary(%mX, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  %u2 = func.call @mat_is_unitary(%mY, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  %u3 = func.call @mat_is_unitary(%mZ, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  %u4 = func.call @mat_is_unitary(%mS, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  %u5 = func.call @mat_is_unitary(%mT, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  %u6 = func.call @mat_is_unitary(%mC, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  %u7 = func.call @mat_is_unitary(%mHX, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  // print as decimal string of 8 digits 0/1
  %lu = llvm.mlir.addressof @q_u : !llvm.ptr
  %l1 = func.call @s_cstr(%b, %c0, %lu) : (memref<?xi8>, index, !llvm.ptr) -> index
  %eqs = arith.constant 61 : i8
  %sp = arith.constant 32 : i8
  %l2 = func.call @s_byte(%b, %l1, %sp) : (memref<?xi8>, index, i8) -> index
  %l3 = func.call @s_byte(%b, %l2, %eqs) : (memref<?xi8>, index, i8) -> index
  %l4 = func.call @s_byte(%b, %l3, %sp) : (memref<?xi8>, index, i8) -> index
  %l5 = func.call @s_bool(%b, %l4, %u0) : (memref<?xi8>, index, i1) -> index
  %l6 = func.call @s_byte(%b, %l5, %sp) : (memref<?xi8>, index, i8) -> index
  %l7 = func.call @s_bool(%b, %l6, %u1) : (memref<?xi8>, index, i1) -> index
  %l8 = func.call @s_byte(%b, %l7, %sp) : (memref<?xi8>, index, i8) -> index
  %l9 = func.call @s_bool(%b, %l8, %u2) : (memref<?xi8>, index, i1) -> index
  %l10 = func.call @s_byte(%b, %l9, %sp) : (memref<?xi8>, index, i8) -> index
  %l11 = func.call @s_bool(%b, %l10, %u3) : (memref<?xi8>, index, i1) -> index
  %l12 = func.call @s_byte(%b, %l11, %sp) : (memref<?xi8>, index, i8) -> index
  %l13 = func.call @s_bool(%b, %l12, %u4) : (memref<?xi8>, index, i1) -> index
  %l14 = func.call @s_byte(%b, %l13, %sp) : (memref<?xi8>, index, i8) -> index
  %l15 = func.call @s_bool(%b, %l14, %u5) : (memref<?xi8>, index, i1) -> index
  %l16 = func.call @s_byte(%b, %l15, %sp) : (memref<?xi8>, index, i8) -> index
  %l17 = func.call @s_bool(%b, %l16, %u6) : (memref<?xi8>, index, i1) -> index
  %l18 = func.call @s_byte(%b, %l17, %sp) : (memref<?xi8>, index, i8) -> index
  %l19 = func.call @s_bool(%b, %l18, %u7) : (memref<?xi8>, index, i1) -> index
  func.call @s_print(%b, %l19) : (memref<?xi8>, index) -> ()
  // H (x) X shape
  %hr = memref.dim %mHX, %c0 : memref<?x?xcomplex<f64>>
  %hr64 = arith.index_cast %hr : index to i64
  %lhx = llvm.mlir.addressof @q_hx : !llvm.ptr
  func.call @print_i64(%lhx, %hr64) : (!llvm.ptr, i64) -> ()
  // X * X = I
  %xx = func.call @mat_mult(%mX, %mX) : (memref<?x?xcomplex<f64>>, memref<?x?xcomplex<f64>>) -> memref<?x?xcomplex<f64>>
  %x00 = memref.load %xx[%c0, %c0] : memref<?x?xcomplex<f64>>
  %x01 = memref.load %xx[%c0, %c1] : memref<?x?xcomplex<f64>>
  %x10 = memref.load %xx[%c1, %c0] : memref<?x?xcomplex<f64>>
  %x11 = memref.load %xx[%c1, %c1] : memref<?x?xcomplex<f64>>
  %r00 = complex.re %x00 : complex<f64>
  %r01 = complex.re %x01 : complex<f64>
  %r10 = complex.re %x10 : complex<f64>
  %r11 = complex.re %x11 : complex<f64>
  %lxx = llvm.mlir.addressof @q_xx : !llvm.ptr
  func.call @print_f64(%lxx, %r00) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%lxx, %r01) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%lxx, %r10) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%lxx, %r11) : (!llvm.ptr, f64) -> ()
  // Bell circuit: H(0), CNOT(0,1) on 2 qubits
  %circ = memref.alloc(%c2) : memref<?x3xindex>
  func.call @set_gate(%circ, %c0, %c0, %c0, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @set_gate(%circ, %c1, %c6, %c0, %c1) : (memref<?x3xindex>, index, index, index, index) -> ()
  %u = func.call @qc_to_unitary(%c2, %circ) : (index, memref<?x3xindex>) -> memref<?x?xcomplex<f64>>
  %uu = func.call @mat_is_unitary(%u, %tol) : (memref<?x?xcomplex<f64>>, f64) -> i1
  %uu64 = func.call @bit64(%uu) : (i1) -> i64
  %lbu = llvm.mlir.addressof @q_bu : !llvm.ptr
  func.call @print_i64(%lbu, %uu64) : (!llvm.ptr, i64) -> ()
  %init = func.call @sv_basis(%c2, %c0) : (index, index) -> memref<?xcomplex<f64>>
  %out = func.call @qc_run(%c2, %circ, %init) : (index, memref<?x3xindex>, memref<?xcomplex<f64>>) -> memref<?xcomplex<f64>>
  %bn = func.call @sv_norm2(%out) : (memref<?xcomplex<f64>>) -> f64
  %lbn = llvm.mlir.addressof @q_bn : !llvm.ptr
  func.call @print_f64(%lbn, %bn) : (!llvm.ptr, f64) -> ()
  %a0 = memref.load %out[%c0] : memref<?xcomplex<f64>>
  %a0r = complex.re %a0 : complex<f64>
  %lba = llvm.mlir.addressof @q_ba : !llvm.ptr
  func.call @print_f64(%lba, %a0r) : (!llvm.ptr, f64) -> ()
  %pr = func.call @qs_probabilities(%out) : (memref<?xcomplex<f64>>) -> memref<?xf64>
  %p0 = memref.load %pr[%c0] : memref<?xf64>
  %p1 = memref.load %pr[%c1] : memref<?xf64>
  %p2 = memref.load %pr[%c2] : memref<?xf64>
  %p3 = memref.load %pr[%c3] : memref<?xf64>
  %lp0 = llvm.mlir.addressof @q_p0 : !llvm.ptr
  %lp1 = llvm.mlir.addressof @q_p1 : !llvm.ptr
  %lp2 = llvm.mlir.addressof @q_p2 : !llvm.ptr
  %lp3 = llvm.mlir.addressof @q_p3 : !llvm.ptr
  func.call @print_f64(%lp0, %p0) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%lp1, %p1) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%lp2, %p2) : (!llvm.ptr, f64) -> ()
  func.call @print_f64(%lp3, %p3) : (!llvm.ptr, f64) -> ()
  %r3 = arith.constant 0.3 : f64
  %r7 = arith.constant 0.7 : f64
  %sm1 = func.call @qs_sample(%out, %r3) : (memref<?xcomplex<f64>>, f64) -> index
  %sm2 = func.call @qs_sample(%out, %r7) : (memref<?xcomplex<f64>>, f64) -> index
  %sm1i = arith.index_cast %sm1 : index to i64
  %sm2i = arith.index_cast %sm2 : index to i64
  %ls1 = llvm.mlir.addressof @q_s1 : !llvm.ptr
  %ls2 = llvm.mlir.addressof @q_s2 : !llvm.ptr
  func.call @print_i64(%ls1, %sm1i) : (!llvm.ptr, i64) -> ()
  func.call @print_i64(%ls2, %sm2i) : (!llvm.ptr, i64) -> ()
  // classical reversible baseline: "101" -> not(1) -> toffoli(0,1,2)
  %bits = memref.alloc(%c3) : memref<?xi8>
  %one8 = arith.constant 1 : i8
  %zero8 = arith.constant 0 : i8
  memref.store %one8, %bits[%c0] : memref<?xi8>
  memref.store %zero8, %bits[%c1] : memref<?xi8>
  memref.store %one8, %bits[%c2] : memref<?xi8>
  func.call @cr_not(%bits, %c1) : (memref<?xi8>, index) -> ()
  %v1 = func.call @cr_state_int(%bits) : (memref<?xi8>) -> i64
  %lc1 = llvm.mlir.addressof @q_cr1 : !llvm.ptr
  func.call @print_i64(%lc1, %v1) : (!llvm.ptr, i64) -> ()
  func.call @cr_toffoli(%bits, %c0, %c1, %c2) : (memref<?xi8>, index, index, index) -> ()
  %v2 = func.call @cr_state_int(%bits) : (memref<?xi8>) -> i64
  %lc2 = llvm.mlir.addressof @q_cr2 : !llvm.ptr
  func.call @print_i64(%lc2, %v2) : (!llvm.ptr, i64) -> ()
  func.call @cr_cnot(%bits, %c0, %c2) : (memref<?xi8>, index, index) -> ()
  %v3 = func.call @cr_state_int(%bits) : (memref<?xi8>) -> i64
  %lc3 = llvm.mlir.addressof @q_crc : !llvm.ptr
  func.call @print_i64(%lc3, %v3) : (!llvm.ptr, i64) -> ()
  %r = arith.constant 0 : i32
  return %r : i32
}
