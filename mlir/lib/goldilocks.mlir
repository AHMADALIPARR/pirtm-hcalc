// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// goldilocks.mlir — Goldilocks field F_p, p = 2^64 - 2^32 + 1, on i64
// (unsigned). gl_mul uses the fold 2^64 = 2^32 - 1, 2^96 = -1 (mod p):
//   a*b = hi*2^64 + lo, hi = hh*2^32 + hl  =>  a*b = lo + hl*(2^32-1) - hh.
// gl_mul_ref is (a*b) mod p by i128 remainder, used to check the fold.

func.func @gl_p() -> i64 {
  %p = arith.constant 0xFFFFFFFF00000001 : i64
  return %p : i64
}

func.func @gl_add(%a: i64, %b: i64) -> i64 {
  %p = func.call @gl_p() : () -> i64
  %a2 = arith.extui %a : i64 to i128
  %b2 = arith.extui %b : i64 to i128
  %p2 = arith.extui %p : i64 to i128
  %s = arith.addi %a2, %b2 : i128
  %ge = arith.cmpi uge, %s, %p2 : i128
  %d = arith.subi %s, %p2 : i128
  %r = arith.select %ge, %d, %s : i128
  %o = arith.trunci %r : i128 to i64
  return %o : i64
}

func.func @gl_sub(%a: i64, %b: i64) -> i64 {
  %p = func.call @gl_p() : () -> i64
  %lt = arith.cmpi ult, %a, %b : i64
  %d = arith.subi %a, %b : i64
  %dp = arith.addi %d, %p : i64
  %r = arith.select %lt, %dp, %d : i64
  return %r : i64
}

func.func @gl_mul(%a: i64, %b: i64) -> i64 {
  %p = func.call @gl_p() : () -> i64
  %a2 = arith.extui %a : i64 to i128
  %b2 = arith.extui %b : i64 to i128
  %t = arith.muli %a2, %b2 : i128
  %c64 = arith.constant 64 : i128
  %c32 = arith.constant 32 : i128
  %m64 = arith.constant 0xFFFFFFFFFFFFFFFF : i128
  %m32 = arith.constant 0xFFFFFFFF : i128
  %lo = arith.andi %t, %m64 : i128
  %hi = arith.shrui %t, %c64 : i128
  %hl = arith.andi %hi, %m32 : i128
  %hh = arith.shrui %hi, %c32 : i128
  %epsf = arith.constant 4294967295 : i128
  %f0 = arith.muli %hl, %epsf : i128
  %f = arith.addi %lo, %f0 : i128
  %p2 = arith.extui %p : i64 to i128
  %r0 = arith.subi %f, %hh : i128
  %z = arith.constant 0 : i128
  %neg = arith.cmpi slt, %r0, %z : i128
  %r0p = arith.addi %r0, %p2 : i128
  %r1 = arith.select %neg, %r0p, %r0 : i128
  %r = scf.while (%x = %r1) : (i128) -> i128 {
    %ge = arith.cmpi uge, %x, %p2 : i128
    scf.condition(%ge) %x : i128
  } do {
  ^bb0(%x: i128):
    %y = arith.subi %x, %p2 : i128
    scf.yield %y : i128
  }
  %o = arith.trunci %r : i128 to i64
  return %o : i64
}

func.func @gl_mul_ref(%a: i64, %b: i64) -> i64 {
  %p = func.call @gl_p() : () -> i64
  %a2 = arith.extui %a : i64 to i128
  %b2 = arith.extui %b : i64 to i128
  %p2 = arith.extui %p : i64 to i128
  %t = arith.muli %a2, %b2 : i128
  %r = arith.remui %t, %p2 : i128
  %o = arith.trunci %r : i128 to i64
  return %o : i64
}

func.func @gl_pow(%a: i64, %e: i64) -> i64 {
  %one = arith.constant 1 : i64
  %zero = arith.constant 0 : i64
  %r:3 = scf.while (%res = %one, %b = %a, %k = %e) : (i64, i64, i64) -> (i64, i64, i64) {
    %go = arith.cmpi ne, %k, %zero : i64
    scf.condition(%go) %res, %b, %k : i64, i64, i64
  } do {
  ^bb0(%res: i64, %b: i64, %k: i64):
    %bit = arith.andi %k, %one : i64
    %odd = arith.cmpi ne, %bit, %zero : i64
    %m = func.call @gl_mul(%res, %b) : (i64, i64) -> i64
    %nres = arith.select %odd, %m, %res : i64
    %nb = func.call @gl_mul(%b, %b) : (i64, i64) -> i64
    %nk = arith.shrui %k, %one : i64
    scf.yield %nres, %nb, %nk : i64, i64, i64
  }
  return %r#0 : i64
}

func.func @gl_inv(%a: i64) -> i64 {
  %p = func.call @gl_p() : () -> i64
  %two = arith.constant 2 : i64
  %e = arith.subi %p, %two : i64
  %r = func.call @gl_pow(%a, %e) : (i64, i64) -> i64
  return %r : i64
}
