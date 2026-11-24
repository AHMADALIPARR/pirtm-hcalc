// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// main/oracle.mlir — port of tests/test_oracle.py (CAS put/get/immutability/
// provenance/verify, deterministic embedding, retrieval + filter) plus the
// SHA-256 known-answer values used as cross-checks.

llvm.mlir.global internal constant @e_empty("\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_t("== oracle: CAS + retrieval (tests/test_oracle.py)\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_d1("test invariant I04 immutability content\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_a01("A01\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_a04("A04\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_abc("abc\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_doc1("unitary transformation matrix Pauli gate\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_doc2("causal DAG event order partial order\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_quantum("quantum\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_causality("causality\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_q1("unitary transformation\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_q2("transformation\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_q3("quantum unitarity\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_e1("quantum circuit unitarity invariant\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_e2("historical nostalgic quatrain evaluation\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_sha("sha256 \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_put("put sha \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_put2("re-put same sha (immutability) \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_getok("get roundtrip equal \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_prov("provenance creator==A01 \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_ver("verify integrity_valid \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_ret("retrieve \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_filt(" filter domain=causality\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_arrow(" -> \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_score(" score \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_bits(" bits \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_count("results \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_emb("embed: len=64 deterministic=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_emb2(" distinct=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_tok("tokens(\"Evidence[R1:H_x]: status=TESTED, items.\") = \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @o_toksrc("Evidence[R1:H_x]: status=TESTED, items.\00") {addr_space = 0 : i32}

func.func @lit(%p: !llvm.ptr) -> (memref<?xi8>, index) {
  %b = func.call @s_new() : () -> memref<?xi8>
  %c0 = arith.constant 0 : index
  %l = func.call @s_cstr(%b, %c0, %p) : (memref<?xi8>, index, !llvm.ptr) -> index
  return %b, %l : memref<?xi8>, index
}

func.func @print_lit_hex(%label: !llvm.ptr, %d: memref<8xi32>) {
  %b = func.call @s_new() : () -> memref<?xi8>
  %c0 = arith.constant 0 : index
  %c64 = arith.constant 64 : index
  %l1 = func.call @s_cstr(%b, %c0, %label) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_hex(%b, %l1, %d, %c64) : (memref<?xi8>, index, memref<8xi32>, index) -> index
  func.call @s_print(%b, %l2) : (memref<?xi8>, index) -> ()
  return
}

func.func @print_label_bool(%label: !llvm.ptr, %v: i1) {
  %b = func.call @s_new() : () -> memref<?xi8>
  %c0 = arith.constant 0 : index
  %l1 = func.call @s_cstr(%b, %c0, %label) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_bool(%b, %l1, %v) : (memref<?xi8>, index, i1) -> index
  func.call @s_print(%b, %l2) : (memref<?xi8>, index) -> ()
  return
}

func.func @do_retrieve(%q: !llvm.ptr, %domain: !llvm.ptr, %filtered: i1) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c5 = arith.constant 5 : index
  %c64 = arith.constant 64 : index
  %qb:2 = func.call @lit(%q) : (!llvm.ptr) -> (memref<?xi8>, index)
  %os = memref.alloc(%c5) : memref<?xindex>
  %ov = memref.alloc(%c5) : memref<?xf64>
  %n = func.call @retrieve(%qb#0, %qb#1, %c5, %domain, %os, %ov) : (memref<?xi8>, index, index, !llvm.ptr, memref<?xindex>, memref<?xf64>) -> index
  %d = memref.alloca() : memref<8xi32>
  scf.for %i = %c0 to %n step %c1 {
    %s = memref.load %os[%i] : memref<?xindex>
    %v = memref.load %ov[%i] : memref<?xf64>
    func.call @cas_digest(%s, %d) : (index, memref<8xi32>) -> ()
    %b = func.call @s_new() : () -> memref<?xi8>
    %pr = llvm.mlir.addressof @o_ret : !llvm.ptr
    %l1 = func.call @s_cstr(%b, %c0, %pr) : (memref<?xi8>, index, !llvm.ptr) -> index
    %qt = arith.constant 39 : i8
    %l2 = func.call @s_byte(%b, %l1, %qt) : (memref<?xi8>, index, i8) -> index
    %l3 = func.call @s_cstr(%b, %l2, %q) : (memref<?xi8>, index, !llvm.ptr) -> index
    %l4 = func.call @s_byte(%b, %l3, %qt) : (memref<?xi8>, index, i8) -> index
    %fp = llvm.mlir.addressof @o_filt : !llvm.ptr
    %l5 = scf.if %filtered -> (index) {
      %x = func.call @s_cstr(%b, %l4, %fp) : (memref<?xi8>, index, !llvm.ptr) -> index
      scf.yield %x : index
    } else {
      scf.yield %l4 : index
    }
    %ap = llvm.mlir.addressof @o_arrow : !llvm.ptr
    %l6 = func.call @s_cstr(%b, %l5, %ap) : (memref<?xi8>, index, !llvm.ptr) -> index
    %l7 = func.call @s_hex(%b, %l6, %d, %c64) : (memref<?xi8>, index, memref<8xi32>, index) -> index
    %sp = llvm.mlir.addressof @o_score : !llvm.ptr
    %l8 = func.call @s_cstr(%b, %l7, %sp) : (memref<?xi8>, index, !llvm.ptr) -> index
    %l9 = func.call @s_repr(%b, %l8, %v) : (memref<?xi8>, index, f64) -> index
    %bp = llvm.mlir.addressof @o_bits : !llvm.ptr
    %l10 = func.call @s_cstr(%b, %l9, %bp) : (memref<?xi8>, index, !llvm.ptr) -> index
    %vb = arith.bitcast %v : f64 to i64
    %l11 = func.call @s_int(%b, %l10, %vb) : (memref<?xi8>, index, i64) -> index
    func.call @s_print(%b, %l11) : (memref<?xi8>, index) -> ()
  }
  return
}

func.func @main() -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c64 = arith.constant 64 : index
  %true = arith.constant true
  %false = arith.constant false
  %e = llvm.mlir.addressof @e_empty : !llvm.ptr
  %t = llvm.mlir.addressof @o_t : !llvm.ptr
  %tb:2 = func.call @lit(%t) : (!llvm.ptr) -> (memref<?xi8>, index)
  func.call @s_print(%tb#0, %tb#1) : (memref<?xi8>, index) -> ()
  // SHA-256 known answers
  %pabc = llvm.mlir.addressof @o_abc : !llvm.ptr
  %ab:2 = func.call @lit(%pabc) : (!llvm.ptr) -> (memref<?xi8>, index)
  %dg = memref.alloca() : memref<8xi32>
  func.call @sha256(%ab#0, %ab#1, %dg) : (memref<?xi8>, index, memref<8xi32>) -> ()
  %lsha = llvm.mlir.addressof @o_sha : !llvm.ptr
  func.call @print_lit_hex(%lsha, %dg) : (!llvm.ptr, memref<8xi32>) -> ()
  func.call @sha256(%ab#0, %c0, %dg) : (memref<?xi8>, index, memref<8xi32>) -> ()
  func.call @print_lit_hex(%lsha, %dg) : (!llvm.ptr, memref<8xi32>) -> ()
  // test_cas_put_get_immutability
  func.call @cas_reset() : () -> ()
  %pd1 = llvm.mlir.addressof @o_d1 : !llvm.ptr
  %a01 = llvm.mlir.addressof @o_a01 : !llvm.ptr
  %d1:2 = func.call @lit(%pd1) : (!llvm.ptr) -> (memref<?xi8>, index)
  %s1 = func.call @cas_put(%d1#0, %d1#1, %a01, %e, %dg) : (memref<?xi8>, index, !llvm.ptr, !llvm.ptr, memref<8xi32>) -> index
  %lput = llvm.mlir.addressof @o_put : !llvm.ptr
  func.call @print_lit_hex(%lput, %dg) : (!llvm.ptr, memref<8xi32>) -> ()
  %dg2 = memref.alloca() : memref<8xi32>
  %s2 = func.call @cas_put(%d1#0, %d1#1, %a01, %e, %dg2) : (memref<?xi8>, index, !llvm.ptr, !llvm.ptr, memref<8xi32>) -> index
  %lput2 = llvm.mlir.addressof @o_put2 : !llvm.ptr
  func.call @print_lit_hex(%lput2, %dg2) : (!llvm.ptr, memref<8xi32>) -> ()
  %got:2 = func.call @cas_get(%s1) : (index) -> (memref<?xi8>, index)
  %geq = func.call @buf_eq_cstr(%got#0, %c0, %got#1, %pd1) : (memref<?xi8>, index, index, !llvm.ptr) -> i1
  %sameslot = arith.cmpi eq, %s1, %s2 : index
  %g = arith.andi %geq, %sameslot : i1
  %lget = llvm.mlir.addressof @o_getok : !llvm.ptr
  func.call @print_label_bool(%lget, %g) : (!llvm.ptr, i1) -> ()
  %pv = func.call @cas_creator_is(%s1, %a01) : (index, !llvm.ptr) -> i1
  %lprov = llvm.mlir.addressof @o_prov : !llvm.ptr
  func.call @print_label_bool(%lprov, %pv) : (!llvm.ptr, i1) -> ()
  %vv = func.call @cas_verify(%s1) : (index) -> i1
  %lver = llvm.mlir.addressof @o_ver : !llvm.ptr
  func.call @print_label_bool(%lver, %vv) : (!llvm.ptr, i1) -> ()
  // test_oracle_embed_deterministic_fallback
  %pe1 = llvm.mlir.addressof @o_e1 : !llvm.ptr
  %pe2 = llvm.mlir.addressof @o_e2 : !llvm.ptr
  %e1:2 = func.call @lit(%pe1) : (!llvm.ptr) -> (memref<?xi8>, index)
  %e2:2 = func.call @lit(%pe2) : (!llvm.ptr) -> (memref<?xi8>, index)
  %v1 = memref.alloca() : memref<64xf64>
  %v1b = memref.alloca() : memref<64xf64>
  %v2 = memref.alloca() : memref<64xf64>
  func.call @embed(%e1#0, %e1#1, %v1) : (memref<?xi8>, index, memref<64xf64>) -> ()
  func.call @embed(%e1#0, %e1#1, %v1b) : (memref<?xi8>, index, memref<64xf64>) -> ()
  func.call @embed(%e2#0, %e2#1, %v2) : (memref<?xi8>, index, memref<64xf64>) -> ()
  %res:2 = scf.for %i = %c0 to %c64 step %c1 iter_args(%same = %true, %diff = %false) -> (i1, i1) {
    %a = memref.load %v1[%i] : memref<64xf64>
    %b = memref.load %v1b[%i] : memref<64xf64>
    %c = memref.load %v2[%i] : memref<64xf64>
    %x = arith.cmpf oeq, %a, %b : f64
    %y = arith.cmpf one, %a, %c : f64
    %s = arith.andi %same, %x : i1
    %d = arith.ori %diff, %y : i1
    scf.yield %s, %d : i1, i1
  }
  %eb = func.call @s_new() : () -> memref<?xi8>
  %lemb = llvm.mlir.addressof @o_emb : !llvm.ptr
  %el1 = func.call @s_cstr(%eb, %c0, %lemb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %el2 = func.call @s_bool(%eb, %el1, %res#0) : (memref<?xi8>, index, i1) -> index
  %lemb2 = llvm.mlir.addressof @o_emb2 : !llvm.ptr
  %el3 = func.call @s_cstr(%eb, %el2, %lemb2) : (memref<?xi8>, index, !llvm.ptr) -> index
  %el4 = func.call @s_bool(%eb, %el3, %res#1) : (memref<?xi8>, index, i1) -> index
  func.call @s_print(%eb, %el4) : (memref<?xi8>, index) -> ()
  // tokenizer check on punctuation-heavy text
  %pts = llvm.mlir.addressof @o_toksrc : !llvm.ptr
  %ts:2 = func.call @lit(%pts) : (!llvm.ptr) -> (memref<?xi8>, index)
  %tl = func.call @lower(%ts#0, %ts#1) : (memref<?xi8>, index) -> memref<?xi8>
  %tk = memref.alloc(%ts#1) : memref<?x2xindex>
  %tn = func.call @tokenize(%tl, %ts#1, %tk) : (memref<?xi8>, index, memref<?x2xindex>) -> index
  %tb2 = func.call @s_new() : () -> memref<?xi8>
  %ptok = llvm.mlir.addressof @o_tok : !llvm.ptr
  %tl1 = func.call @s_cstr(%tb2, %c0, %ptok) : (memref<?xi8>, index, !llvm.ptr) -> index
  %bar = arith.constant 124 : i8
  %tl2 = scf.for %i = %c0 to %tn step %c1 iter_args(%l = %tl1) -> (index) {
    %s = memref.load %tk[%i, %c0] : memref<?x2xindex>
    %en = memref.load %tk[%i, %c1] : memref<?x2xindex>
    %la = func.call @s_slice(%tb2, %l, %tl, %s, %en) : (memref<?xi8>, index, memref<?xi8>, index, index) -> index
    %lb = func.call @s_byte(%tb2, %la, %bar) : (memref<?xi8>, index, i8) -> index
    scf.yield %lb : index
  }
  func.call @s_print(%tb2, %tl2) : (memref<?xi8>, index) -> ()
  // test_oracle_retrieve_and_filter (fresh oracle)
  func.call @cas_reset() : () -> ()
  %a04 = llvm.mlir.addressof @o_a04 : !llvm.ptr
  %pdoc1 = llvm.mlir.addressof @o_doc1 : !llvm.ptr
  %pdoc2 = llvm.mlir.addressof @o_doc2 : !llvm.ptr
  %pqu = llvm.mlir.addressof @o_quantum : !llvm.ptr
  %pca = llvm.mlir.addressof @o_causality : !llvm.ptr
  %doc1:2 = func.call @lit(%pdoc1) : (!llvm.ptr) -> (memref<?xi8>, index)
  %doc2:2 = func.call @lit(%pdoc2) : (!llvm.ptr) -> (memref<?xi8>, index)
  %r1 = func.call @record_document(%doc1#0, %doc1#1, %a04, %pqu, %dg) : (memref<?xi8>, index, !llvm.ptr, !llvm.ptr, memref<8xi32>) -> index
  func.call @print_lit_hex(%lput, %dg) : (!llvm.ptr, memref<8xi32>) -> ()
  %r2 = func.call @record_document(%doc2#0, %doc2#1, %a01, %pca, %dg) : (memref<?xi8>, index, !llvm.ptr, !llvm.ptr, memref<8xi32>) -> index
  func.call @print_lit_hex(%lput, %dg) : (!llvm.ptr, memref<8xi32>) -> ()
  %pq1 = llvm.mlir.addressof @o_q1 : !llvm.ptr
  %pq2 = llvm.mlir.addressof @o_q2 : !llvm.ptr
  %pq3 = llvm.mlir.addressof @o_q3 : !llvm.ptr
  func.call @do_retrieve(%pq1, %e, %false) : (!llvm.ptr, !llvm.ptr, i1) -> ()
  func.call @do_retrieve(%pq2, %pca, %true) : (!llvm.ptr, !llvm.ptr, i1) -> ()
  func.call @do_retrieve(%pq3, %e, %false) : (!llvm.ptr, !llvm.ptr, i1) -> ()
  %r = arith.constant 0 : i32
  return %r : i32
}
