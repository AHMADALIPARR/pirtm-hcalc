// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// main/engine.mlir — port of pirtm/recursive/engine.py (bounded recursive
// knowledge engine: hypothesis registry with sha256 ids, countermodel check,
// contradiction log that is never pruned, evidence publication with
// content-hash dedup, fuel bound) and tests/test_recursive_engine.py.
// Status codes: 0 PROPOSED, 1 TESTED, 2 COUNTERMODEL_FOUND, 3 VERIFIED.

memref.global "private" @eng_n : memref<1xindex> = dense<0>
memref.global "private" @eng_fuel : memref<1xindex> = dense<0>
memref.global "private" @eng_round : memref<1xindex> = dense<0>
memref.global "private" @eng_contra : memref<1xindex> = dense<0>
memref.global "private" @eng_nseen : memref<1xindex> = dense<0>
memref.global "private" @eng_stmt : memref<16x256xi8> = uninitialized
memref.global "private" @eng_slen : memref<16xindex> = uninitialized
memref.global "private" @eng_id : memref<16x8xi32> = uninitialized
memref.global "private" @eng_status : memref<16xindex> = uninitialized
memref.global "private" @eng_nev : memref<16xindex> = uninitialized
memref.global "private" @eng_ncm : memref<16xindex> = uninitialized
memref.global "private" @eng_nct : memref<16xindex> = uninitialized
memref.global "private" @eng_seen : memref<64x8xi32> = uninitialized

llvm.mlir.global internal constant @g_empty("\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_title("== engine: bounded recursive knowledge engine (max_fuel=4)\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_scen("-- scenario \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_hypo(" hypo H_\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_round(" round \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_fuel(" fuel \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_eval(" eval \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_contra(" contra \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_conv(" conv \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_ev(" ev \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_status(" status H_\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_doc(" doc \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_rounds(" rounds_run \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_preserved(" contradiction_log_preserved \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_dedup("-- test_deduplication: same id \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_regsize(" registry_size \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @st_proposed("PROPOSED\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @st_tested("TESTED\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @st_counter("COUNTERMODEL_FOUND\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @st_verified("VERIFIED\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @ev_a("Evidence[R\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @ev_b(":H_\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @ev_c("]: status=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @ev_d(", model=Mathematical model for \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @ev_e(": validated against retrieved context \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @ev_f(" items.\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @creator("recursive_engine\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @vac1("Moon.madeOfCheese\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @vac2("unitarity violation\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @q_default("quantum unitarity\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h1("Causal graphs are acyclic\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h2("Moon.madeOfCheese is asserted as true\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @h3("Unitary gates preserve inner products\00") {addr_space = 0 : i32}

func.func @gget(%g: memref<1xindex>) -> index {
  %c0 = arith.constant 0 : index
  %v = memref.load %g[%c0] : memref<1xindex>
  return %v : index
}
func.func @gset(%g: memref<1xindex>, %v: index) {
  %c0 = arith.constant 0 : index
  memref.store %v, %g[%c0] : memref<1xindex>
  return
}

func.func @status_lit(%s: index) -> !llvm.ptr {
  %a = llvm.mlir.addressof @st_proposed : !llvm.ptr
  %b = llvm.mlir.addressof @st_tested : !llvm.ptr
  %c = llvm.mlir.addressof @st_counter : !llvm.ptr
  %d = llvm.mlir.addressof @st_verified : !llvm.ptr
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %i1 = arith.cmpi eq, %s, %c1 : index
  %i2 = arith.cmpi eq, %s, %c2 : index
  %i3 = arith.cmpi eq, %s, %c3 : index
  %x1 = arith.select %i1, %b, %a : !llvm.ptr
  %x2 = arith.select %i2, %c, %x1 : !llvm.ptr
  %x3 = arith.select %i3, %d, %x2 : !llvm.ptr
  return %x3 : !llvm.ptr
}

func.func @eng_reset(%fuel: index) {
  %c0 = arith.constant 0 : index
  %n = memref.get_global @eng_n : memref<1xindex>
  %f = memref.get_global @eng_fuel : memref<1xindex>
  %r = memref.get_global @eng_round : memref<1xindex>
  %ct = memref.get_global @eng_contra : memref<1xindex>
  %ns = memref.get_global @eng_nseen : memref<1xindex>
  func.call @gset(%n, %c0) : (memref<1xindex>, index) -> ()
  func.call @gset(%f, %fuel) : (memref<1xindex>, index) -> ()
  func.call @gset(%r, %c0) : (memref<1xindex>, index) -> ()
  func.call @gset(%ct, %c0) : (memref<1xindex>, index) -> ()
  func.call @gset(%ns, %c0) : (memref<1xindex>, index) -> ()
  func.call @cas_reset() : () -> ()
  return
}

// "H_" + sha256(statement)[:12] equality = first 48 bits of the digest
func.func @id_eq(%a: memref<8xi32>, %slot: index) -> i1 {
  %ids = memref.get_global @eng_id : memref<16x8xi32>
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c16 = arith.constant 16 : i32
  %a0 = memref.load %a[%c0] : memref<8xi32>
  %a1 = memref.load %a[%c1] : memref<8xi32>
  %b0 = memref.load %ids[%slot, %c0] : memref<16x8xi32>
  %b1 = memref.load %ids[%slot, %c1] : memref<16x8xi32>
  %e0 = arith.cmpi eq, %a0, %b0 : i32
  %a1h = arith.shrui %a1, %c16 : i32
  %b1h = arith.shrui %b1, %c16 : i32
  %e1 = arith.cmpi eq, %a1h, %b1h : i32
  %r = arith.andi %e0, %e1 : i1
  return %r : i1
}

// propose_hypothesis: returns the registry slot (existing slot on duplicate id)
func.func @propose(%stmt: !llvm.ptr) -> index {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %len = func.call @s_cstr(%b, %c0, %stmt) : (memref<?xi8>, index, !llvm.ptr) -> index
  %d = memref.alloca() : memref<8xi32>
  func.call @sha256(%b, %len, %d) : (memref<?xi8>, index, memref<8xi32>) -> ()
  %ng = memref.get_global @eng_n : memref<1xindex>
  %n = func.call @gget(%ng) : (memref<1xindex>) -> index
  %none = arith.constant -1 : index
  %found = scf.for %s = %c0 to %n step %c1 iter_args(%f = %none) -> (index) {
    %e = func.call @id_eq(%d, %s) : (memref<8xi32>, index) -> i1
    %isn = arith.cmpi eq, %f, %none : index
    %t = arith.andi %e, %isn : i1
    %nf = arith.select %t, %s, %f : index
    scf.yield %nf : index
  }
  %isnew = arith.cmpi eq, %found, %none : index
  %slot = scf.if %isnew -> (index) {
    %ids = memref.get_global @eng_id : memref<16x8xi32>
    scf.for %i = %c0 to %c8 step %c1 {
      %v = memref.load %d[%i] : memref<8xi32>
      memref.store %v, %ids[%n, %i] : memref<16x8xi32>
    }
    %st = memref.get_global @eng_stmt : memref<16x256xi8>
    scf.for %i = %c0 to %len step %c1 {
      %ch = memref.load %b[%i] : memref<?xi8>
      memref.store %ch, %st[%n, %i] : memref<16x256xi8>
    }
    %sl = memref.get_global @eng_slen : memref<16xindex>
    memref.store %len, %sl[%n] : memref<16xindex>
    %stt = memref.get_global @eng_status : memref<16xindex>
    memref.store %c0, %stt[%n] : memref<16xindex>
    %nev = memref.get_global @eng_nev : memref<16xindex>
    %ncm = memref.get_global @eng_ncm : memref<16xindex>
    %nct = memref.get_global @eng_nct : memref<16xindex>
    memref.store %c0, %nev[%n] : memref<16xindex>
    memref.store %c0, %ncm[%n] : memref<16xindex>
    memref.store %c0, %nct[%n] : memref<16xindex>
    %n1 = arith.addi %n, %c1 : index
    func.call @gset(%ng, %n1) : (memref<1xindex>, index) -> ()
    scf.yield %n : index
  } else {
    scf.yield %found : index
  }
  return %slot : index
}

func.func @append_id(%b: memref<?xi8>, %l: index, %slot: index) -> index {
  %ids = memref.get_global @eng_id : memref<16x8xi32>
  %d = memref.alloca() : memref<8xi32>
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  %c12 = arith.constant 12 : index
  scf.for %i = %c0 to %c8 step %c1 {
    %v = memref.load %ids[%slot, %i] : memref<16x8xi32>
    memref.store %v, %d[%i] : memref<8xi32>
  }
  %r = func.call @s_hex(%b, %l, %d, %c12) : (memref<?xi8>, index, memref<8xi32>, index) -> index
  return %r : index
}

func.func @append_stmt(%b: memref<?xi8>, %l: index, %slot: index) -> index {
  %st = memref.get_global @eng_stmt : memref<16x256xi8>
  %sl = memref.get_global @eng_slen : memref<16xindex>
  %n = memref.load %sl[%slot] : memref<16xindex>
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %r = scf.for %i = %c0 to %n step %c1 iter_args(%acc = %l) -> (index) {
    %ch = memref.load %st[%slot, %i] : memref<16x256xi8>
    memref.store %ch, %b[%acc] : memref<?xi8>
    %a2 = arith.addi %acc, %c1 : index
    scf.yield %a2 : index
  }
  return %r : index
}

func.func @seen_or_add(%d: memref<8xi32>) -> i1 {
  %sg = memref.get_global @eng_seen : memref<64x8xi32>
  %nsg = memref.get_global @eng_nseen : memref<1xindex>
  %n = func.call @gget(%nsg) : (memref<1xindex>) -> index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  %tmp = memref.alloca() : memref<8xi32>
  %f = arith.constant false
  %seen = scf.for %s = %c0 to %n step %c1 iter_args(%acc = %f) -> (i1) {
    scf.for %i = %c0 to %c8 step %c1 {
      %v = memref.load %sg[%s, %i] : memref<64x8xi32>
      memref.store %v, %tmp[%i] : memref<8xi32>
    }
    %e = func.call @digest_eq(%tmp, %d) : (memref<8xi32>, memref<8xi32>) -> i1
    %o = arith.ori %acc, %e : i1
    scf.yield %o : i1
  }
  scf.if %seen {
  } else {
    scf.for %i = %c0 to %c8 step %c1 {
      %v = memref.load %d[%i] : memref<8xi32>
      memref.store %v, %sg[%n, %i] : memref<64x8xi32>
    }
    %n1 = arith.addi %n, %c1 : index
    func.call @gset(%nsg, %n1) : (memref<1xindex>, index) -> ()
  }
  return %seen : i1
}

// step_round: prints " round r fuel f eval n contra c conv b ev [..]"; returns converged
func.func @step_round(%query: !llvm.ptr) -> i1 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %c5 = arith.constant 5 : index
  %c64 = arith.constant 64 : index
  %true = arith.constant true
  %fg = memref.get_global @eng_fuel : memref<1xindex>
  %rg = memref.get_global @eng_round : memref<1xindex>
  %ctg = memref.get_global @eng_contra : memref<1xindex>
  %ng = memref.get_global @eng_n : memref<1xindex>
  %fuel0 = func.call @gget(%fg) : (memref<1xindex>) -> index
  %out = func.call @s_new() : () -> memref<?xi8>
  %nofuel = arith.cmpi eq, %fuel0, %c0 : index
  %conv = scf.if %nofuel -> (i1) {
    scf.yield %true : i1
  } else {
    %r0 = func.call @gget(%rg) : (memref<1xindex>) -> index
    %round = arith.addi %r0, %c1 : index
    func.call @gset(%rg, %round) : (memref<1xindex>, index) -> ()
    %fuel = arith.subi %fuel0, %c1 : index
    func.call @gset(%fg, %fuel) : (memref<1xindex>, index) -> ()
    // 1. RETRIEVE CONTEXT
    %qb = func.call @s_new() : () -> memref<?xi8>
    %ql = func.call @s_cstr(%qb, %c0, %query) : (memref<?xi8>, index, !llvm.ptr) -> index
    %os = memref.alloc(%c5) : memref<?xindex>
    %ov = memref.alloc(%c5) : memref<?xf64>
    %e = llvm.mlir.addressof @g_empty : !llvm.ptr
    %nctx = func.call @retrieve(%qb, %ql, %c5, %e, %os, %ov) : (memref<?xi8>, index, index, !llvm.ptr, memref<?xindex>, memref<?xf64>) -> index
    // header of the round line
    %pr = llvm.mlir.addressof @g_round : !llvm.ptr
    %l1 = func.call @s_cstr(%out, %c0, %pr) : (memref<?xi8>, index, !llvm.ptr) -> index
    %round64 = arith.index_cast %round : index to i64
    %l2 = func.call @s_uint(%out, %l1, %round64) : (memref<?xi8>, index, i64) -> index
    %pf = llvm.mlir.addressof @g_fuel : !llvm.ptr
    %l3 = func.call @s_cstr(%out, %l2, %pf) : (memref<?xi8>, index, !llvm.ptr) -> index
    %fuel64 = arith.index_cast %fuel : index to i64
    %l4 = func.call @s_uint(%out, %l3, %fuel64) : (memref<?xi8>, index, i64) -> index
    // evidence list collected separately
    %evb = func.call @s_new() : () -> memref<?xi8>
    %lb = arith.constant 91 : i8
    %ev0 = func.call @s_byte(%evb, %c0, %lb) : (memref<?xi8>, index, i8) -> index
    %n = func.call @gget(%ng) : (memref<1xindex>) -> index
    %stt = memref.get_global @eng_status : memref<16xindex>
    %nev = memref.get_global @eng_nev : memref<16xindex>
    %ncm = memref.get_global @eng_ncm : memref<16xindex>
    %nct = memref.get_global @eng_nct : memref<16xindex>
    %evl:2 = scf.for %h = %c0 to %n step %c1 iter_args(%el = %ev0, %first = %true) -> (index, i1) {
      %s = memref.load %stt[%h] : memref<16xindex>
      %done2 = arith.cmpi eq, %s, %c2 : index
      %done3 = arith.cmpi eq, %s, %c3 : index
      %skip = arith.ori %done2, %done3 : i1
      %res:2 = scf.if %skip -> (index, i1) {
        scf.yield %el, %first : index, i1
      } else {
        // 4. GENERATE COUNTERMODELS (vacuity pattern check)
        %sb = func.call @s_new() : () -> memref<?xi8>
        %sl = func.call @append_stmt(%sb, %c0, %h) : (memref<?xi8>, index, index) -> index
        %v1 = llvm.mlir.addressof @vac1 : !llvm.ptr
        %v2 = llvm.mlir.addressof @vac2 : !llvm.ptr
        %i1 = func.call @buf_contains(%sb, %sl, %v1) : (memref<?xi8>, index, !llvm.ptr) -> i1
        %i2 = func.call @buf_contains(%sb, %sl, %v2) : (memref<?xi8>, index, !llvm.ptr) -> i1
        %vac = arith.ori %i1, %i2 : i1
        scf.if %vac {
          %x = memref.load %ncm[%h] : memref<16xindex>
          %x1 = arith.addi %x, %c1 : index
          memref.store %x1, %ncm[%h] : memref<16xindex>
          %y = memref.load %nct[%h] : memref<16xindex>
          %y1 = arith.addi %y, %c1 : index
          memref.store %y1, %nct[%h] : memref<16xindex>
          memref.store %c2, %stt[%h] : memref<16xindex>
          %cl = func.call @gget(%ctg) : (memref<1xindex>) -> index
          %cl1 = arith.addi %cl, %c1 : index
          func.call @gset(%ctg, %cl1) : (memref<1xindex>, index) -> ()
        } else {
          memref.store %c1, %stt[%h] : memref<16xindex>
        }
        // 7. PUBLISH EVIDENCE
        %ns = memref.load %stt[%h] : memref<16xindex>
        %eb = func.call @s_new() : () -> memref<?xi8>
        %pa = llvm.mlir.addressof @ev_a : !llvm.ptr
        %pb = llvm.mlir.addressof @ev_b : !llvm.ptr
        %pc = llvm.mlir.addressof @ev_c : !llvm.ptr
        %pd = llvm.mlir.addressof @ev_d : !llvm.ptr
        %pe = llvm.mlir.addressof @ev_e : !llvm.ptr
        %pff = llvm.mlir.addressof @ev_f : !llvm.ptr
        %k1 = func.call @s_cstr(%eb, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
        %k2 = func.call @s_uint(%eb, %k1, %round64) : (memref<?xi8>, index, i64) -> index
        %k3 = func.call @s_cstr(%eb, %k2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
        %k4 = func.call @append_id(%eb, %k3, %h) : (memref<?xi8>, index, index) -> index
        %k5 = func.call @s_cstr(%eb, %k4, %pc) : (memref<?xi8>, index, !llvm.ptr) -> index
        %sp = func.call @status_lit(%ns) : (index) -> !llvm.ptr
        %k6 = func.call @s_cstr(%eb, %k5, %sp) : (memref<?xi8>, index, !llvm.ptr) -> index
        %k7 = func.call @s_cstr(%eb, %k6, %pd) : (memref<?xi8>, index, !llvm.ptr) -> index
        %k8 = func.call @append_stmt(%eb, %k7, %h) : (memref<?xi8>, index, index) -> index
        %k9 = func.call @s_cstr(%eb, %k8, %pe) : (memref<?xi8>, index, !llvm.ptr) -> index
        %nctx64 = arith.index_cast %nctx : index to i64
        %k10 = func.call @s_uint(%eb, %k9, %nctx64) : (memref<?xi8>, index, i64) -> index
        %k11 = func.call @s_cstr(%eb, %k10, %pff) : (memref<?xi8>, index, !llvm.ptr) -> index
        %evh = memref.alloca() : memref<8xi32>
        func.call @sha256(%eb, %k11, %evh) : (memref<?xi8>, index, memref<8xi32>) -> ()
        %seen = func.call @seen_or_add(%evh) : (memref<8xi32>) -> i1
        %r2:2 = scf.if %seen -> (index, i1) {
          scf.yield %el, %first : index, i1
        } else {
          %cr = llvm.mlir.addressof @creator : !llvm.ptr
          %dg = memref.alloca() : memref<8xi32>
          %slot = func.call @record_document(%eb, %k11, %cr, %e, %dg) : (memref<?xi8>, index, !llvm.ptr, !llvm.ptr, memref<8xi32>) -> index
          %x = memref.load %nev[%h] : memref<16xindex>
          %x1 = arith.addi %x, %c1 : index
          memref.store %x1, %nev[%h] : memref<16xindex>
          %comma = arith.constant 44 : i8
          %spc = arith.constant 32 : i8
          %q = arith.constant 39 : i8
          %ea = scf.if %first -> (index) {
            scf.yield %el : index
          } else {
            %t1 = func.call @s_byte(%evb, %el, %comma) : (memref<?xi8>, index, i8) -> index
            %t2 = func.call @s_byte(%evb, %t1, %spc) : (memref<?xi8>, index, i8) -> index
            scf.yield %t2 : index
          }
          %eq1 = func.call @s_byte(%evb, %ea, %q) : (memref<?xi8>, index, i8) -> index
          %eh = func.call @s_hex(%evb, %eq1, %dg, %c64) : (memref<?xi8>, index, memref<8xi32>, index) -> index
          %eq2 = func.call @s_byte(%evb, %eh, %q) : (memref<?xi8>, index, i8) -> index
          %false = arith.constant false
          scf.yield %eq2, %false : index, i1
        }
        scf.yield %r2#0, %r2#1 : index, i1
      }
      scf.yield %res#0, %res#1 : index, i1
    }
    // 8. CHECK CONVERGENCE
    %allok = scf.for %h = %c0 to %n step %c1 iter_args(%acc = %true) -> (i1) {
      %s = memref.load %stt[%h] : memref<16xindex>
      %p = arith.cmpi ne, %s, %c0 : index
      %o = arith.andi %acc, %p : i1
      scf.yield %o : i1
    }
    %fz = arith.cmpi eq, %fuel, %c0 : index
    %cv = arith.ori %fz, %allok : i1
    %pe2 = llvm.mlir.addressof @g_eval : !llvm.ptr
    %l5 = func.call @s_cstr(%out, %l4, %pe2) : (memref<?xi8>, index, !llvm.ptr) -> index
    %n64 = arith.index_cast %n : index to i64
    %l6 = func.call @s_uint(%out, %l5, %n64) : (memref<?xi8>, index, i64) -> index
    %pc2 = llvm.mlir.addressof @g_contra : !llvm.ptr
    %l7 = func.call @s_cstr(%out, %l6, %pc2) : (memref<?xi8>, index, !llvm.ptr) -> index
    %cl = func.call @gget(%ctg) : (memref<1xindex>) -> index
    %cl64 = arith.index_cast %cl : index to i64
    %l8 = func.call @s_uint(%out, %l7, %cl64) : (memref<?xi8>, index, i64) -> index
    %pcv = llvm.mlir.addressof @g_conv : !llvm.ptr
    %l9 = func.call @s_cstr(%out, %l8, %pcv) : (memref<?xi8>, index, !llvm.ptr) -> index
    %l10 = func.call @s_bool(%out, %l9, %cv) : (memref<?xi8>, index, i1) -> index
    %pev = llvm.mlir.addressof @g_ev : !llvm.ptr
    %l11 = func.call @s_cstr(%out, %l10, %pev) : (memref<?xi8>, index, !llvm.ptr) -> index
    %rb = arith.constant 93 : i8
    %evend = func.call @s_byte(%evb, %evl#0, %rb) : (memref<?xi8>, index, i8) -> index
    %l12 = func.call @s_slice(%out, %l11, %evb, %c0, %evend) : (memref<?xi8>, index, memref<?xi8>, index, index) -> index
    func.call @s_print(%out, %l12) : (memref<?xi8>, index) -> ()
    scf.yield %cv : i1
  }
  return %conv : i1
}

// run_until_convergence; returns number of rounds run
func.func @run_until_convergence(%query: !llvm.ptr) -> index {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %fg = memref.get_global @eng_fuel : memref<1xindex>
  %true = arith.constant true
  %r:2 = scf.while (%k = %c0, %go = %true) : (index, i1) -> (index, i1) {
    %f = func.call @gget(%fg) : (memref<1xindex>) -> index
    %hasf = arith.cmpi ugt, %f, %c0 : index
    %c = arith.andi %hasf, %go : i1
    scf.condition(%c) %k, %go : index, i1
  } do {
  ^bb0(%k: index, %go: i1):
    %cv = func.call @step_round(%query) : (!llvm.ptr) -> i1
    %k1 = arith.addi %k, %c1 : index
    %ng = arith.xori %cv, %true : i1
    scf.yield %k1, %ng : index, i1
  }
  return %r#0 : index
}

func.func @print_hypo(%slot: index) {
  %c0 = arith.constant 0 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %p = llvm.mlir.addressof @g_hypo : !llvm.ptr
  %l1 = func.call @s_cstr(%b, %c0, %p) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @append_id(%b, %l1, %slot) : (memref<?xi8>, index, index) -> index
  %sp = arith.constant 32 : i8
  %q = arith.constant 39 : i8
  %l3 = func.call @s_byte(%b, %l2, %sp) : (memref<?xi8>, index, i8) -> index
  %l4 = func.call @s_byte(%b, %l3, %q) : (memref<?xi8>, index, i8) -> index
  %l5 = func.call @append_stmt(%b, %l4, %slot) : (memref<?xi8>, index, index) -> index
  %l6 = func.call @s_byte(%b, %l5, %q) : (memref<?xi8>, index, i8) -> index
  func.call @s_print(%b, %l6) : (memref<?xi8>, index) -> ()
  return
}

func.func @print_summary(%rounds: index) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %sp = arith.constant 32 : i8
  %ng = memref.get_global @eng_n : memref<1xindex>
  %n = func.call @gget(%ng) : (memref<1xindex>) -> index
  %stt = memref.get_global @eng_status : memref<16xindex>
  %ncm = memref.get_global @eng_ncm : memref<16xindex>
  %nct = memref.get_global @eng_nct : memref<16xindex>
  scf.for %h = %c0 to %n step %c1 {
    %b = func.call @s_new() : () -> memref<?xi8>
    %p = llvm.mlir.addressof @g_status : !llvm.ptr
    %l1 = func.call @s_cstr(%b, %c0, %p) : (memref<?xi8>, index, !llvm.ptr) -> index
    %l2 = func.call @append_id(%b, %l1, %h) : (memref<?xi8>, index, index) -> index
    %l3 = func.call @s_byte(%b, %l2, %sp) : (memref<?xi8>, index, i8) -> index
    %s = memref.load %stt[%h] : memref<16xindex>
    %sl = func.call @status_lit(%s) : (index) -> !llvm.ptr
    %l4 = func.call @s_cstr(%b, %l3, %sl) : (memref<?xi8>, index, !llvm.ptr) -> index
    %l5 = func.call @s_byte(%b, %l4, %sp) : (memref<?xi8>, index, i8) -> index
    %cm = memref.load %ncm[%h] : memref<16xindex>
    %cm64 = arith.index_cast %cm : index to i64
    %l6 = func.call @s_uint(%b, %l5, %cm64) : (memref<?xi8>, index, i64) -> index
    %l7 = func.call @s_byte(%b, %l6, %sp) : (memref<?xi8>, index, i8) -> index
    %ct = memref.load %nct[%h] : memref<16xindex>
    %ct64 = arith.index_cast %ct : index to i64
    %l8 = func.call @s_uint(%b, %l7, %ct64) : (memref<?xi8>, index, i64) -> index
    func.call @s_print(%b, %l8) : (memref<?xi8>, index) -> ()
  }
  // every CAS document with its content
  %nd = func.call @cas_count() : () -> index
  %dg = memref.alloca() : memref<8xi32>
  %c64 = arith.constant 64 : index
  scf.for %s = %c0 to %nd step %c1 {
    %b = func.call @s_new() : () -> memref<?xi8>
    %p = llvm.mlir.addressof @g_doc : !llvm.ptr
    %l1 = func.call @s_cstr(%b, %c0, %p) : (memref<?xi8>, index, !llvm.ptr) -> index
    func.call @cas_digest(%s, %dg) : (index, memref<8xi32>) -> ()
    %l2 = func.call @s_hex(%b, %l1, %dg, %c64) : (memref<?xi8>, index, memref<8xi32>, index) -> index
    %l3 = func.call @s_byte(%b, %l2, %sp) : (memref<?xi8>, index, i8) -> index
    %q = arith.constant 39 : i8
    %l4 = func.call @s_byte(%b, %l3, %q) : (memref<?xi8>, index, i8) -> index
    %doc:2 = func.call @cas_get(%s) : (index) -> (memref<?xi8>, index)
    %l5 = func.call @s_slice(%b, %l4, %doc#0, %c0, %doc#1) : (memref<?xi8>, index, memref<?xi8>, index, index) -> index
    %l6 = func.call @s_byte(%b, %l5, %q) : (memref<?xi8>, index, i8) -> index
    func.call @s_print(%b, %l6) : (memref<?xi8>, index) -> ()
  }
  %b = func.call @s_new() : () -> memref<?xi8>
  %p = llvm.mlir.addressof @g_rounds : !llvm.ptr
  %l1 = func.call @s_cstr(%b, %c0, %p) : (memref<?xi8>, index, !llvm.ptr) -> index
  %r64 = arith.index_cast %rounds : index to i64
  %l2 = func.call @s_uint(%b, %l1, %r64) : (memref<?xi8>, index, i64) -> index
  %pp = llvm.mlir.addressof @g_preserved : !llvm.ptr
  %l3 = func.call @s_cstr(%b, %l2, %pp) : (memref<?xi8>, index, !llvm.ptr) -> index
  %ctg = memref.get_global @eng_contra : memref<1xindex>
  %cl = func.call @gget(%ctg) : (memref<1xindex>) -> index
  %cl64 = arith.index_cast %cl : index to i64
  %l4 = func.call @s_uint(%b, %l3, %cl64) : (memref<?xi8>, index, i64) -> index
  func.call @s_print(%b, %l4) : (memref<?xi8>, index) -> ()
  return
}

func.func @title(%p: !llvm.ptr, %k: i64) {
  %c0 = arith.constant 0 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %l1 = func.call @s_cstr(%b, %c0, %p) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_uint(%b, %l1, %k) : (memref<?xi8>, index, i64) -> index
  func.call @s_print(%b, %l2) : (memref<?xi8>, index) -> ()
  return
}

func.func @main() -> i32 {
  %c0 = arith.constant 0 : index
  %c4 = arith.constant 4 : index
  %t = llvm.mlir.addressof @g_title : !llvm.ptr
  %tb = func.call @s_new() : () -> memref<?xi8>
  %tl = func.call @s_cstr(%tb, %c0, %t) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @s_print(%tb, %tl) : (memref<?xi8>, index) -> ()
  %ph1 = llvm.mlir.addressof @h1 : !llvm.ptr
  %ph2 = llvm.mlir.addressof @h2 : !llvm.ptr
  %ph3 = llvm.mlir.addressof @h3 : !llvm.ptr
  %q = llvm.mlir.addressof @q_default : !llvm.ptr
  %ps = llvm.mlir.addressof @g_scen : !llvm.ptr
  %one = arith.constant 1 : i64
  %two = arith.constant 2 : i64
  %three = arith.constant 3 : i64
  // scenario 1: test_bounded_execution_and_fuel_depletion
  func.call @title(%ps, %one) : (!llvm.ptr, i64) -> ()
  func.call @eng_reset(%c4) : (index) -> ()
  %a = func.call @propose(%ph1) : (!llvm.ptr) -> index
  func.call @print_hypo(%a) : (index) -> ()
  %r1 = func.call @run_until_convergence(%q) : (!llvm.ptr) -> index
  func.call @print_summary(%r1) : (index) -> ()
  // scenario 2: test_contradiction_preservation_and_countermodel
  func.call @title(%ps, %two) : (!llvm.ptr, i64) -> ()
  func.call @eng_reset(%c4) : (index) -> ()
  %b = func.call @propose(%ph2) : (!llvm.ptr) -> index
  func.call @print_hypo(%b) : (index) -> ()
  %r2 = func.call @run_until_convergence(%q) : (!llvm.ptr) -> index
  func.call @print_summary(%r2) : (index) -> ()
  // scenario 3: three hypotheses together
  func.call @title(%ps, %three) : (!llvm.ptr, i64) -> ()
  func.call @eng_reset(%c4) : (index) -> ()
  %x1 = func.call @propose(%ph1) : (!llvm.ptr) -> index
  func.call @print_hypo(%x1) : (index) -> ()
  %x2 = func.call @propose(%ph2) : (!llvm.ptr) -> index
  func.call @print_hypo(%x2) : (index) -> ()
  %x3 = func.call @propose(%ph3) : (!llvm.ptr) -> index
  func.call @print_hypo(%x3) : (index) -> ()
  %r3 = func.call @run_until_convergence(%q) : (!llvm.ptr) -> index
  func.call @print_summary(%r3) : (index) -> ()
  // test_deduplication
  func.call @eng_reset(%c4) : (index) -> ()
  %d1 = func.call @propose(%ph3) : (!llvm.ptr) -> index
  %d2 = func.call @propose(%ph3) : (!llvm.ptr) -> index
  %same = arith.cmpi eq, %d1, %d2 : index
  %db = func.call @s_new() : () -> memref<?xi8>
  %pd = llvm.mlir.addressof @g_dedup : !llvm.ptr
  %dl1 = func.call @s_cstr(%db, %c0, %pd) : (memref<?xi8>, index, !llvm.ptr) -> index
  %dl2 = func.call @s_bool(%db, %dl1, %same) : (memref<?xi8>, index, i1) -> index
  %pr = llvm.mlir.addressof @g_regsize : !llvm.ptr
  %dl3 = func.call @s_cstr(%db, %dl2, %pr) : (memref<?xi8>, index, !llvm.ptr) -> index
  %ng = memref.get_global @eng_n : memref<1xindex>
  %nn = func.call @gget(%ng) : (memref<1xindex>) -> index
  %nn64 = arith.index_cast %nn : index to i64
  %dl4 = func.call @s_uint(%db, %dl3, %nn64) : (memref<?xi8>, index, i64) -> index
  func.call @s_print(%db, %dl4) : (memref<?xi8>, index) -> ()
  %r = arith.constant 0 : i32
  return %r : i32
}
