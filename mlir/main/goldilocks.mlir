// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// main/goldilocks.mlir — prints the same lines as the Goldilocks section of
// j/demo.ijs (J integers, booleans as 1/0) so the outputs diff directly.

llvm.mlir.global internal constant @g_title("== goldilocks\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_p("p\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_add("add\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_sub("sub\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_subr("sub_rev\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_mul("mul\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_mre("mul_ref_equal\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_pm1("mul_pm1_sq\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_pow("pow_7_100\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_inv("inv_a\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_ainv("a_times_inv_a\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_ferm("fermat_a\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_fold("fold_vs_ref_200\00") {addr_space = 0 : i32}

func.func @line(%label: !llvm.ptr, %v: i64) {
  %c0 = arith.constant 0 : index
  %sp = arith.constant 32 : i8
  %b = func.call @s_new() : () -> memref<?xi8>
  %l1 = func.call @s_cstr(%b, %c0, %label) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_byte(%b, %l1, %sp) : (memref<?xi8>, index, i8) -> index
  %l3 = func.call @s_uint(%b, %l2, %v) : (memref<?xi8>, index, i64) -> index
  func.call @s_print(%b, %l3) : (memref<?xi8>, index) -> ()
  return
}

func.func @main() -> i32 {
  %c0 = arith.constant 0 : index
  %t = llvm.mlir.addressof @g_title : !llvm.ptr
  %tb = func.call @s_new() : () -> memref<?xi8>
  %tl = func.call @s_cstr(%tb, %c0, %t) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @s_print(%tb, %tl) : (memref<?xi8>, index) -> ()
  %p = func.call @gl_p() : () -> i64
  // a = 12345678901234567890, b = 9876543210987654321 (both < p)
  %a = arith.constant 0xAB54A98CEB1F0AD2 : i64
  %b = arith.constant 0x891087B8E3B70CB1 : i64
  %one = arith.constant 1 : i64
  %l = llvm.mlir.addressof @g_p : !llvm.ptr
  func.call @line(%l, %p) : (!llvm.ptr, i64) -> ()
  %ad = func.call @gl_add(%a, %b) : (i64, i64) -> i64
  %l1 = llvm.mlir.addressof @g_add : !llvm.ptr
  func.call @line(%l1, %ad) : (!llvm.ptr, i64) -> ()
  %sb = func.call @gl_sub(%a, %b) : (i64, i64) -> i64
  %l2 = llvm.mlir.addressof @g_sub : !llvm.ptr
  func.call @line(%l2, %sb) : (!llvm.ptr, i64) -> ()
  %sr = func.call @gl_sub(%b, %a) : (i64, i64) -> i64
  %l3 = llvm.mlir.addressof @g_subr : !llvm.ptr
  func.call @line(%l3, %sr) : (!llvm.ptr, i64) -> ()
  %ml = func.call @gl_mul(%a, %b) : (i64, i64) -> i64
  %l4 = llvm.mlir.addressof @g_mul : !llvm.ptr
  func.call @line(%l4, %ml) : (!llvm.ptr, i64) -> ()
  %mr = func.call @gl_mul_ref(%a, %b) : (i64, i64) -> i64
  %eq = arith.cmpi eq, %ml, %mr : i64
  %eq64 = arith.extui %eq : i1 to i64
  %l5 = llvm.mlir.addressof @g_mre : !llvm.ptr
  func.call @line(%l5, %eq64) : (!llvm.ptr, i64) -> ()
  %pm1 = arith.subi %p, %one : i64
  %sq = func.call @gl_mul(%pm1, %pm1) : (i64, i64) -> i64
  %l6 = llvm.mlir.addressof @g_pm1 : !llvm.ptr
  func.call @line(%l6, %sq) : (!llvm.ptr, i64) -> ()
  %seven = arith.constant 7 : i64
  %hundred = arith.constant 100 : i64
  %pw = func.call @gl_pow(%seven, %hundred) : (i64, i64) -> i64
  %l7 = llvm.mlir.addressof @g_pow : !llvm.ptr
  func.call @line(%l7, %pw) : (!llvm.ptr, i64) -> ()
  %inv = func.call @gl_inv(%a) : (i64) -> i64
  %l8 = llvm.mlir.addressof @g_inv : !llvm.ptr
  func.call @line(%l8, %inv) : (!llvm.ptr, i64) -> ()
  %ai = func.call @gl_mul(%a, %inv) : (i64, i64) -> i64
  %l9 = llvm.mlir.addressof @g_ainv : !llvm.ptr
  func.call @line(%l9, %ai) : (!llvm.ptr, i64) -> ()
  %fe = func.call @gl_pow(%a, %pm1) : (i64, i64) -> i64
  %l10 = llvm.mlir.addressof @g_ferm : !llvm.ptr
  func.call @line(%l10, %fe) : (!llvm.ptr, i64) -> ()
  // s_i = (6364136223846793005 * (i+1)) mod p, i < 200; fold(s_i, s_{199-i}) = ref
  %c1 = arith.constant 1 : index
  %c200 = arith.constant 200 : index
  %c199 = arith.constant 199 : index
  %mult = arith.constant 6364136223846793005 : i128
  %p2 = arith.extui %p : i64 to i128
  %true = arith.constant true
  %all = scf.for %i = %c0 to %c200 step %c1 iter_args(%acc = %true) -> (i1) {
    %j = arith.subi %c199, %i : index
    %i1 = arith.addi %i, %c1 : index
    %j1 = arith.addi %j, %c1 : index
    %ii = arith.index_cast %i1 : index to i128
    %jj = arith.index_cast %j1 : index to i128
    %si0 = arith.muli %mult, %ii : i128
    %sj0 = arith.muli %mult, %jj : i128
    %si1 = arith.remui %si0, %p2 : i128
    %sj1 = arith.remui %sj0, %p2 : i128
    %si = arith.trunci %si1 : i128 to i64
    %sj = arith.trunci %sj1 : i128 to i64
    %f = func.call @gl_mul(%si, %sj) : (i64, i64) -> i64
    %r = func.call @gl_mul_ref(%si, %sj) : (i64, i64) -> i64
    %e = arith.cmpi eq, %f, %r : i64
    %n = arith.andi %acc, %e : i1
    scf.yield %n : i1
  }
  %all64 = arith.extui %all : i1 to i64
  %l11 = llvm.mlir.addressof @g_fold : !llvm.ptr
  func.call @line(%l11, %all64) : (!llvm.ptr, i64) -> ()
  %rc = arith.constant 0 : i32
  return %rc : i32
}
