// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// jfmt.mlir — print "<label> v0 v1 ..." with J number display (17 digits),
// so outputs diff directly against jconsole output.

func.func @j_print_vec(%label: !llvm.ptr, %v: memref<?xf64>) {
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

func.func @j_print_num(%label: !llvm.ptr, %x: f64) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %v = memref.alloc(%c1) : memref<?xf64>
  memref.store %x, %v[%c0] : memref<?xf64>
  func.call @j_print_vec(%label, %v) : (!llvm.ptr, memref<?xf64>) -> ()
  return
}

// J displays an extended integer in plain decimal
func.func @j_print_u64(%label: !llvm.ptr, %x: i64) {
  %c0 = arith.constant 0 : index
  %sp = arith.constant 32 : i8
  %b = func.call @s_new() : () -> memref<?xi8>
  %l0 = func.call @s_cstr(%b, %c0, %label) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l1 = func.call @s_byte(%b, %l0, %sp) : (memref<?xi8>, index, i8) -> index
  %l2 = func.call @s_uint(%b, %l1, %x) : (memref<?xi8>, index, i64) -> index
  func.call @s_print(%b, %l2) : (memref<?xi8>, index) -> ()
  return
}
