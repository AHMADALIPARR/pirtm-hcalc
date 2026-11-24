// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// sha256.mlir — FIPS 180-4 SHA-256 over a byte buffer (port of hashlib.sha256
// as used by PIRTM's CAS, hypothesis ids and evidence dedup).

memref.global "private" constant @sha_k : memref<64xi32> = dense<[
  1116352408, 1899447441, -1245643825, -373957723, 961987163, 1508970993, -1841331548, -1424204075,
  -670586216, 310598401, 607225278, 1426881987, 1925078388, -2132889090, -1680079193, -1046744716,
  -459576895, -272742522, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986,
  -1740746414, -1473132947, -1341970488, -1084653625, -958395405, -710438585, 113926993, 338241895,
  666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, -2117940946, -1838011259,
  -1564481375, -1474664885, -1035236496, -949202525, -778901479, -694614492, -200395387, 275423344,
  430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779,
  1955562222, 2024104815, -2067236844, -1933114872, -1866530822, -1538233109, -1090935817, -965641998]>

memref.global "private" constant @sha_h0 : memref<8xi32> = dense<[
  1779033703, -1150833019, 1013904242, -1521486534, 1359893119, -1694144372, 528734635, 1541459225]>

func.func @rotr(%x: i32, %n: i32) -> i32 {
  %c32 = arith.constant 32 : i32
  %a = arith.shrui %x, %n : i32
  %m = arith.subi %c32, %n : i32
  %b = arith.shli %x, %m : i32
  %r = arith.ori %a, %b : i32
  return %r : i32
}

// digest of msg[0..n) into out (8 big-endian words)
func.func @sha256(%msg: memref<?xi8>, %n: index, %out: memref<8xi32>) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c4 = arith.constant 4 : index
  %c8 = arith.constant 8 : index
  %c9 = arith.constant 9 : index
  %c16 = arith.constant 16 : index
  %c64 = arith.constant 64 : index
  %c63 = arith.constant 63 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %c5 = arith.constant 5 : index
  %c6 = arith.constant 6 : index
  %c7 = arith.constant 7 : index
  %c15 = arith.constant 15 : index
  %c8_64 = arith.constant 8 : i64
  // padded length = ceil((n + 9) / 64) * 64
  %t0 = arith.addi %n, %c9 : index
  %t1 = arith.addi %t0, %c63 : index
  %nb = arith.divui %t1, %c64 : index
  %plen = arith.muli %nb, %c64 : index
  %pad = memref.alloc(%plen) : memref<?xi8>
  %z8 = arith.constant 0 : i8
  scf.for %i = %c0 to %plen step %c1 {
    memref.store %z8, %pad[%i] : memref<?xi8>
  }
  scf.for %i = %c0 to %n step %c1 {
    %ch = memref.load %msg[%i] : memref<?xi8>
    memref.store %ch, %pad[%i] : memref<?xi8>
  }
  %x80 = arith.constant -128 : i8
  memref.store %x80, %pad[%n] : memref<?xi8>
  %n64 = arith.index_cast %n : index to i64
  %c3_64 = arith.constant 3 : i64
  %bits = arith.shli %n64, %c3_64 : i64
  scf.for %j = %c0 to %c8 step %c1 {
    // byte j of the big-endian 64-bit length at the end
    %j64 = arith.index_cast %j : index to i64
    %c7i = arith.constant 7 : i64
    %e = arith.subi %c7i, %j64 : i64
    %sh = arith.muli %e, %c8_64 : i64
    %v = arith.shrui %bits, %sh : i64
    %v8 = arith.trunci %v : i64 to i8
    %pos0 = arith.subi %plen, %c8 : index
    %pos = arith.addi %pos0, %j : index
    memref.store %v8, %pad[%pos] : memref<?xi8>
  }
  %k = memref.get_global @sha_k : memref<64xi32>
  %h0 = memref.get_global @sha_h0 : memref<8xi32>
  %h = memref.alloca() : memref<8xi32>
  scf.for %i = %c0 to %c8 step %c1 {
    %v = memref.load %h0[%i] : memref<8xi32>
    memref.store %v, %h[%i] : memref<8xi32>
  }
  %w = memref.alloca() : memref<64xi32>
  %c24 = arith.constant 24 : i32
  %c16_32 = arith.constant 16 : i32
  %c8_32 = arith.constant 8 : i32
  %r2 = arith.constant 2 : i32
  %r6 = arith.constant 6 : i32
  %r7 = arith.constant 7 : i32
  %r11 = arith.constant 11 : i32
  %r13 = arith.constant 13 : i32
  %r17 = arith.constant 17 : i32
  %r18 = arith.constant 18 : i32
  %r19 = arith.constant 19 : i32
  %r22 = arith.constant 22 : i32
  %r25 = arith.constant 25 : i32
  %s3 = arith.constant 3 : i32
  %s10 = arith.constant 10 : i32
  %ones = arith.constant -1 : i32
  scf.for %blk = %c0 to %nb step %c1 {
    %base = arith.muli %blk, %c64 : index
    scf.for %t = %c0 to %c16 step %c1 {
      %o = arith.muli %t, %c4 : index
      %p0 = arith.addi %base, %o : index
      %p1 = arith.addi %p0, %c1 : index
      %p2 = arith.addi %p1, %c1 : index
      %p3 = arith.addi %p2, %c1 : index
      %b0 = memref.load %pad[%p0] : memref<?xi8>
      %b1 = memref.load %pad[%p1] : memref<?xi8>
      %b2 = memref.load %pad[%p2] : memref<?xi8>
      %b3 = memref.load %pad[%p3] : memref<?xi8>
      %e0 = arith.extui %b0 : i8 to i32
      %e1 = arith.extui %b1 : i8 to i32
      %e2 = arith.extui %b2 : i8 to i32
      %e3 = arith.extui %b3 : i8 to i32
      %s0 = arith.shli %e0, %c24 : i32
      %s1 = arith.shli %e1, %c16_32 : i32
      %s2 = arith.shli %e2, %c8_32 : i32
      %o1 = arith.ori %s0, %s1 : i32
      %o2 = arith.ori %o1, %s2 : i32
      %o3 = arith.ori %o2, %e3 : i32
      memref.store %o3, %w[%t] : memref<64xi32>
    }
    scf.for %t = %c16 to %c64 step %c1 {
      %t2 = arith.subi %t, %c2 : index
      %t7 = arith.subi %t, %c7 : index
      %t15 = arith.subi %t, %c15 : index
      %t16 = arith.subi %t, %c16 : index
      %w2 = memref.load %w[%t2] : memref<64xi32>
      %w7 = memref.load %w[%t7] : memref<64xi32>
      %w15 = memref.load %w[%t15] : memref<64xi32>
      %w16 = memref.load %w[%t16] : memref<64xi32>
      %a1 = func.call @rotr(%w15, %r7) : (i32, i32) -> i32
      %a2 = func.call @rotr(%w15, %r18) : (i32, i32) -> i32
      %a3 = arith.shrui %w15, %s3 : i32
      %x1 = arith.xori %a1, %a2 : i32
      %sig0 = arith.xori %x1, %a3 : i32
      %b1 = func.call @rotr(%w2, %r17) : (i32, i32) -> i32
      %b2 = func.call @rotr(%w2, %r19) : (i32, i32) -> i32
      %b3 = arith.shrui %w2, %s10 : i32
      %y1 = arith.xori %b1, %b2 : i32
      %sig1 = arith.xori %y1, %b3 : i32
      %u1 = arith.addi %w16, %sig0 : i32
      %u2 = arith.addi %u1, %w7 : i32
      %u3 = arith.addi %u2, %sig1 : i32
      memref.store %u3, %w[%t] : memref<64xi32>
    }
    %ha = memref.load %h[%c0] : memref<8xi32>
    %hb = memref.load %h[%c1] : memref<8xi32>
    %hc = memref.load %h[%c2] : memref<8xi32>
    %hd = memref.load %h[%c3] : memref<8xi32>
    %he = memref.load %h[%c4] : memref<8xi32>
    %hf = memref.load %h[%c5] : memref<8xi32>
    %hg = memref.load %h[%c6] : memref<8xi32>
    %hh = memref.load %h[%c7] : memref<8xi32>
    %fin:8 = scf.for %t = %c0 to %c64 step %c1
        iter_args(%a = %ha, %b = %hb, %c = %hc, %d = %hd, %e = %he, %f = %hf, %g = %hg, %hv = %hh)
        -> (i32, i32, i32, i32, i32, i32, i32, i32) {
      %e6 = func.call @rotr(%e, %r6) : (i32, i32) -> i32
      %e11 = func.call @rotr(%e, %r11) : (i32, i32) -> i32
      %e25 = func.call @rotr(%e, %r25) : (i32, i32) -> i32
      %ex = arith.xori %e6, %e11 : i32
      %S1 = arith.xori %ex, %e25 : i32
      %ef = arith.andi %e, %f : i32
      %ne = arith.xori %e, %ones : i32
      %neg = arith.andi %ne, %g : i32
      %ch = arith.xori %ef, %neg : i32
      %kt = memref.load %k[%t] : memref<64xi32>
      %wt = memref.load %w[%t] : memref<64xi32>
      %q1 = arith.addi %hv, %S1 : i32
      %q2 = arith.addi %q1, %ch : i32
      %q3 = arith.addi %q2, %kt : i32
      %temp1 = arith.addi %q3, %wt : i32
      %a2 = func.call @rotr(%a, %r2) : (i32, i32) -> i32
      %a13 = func.call @rotr(%a, %r13) : (i32, i32) -> i32
      %a22 = func.call @rotr(%a, %r22) : (i32, i32) -> i32
      %ax = arith.xori %a2, %a13 : i32
      %S0 = arith.xori %ax, %a22 : i32
      %ab = arith.andi %a, %b : i32
      %ac = arith.andi %a, %c : i32
      %bc = arith.andi %b, %c : i32
      %m1 = arith.xori %ab, %ac : i32
      %maj = arith.xori %m1, %bc : i32
      %temp2 = arith.addi %S0, %maj : i32
      %ne2 = arith.addi %d, %temp1 : i32
      %na = arith.addi %temp1, %temp2 : i32
      scf.yield %na, %a, %b, %c, %ne2, %e, %f, %g : i32, i32, i32, i32, i32, i32, i32, i32
    }
    %n0 = arith.addi %ha, %fin#0 : i32
    %n1 = arith.addi %hb, %fin#1 : i32
    %n2 = arith.addi %hc, %fin#2 : i32
    %n3 = arith.addi %hd, %fin#3 : i32
    %n4 = arith.addi %he, %fin#4 : i32
    %n5 = arith.addi %hf, %fin#5 : i32
    %n6 = arith.addi %hg, %fin#6 : i32
    %n7 = arith.addi %hh, %fin#7 : i32
    memref.store %n0, %h[%c0] : memref<8xi32>
    memref.store %n1, %h[%c1] : memref<8xi32>
    memref.store %n2, %h[%c2] : memref<8xi32>
    memref.store %n3, %h[%c3] : memref<8xi32>
    memref.store %n4, %h[%c4] : memref<8xi32>
    memref.store %n5, %h[%c5] : memref<8xi32>
    memref.store %n6, %h[%c6] : memref<8xi32>
    memref.store %n7, %h[%c7] : memref<8xi32>
  }
  scf.for %i = %c0 to %c8 step %c1 {
    %v = memref.load %h[%i] : memref<8xi32>
    memref.store %v, %out[%i] : memref<8xi32>
  }
  memref.dealloc %pad : memref<?xi8>
  return
}

func.func @digest_eq(%a: memref<8xi32>, %b: memref<8xi32>) -> i1 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  %t = arith.constant true
  %r = scf.for %i = %c0 to %c8 step %c1 iter_args(%acc = %t) -> (i1) {
    %x = memref.load %a[%i] : memref<8xi32>
    %y = memref.load %b[%i] : memref<8xi32>
    %e = arith.cmpi eq, %x, %y : i32
    %n = arith.andi %acc, %e : i1
    scf.yield %n : i1
  }
  return %r : i1
}
