// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// io.mlir — string buffers and exact float formatting (upstream dialects only).
// A "string" is a (memref<?xi8> buffer, index length) pair. Every s_* function
// appends to the buffer at `len` and returns the new length.
// Float formatting reproduces CPython's format()/repr() digit choice with exact
// integer arithmetic (i128): s_fixed (".Nf"), s_sci (".Ne"), s_repr (shortest
// round-trip, positional range only). Limits are listed in GAPS.md.

llvm.func @printf(!llvm.ptr, ...) -> i32
llvm.func @snprintf(!llvm.ptr, i64, !llvm.ptr, ...) -> i32
llvm.mlir.global internal constant @io_fmt_g17("%.17g\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @io_fmt_line("%.*s\0A\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @io_fmt_f64("%s = %.17g (bits %lld)\0A\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @io_fmt_i64("%s = %lld\0A\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @io_true("True\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @io_false("False\00") {addr_space = 0 : i32}

func.func @buf_ptr(%b: memref<?xi8>) -> !llvm.ptr {
  %i = memref.extract_aligned_pointer_as_index %b : memref<?xi8> -> index
  %i64 = arith.index_cast %i : index to i64
  %p = llvm.inttoptr %i64 : i64 to !llvm.ptr
  return %p : !llvm.ptr
}

func.func @s_new() -> memref<?xi8> {
  %cap = arith.constant 8192 : index
  %b = memref.alloc(%cap) : memref<?xi8>
  return %b : memref<?xi8>
}

// print buffer[0..len) followed by newline
func.func @s_print(%b: memref<?xi8>, %len: index) {
  %p = func.call @buf_ptr(%b) : (memref<?xi8>) -> !llvm.ptr
  %f = llvm.mlir.addressof @io_fmt_line : !llvm.ptr
  %n = arith.index_cast %len : index to i32
  %r = llvm.call @printf(%f, %n, %p) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, i32, !llvm.ptr) -> i32
  return
}

// print "<label> = %.17g (bits N)"
func.func @print_f64(%label: !llvm.ptr, %v: f64) {
  %f = llvm.mlir.addressof @io_fmt_f64 : !llvm.ptr
  %bits = arith.bitcast %v : f64 to i64
  %r = llvm.call @printf(%f, %label, %v, %bits) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, !llvm.ptr, f64, i64) -> i32
  return
}

func.func @print_i64(%label: !llvm.ptr, %v: i64) {
  %f = llvm.mlir.addressof @io_fmt_i64 : !llvm.ptr
  %r = llvm.call @printf(%f, %label, %v) vararg(!llvm.func<i32 (ptr, ...)>) : (!llvm.ptr, !llvm.ptr, i64) -> i32
  return
}

func.func @s_byte(%b: memref<?xi8>, %len: index, %ch: i8) -> index {
  memref.store %ch, %b[%len] : memref<?xi8>
  %one = arith.constant 1 : index
  %l = arith.addi %len, %one : index
  return %l : index
}

// append NUL-terminated literal
func.func @s_cstr(%b: memref<?xi8>, %len: index, %p: !llvm.ptr) -> index {
  %z = arith.constant 0 : i8
  %one = arith.constant 1 : index
  %res:2 = scf.while (%l = %len, %q = %p) : (index, !llvm.ptr) -> (index, !llvm.ptr) {
    %ch = llvm.load %q : !llvm.ptr -> i8
    %nz = arith.cmpi ne, %ch, %z : i8
    scf.condition(%nz) %l, %q : index, !llvm.ptr
  } do {
  ^bb0(%l: index, %q: !llvm.ptr):
    %ch = llvm.load %q : !llvm.ptr -> i8
    memref.store %ch, %b[%l] : memref<?xi8>
    %l2 = arith.addi %l, %one : index
    %q2 = llvm.getelementptr %q[1] : (!llvm.ptr) -> !llvm.ptr, i8
    scf.yield %l2, %q2 : index, !llvm.ptr
  }
  return %res#0 : index
}

// append bytes src[from..to)
func.func @s_slice(%b: memref<?xi8>, %len: index, %src: memref<?xi8>, %from: index, %to: index) -> index {
  %one = arith.constant 1 : index
  %r = scf.for %i = %from to %to step %one iter_args(%l = %len) -> (index) {
    %ch = memref.load %src[%i] : memref<?xi8>
    memref.store %ch, %b[%l] : memref<?xi8>
    %l2 = arith.addi %l, %one : index
    scf.yield %l2 : index
  }
  return %r : index
}

func.func @s_bool(%b: memref<?xi8>, %len: index, %v: i1) -> index {
  %t = llvm.mlir.addressof @io_true : !llvm.ptr
  %f = llvm.mlir.addressof @io_false : !llvm.ptr
  %p = arith.select %v, %t, %f : !llvm.ptr
  %l = func.call @s_cstr(%b, %len, %p) : (memref<?xi8>, index, !llvm.ptr) -> index
  return %l : index
}

// append unsigned decimal of an i128 (>= 0), at least `minw` digits (zero padded)
func.func @s_u128(%b: memref<?xi8>, %len: index, %v: i128, %minw: index) -> index {
  %tmp = memref.alloca() : memref<48xi8>
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %ten = arith.constant 10 : i128
  %zero = arith.constant 0 : i128
  %c48 = arith.constant 48 : i8
  // produce digits least-significant first
  %res:2 = scf.while (%x = %v, %n = %c0) : (i128, index) -> (i128, index) {
    %more = arith.cmpi ne, %x, %zero : i128
    %short = arith.cmpi ult, %n, %minw : index
    %first = arith.cmpi eq, %n, %c0 : index
    %a = arith.ori %more, %short : i1
    %go = arith.ori %a, %first : i1
    scf.condition(%go) %x, %n : i128, index
  } do {
  ^bb0(%x: i128, %n: index):
    %d = arith.remui %x, %ten : i128
    %q = arith.divui %x, %ten : i128
    %d8 = arith.trunci %d : i128 to i8
    %ch = arith.addi %d8, %c48 : i8
    memref.store %ch, %tmp[%n] : memref<48xi8>
    %n2 = arith.addi %n, %one : index
    scf.yield %q, %n2 : i128, index
  }
  %r = scf.for %i = %c0 to %res#1 step %one iter_args(%l = %len) -> (index) {
    %ri = arith.subi %res#1, %i : index
    %ri1 = arith.subi %ri, %one : index
    %ch = memref.load %tmp[%ri1] : memref<48xi8>
    memref.store %ch, %b[%l] : memref<?xi8>
    %l2 = arith.addi %l, %one : index
    scf.yield %l2 : index
  }
  return %r : index
}

func.func @s_uint(%b: memref<?xi8>, %len: index, %v: i64) -> index {
  %w = arith.extui %v : i64 to i128
  %one = arith.constant 1 : index
  %l = func.call @s_u128(%b, %len, %w, %one) : (memref<?xi8>, index, i128, index) -> index
  return %l : index
}

func.func @s_int(%b: memref<?xi8>, %len: index, %v: i64) -> index {
  %z = arith.constant 0 : i64
  %neg = arith.cmpi slt, %v, %z : i64
  %l1 = scf.if %neg -> (index) {
    %m = arith.constant 45 : i8
    %t = func.call @s_byte(%b, %len, %m) : (memref<?xi8>, index, i8) -> index
    scf.yield %t : index
  } else {
    scf.yield %len : index
  }
  %nv = arith.subi %z, %v : i64
  %a = arith.select %neg, %nv, %v : i64
  %l2 = func.call @s_uint(%b, %l1, %a) : (memref<?xi8>, index, i64) -> index
  return %l2 : index
}

// lowercase hex of the first n nibbles of an 8-word big-endian digest
func.func @s_hex(%b: memref<?xi8>, %len: index, %d: memref<8xi32>, %n: index) -> index {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  %c28 = arith.constant 28 : i32
  %c4 = arith.constant 4 : i32
  %c15 = arith.constant 15 : i32
  %c10 = arith.constant 10 : i32
  %c48 = arith.constant 48 : i32
  %c87 = arith.constant 87 : i32
  %r = scf.for %i = %c0 to %n step %one iter_args(%l = %len) -> (index) {
    %wi = arith.divui %i, %c8 : index
    %ni = arith.remui %i, %c8 : index
    %w = memref.load %d[%wi] : memref<8xi32>
    %ni32 = arith.index_cast %ni : index to i32
    %sh0 = arith.muli %ni32, %c4 : i32
    %sh = arith.subi %c28, %sh0 : i32
    %x = arith.shrui %w, %sh : i32
    %nib = arith.andi %x, %c15 : i32
    %isd = arith.cmpi ult, %nib, %c10 : i32
    %base = arith.select %isd, %c48, %c87 : i32
    %ch32 = arith.addi %nib, %base : i32
    %ch = arith.trunci %ch32 : i32 to i8
    memref.store %ch, %b[%l] : memref<?xi8>
    %l2 = arith.addi %l, %one : index
    scf.yield %l2 : index
  }
  return %r : index
}

// ---------------------------------------------------------------- exact floats
// v = m * 2^(-k) for finite v > 0
func.func @f_decomp(%v: f64) -> (i64, i64) {
  %bits = arith.bitcast %v : f64 to i64
  %c52 = arith.constant 52 : i64
  %emask = arith.constant 2047 : i64
  %fmask = arith.constant 4503599627370495 : i64
  %hidden = arith.constant 4503599627370496 : i64
  %c1075 = arith.constant 1075 : i64
  %c1074 = arith.constant 1074 : i64
  %z = arith.constant 0 : i64
  %eb0 = arith.shrui %bits, %c52 : i64
  %eb = arith.andi %eb0, %emask : i64
  %f = arith.andi %bits, %fmask : i64
  %sub = arith.cmpi eq, %eb, %z : i64
  %mn = arith.ori %f, %hidden : i64
  %m = arith.select %sub, %f, %mn : i64
  %kn = arith.subi %c1075, %eb : i64
  %k = arith.select %sub, %c1074, %kn : i64
  return %m, %k : i64, i64
}

func.func @pow10_i128(%n: i64) -> i128 {
  %one = arith.constant 1 : i128
  %ten = arith.constant 10 : i128
  %z = arith.constant 0 : i64
  %c1 = arith.constant 1 : i64
  %r:2 = scf.while (%acc = %one, %i = %z) : (i128, i64) -> (i128, i64) {
    %go = arith.cmpi slt, %i, %n : i64
    scf.condition(%go) %acc, %i : i128, i64
  } do {
  ^bb0(%acc: i128, %i: i64):
    %a2 = arith.muli %acc, %ten : i128
    %i2 = arith.addi %i, %c1 : i64
    scf.yield %a2, %i2 : i128, i64
  }
  return %r#0 : i128
}

// round_half_even(m * 10^s / 2^k), s >= 0
func.func @round_scaled(%m: i64, %k: i64, %s: i64) -> i128 {
  %p = func.call @pow10_i128(%s) : (i64) -> i128
  %m128 = arith.extui %m : i64 to i128
  %num = arith.muli %m128, %p : i128
  %z = arith.constant 0 : i64
  %c127 = arith.constant 127 : i64
  %le0 = arith.cmpi sle, %k, %z : i64
  %r = scf.if %le0 -> (i128) {
    %nk = arith.subi %z, %k : i64
    %nk128 = arith.extui %nk : i64 to i128
    %v = arith.shli %num, %nk128 : i128
    scf.yield %v : i128
  } else {
    %big = arith.cmpi sge, %k, %c127 : i64
    %v = scf.if %big -> (i128) {
      %zz = arith.constant 0 : i128
      scf.yield %zz : i128
    } else {
      %k128 = arith.extui %k : i64 to i128
      %q = arith.shrui %num, %k128 : i128
      %qs = arith.shli %q, %k128 : i128
      %rem = arith.subi %num, %qs : i128
      %one = arith.constant 1 : i128
      %km1 = arith.subi %k128, %one : i128
      %half = arith.shli %one, %km1 : i128
      %gt = arith.cmpi ugt, %rem, %half : i128
      %eq = arith.cmpi eq, %rem, %half : i128
      %odd0 = arith.andi %q, %one : i128
      %odd = arith.cmpi ne, %odd0, %one : i128
      %isodd = arith.cmpi eq, %odd0, %one : i128
      %tie = arith.andi %eq, %isodd : i1
      %up = arith.ori %gt, %tie : i1
      %q1 = arith.addi %q, %one : i128
      %res = arith.select %up, %q1, %q : i128
      scf.yield %res : i128
    }
    scf.yield %v : i128
  }
  return %r : i128
}

// format(v, ".{prec}f") for v >= 0
func.func @s_fixed(%b: memref<?xi8>, %len: index, %v: f64, %prec: i64) -> index {
  %zf = arith.constant 0.0 : f64
  %isz = arith.cmpf oeq, %v, %zf : f64
  %n = scf.if %isz -> (i128) {
    %z = arith.constant 0 : i128
    scf.yield %z : i128
  } else {
    %mk:2 = func.call @f_decomp(%v) : (f64) -> (i64, i64)
    %t = func.call @round_scaled(%mk#0, %mk#1, %prec) : (i64, i64, i64) -> i128
    scf.yield %t : i128
  }
  %p = func.call @pow10_i128(%prec) : (i64) -> i128
  %ip = arith.divui %n, %p : i128
  %fp = arith.remui %n, %p : i128
  %one = arith.constant 1 : index
  %l1 = func.call @s_u128(%b, %len, %ip, %one) : (memref<?xi8>, index, i128, index) -> index
  %z64 = arith.constant 0 : i64
  %haspt = arith.cmpi sgt, %prec, %z64 : i64
  %l3 = scf.if %haspt -> (index) {
    %dot = arith.constant 46 : i8
    %l2 = func.call @s_byte(%b, %l1, %dot) : (memref<?xi8>, index, i8) -> index
    %w = arith.index_cast %prec : i64 to index
    %l4 = func.call @s_u128(%b, %l2, %fp, %w) : (memref<?xi8>, index, i128, index) -> index
    scf.yield %l4 : index
  } else {
    scf.yield %l1 : index
  }
  return %l3 : index
}

// p significant digits of v (correctly rounded): returns (N, X) with
// 10^(p-1) <= N < 10^p and v ~= N * 10^(X-p+1). Requires p-1-X >= 0.
func.func @sig_digits(%v: f64, %p: i64) -> (i128, i64) {
  %mk:2 = func.call @f_decomp(%v) : (f64) -> (i64, i64)
  %lg = math.log10 %v : f64
  %fl = math.floor %lg : f64
  %x0 = arith.fptosi %fl : f64 to i64
  %c1 = arith.constant 1 : i64
  %pm1 = arith.subi %p, %c1 : i64
  %lo = func.call @pow10_i128(%pm1) : (i64) -> i128
  %hi = func.call @pow10_i128(%p) : (i64) -> i128
  %init = arith.constant 0 : i128
  %true = arith.constant true
  %r:3 = scf.while (%x = %x0, %n = %init, %again = %true) : (i64, i128, i1) -> (i64, i128, i1) {
    scf.condition(%again) %x, %n, %again : i64, i128, i1
  } do {
  ^bb0(%x: i64, %n: i128, %ag: i1):
    %s = arith.subi %pm1, %x : i64
    %nn = func.call @round_scaled(%mk#0, %mk#1, %s) : (i64, i64, i64) -> i128
    %toobig = arith.cmpi sge, %nn, %hi : i128
    %toosmall = arith.cmpi slt, %nn, %lo : i128
    %xp = arith.addi %x, %c1 : i64
    %xm = arith.subi %x, %c1 : i64
    %x1 = arith.select %toosmall, %xm, %x : i64
    %x2 = arith.select %toobig, %xp, %x1 : i64
    %bad = arith.ori %toobig, %toosmall : i1
    scf.yield %x2, %nn, %bad : i64, i128, i1
  }
  return %r#1, %r#0 : i128, i64
}

// format(v, ".{prec}e") for v > 0
func.func @s_sci(%b: memref<?xi8>, %len: index, %v: f64, %prec: i64) -> index {
  %c1 = arith.constant 1 : i64
  %p = arith.addi %prec, %c1 : i64
  %nx:2 = func.call @sig_digits(%v, %p) : (f64, i64) -> (i128, i64)
  %pw = func.call @pow10_i128(%prec) : (i64) -> i128
  %lead = arith.divui %nx#0, %pw : i128
  %rest = arith.remui %nx#0, %pw : i128
  %one = arith.constant 1 : index
  %l1 = func.call @s_u128(%b, %len, %lead, %one) : (memref<?xi8>, index, i128, index) -> index
  %dot = arith.constant 46 : i8
  %l2 = func.call @s_byte(%b, %l1, %dot) : (memref<?xi8>, index, i8) -> index
  %w = arith.index_cast %prec : i64 to index
  %l3 = func.call @s_u128(%b, %l2, %rest, %w) : (memref<?xi8>, index, i128, index) -> index
  %e = arith.constant 101 : i8
  %l4 = func.call @s_byte(%b, %l3, %e) : (memref<?xi8>, index, i8) -> index
  %z = arith.constant 0 : i64
  %neg = arith.cmpi slt, %nx#1, %z : i64
  %minus = arith.constant 45 : i8
  %plus = arith.constant 43 : i8
  %sg = arith.select %neg, %minus, %plus : i8
  %l5 = func.call @s_byte(%b, %l4, %sg) : (memref<?xi8>, index, i8) -> index
  %nxv = arith.subi %z, %nx#1 : i64
  %ax = arith.select %neg, %nxv, %nx#1 : i64
  %ax128 = arith.extui %ax : i64 to i128
  %two = arith.constant 2 : index
  %l6 = func.call @s_u128(%b, %l5, %ax128, %two) : (memref<?xi8>, index, i128, index) -> index
  return %l6 : index
}

// repr(v) for v >= 0 in CPython's positional range (1e-4 <= v < 1e16) or v == 0
func.func @s_repr(%b: memref<?xi8>, %len: index, %v: f64) -> index {
  %zf = arith.constant 0.0 : f64
  %isz = arith.cmpf oeq, %v, %zf : f64
  %one = arith.constant 1 : index
  %dot = arith.constant 46 : i8
  %c48 = arith.constant 48 : i8
  %res = scf.if %isz -> (index) {
    %l1 = func.call @s_byte(%b, %len, %c48) : (memref<?xi8>, index, i8) -> index
    %l2 = func.call @s_byte(%b, %l1, %dot) : (memref<?xi8>, index, i8) -> index
    %l3 = func.call @s_byte(%b, %l2, %c48) : (memref<?xi8>, index, i8) -> index
    scf.yield %l3 : index
  } else {
    %mk:2 = func.call @f_decomp(%v) : (f64) -> (i64, i64)
    %m = arith.constant 0 : i64
    %z64 = arith.constant 0 : i64
    %isint = arith.cmpi sle, %mk#1, %z64 : i64
    %r = scf.if %isint -> (index) {
      %nk = arith.subi %z64, %mk#1 : i64
      %m128 = arith.extui %mk#0 : i64 to i128
      %nk128 = arith.extui %nk : i64 to i128
      %iv = arith.shli %m128, %nk128 : i128
      %l1 = func.call @s_u128(%b, %len, %iv, %one) : (memref<?xi8>, index, i128, index) -> index
      %l2 = func.call @s_byte(%b, %l1, %dot) : (memref<?xi8>, index, i8) -> index
      %l3 = func.call @s_byte(%b, %l2, %c48) : (memref<?xi8>, index, i8) -> index
      scf.yield %l3 : index
    } else {
      // try p = 1..17 significant digits; first candidate that round-trips wins
      %c1 = arith.constant 1 : i64
      %c17 = arith.constant 17 : i64
      %c2_128 = arith.constant 2 : i128
      %one128 = arith.constant 1 : i128
      %m128 = arith.extui %mk#0 : i64 to i128
      %k128 = arith.extui %mk#1 : i64 to i128
      %pow52 = arith.constant 4503599627370496 : i64
      %ispow2 = arith.cmpi eq, %mk#0, %pow52 : i64
      %meven0 = arith.andi %mk#0, %c1 : i64
      %meven = arith.cmpi eq, %meven0, %z64 : i64
      %init = arith.constant 0 : i128
      %false = arith.constant false
      %true_c = arith.constant true
      %w:4 = scf.while (%p = %c1, %n = %init, %s = %z64, %done = %false) : (i64, i128, i64, i1) -> (i64, i128, i64, i1) {
        %notdone = arith.xori %done, %true_c : i1
        %inrange = arith.cmpi sle, %p, %c17 : i64
        %go = arith.andi %notdone, %inrange : i1
        scf.condition(%go) %p, %n, %s, %done : i64, i128, i64, i1
      } do {
      ^bb0(%p: i64, %n0: i128, %s0: i64, %d0: i1):
        %nx:2 = func.call @sig_digits(%v, %p) : (f64, i64) -> (i128, i64)
        %pm1 = arith.subi %p, %c1 : i64
        %s = arith.subi %pm1, %nx#1 : i64
        %p10 = func.call @pow10_i128(%s) : (i64) -> i128
        // lhs = |2*N*2^k - 2*m*10^s| ; rhs = 10^s
        %kp1 = arith.addi %k128, %one128 : i128
        %a = arith.shli %nx#0, %kp1 : i128
        %bm = arith.muli %m128, %p10 : i128
        %b2 = arith.muli %bm, %c2_128 : i128
        %below = arith.cmpi slt, %a, %b2 : i128
        %d1 = arith.subi %a, %b2 : i128
        %d2 = arith.subi %b2, %a : i128
        %lhs0 = arith.select %below, %d2, %d1 : i128
        %tight = arith.andi %below, %ispow2 : i1
        %lhs2 = arith.muli %lhs0, %c2_128 : i128
        %lhs = arith.select %tight, %lhs2, %lhs0 : i128
        %lt = arith.cmpi slt, %lhs, %p10 : i128
        %eq = arith.cmpi eq, %lhs, %p10 : i128
        %tieok = arith.andi %eq, %meven : i1
        %ok = arith.ori %lt, %tieok : i1
        %p2 = arith.addi %p, %c1 : i64
        scf.yield %p2, %nx#0, %s, %ok : i64, i128, i64, i1
      }
      %p10 = func.call @pow10_i128(%w#2) : (i64) -> i128
      %ip = arith.divui %w#1, %p10 : i128
      %fp = arith.remui %w#1, %p10 : i128
      %l1 = func.call @s_u128(%b, %len, %ip, %one) : (memref<?xi8>, index, i128, index) -> index
      %l2 = func.call @s_byte(%b, %l1, %dot) : (memref<?xi8>, index, i8) -> index
      %sw = arith.index_cast %w#2 : i64 to index
      %l3 = func.call @s_u128(%b, %l2, %fp, %sw) : (memref<?xi8>, index, i128, index) -> index
      scf.yield %l3 : index
    }
    scf.yield %r : index
  }
  return %res : index
}

// s_jfloat: J's display of a float at print precision 17 (9!:11 ] 17):
// C "%.17g" digits, with '-' written as '_' and the exponent as e<_>digits
// without '+' or leading zeros (1e-06 -> 1e_6). Used to diff against jconsole.
func.func @s_jfloat(%b: memref<?xi8>, %len: index, %v: f64) -> index {
  %c64 = arith.constant 64 : index
  %tmp = memref.alloc(%c64) : memref<?xi8>
  %tp = func.call @buf_ptr(%tmp) : (memref<?xi8>) -> !llvm.ptr
  %f = llvm.mlir.addressof @io_fmt_g17 : !llvm.ptr
  %cap = arith.constant 64 : i64
  %n32 = llvm.call @snprintf(%tp, %cap, %f, %v) vararg(!llvm.func<i32 (ptr, i64, ptr, ...)>) : (!llvm.ptr, i64, !llvm.ptr, f64) -> i32
  %n = arith.index_cast %n32 : i32 to index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %minus = arith.constant 45 : i8
  %plus = arith.constant 43 : i8
  %under = arith.constant 95 : i8
  %zero = arith.constant 48 : i8
  %e = arith.constant 101 : i8
  %false = arith.constant false
  // state: in_exp (after 'e'), lead (still skipping exponent leading zeros)
  %r:3 = scf.for %i = %c0 to %n step %c1 iter_args(%l = %len, %inexp = %false, %lead = %false) -> (index, i1, i1) {
    %ch = memref.load %tmp[%i] : memref<?xi8>
    %ism = arith.cmpi eq, %ch, %minus : i8
    %isp = arith.cmpi eq, %ch, %plus : i8
    %ise = arith.cmpi eq, %ch, %e : i8
    %isz = arith.cmpi eq, %ch, %zero : i8
    %skipz = arith.andi %lead, %isz : i1
    %skip = arith.ori %isp, %skipz : i1
    %out = arith.select %ism, %under, %ch : i8
    %nl = scf.if %skip -> (index) {
      scf.yield %l : index
    } else {
      %x = func.call @s_byte(%b, %l, %out) : (memref<?xi8>, index, i8) -> index
      scf.yield %x : index
    }
    %ninexp = arith.ori %inexp, %ise : i1
    // leading-zero skipping starts right after 'e' (+ sign) and stops at the first non-zero digit
    %sign = arith.ori %ism, %isp : i1
    %keep = arith.andi %lead, %sign : i1
    %keepz = arith.andi %lead, %isz : i1
    %k1 = arith.ori %keep, %keepz : i1
    %nlead = arith.ori %ise, %k1 : i1
    scf.yield %nl, %ninexp, %nlead : index, i1, i1
  }
  memref.dealloc %tmp : memref<?xi8>
  return %r#0 : index
}
