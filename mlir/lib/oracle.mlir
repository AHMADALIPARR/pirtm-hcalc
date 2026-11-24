// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// oracle.mlir — port of pirtm/oracle/cas.py (ContentAddressedStore, in-memory
// mode) and pirtm/oracle/retrieval.py (EmbeddingOracle: tokenizer, deterministic
// lexical embedding, index, RETRIEVE with Jaccard/TF scoring, VERIFY).
// Module-level state lives in memref globals; @cas_reset clears it.

memref.global "private" @cas_n : memref<1xindex> = dense<0>
memref.global "private" @cas_dig : memref<128x8xi32> = uninitialized
memref.global "private" @cas_data : memref<128x1024xi8> = uninitialized
memref.global "private" @cas_len : memref<128xindex> = uninitialized
memref.global "private" @cas_creator : memref<128x32xi8> = uninitialized
memref.global "private" @cas_clen : memref<128xindex> = uninitialized
memref.global "private" @cas_domain : memref<128x64xi8> = uninitialized
memref.global "private" @cas_dlen : memref<128xindex> = uninitialized
memref.global "private" @cas_tamper : memref<1xindex> = dense<0>

llvm.mlir.global internal constant @o_tamper("CAS: hash collision or tampering detected\00") {addr_space = 0 : i32}

func.func @cas_reset() {
  %n = memref.get_global @cas_n : memref<1xindex>
  %c0 = arith.constant 0 : index
  memref.store %c0, %n[%c0] : memref<1xindex>
  %t = memref.get_global @cas_tamper : memref<1xindex>
  memref.store %c0, %t[%c0] : memref<1xindex>
  return
}

func.func @cas_count() -> index {
  %n = memref.get_global @cas_n : memref<1xindex>
  %c0 = arith.constant 0 : index
  %v = memref.load %n[%c0] : memref<1xindex>
  return %v : index
}

func.func @cas_digest(%slot: index, %out: memref<8xi32>) {
  %d = memref.get_global @cas_dig : memref<128x8xi32>
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  scf.for %i = %c0 to %c8 step %c1 {
    %v = memref.load %d[%slot, %i] : memref<128x8xi32>
    memref.store %v, %out[%i] : memref<8xi32>
  }
  return
}

// index of the slot holding digest dg, or -1 (as index max) if absent
func.func @cas_find(%dg: memref<8xi32>) -> index {
  %n = func.call @cas_count() : () -> index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %none = arith.constant -1 : index
  %tmp = memref.alloca() : memref<8xi32>
  %r = scf.for %s = %c0 to %n step %c1 iter_args(%found = %none) -> (index) {
    func.call @cas_digest(%s, %tmp) : (index, memref<8xi32>) -> ()
    %eq = func.call @digest_eq(%tmp, %dg) : (memref<8xi32>, memref<8xi32>) -> i1
    %isnone = arith.cmpi eq, %found, %none : index
    %take = arith.andi %eq, %isnone : i1
    %nf = arith.select %take, %s, %found : index
    scf.yield %nf : index
  }
  return %r : index
}

// copy a NUL-terminated literal into row `slot` of a byte table; returns length
func.func @store_cstr(%tab: memref<?x?xi8>, %slot: index, %p: !llvm.ptr) -> index {
  %z = arith.constant 0 : i8
  %one = arith.constant 1 : index
  %c0 = arith.constant 0 : index
  %res:2 = scf.while (%l = %c0, %q = %p) : (index, !llvm.ptr) -> (index, !llvm.ptr) {
    %ch = llvm.load %q : !llvm.ptr -> i8
    %nz = arith.cmpi ne, %ch, %z : i8
    scf.condition(%nz) %l, %q : index, !llvm.ptr
  } do {
  ^bb0(%l: index, %q: !llvm.ptr):
    %ch = llvm.load %q : !llvm.ptr -> i8
    memref.store %ch, %tab[%slot, %l] : memref<?x?xi8>
    %l2 = arith.addi %l, %one : index
    %q2 = llvm.getelementptr %q[1] : (!llvm.ptr) -> !llvm.ptr, i8
    scf.yield %l2, %q2 : index, !llvm.ptr
  }
  return %res#0 : index
}

// ContentAddressedStore.put (+ the index metadata used by retrieval filters).
// Returns the slot; the digest is written to `out`.
func.func @cas_put(%buf: memref<?xi8>, %len: index, %creator: !llvm.ptr, %domain: !llvm.ptr, %out: memref<8xi32>) -> index {
  func.call @sha256(%buf, %len, %out) : (memref<?xi8>, index, memref<8xi32>) -> ()
  %found = func.call @cas_find(%out) : (memref<8xi32>) -> index
  %none = arith.constant -1 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  %data = memref.get_global @cas_data : memref<128x1024xi8>
  %lens = memref.get_global @cas_len : memref<128xindex>
  %isnew = arith.cmpi eq, %found, %none : index
  %true_c = arith.constant true
  %slot = scf.if %isnew -> (index) {
    %n = func.call @cas_count() : () -> index
    %dg = memref.get_global @cas_dig : memref<128x8xi32>
    scf.for %i = %c0 to %c8 step %c1 {
      %v = memref.load %out[%i] : memref<8xi32>
      memref.store %v, %dg[%n, %i] : memref<128x8xi32>
    }
    scf.for %i = %c0 to %len step %c1 {
      %ch = memref.load %buf[%i] : memref<?xi8>
      memref.store %ch, %data[%n, %i] : memref<128x1024xi8>
    }
    memref.store %len, %lens[%n] : memref<128xindex>
    %ct = memref.get_global @cas_creator : memref<128x32xi8>
    %ctd = memref.cast %ct : memref<128x32xi8> to memref<?x?xi8>
    %cl = func.call @store_cstr(%ctd, %n, %creator) : (memref<?x?xi8>, index, !llvm.ptr) -> index
    %cls = memref.get_global @cas_clen : memref<128xindex>
    memref.store %cl, %cls[%n] : memref<128xindex>
    %nn = memref.get_global @cas_n : memref<1xindex>
    %n1 = arith.addi %n, %c1 : index
    memref.store %n1, %nn[%c0] : memref<1xindex>
    scf.yield %n : index
  } else {
    // immutability check: identical content required
    %old = memref.load %lens[%found] : memref<128xindex>
    %samelen = arith.cmpi eq, %old, %len : index
    %same = scf.for %i = %c0 to %len step %c1 iter_args(%acc = %samelen) -> (i1) {
      %a = memref.load %buf[%i] : memref<?xi8>
      %b = memref.load %data[%found, %i] : memref<128x1024xi8>
      %e = arith.cmpi eq, %a, %b : i8
      %n = arith.andi %acc, %e : i1
      scf.yield %n : i1
    }
    %bad = arith.xori %same, %true_c : i1
    scf.if %bad {
      %t = memref.get_global @cas_tamper : memref<1xindex>
      memref.store %c1, %t[%c0] : memref<1xindex>
      %b = func.call @s_new() : () -> memref<?xi8>
      %m = llvm.mlir.addressof @o_tamper : !llvm.ptr
      %l = func.call @s_cstr(%b, %c0, %m) : (memref<?xi8>, index, !llvm.ptr) -> index
      func.call @s_print(%b, %l) : (memref<?xi8>, index) -> ()
    }
    scf.yield %found : index
  }
  // index metadata (re-indexing overwrites, as dict assignment does)
  %dt = memref.get_global @cas_domain : memref<128x64xi8>
  %dtd = memref.cast %dt : memref<128x64xi8> to memref<?x?xi8>
  %dl = func.call @store_cstr(%dtd, %slot, %domain) : (memref<?x?xi8>, index, !llvm.ptr) -> index
  %dls = memref.get_global @cas_dlen : memref<128xindex>
  memref.store %dl, %dls[%slot] : memref<128xindex>
  return %slot : index
}

// copy content of a slot into a fresh buffer; returns (buffer, length) — CAS get
func.func @cas_get(%slot: index) -> (memref<?xi8>, index) {
  %data = memref.get_global @cas_data : memref<128x1024xi8>
  %lens = memref.get_global @cas_len : memref<128xindex>
  %len = memref.load %lens[%slot] : memref<128xindex>
  %b = func.call @s_new() : () -> memref<?xi8>
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  scf.for %i = %c0 to %len step %c1 {
    %ch = memref.load %data[%slot, %i] : memref<128x1024xi8>
    memref.store %ch, %b[%i] : memref<?xi8>
  }
  return %b, %len : memref<?xi8>, index
}

// ContentAddressedStore.verify: sha256(content) == artifact id
func.func @cas_verify(%slot: index) -> i1 {
  %bl:2 = func.call @cas_get(%slot) : (index) -> (memref<?xi8>, index)
  %d1 = memref.alloca() : memref<8xi32>
  %d2 = memref.alloca() : memref<8xi32>
  func.call @sha256(%bl#0, %bl#1, %d1) : (memref<?xi8>, index, memref<8xi32>) -> ()
  func.call @cas_digest(%slot, %d2) : (index, memref<8xi32>) -> ()
  %eq = func.call @digest_eq(%d1, %d2) : (memref<8xi32>, memref<8xi32>) -> i1
  return %eq : i1
}

// creator recorded in the provenance entry for a slot equals literal p
func.func @cas_creator_is(%slot: index, %p: !llvm.ptr) -> i1 {
  %ct = memref.get_global @cas_creator : memref<128x32xi8>
  %cls = memref.get_global @cas_clen : memref<128xindex>
  %n = memref.load %cls[%slot] : memref<128xindex>
  %b = func.call @s_new() : () -> memref<?xi8>
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  scf.for %i = %c0 to %n step %c1 {
    %ch = memref.load %ct[%slot, %i] : memref<128x32xi8>
    memref.store %ch, %b[%i] : memref<?xi8>
  }
  %e = func.call @buf_eq_cstr(%b, %c0, %n, %p) : (memref<?xi8>, index, index, !llvm.ptr) -> i1
  return %e : i1
}

// bytes b[from..to) equal NUL-terminated literal p
func.func @buf_eq_cstr(%b: memref<?xi8>, %from: index, %to: index, %p: !llvm.ptr) -> i1 {
  %z = arith.constant 0 : i8
  %c1 = arith.constant 1 : index
  %t = arith.constant true
  %r:3 = scf.while (%i = %from, %q = %p, %ok = %t) : (index, !llvm.ptr, i1) -> (index, !llvm.ptr, i1) {
    %ch = llvm.load %q : !llvm.ptr -> i8
    %more = arith.cmpi ne, %ch, %z : i8
    %inb = arith.cmpi ult, %i, %to : index
    %both = arith.andi %more, %inb : i1
    %go = arith.andi %both, %ok : i1
    scf.condition(%go) %i, %q, %ok : index, !llvm.ptr, i1
  } do {
  ^bb0(%i: index, %q: !llvm.ptr, %ok: i1):
    %ch = llvm.load %q : !llvm.ptr -> i8
    %bc = memref.load %b[%i] : memref<?xi8>
    %e = arith.cmpi eq, %ch, %bc : i8
    %i2 = arith.addi %i, %c1 : index
    %q2 = llvm.getelementptr %q[1] : (!llvm.ptr) -> !llvm.ptr, i8
    scf.yield %i2, %q2, %e : index, !llvm.ptr, i1
  }
  %end = llvm.load %r#1 : !llvm.ptr -> i8
  %litdone = arith.cmpi eq, %end, %z : i8
  %bufdone = arith.cmpi eq, %r#0, %to : index
  %a = arith.andi %r#2, %litdone : i1
  %res = arith.andi %a, %bufdone : i1
  return %res : i1
}

// substring test: literal p occurs in b[0..len)
func.func @buf_contains(%b: memref<?xi8>, %len: index, %p: !llvm.ptr) -> i1 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %f = arith.constant false
  %r = scf.for %s = %c0 to %len step %c1 iter_args(%acc = %f) -> (i1) {
    %pre = func.call @buf_prefix_cstr(%b, %s, %len, %p) : (memref<?xi8>, index, index, !llvm.ptr) -> i1
    %n = arith.ori %acc, %pre : i1
    scf.yield %n : i1
  }
  return %r : i1
}

// literal p is a prefix of b[from..to)
func.func @buf_prefix_cstr(%b: memref<?xi8>, %from: index, %to: index, %p: !llvm.ptr) -> i1 {
  %z = arith.constant 0 : i8
  %c1 = arith.constant 1 : index
  %t = arith.constant true
  %r:3 = scf.while (%i = %from, %q = %p, %ok = %t) : (index, !llvm.ptr, i1) -> (index, !llvm.ptr, i1) {
    %ch = llvm.load %q : !llvm.ptr -> i8
    %more = arith.cmpi ne, %ch, %z : i8
    %go = arith.andi %more, %ok : i1
    scf.condition(%go) %i, %q, %ok : index, !llvm.ptr, i1
  } do {
  ^bb0(%i: index, %q: !llvm.ptr, %ok: i1):
    %ch = llvm.load %q : !llvm.ptr -> i8
    %inb = arith.cmpi ult, %i, %to : index
    %e = scf.if %inb -> (i1) {
      %bc = memref.load %b[%i] : memref<?xi8>
      %x = arith.cmpi eq, %ch, %bc : i8
      scf.yield %x : i1
    } else {
      %ff = arith.constant false
      scf.yield %ff : i1
    }
    %i2 = arith.addi %i, %c1 : index
    %q2 = llvm.getelementptr %q[1] : (!llvm.ptr) -> !llvm.ptr, i8
    scf.yield %i2, %q2, %e : index, !llvm.ptr, i1
  }
  return %r#2 : i1
}

// ------------------------------------------------------------------ tokenizer
// re.findall(r"\b[a-zA-Z0-9_\-\.\:\/]+\b", text.lower())
func.func @is_word(%ch: i8) -> i1 {
  %a = arith.constant 97 : i8
  %zc = arith.constant 122 : i8
  %A = arith.constant 65 : i8
  %Z = arith.constant 90 : i8
  %d0 = arith.constant 48 : i8
  %d9 = arith.constant 57 : i8
  %us = arith.constant 95 : i8
  %l1 = arith.cmpi uge, %ch, %a : i8
  %l2 = arith.cmpi ule, %ch, %zc : i8
  %l = arith.andi %l1, %l2 : i1
  %u1 = arith.cmpi uge, %ch, %A : i8
  %u2 = arith.cmpi ule, %ch, %Z : i8
  %u = arith.andi %u1, %u2 : i1
  %n1 = arith.cmpi uge, %ch, %d0 : i8
  %n2 = arith.cmpi ule, %ch, %d9 : i8
  %n = arith.andi %n1, %n2 : i1
  %s = arith.cmpi eq, %ch, %us : i8
  %r1 = arith.ori %l, %u : i1
  %r2 = arith.ori %r1, %n : i1
  %r = arith.ori %r2, %s : i1
  return %r : i1
}

func.func @is_tokch(%ch: i8) -> i1 {
  %w = func.call @is_word(%ch) : (i8) -> i1
  %dash = arith.constant 45 : i8
  %dot = arith.constant 46 : i8
  %colon = arith.constant 58 : i8
  %slash = arith.constant 47 : i8
  %a = arith.cmpi eq, %ch, %dash : i8
  %b = arith.cmpi eq, %ch, %dot : i8
  %c = arith.cmpi eq, %ch, %colon : i8
  %d = arith.cmpi eq, %ch, %slash : i8
  %x1 = arith.ori %w, %a : i1
  %x2 = arith.ori %x1, %b : i1
  %x3 = arith.ori %x2, %c : i1
  %x = arith.ori %x3, %d : i1
  return %x : i1
}

// word-ness of position i (false outside [0,len))
func.func @word_at(%b: memref<?xi8>, %len: index, %i: index) -> i1 {
  %inb = arith.cmpi ult, %i, %len : index
  %r = scf.if %inb -> (i1) {
    %ch = memref.load %b[%i] : memref<?xi8>
    %w = func.call @is_word(%ch) : (i8) -> i1
    scf.yield %w : i1
  } else {
    %f = arith.constant false
    scf.yield %f : i1
  }
  return %r : i1
}

func.func @boundary(%b: memref<?xi8>, %len: index, %p: index) -> i1 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %atstart = arith.cmpi eq, %p, %c0 : index
  %pm1 = arith.subi %p, %c1 : index
  %prev = scf.if %atstart -> (i1) {
    %f = arith.constant false
    scf.yield %f : i1
  } else {
    %w = func.call @word_at(%b, %len, %pm1) : (memref<?xi8>, index, index) -> i1
    scf.yield %w : i1
  }
  %cur = func.call @word_at(%b, %len, %p) : (memref<?xi8>, index, index) -> i1
  %r = arith.xori %prev, %cur : i1
  return %r : i1
}

// lowercase copy of b[0..len)
func.func @lower(%b: memref<?xi8>, %len: index) -> memref<?xi8> {
  %o = func.call @s_new() : () -> memref<?xi8>
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %A = arith.constant 65 : i8
  %Z = arith.constant 90 : i8
  %d = arith.constant 32 : i8
  scf.for %i = %c0 to %len step %c1 {
    %ch = memref.load %b[%i] : memref<?xi8>
    %u1 = arith.cmpi uge, %ch, %A : i8
    %u2 = arith.cmpi ule, %ch, %Z : i8
    %u = arith.andi %u1, %u2 : i1
    %lc = arith.addi %ch, %d : i8
    %r = arith.select %u, %lc, %ch : i8
    memref.store %r, %o[%i] : memref<?xi8>
  }
  return %o : memref<?xi8>
}

// tokens of an (already lowercased) buffer: toks[t] = (start, end); returns count
func.func @tokenize(%b: memref<?xi8>, %len: index, %toks: memref<?x2xindex>) -> index {
  %true_c = arith.constant true
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %r:2 = scf.while (%i = %c0, %n = %c0) : (index, index) -> (index, index) {
    %go = arith.cmpi ult, %i, %len : index
    scf.condition(%go) %i, %n : index, index
  } do {
  ^bb0(%i: index, %n: index):
    %ch = memref.load %b[%i] : memref<?xi8>
    %tc = func.call @is_tokch(%ch) : (i8) -> i1
    %bd = func.call @boundary(%b, %len, %i) : (memref<?xi8>, index, index) -> i1
    %start = arith.andi %tc, %bd : i1
    %res:2 = scf.if %start -> (index, index) {
      // maximal run of token chars from i
      %j = scf.while (%k = %i) : (index) -> (index) {
        %inb = arith.cmpi ult, %k, %len : index
        %ok = scf.if %inb -> (i1) {
          %c = memref.load %b[%k] : memref<?xi8>
          %t = func.call @is_tokch(%c) : (i8) -> i1
          scf.yield %t : i1
        } else {
          %f = arith.constant false
          scf.yield %f : i1
        }
        scf.condition(%ok) %k : index
      } do {
      ^bb0(%k: index):
        %k2 = arith.addi %k, %c1 : index
        scf.yield %k2 : index
      }
      // greedy backtrack: largest e in (i, j] with a word boundary at e
      %e = scf.while (%k = %j) : (index) -> (index) {
        %gt = arith.cmpi ugt, %k, %i : index
        %bb = scf.if %gt -> (i1) {
          %x = func.call @boundary(%b, %len, %k) : (memref<?xi8>, index, index) -> i1
          scf.yield %x : i1
        } else {
          %t = arith.constant true
          scf.yield %t : i1
        }
        %cont0 = arith.xori %bb, %true_c : i1
        %cont = arith.andi %cont0, %gt : i1
        scf.condition(%cont) %k : index
      } do {
      ^bb0(%k: index):
        %k2 = arith.subi %k, %c1 : index
        scf.yield %k2 : index
      }
      %found = arith.cmpi ugt, %e, %i : index
      %rr:2 = scf.if %found -> (index, index) {
        memref.store %i, %toks[%n, %c0] : memref<?x2xindex>
        memref.store %e, %toks[%n, %c1] : memref<?x2xindex>
        %n2 = arith.addi %n, %c1 : index
        scf.yield %e, %n2 : index, index
      } else {
        %i2 = arith.addi %i, %c1 : index
        scf.yield %i2, %n : index, index
      }
      scf.yield %rr#0, %rr#1 : index, index
    } else {
      %i2 = arith.addi %i, %c1 : index
      scf.yield %i2, %n : index, index
    }
    scf.yield %res#0, %res#1 : index, index
  }
  return %r#1 : index
}

func.func @tok_eq(%a: memref<?xi8>, %as: index, %ae: index, %b: memref<?xi8>, %bs: index, %be: index) -> i1 {
  %la = arith.subi %ae, %as : index
  %lb = arith.subi %be, %bs : index
  %same = arith.cmpi eq, %la, %lb : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %n = arith.select %same, %la, %c0 : index
  %r = scf.for %k = %c0 to %n step %c1 iter_args(%acc = %same) -> (i1) {
    %ia = arith.addi %as, %k : index
    %ib = arith.addi %bs, %k : index
    %x = memref.load %a[%ia] : memref<?xi8>
    %y = memref.load %b[%ib] : memref<?xi8>
    %e = arith.cmpi eq, %x, %y : i8
    %o = arith.andi %acc, %e : i1
    scf.yield %o : i1
  }
  return %r : i1
}

// token t of (b,toks) occurs among the first n tokens of (c,ctoks)
func.func @tok_in(%b: memref<?xi8>, %toks: memref<?x2xindex>, %t: index,
                  %c: memref<?xi8>, %ctoks: memref<?x2xindex>, %n: index) -> i1 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %s = memref.load %toks[%t, %c0] : memref<?x2xindex>
  %e = memref.load %toks[%t, %c1] : memref<?x2xindex>
  %f = arith.constant false
  %r = scf.for %k = %c0 to %n step %c1 iter_args(%acc = %f) -> (i1) {
    %s2 = memref.load %ctoks[%k, %c0] : memref<?x2xindex>
    %e2 = memref.load %ctoks[%k, %c1] : memref<?x2xindex>
    %eq = func.call @tok_eq(%b, %s, %e, %c, %s2, %e2) : (memref<?xi8>, index, index, memref<?xi8>, index, index) -> i1
    %o = arith.ori %acc, %eq : i1
    scf.yield %o : i1
  }
  return %r : i1
}

// number of distinct tokens
func.func @tok_unique(%b: memref<?xi8>, %toks: memref<?x2xindex>, %n: index) -> index {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %r = scf.for %t = %c0 to %n step %c1 iter_args(%acc = %c0) -> (index) {
    %seen = func.call @tok_in(%b, %toks, %t, %b, %toks, %t) : (memref<?xi8>, memref<?x2xindex>, index, memref<?xi8>, memref<?x2xindex>, index) -> i1
    %inc = arith.addi %acc, %c1 : index
    %o = arith.select %seen, %acc, %inc : index
    scf.yield %o : index
  }
  return %r : index
}

// ------------------------------------------------------------- embedding
// Deterministic 64-dim lexical projection. The source uses Python's salted
// hash(); this port uses 64-bit FNV-1a (see GAPS.md). Floor-div/mod semantics
// follow Python: idx = |h| % 64, sign = +1 iff (h // 64) % 2 == 0.
func.func @fnv1a(%b: memref<?xi8>, %s: index, %e: index) -> i64 {
  %basis = arith.constant -3750763034362895579 : i64
  %prime = arith.constant 1099511628211 : i64
  %c1 = arith.constant 1 : index
  %r = scf.for %i = %s to %e step %c1 iter_args(%h = %basis) -> (i64) {
    %ch = memref.load %b[%i] : memref<?xi8>
    %c64 = arith.extui %ch : i8 to i64
    %x = arith.xori %h, %c64 : i64
    %m = arith.muli %x, %prime : i64
    scf.yield %m : i64
  }
  return %r : i64
}

func.func @embed(%b0: memref<?xi8>, %len: index, %vec: memref<64xf64>) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c64 = arith.constant 64 : index
  %z = arith.constant 0.0 : f64
  scf.for %i = %c0 to %c64 step %c1 {
    memref.store %z, %vec[%i] : memref<64xf64>
  }
  %b = func.call @lower(%b0, %len) : (memref<?xi8>, index) -> memref<?xi8>
  %toks = memref.alloc(%len) : memref<?x2xindex>
  %n = func.call @tokenize(%b, %len, %toks) : (memref<?xi8>, index, memref<?x2xindex>) -> index
  %i64_64 = arith.constant 64 : i64
  %i0 = arith.constant 0 : i64
  %i2 = arith.constant 2 : i64
  %one = arith.constant 1.0 : f64
  %mone = arith.constant -1.0 : f64
  scf.for %t = %c0 to %n step %c1 {
    %s = memref.load %toks[%t, %c0] : memref<?x2xindex>
    %e = memref.load %toks[%t, %c1] : memref<?x2xindex>
    %h = func.call @fnv1a(%b, %s, %e) : (memref<?xi8>, index, index) -> i64
    %neg = arith.cmpi slt, %h, %i0 : i64
    %nh = arith.subi %i0, %h : i64
    %ah = arith.select %neg, %nh, %h : i64
    %idx = arith.remui %ah, %i64_64 : i64
    %q = arith.floordivsi %h, %i64_64 : i64
    %qm = arith.remsi %q, %i2 : i64
    %even = arith.cmpi eq, %qm, %i0 : i64
    %sg = arith.select %even, %one, %mone : f64
    %ii = arith.index_cast %idx : i64 to index
    %old = memref.load %vec[%ii] : memref<64xf64>
    %nv = arith.addf %old, %sg : f64
    memref.store %nv, %vec[%ii] : memref<64xf64>
  }
  %ss = scf.for %i = %c0 to %c64 step %c1 iter_args(%acc = %z) -> (f64) {
    %v = memref.load %vec[%i] : memref<64xf64>
    %vv = arith.mulf %v, %v : f64
    %o = arith.addf %acc, %vv : f64
    scf.yield %o : f64
  }
  %norm = math.sqrt %ss : f64
  %eps = arith.constant 1.0e-12 : f64
  %big = arith.cmpf ogt, %norm, %eps : f64
  scf.if %big {
    scf.for %i = %c0 to %c64 step %c1 {
      %v = memref.load %vec[%i] : memref<64xf64>
      %d = arith.divf %v, %norm : f64
      memref.store %d, %vec[%i] : memref<64xf64>
    }
  }
  return
}

// ------------------------------------------------------------- retrieval
// EmbeddingOracle.retrieve, lexical fallback. Filter: if `domain` is a
// non-empty literal, only entries whose indexed domain equals it qualify.
// Writes (slot, score) of the top `limit` results, stable by score desc;
// returns the result count.
func.func @retrieve(%q0: memref<?xi8>, %qlen: index, %limit: index, %domain: !llvm.ptr,
                    %outslot: memref<?xindex>, %outscore: memref<?xf64>) -> index {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %q = func.call @lower(%q0, %qlen) : (memref<?xi8>, index) -> memref<?xi8>
  %qt = memref.alloc(%qlen) : memref<?x2xindex>
  %qn = func.call @tokenize(%q, %qlen, %qt) : (memref<?xi8>, index, memref<?x2xindex>) -> index
  %qu = func.call @tok_unique(%q, %qt, %qn) : (memref<?xi8>, memref<?x2xindex>, index) -> index
  %n = func.call @cas_count() : () -> index
  %cslot = memref.alloc(%n) : memref<?xindex>
  %cscore = memref.alloc(%n) : memref<?xf64>
  %dfirst = llvm.load %domain : !llvm.ptr -> i8
  %z8 = arith.constant 0 : i8
  %hasfilter = arith.cmpi ne, %dfirst, %z8 : i8
  %dt = memref.get_global @cas_domain : memref<128x64xi8>
  %dls = memref.get_global @cas_dlen : memref<128xindex>
  %true_c = arith.constant true
  %half = arith.constant 0.5 : f64
  %ten = arith.constant 10.0 : f64
  %one = arith.constant 1.0 : f64
  %zf = arith.constant 0.0 : f64
  %cnt = scf.for %s = %c0 to %n step %c1 iter_args(%m = %c0) -> (index) {
    // filter check
    %dl = memref.load %dls[%s] : memref<128xindex>
    %db = func.call @s_new() : () -> memref<?xi8>
    scf.for %i = %c0 to %dl step %c1 {
      %ch = memref.load %dt[%s, %i] : memref<128x64xi8>
      memref.store %ch, %db[%i] : memref<?xi8>
    }
    %dm = func.call @buf_eq_cstr(%db, %c0, %dl, %domain) : (memref<?xi8>, index, index, !llvm.ptr) -> i1
    %nf = arith.xori %hasfilter, %true_c : i1
    %pass = arith.ori %nf, %dm : i1
    %m2 = scf.if %pass -> (index) {
      %doc:2 = func.call @cas_get(%s) : (index) -> (memref<?xi8>, index)
      %d = func.call @lower(%doc#0, %doc#1) : (memref<?xi8>, index) -> memref<?xi8>
      %dtk = memref.alloc(%doc#1) : memref<?x2xindex>
      %dn = func.call @tokenize(%d, %doc#1, %dtk) : (memref<?xi8>, index, memref<?x2xindex>) -> index
      %du = func.call @tok_unique(%d, %dtk, %dn) : (memref<?xi8>, memref<?x2xindex>, index) -> index
      // |Q ∩ D| over distinct query tokens
      %inter = scf.for %t = %c0 to %qn step %c1 iter_args(%acc = %c0) -> (index) {
        %dup = func.call @tok_in(%q, %qt, %t, %q, %qt, %t) : (memref<?xi8>, memref<?x2xindex>, index, memref<?xi8>, memref<?x2xindex>, index) -> i1
        %ind = func.call @tok_in(%q, %qt, %t, %d, %dtk, %dn) : (memref<?xi8>, memref<?x2xindex>, index, memref<?xi8>, memref<?x2xindex>, index) -> i1
        %nd = arith.xori %dup, %true_c : i1
        %hit = arith.andi %nd, %ind : i1
        %inc = arith.addi %acc, %c1 : index
        %o = arith.select %hit, %inc, %acc : index
        scf.yield %o : index
      }
      %u0 = arith.addi %qu, %du : index
      %union = arith.subi %u0, %inter : index
      %ui = arith.index_cast %union : index to i64
      %ii = arith.index_cast %inter : index to i64
      %uf = arith.sitofp %ui : i64 to f64
      %if = arith.sitofp %ii : i64 to f64
      %hasu = arith.cmpi ne, %union, %c0 : index
      %jr = arith.divf %if, %uf : f64
      %jac = arith.select %hasu, %jr, %zf : f64
      // tf = number of document tokens (with multiplicity) that are query tokens
      %tf = scf.for %t = %c0 to %dn step %c1 iter_args(%acc = %zf) -> (f64) {
        %inq = func.call @tok_in(%d, %dtk, %t, %q, %qt, %qn) : (memref<?xi8>, memref<?x2xindex>, index, memref<?xi8>, memref<?x2xindex>, index) -> i1
        %a1 = arith.addf %acc, %one : f64
        %o = arith.select %inq, %a1, %acc : f64
        scf.yield %o : f64
      }
      %tfd = arith.divf %tf, %ten : f64
      %tfm = arith.minimumf %tfd, %half : f64
      %jh = arith.mulf %jac, %half : f64
      %sim = arith.addf %jh, %tfm : f64
      memref.store %s, %cslot[%m] : memref<?xindex>
      memref.store %sim, %cscore[%m] : memref<?xf64>
      %mm = arith.addi %m, %c1 : index
      scf.yield %mm : index
    } else {
      scf.yield %m : index
    }
    scf.yield %m2 : index
  }
  // stable insertion sort by score, descending
  scf.for %i = %c1 to %cnt step %c1 {
    %ks = memref.load %cslot[%i] : memref<?xindex>
    %kv = memref.load %cscore[%i] : memref<?xf64>
    %pos = scf.while (%j = %i) : (index) -> (index) {
      %gt0 = arith.cmpi ugt, %j, %c0 : index
      %mv = scf.if %gt0 -> (i1) {
        %jm = arith.subi %j, %c1 : index
        %pv = memref.load %cscore[%jm] : memref<?xf64>
        %lt = arith.cmpf olt, %pv, %kv : f64
        scf.yield %lt : i1
      } else {
        %f = arith.constant false
        scf.yield %f : i1
      }
      scf.condition(%mv) %j : index
    } do {
    ^bb0(%j: index):
      %jm = arith.subi %j, %c1 : index
      %ps = memref.load %cslot[%jm] : memref<?xindex>
      %pv = memref.load %cscore[%jm] : memref<?xf64>
      memref.store %ps, %cslot[%j] : memref<?xindex>
      memref.store %pv, %cscore[%j] : memref<?xf64>
      scf.yield %jm : index
    }
    memref.store %ks, %cslot[%pos] : memref<?xindex>
    memref.store %kv, %cscore[%pos] : memref<?xf64>
  }
  %take = arith.minui %cnt, %limit : index
  scf.for %i = %c0 to %take step %c1 {
    %s = memref.load %cslot[%i] : memref<?xindex>
    %v = memref.load %cscore[%i] : memref<?xf64>
    memref.store %s, %outslot[%i] : memref<?xindex>
    memref.store %v, %outscore[%i] : memref<?xf64>
  }
  return %take : index
}

// EmbeddingOracle.record_document: CAS put + embed + index. Returns slot.
func.func @record_document(%buf: memref<?xi8>, %len: index, %creator: !llvm.ptr, %domain: !llvm.ptr, %out: memref<8xi32>) -> index {
  %slot = func.call @cas_put(%buf, %len, %creator, %domain, %out) : (memref<?xi8>, index, !llvm.ptr, !llvm.ptr, memref<8xi32>) -> index
  %v = memref.alloca() : memref<64xf64>
  func.call @embed(%buf, %len, %v) : (memref<?xi8>, index, memref<64xf64>) -> ()
  return %slot : index
}
