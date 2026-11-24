// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// custom/pirtm_roundtrip.mlir — PIRTM test_11qubit_reversible_roundtrip written
// with `pirtm` dialect ops (H0, CNOT0-1, S1, CNOT1-5, H5, CNOT5-10, X10 on |7>),
// plus SHA-256("abc"). Every printed line must appear in the Python-derived
// expected files logs/reference/expected/{hilbert11,oracle}.txt.

llvm.mlir.global internal constant @r_fn("forward_norm_squared\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @r_ff("forward_fidelity_vs_initial\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @r_bf("roundtrip_fidelity\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @r_sha("sha256 \00") {addr_space = 0 : i32}

func.func @main() -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %c4 = arith.constant 4 : index
  %c5 = arith.constant 5 : index
  %c6 = arith.constant 6 : index
  %c7 = arith.constant 7 : index
  %c10 = arith.constant 10 : index
  %nq = arith.constant 11 : index
  %st = "pirtm.basis"(%nq, %c7) : (index, index) -> memref<?xcomplex<f64>>
  %orig = "pirtm.copy"(%st) : (memref<?xcomplex<f64>>) -> memref<?xcomplex<f64>>
  // opcodes: H 0, X 1, Y 2, Z 3, S 4, Sdg 5, CNOT 6
  %circ = "pirtm.circuit"(%c7) : (index) -> memref<?x3xindex>
  "pirtm.gate"(%circ, %c0, %c0, %c0, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  "pirtm.gate"(%circ, %c1, %c6, %c0, %c1) : (memref<?x3xindex>, index, index, index, index) -> ()
  "pirtm.gate"(%circ, %c2, %c4, %c1, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  "pirtm.gate"(%circ, %c3, %c6, %c1, %c5) : (memref<?x3xindex>, index, index, index, index) -> ()
  "pirtm.gate"(%circ, %c4, %c0, %c5, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  "pirtm.gate"(%circ, %c5, %c6, %c5, %c10) : (memref<?x3xindex>, index, index, index, index) -> ()
  "pirtm.gate"(%circ, %c6, %c1, %c10, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  %fw = "pirtm.evolve"(%st, %nq, %circ) : (memref<?xcomplex<f64>>, index, memref<?x3xindex>) -> memref<?xcomplex<f64>>
  %n = "pirtm.norm2"(%fw) : (memref<?xcomplex<f64>>) -> f64
  %ln = llvm.mlir.addressof @r_fn : !llvm.ptr
  func.call @print_f64(%ln, %n) : (!llvm.ptr, f64) -> ()
  %ff = "pirtm.fidelity"(%orig, %fw) : (memref<?xcomplex<f64>>, memref<?xcomplex<f64>>) -> f64
  %lff = llvm.mlir.addressof @r_ff : !llvm.ptr
  func.call @print_f64(%lff, %ff) : (!llvm.ptr, f64) -> ()
  %bk = "pirtm.evolve_inverse"(%fw, %nq, %circ) : (memref<?xcomplex<f64>>, index, memref<?x3xindex>) -> memref<?xcomplex<f64>>
  %bf = "pirtm.fidelity"(%orig, %bk) : (memref<?xcomplex<f64>>, memref<?xcomplex<f64>>) -> f64
  %lbf = llvm.mlir.addressof @r_bf : !llvm.ptr
  func.call @print_f64(%lbf, %bf) : (!llvm.ptr, f64) -> ()
  // SHA-256("abc")
  %msg = memref.alloc(%c3) : memref<?xi8>
  %ca = arith.constant 97 : i8
  %cb = arith.constant 98 : i8
  %cc = arith.constant 99 : i8
  memref.store %ca, %msg[%c0] : memref<?xi8>
  memref.store %cb, %msg[%c1] : memref<?xi8>
  memref.store %cc, %msg[%c2] : memref<?xi8>
  %dg = memref.alloc() : memref<8xi32>
  "pirtm.sha256"(%msg, %c3, %dg) : (memref<?xi8>, index, memref<8xi32>) -> ()
  %b = func.call @s_new() : () -> memref<?xi8>
  %lsha = llvm.mlir.addressof @r_sha : !llvm.ptr
  %l0 = func.call @s_cstr(%b, %c0, %lsha) : (memref<?xi8>, index, !llvm.ptr) -> index
  %c64 = arith.constant 64 : index
  %l1 = func.call @s_hex(%b, %l0, %dg, %c64) : (memref<?xi8>, index, memref<8xi32>, index) -> index
  func.call @s_print(%b, %l1) : (memref<?xi8>, index) -> ()
  %ret = arith.constant 0 : i32
  return %ret : i32
}
