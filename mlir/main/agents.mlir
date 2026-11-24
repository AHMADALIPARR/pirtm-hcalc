// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// main/agents.mlir — port of pirtm/agents/{base,workers}.py and
// pirtm/scheduler/concurrent_runner.py: the 11 logical workers A01..A11,
// their Block-7 reports, and one scheduler cycle with the deterministic merge
// contract (sorted agent order, invariant set union sorted byte-wise, ledger
// integrity check over every merged artifact).
// The source dispatches workers on a ThreadPoolExecutor; the merge only depends
// on sorted agent ids, so this port runs them sequentially in sorted order
// (recorded in GAPS.md).
// Gate opcodes (lib/qsim.mlir): H 0, X 1, Y 2, Z 3, S 4, Sdag 5, CNOT 6.

// !st is defined in lib/qsim.mlir

memref.global "private" @r_block : memref<11xindex> = uninitialized
memref.global "private" @r_pass : memref<11xindex> = uninitialized
memref.global "private" @r_fail : memref<11xindex> = uninitialized
memref.global "private" @r_notrun : memref<11xindex> = uninitialized
memref.global "private" @r_proof : memref<11xindex> = uninitialized
memref.global "private" @r_slot : memref<11xindex> = uninitialized
memref.global "private" @inv_seen : memref<19xi8> = dense<0>

llvm.mlir.global internal constant @a_title("== scheduler: dispatch_cycle(round=1), 11 workers, deterministic merge\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id01("A01\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id02("A02\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id03("A03\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id04("A04\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id05("A05\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id06("A06\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id07("A07\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id08("A08\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id09("A09\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id10("A10\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @id11("A11\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm01("Temporal state transitions\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm02("Reversible quantum evolution\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm03("Eleven-coordinate state transformations\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm04("Quantum measurement distributions\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm05("Historical encoding and decoding\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm06("Symbolic historical-interpretation ambiguity\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm07("Recursive hypothesis revision\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm08("Restricted observer reconstruction\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm09("Entropy and information bounds\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm10("Agda invariant verification\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @dm11("Adversarial counterexample generation\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @pf0("VERIFIED_LOCALLY\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @pf1("REJECTED_AS_PHYSICAL_PREDICTOR\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @pf2("NOT_RUN\00") {addr_space = 0 : i32}
// invariant literals, deliberately in first-appearance order (not sorted)
llvm.mlir.global internal constant @iv0("I02 — Causal ordering\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv1("I01 — State preservation\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv2("I06 — Quantum unitarity\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv3("I07 — Probability normalization\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv4("I08 — Encoding integrity\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv5("I11 — Evidence classification\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv6("I05 — Termination\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv7("I09 — Observation boundaries\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv8("I01\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv9("I02\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv10("I03\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv11("I04\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv12("I05\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv13("I06\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv14("I07\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv15("I08\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv16("I09\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv17("I10\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @iv18("I11\00") {addr_space = 0 : i32}
// artifact text fragments
llvm.mlir.global internal constant @t01("Temporal State Transitions: 11-qubit DAG transitions=3, transition_fidelities=[\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t02a("Reversible 11-Qubit Evolution: norm=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t02b(", roundtrip_fidelity=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t03a("11-Coordinate Hadamard Transformation: 2048-dim uniform superposition verified=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t03b(", max_err=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t04a("11-Qubit Born Rule Probabilities: total_prob=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t04b(", active_outcomes=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t05a("Historical Encoding Experiment: full_recovery_fidelity=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t05b(", restricted_subsystem_trace_rho00=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @quatrain("Quand le fourchu sera soustenus de deux paux, avec six demy cors, & six cizeaux ouvers...\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t06a("Quantitative Ambiguity Scoring: tokens=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t06b(", unique=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t06c(", lexical_entropy_ratio=\00") {addr_space = 0 : i32}
// boundaries.py registry["nostradamus_historical_analysis"].status
llvm.mlir.global internal constant @t06d(", status=SPECULATION\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t07a("Recursive Hypothesis Revision: round=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t07b(", fuel_remaining=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t07c(", converged=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t08a("Restricted Observer Subsystem: purity=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t08b(", mixed_state_loss=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t09a("Subsystem Entropy Bound: von_neumann_entropy=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t09b(" bits, bound_capacity=1.0 bit\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t10("Agda Invariant Verification: Status=NOT_RUN. Required command: `agda --no-libraries -i . agda/PIRTM/Invariants.agda`. Formal Invariants defined: I01 to I11 in agda/PIRTM/Invariants.agda.\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t11a("Central Adversarial Experiment: global_distinguishable=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t11b(", subsystem_distinguishable=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t11c(", trace_distance=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @t11d(", passed=\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @sep(", \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_pass("passed \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_fail(" failed \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_art(" artifacts \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_led(" ledger \00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @g_inv("invariants [\00") {addr_space = 0 : i32}

func.func @agent_id(%k: index) -> !llvm.ptr {
  %p0 = llvm.mlir.addressof @id01 : !llvm.ptr
  %p1 = llvm.mlir.addressof @id02 : !llvm.ptr
  %p2 = llvm.mlir.addressof @id03 : !llvm.ptr
  %p3 = llvm.mlir.addressof @id04 : !llvm.ptr
  %p4 = llvm.mlir.addressof @id05 : !llvm.ptr
  %p5 = llvm.mlir.addressof @id06 : !llvm.ptr
  %p6 = llvm.mlir.addressof @id07 : !llvm.ptr
  %p7 = llvm.mlir.addressof @id08 : !llvm.ptr
  %p8 = llvm.mlir.addressof @id09 : !llvm.ptr
  %p9 = llvm.mlir.addressof @id10 : !llvm.ptr
  %p10 = llvm.mlir.addressof @id11 : !llvm.ptr
  %r = scf.index_switch %k -> !llvm.ptr
  case 0 { scf.yield %p0 : !llvm.ptr }
  case 1 { scf.yield %p1 : !llvm.ptr }
  case 2 { scf.yield %p2 : !llvm.ptr }
  case 3 { scf.yield %p3 : !llvm.ptr }
  case 4 { scf.yield %p4 : !llvm.ptr }
  case 5 { scf.yield %p5 : !llvm.ptr }
  case 6 { scf.yield %p6 : !llvm.ptr }
  case 7 { scf.yield %p7 : !llvm.ptr }
  case 8 { scf.yield %p8 : !llvm.ptr }
  case 9 { scf.yield %p9 : !llvm.ptr }
  default { scf.yield %p10 : !llvm.ptr }
  return %r : !llvm.ptr
}

func.func @agent_domain(%k: index) -> !llvm.ptr {
  %p0 = llvm.mlir.addressof @dm01 : !llvm.ptr
  %p1 = llvm.mlir.addressof @dm02 : !llvm.ptr
  %p2 = llvm.mlir.addressof @dm03 : !llvm.ptr
  %p3 = llvm.mlir.addressof @dm04 : !llvm.ptr
  %p4 = llvm.mlir.addressof @dm05 : !llvm.ptr
  %p5 = llvm.mlir.addressof @dm06 : !llvm.ptr
  %p6 = llvm.mlir.addressof @dm07 : !llvm.ptr
  %p7 = llvm.mlir.addressof @dm08 : !llvm.ptr
  %p8 = llvm.mlir.addressof @dm09 : !llvm.ptr
  %p9 = llvm.mlir.addressof @dm10 : !llvm.ptr
  %p10 = llvm.mlir.addressof @dm11 : !llvm.ptr
  %r = scf.index_switch %k -> !llvm.ptr
  case 0 { scf.yield %p0 : !llvm.ptr }
  case 1 { scf.yield %p1 : !llvm.ptr }
  case 2 { scf.yield %p2 : !llvm.ptr }
  case 3 { scf.yield %p3 : !llvm.ptr }
  case 4 { scf.yield %p4 : !llvm.ptr }
  case 5 { scf.yield %p5 : !llvm.ptr }
  case 6 { scf.yield %p6 : !llvm.ptr }
  case 7 { scf.yield %p7 : !llvm.ptr }
  case 8 { scf.yield %p8 : !llvm.ptr }
  case 9 { scf.yield %p9 : !llvm.ptr }
  default { scf.yield %p10 : !llvm.ptr }
  return %r : !llvm.ptr
}

func.func @proof_lit(%k: index) -> !llvm.ptr {
  %a = llvm.mlir.addressof @pf0 : !llvm.ptr
  %b = llvm.mlir.addressof @pf1 : !llvm.ptr
  %c = llvm.mlir.addressof @pf2 : !llvm.ptr
  %r = scf.index_switch %k -> !llvm.ptr
  case 0 { scf.yield %a : !llvm.ptr }
  case 1 { scf.yield %b : !llvm.ptr }
  default { scf.yield %c : !llvm.ptr }
  return %r : !llvm.ptr
}

func.func @inv_lit(%k: index) -> !llvm.ptr {
  %p0 = llvm.mlir.addressof @iv0 : !llvm.ptr
  %p1 = llvm.mlir.addressof @iv1 : !llvm.ptr
  %p2 = llvm.mlir.addressof @iv2 : !llvm.ptr
  %p3 = llvm.mlir.addressof @iv3 : !llvm.ptr
  %p4 = llvm.mlir.addressof @iv4 : !llvm.ptr
  %p5 = llvm.mlir.addressof @iv5 : !llvm.ptr
  %p6 = llvm.mlir.addressof @iv6 : !llvm.ptr
  %p7 = llvm.mlir.addressof @iv7 : !llvm.ptr
  %p8 = llvm.mlir.addressof @iv8 : !llvm.ptr
  %p9 = llvm.mlir.addressof @iv9 : !llvm.ptr
  %p10 = llvm.mlir.addressof @iv10 : !llvm.ptr
  %p11 = llvm.mlir.addressof @iv11 : !llvm.ptr
  %p12 = llvm.mlir.addressof @iv12 : !llvm.ptr
  %p13 = llvm.mlir.addressof @iv13 : !llvm.ptr
  %p14 = llvm.mlir.addressof @iv14 : !llvm.ptr
  %p15 = llvm.mlir.addressof @iv15 : !llvm.ptr
  %p16 = llvm.mlir.addressof @iv16 : !llvm.ptr
  %p17 = llvm.mlir.addressof @iv17 : !llvm.ptr
  %p18 = llvm.mlir.addressof @iv18 : !llvm.ptr
  %r = scf.index_switch %k -> !llvm.ptr
  case 0 { scf.yield %p0 : !llvm.ptr }
  case 1 { scf.yield %p1 : !llvm.ptr }
  case 2 { scf.yield %p2 : !llvm.ptr }
  case 3 { scf.yield %p3 : !llvm.ptr }
  case 4 { scf.yield %p4 : !llvm.ptr }
  case 5 { scf.yield %p5 : !llvm.ptr }
  case 6 { scf.yield %p6 : !llvm.ptr }
  case 7 { scf.yield %p7 : !llvm.ptr }
  case 8 { scf.yield %p8 : !llvm.ptr }
  case 9 { scf.yield %p9 : !llvm.ptr }
  case 10 { scf.yield %p10 : !llvm.ptr }
  case 11 { scf.yield %p11 : !llvm.ptr }
  case 12 { scf.yield %p12 : !llvm.ptr }
  case 13 { scf.yield %p13 : !llvm.ptr }
  case 14 { scf.yield %p14 : !llvm.ptr }
  case 15 { scf.yield %p15 : !llvm.ptr }
  case 16 { scf.yield %p16 : !llvm.ptr }
  case 17 { scf.yield %p17 : !llvm.ptr }
  default { scf.yield %p18 : !llvm.ptr }
  return %r : !llvm.ptr
}

// byte-wise (= code point, for UTF-8) strict less-than on C strings
func.func @cstr_lt(%a: !llvm.ptr, %b: !llvm.ptr) -> i1 {
  %c0 = arith.constant 0 : i64
  %c1 = arith.constant 1 : i64
  %z = arith.constant 0 : i8
  %r:2 = scf.while (%i = %c0) : (i64) -> (i64, i64) {
    %pa = llvm.getelementptr %a[%i] : (!llvm.ptr, i64) -> !llvm.ptr, i8
    %pb = llvm.getelementptr %b[%i] : (!llvm.ptr, i64) -> !llvm.ptr, i8
    %x = llvm.load %pa : !llvm.ptr -> i8
    %y = llvm.load %pb : !llvm.ptr -> i8
    %eq = arith.cmpi eq, %x, %y : i8
    %nz = arith.cmpi ne, %x, %z : i8
    %go = arith.andi %eq, %nz : i1
    scf.condition(%go) %i, %i : i64, i64
  } do {
  ^bb0(%i: i64, %j: i64):
    %n = arith.addi %i, %c1 : i64
    scf.yield %n : i64
  }
  %pa = llvm.getelementptr %a[%r#0] : (!llvm.ptr, i64) -> !llvm.ptr, i8
  %pb = llvm.getelementptr %b[%r#0] : (!llvm.ptr, i64) -> !llvm.ptr, i8
  %x = llvm.load %pa : !llvm.ptr -> i8
  %y = llvm.load %pb : !llvm.ptr -> i8
  %lt = arith.cmpi ult, %x, %y : i8
  return %lt : i1
}

func.func @assert_inv(%k: index) {
  %g = memref.get_global @inv_seen : memref<19xi8>
  %one = arith.constant 1 : i8
  memref.store %one, %g[%k] : memref<19xi8>
  return
}

// record the artifact in the oracle and store the Block-7 report fields
func.func @finish(%k: index, %b: memref<?xi8>, %len: index, %block: index, %pass: index, %fail: index,
                  %notrun: index, %proof: index) {
  %id = func.call @agent_id(%k) : (index) -> !llvm.ptr
  %dm = func.call @agent_domain(%k) : (index) -> !llvm.ptr
  %dg = memref.alloca() : memref<8xi32>
  %slot = func.call @record_document(%b, %len, %id, %dm, %dg) : (memref<?xi8>, index, !llvm.ptr, !llvm.ptr, memref<8xi32>) -> index
  %g0 = memref.get_global @r_block : memref<11xindex>
  %g1 = memref.get_global @r_pass : memref<11xindex>
  %g2 = memref.get_global @r_fail : memref<11xindex>
  %g3 = memref.get_global @r_notrun : memref<11xindex>
  %g4 = memref.get_global @r_proof : memref<11xindex>
  %g5 = memref.get_global @r_slot : memref<11xindex>
  memref.store %block, %g0[%k] : memref<11xindex>
  memref.store %pass, %g1[%k] : memref<11xindex>
  memref.store %fail, %g2[%k] : memref<11xindex>
  memref.store %notrun, %g3[%k] : memref<11xindex>
  memref.store %proof, %g4[%k] : memref<11xindex>
  memref.store %slot, %g5[%k] : memref<11xindex>
  return
}

func.func @gate(%c: memref<?x3xindex>, %row: index, %op: index, %q0: index, %q1: index) {
  func.call @set_gate(%c, %row, %op, %q0, %q1) : (memref<?x3xindex>, index, index, index, index) -> ()
  return
}

func.func @w01() {
  %nq = arith.constant 11 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c3 = arith.constant 3 : index
  %h = arith.constant 0 : index
  %cx = arith.constant 6 : index
  %s0 = func.call @sv_basis(%nq, %c0) : (index, index) -> !st
  %b = func.call @s_new() : () -> memref<?xi8>
  %p = llvm.mlir.addressof @t01 : !llvm.ptr
  %l0 = func.call @s_cstr(%b, %c0, %p) : (memref<?xi8>, index, !llvm.ptr) -> index
  %sp = llvm.mlir.addressof @sep : !llvm.ptr
  %l1 = scf.for %i = %c0 to %c3 step %c1 iter_args(%l = %l0) -> (index) {
    %prev = func.call @sv_copy(%s0) : (!st) -> !st
    %i1 = arith.addi %i, %c1 : index
    %x = func.call @sv_apply_op(%s0, %nq, %h, %i, %c0) : (!st, index, index, index, index) -> !st
    %y = func.call @sv_apply_op(%x, %nq, %cx, %i, %i1) : (!st, index, index, index, index) -> !st
    %f = func.call @sv_fidelity(%prev, %y) : (!st, !st) -> f64
    %first = arith.cmpi eq, %i, %c0 : index
    %la = scf.if %first -> (index) {
      scf.yield %l : index
    } else {
      %t = func.call @s_cstr(%b, %l, %sp) : (memref<?xi8>, index, !llvm.ptr) -> index
      scf.yield %t : index
    }
    %lb = func.call @s_repr(%b, %la, %f) : (memref<?xi8>, index, f64) -> index
    scf.yield %lb : index
  }
  %rb = arith.constant 93 : i8
  %l2 = func.call @s_byte(%b, %l1, %rb) : (memref<?xi8>, index, i8) -> index
  %k = arith.constant 0 : index
  %blk = arith.constant 1 : index
  %ps = arith.constant 3 : index
  func.call @finish(%k, %b, %l2, %blk, %ps, %c0, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  %iv = arith.constant 0 : index
  func.call @assert_inv(%iv) : (index) -> ()
  return
}

func.func @w02() {
  %nq = arith.constant 11 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %c4 = arith.constant 4 : index
  %c5 = arith.constant 5 : index
  %c6 = arith.constant 6 : index
  %c10 = arith.constant 10 : index
  %c42 = arith.constant 42 : index
  %init = func.call @sv_basis(%nq, %c42) : (index, index) -> !st
  %st0 = func.call @sv_copy(%init) : (!st) -> !st
  %circ = memref.alloc(%c5) : memref<?x3xindex>
  func.call @gate(%circ, %c0, %c0, %c0, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @gate(%circ, %c1, %c6, %c0, %c5) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @gate(%circ, %c2, %c4, %c5, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @gate(%circ, %c3, %c6, %c5, %c10) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @gate(%circ, %c4, %c1, %c10, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  %ev = func.call @sv_evolve(%st0, %nq, %circ) : (!st, index, memref<?x3xindex>) -> !st
  %norm = func.call @sv_norm2(%ev) : (!st) -> f64
  %back = func.call @sv_evolve_inverse(%ev, %nq, %circ) : (!st, index, memref<?x3xindex>) -> !st
  %fid = func.call @sv_fidelity(%init, %back) : (!st, !st) -> f64
  %one = arith.constant 1.0 : f64
  %tol = arith.constant 1.0e-6 : f64
  %d1 = arith.subf %norm, %one : f64
  %a1 = math.absf %d1 : f64
  %d2 = arith.subf %fid, %one : f64
  %a2 = math.absf %d2 : f64
  %ok1 = arith.cmpf olt, %a1, %tol : f64
  %ok2 = arith.cmpf olt, %a2, %tol : f64
  %ok = arith.andi %ok1, %ok2 : i1
  %pass = arith.select %ok, %c2, %c0 : index
  %fail = arith.select %ok, %c0, %c1 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t02a : !llvm.ptr
  %pb = llvm.mlir.addressof @t02b : !llvm.ptr
  %six = arith.constant 6 : i64
  %eight = arith.constant 8 : i64
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_fixed(%b, %l1, %norm, %six) : (memref<?xi8>, index, f64, i64) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l4 = func.call @s_fixed(%b, %l3, %fid, %eight) : (memref<?xi8>, index, f64, i64) -> index
  func.call @finish(%c1, %b, %l4, %c1, %pass, %fail, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c1) : (index) -> ()
  func.call @assert_inv(%c2) : (index) -> ()
  return
}

func.func @w03() {
  %nq = arith.constant 11 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %s0 = func.call @sv_basis(%nq, %c0) : (index, index) -> !st
  %s = scf.for %q = %c0 to %nq step %c1 iter_args(%x = %s0) -> (!st) {
    %y = func.call @sv_apply_op(%x, %nq, %c0, %q, %c0) : (!st, index, index, index, index) -> !st
    scf.yield %y : !st
  }
  %onef = arith.constant 1.0 : f64
  %d2048 = arith.constant 2048.0 : f64
  %sq = math.sqrt %d2048 : f64
  %exp = arith.divf %onef, %sq : f64
  %dim = memref.dim %s, %c0 : !st
  %zf = arith.constant 0.0 : f64
  %mx = scf.for %i = %c0 to %dim step %c1 iter_args(%m = %zf) -> (f64) {
    %a = memref.load %s[%i] : !st
    %re = complex.re %a : complex<f64>
    %d = arith.subf %re, %exp : f64
    %ad = math.absf %d : f64
    %gt = arith.cmpf ogt, %ad, %m : f64
    %nm = arith.select %gt, %ad, %m : f64
    scf.yield %nm : f64
  }
  %tol = arith.constant 1.0e-6 : f64
  %uni = arith.cmpf olt, %mx, %tol : f64
  %pass = arith.select %uni, %c1, %c0 : index
  %fail = arith.select %uni, %c0, %c1 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t03a : !llvm.ptr
  %pb = llvm.mlir.addressof @t03b : !llvm.ptr
  %two = arith.constant 2 : i64
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_bool(%b, %l1, %uni) : (memref<?xi8>, index, i1) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l4 = func.call @s_sci(%b, %l3, %mx, %two) : (memref<?xi8>, index, f64, i64) -> index
  func.call @finish(%c2, %b, %l4, %c1, %pass, %fail, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c1) : (index) -> ()
  return
}

// CPython >= 3.12 sum() over floats: Neumaier compensated summation
func.func @py_sum(%v: memref<?xf64>) -> f64 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %n = memref.dim %v, %c0 : memref<?xf64>
  %z = arith.constant 0.0 : f64
  %r:2 = scf.for %i = %c0 to %n step %c1 iter_args(%s = %z, %c = %z) -> (f64, f64) {
    %x = memref.load %v[%i] : memref<?xf64>
    %t = arith.addf %s, %x : f64
    %as = math.absf %s : f64
    %ax = math.absf %x : f64
    %ge = arith.cmpf oge, %as, %ax : f64
    %d1 = arith.subf %s, %t : f64
    %e1 = arith.addf %d1, %x : f64
    %d2 = arith.subf %x, %t : f64
    %e2 = arith.addf %d2, %s : f64
    %e = arith.select %ge, %e1, %e2 : f64
    %nc = arith.addf %c, %e : f64
    scf.yield %t, %nc : f64, f64
  }
  %out = arith.addf %r#0, %r#1 : f64
  return %out : f64
}

func.func @w04() {
  %nq = arith.constant 11 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %c4 = arith.constant 4 : index
  %c6 = arith.constant 6 : index
  %s0 = func.call @sv_basis(%nq, %c0) : (index, index) -> !st
  %s1 = func.call @sv_apply_op(%s0, %nq, %c0, %c0, %c0) : (!st, index, index, index, index) -> !st
  %s2 = func.call @sv_apply_op(%s1, %nq, %c6, %c0, %c1) : (!st, index, index, index, index) -> !st
  %s3 = func.call @sv_apply_op(%s2, %nq, %c6, %c1, %c2) : (!st, index, index, index, index) -> !st
  %pr = func.call @sv_probabilities(%s3) : (!st) -> memref<?xf64>
  %sum = func.call @py_sum(%pr) : (memref<?xf64>) -> f64
  %n = memref.dim %pr, %c0 : memref<?xf64>
  %thr = arith.constant 1.0e-5 : f64
  %nz = scf.for %i = %c0 to %n step %c1 iter_args(%k = %c0) -> (index) {
    %p = memref.load %pr[%i] : memref<?xf64>
    %gt = arith.cmpf ogt, %p, %thr : f64
    %k1 = arith.addi %k, %c1 : index
    %nk = arith.select %gt, %k1, %k : index
    scf.yield %nk : index
  }
  %one = arith.constant 1.0 : f64
  %tol = arith.constant 1.0e-6 : f64
  %d = arith.subf %sum, %one : f64
  %ad = math.absf %d : f64
  %nv = arith.cmpf olt, %ad, %tol : f64
  %two_out = arith.cmpi eq, %nz, %c2 : index
  %ok = arith.andi %nv, %two_out : i1
  %pass = arith.select %ok, %c2, %c0 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t04a : !llvm.ptr
  %pb = llvm.mlir.addressof @t04b : !llvm.ptr
  %eight = arith.constant 8 : i64
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_fixed(%b, %l1, %sum, %eight) : (memref<?xi8>, index, f64, i64) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %nz64 = arith.index_cast %nz : index to i64
  %l4 = func.call @s_uint(%b, %l3, %nz64) : (memref<?xi8>, index, i64) -> index
  func.call @finish(%c3, %b, %l4, %c4, %pass, %c0, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c3) : (index) -> ()
  return
}

func.func @w05() {
  %nq = arith.constant 11 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %c4 = arith.constant 4 : index
  %c5 = arith.constant 5 : index
  %c6 = arith.constant 6 : index
  %c7 = arith.constant 7 : index
  %c100 = arith.constant 100 : index
  %st = func.call @sv_basis(%nq, %c100) : (index, index) -> !st
  %init = func.call @sv_copy(%st) : (!st) -> !st
  %circ = memref.alloc(%c3) : memref<?x3xindex>
  func.call @gate(%circ, %c0, %c0, %c0, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @gate(%circ, %c1, %c6, %c0, %c4) : (memref<?x3xindex>, index, index, index, index) -> ()
  func.call @gate(%circ, %c2, %c1, %c7, %c0) : (memref<?x3xindex>, index, index, index, index) -> ()
  %ev = func.call @sv_evolve(%st, %nq, %circ) : (!st, index, memref<?x3xindex>) -> !st
  %rec0 = func.call @sv_copy(%ev) : (!st) -> !st
  %rec = func.call @sv_evolve_inverse(%rec0, %nq, %circ) : (!st, index, memref<?x3xindex>) -> !st
  %fid = func.call @sv_fidelity(%init, %rec) : (!st, !st) -> f64
  %acc = memref.alloc(%c1) : memref<?xindex>
  memref.store %c0, %acc[%c0] : memref<?xindex>
  %rho = func.call @sv_partial_trace(%ev, %nq, %acc) : (!st, index, memref<?xindex>) -> memref<?x?xcomplex<f64>>
  %r00 = memref.load %rho[%c0, %c0] : memref<?x?xcomplex<f64>>
  %p0 = complex.re %r00 : complex<f64>
  %thr = arith.constant 0.999 : f64
  %ok = arith.cmpf ogt, %fid, %thr : f64
  %pass = arith.select %ok, %c2, %c0 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t05a : !llvm.ptr
  %pb = llvm.mlir.addressof @t05b : !llvm.ptr
  %eight = arith.constant 8 : i64
  %four = arith.constant 4 : i64
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_fixed(%b, %l1, %fid, %eight) : (memref<?xi8>, index, f64, i64) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l4 = func.call @s_fixed(%b, %l3, %p0, %four) : (memref<?xi8>, index, f64, i64) -> index
  func.call @finish(%c4, %b, %l4, %c5, %pass, %c0, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c4) : (index) -> ()
  return
}

// str.split(): maximal runs of non-whitespace (space, \t, \n, \r, \v, \f)
func.func @is_space(%ch: i8) -> i1 {
  %sp = arith.constant 32 : i8
  %t9 = arith.constant 9 : i8
  %t13 = arith.constant 13 : i8
  %a = arith.cmpi eq, %ch, %sp : i8
  %ge = arith.cmpi uge, %ch, %t9 : i8
  %le = arith.cmpi ule, %ch, %t13 : i8
  %r = arith.andi %ge, %le : i1
  %o = arith.ori %a, %r : i1
  return %o : i1
}

func.func @split_ws(%b: memref<?xi8>, %len: index, %toks: memref<?x2xindex>) -> index {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %none = arith.constant -1 : index
  %r:2 = scf.for %i = %c0 to %len step %c1 iter_args(%n = %c0, %start = %none) -> (index, index) {
    %ch = memref.load %b[%i] : memref<?xi8>
    %ws = func.call @is_space(%ch) : (i8) -> i1
    %inside = arith.cmpi ne, %start, %none : index
    %res:2 = scf.if %ws -> (index, index) {
      %n2 = scf.if %inside -> (index) {
        memref.store %start, %toks[%n, %c0] : memref<?x2xindex>
        memref.store %i, %toks[%n, %c1] : memref<?x2xindex>
        %n1 = arith.addi %n, %c1 : index
        scf.yield %n1 : index
      } else {
        scf.yield %n : index
      }
      scf.yield %n2, %none : index, index
    } else {
      %s2 = arith.select %inside, %start, %i : index
      scf.yield %n, %s2 : index, index
    }
    scf.yield %res#0, %res#1 : index, index
  }
  %inside = arith.cmpi ne, %r#1, %none : index
  %final = scf.if %inside -> (index) {
    memref.store %r#1, %toks[%r#0, %c0] : memref<?x2xindex>
    memref.store %len, %toks[%r#0, %c1] : memref<?x2xindex>
    %n1 = arith.addi %r#0, %c1 : index
    scf.yield %n1 : index
  } else {
    scf.yield %r#0 : index
  }
  return %final : index
}

func.func @w06() {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c5 = arith.constant 5 : index
  %c6 = arith.constant 6 : index
  %q = llvm.mlir.addressof @quatrain : !llvm.ptr
  %qb = func.call @s_new() : () -> memref<?xi8>
  %ql = func.call @s_cstr(%qb, %c0, %q) : (memref<?xi8>, index, !llvm.ptr) -> index
  %low = func.call @lower(%qb, %ql) : (memref<?xi8>, index) -> memref<?xi8>
  %toks = memref.alloc(%ql) : memref<?x2xindex>
  %n = func.call @split_ws(%low, %ql, %toks) : (memref<?xi8>, index, memref<?x2xindex>) -> index
  %u = func.call @tok_unique(%low, %toks, %n) : (memref<?xi8>, memref<?x2xindex>, index) -> index
  %n64 = arith.index_cast %n : index to i64
  %u64 = arith.index_cast %u : index to i64
  %nf = arith.sitofp %n64 : i64 to f64
  %uf = arith.sitofp %u64 : i64 to f64
  %ratio = arith.divf %uf, %nf : f64
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t06a : !llvm.ptr
  %pb = llvm.mlir.addressof @t06b : !llvm.ptr
  %pc = llvm.mlir.addressof @t06c : !llvm.ptr
  %pd = llvm.mlir.addressof @t06d : !llvm.ptr
  %four = arith.constant 4 : i64
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_uint(%b, %l1, %n64) : (memref<?xi8>, index, i64) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l4 = func.call @s_uint(%b, %l3, %u64) : (memref<?xi8>, index, i64) -> index
  %l5 = func.call @s_cstr(%b, %l4, %pc) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l6 = func.call @s_fixed(%b, %l5, %ratio, %four) : (memref<?xi8>, index, f64, i64) -> index
  %l7 = func.call @s_cstr(%b, %l6, %pd) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @finish(%c5, %b, %l7, %c6, %c1, %c0, %c0, %c1) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c5) : (index) -> ()
  return
}

func.func @w07(%round: i64) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c5 = arith.constant 5 : index
  %c6 = arith.constant 6 : index
  %fuel = arith.constant 3 : i64
  %one = arith.constant 1 : i64
  %conv = arith.cmpi sle, %fuel, %one : i64
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t07a : !llvm.ptr
  %pb = llvm.mlir.addressof @t07b : !llvm.ptr
  %pc = llvm.mlir.addressof @t07c : !llvm.ptr
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_uint(%b, %l1, %round) : (memref<?xi8>, index, i64) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l4 = func.call @s_uint(%b, %l3, %fuel) : (memref<?xi8>, index, i64) -> index
  %l5 = func.call @s_cstr(%b, %l4, %pc) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l6 = func.call @s_bool(%b, %l5, %conv) : (memref<?xi8>, index, i1) -> index
  func.call @finish(%c6, %b, %l6, %c5, %c1, %c0, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c6) : (index) -> ()
  return
}

func.func @w08() {
  %nq = arith.constant 11 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c6 = arith.constant 6 : index
  %c7 = arith.constant 7 : index
  %c10 = arith.constant 10 : index
  %s0 = func.call @sv_basis(%nq, %c0) : (index, index) -> !st
  %s1 = func.call @sv_apply_op(%s0, %nq, %c0, %c0, %c0) : (!st, index, index, index, index) -> !st
  %s2 = func.call @sv_apply_op(%s1, %nq, %c6, %c0, %c10) : (!st, index, index, index, index) -> !st
  %acc = memref.alloc(%c1) : memref<?xindex>
  memref.store %c0, %acc[%c0] : memref<?xindex>
  %rho = func.call @sv_partial_trace(%s2, %nq, %acc) : (!st, index, memref<?xindex>) -> memref<?x?xcomplex<f64>>
  %r00 = memref.load %rho[%c0, %c0] : memref<?x?xcomplex<f64>>
  %r11 = memref.load %rho[%c1, %c1] : memref<?x?xcomplex<f64>>
  %r01 = memref.load %rho[%c0, %c1] : memref<?x?xcomplex<f64>>
  %a = complex.re %r00 : complex<f64>
  %d = complex.re %r11 : complex<f64>
  %x = complex.re %r01 : complex<f64>
  %y = complex.im %r01 : complex<f64>
  %a2 = arith.mulf %a, %a : f64
  %d2 = arith.mulf %d, %d : f64
  %x2 = arith.mulf %x, %x : f64
  %y2 = arith.mulf %y, %y : f64
  %two = arith.constant 2.0 : f64
  %s = arith.addf %a2, %d2 : f64
  %o = arith.addf %x2, %y2 : f64
  %o2 = arith.mulf %two, %o : f64
  %pur = arith.addf %s, %o2 : f64
  %thr = arith.constant 0.99 : f64
  %mixed = arith.cmpf olt, %pur, %thr : f64
  %pass = arith.select %mixed, %c1, %c0 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t08a : !llvm.ptr
  %pb = llvm.mlir.addressof @t08b : !llvm.ptr
  %four = arith.constant 4 : i64
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_fixed(%b, %l1, %pur, %four) : (memref<?xi8>, index, f64, i64) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l4 = func.call @s_bool(%b, %l3, %mixed) : (memref<?xi8>, index, i1) -> index
  func.call @finish(%c7, %b, %l4, %c6, %pass, %c0, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c7) : (index) -> ()
  return
}

func.func @w09() {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c4 = arith.constant 4 : index
  %c8 = arith.constant 8 : index
  %p = arith.constant 0.5 : f64
  %lg = math.log2 %p : f64
  %pl = arith.mulf %p, %lg : f64
  %m2 = arith.constant -2.0 : f64
  %ent = arith.mulf %m2, %pl : f64
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t09a : !llvm.ptr
  %pb = llvm.mlir.addressof @t09b : !llvm.ptr
  %four = arith.constant 4 : i64
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_fixed(%b, %l1, %ent, %four) : (memref<?xi8>, index, f64, i64) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @finish(%c8, %b, %l3, %c1, %c2, %c0, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c4) : (index) -> ()
  return
}

func.func @w10() {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c8 = arith.constant 8 : index
  %c9 = arith.constant 9 : index
  %c11 = arith.constant 11 : index
  %c19 = arith.constant 19 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t10 : !llvm.ptr
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @finish(%c9, %b, %l1, %c2, %c0, %c0, %c11, %c2) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  // invariants = [f"I{i:02d}" for i in range(1, 12)]
  scf.for %k = %c8 to %c19 step %c1 {
    func.call @assert_inv(%k) : (index) -> ()
  }
  return
}

func.func @w11() {
  %nq = arith.constant 11 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c5 = arith.constant 5 : index
  %c7 = arith.constant 7 : index
  %c10 = arith.constant 10 : index
  %r = func.call @sqrt2_inv() : () -> f64
  %z = arith.constant 0.0 : f64
  %i1025 = arith.constant 1025 : index
  %i512 = arith.constant 512 : index
  %i1537 = arith.constant 1537 : index
  %s1a = func.call @sv_alloc(%nq) : (index) -> !st
  %s1b = func.call @sv_set(%s1a, %c0, %r, %z) : (!st, index, f64, f64) -> !st
  %psi1 = func.call @sv_set(%s1b, %i1025, %r, %z) : (!st, index, f64, f64) -> !st
  %s2a = func.call @sv_alloc(%nq) : (index) -> !st
  %s2b = func.call @sv_set(%s2a, %i512, %r, %z) : (!st, index, f64, f64) -> !st
  %psi2 = func.call @sv_set(%s2b, %i1537, %r, %z) : (!st, index, f64, f64) -> !st
  %fid = func.call @sv_fidelity(%psi1, %psi2) : (!st, !st) -> f64
  %acc = memref.alloc(%c1) : memref<?xindex>
  memref.store %c0, %acc[%c0] : memref<?xindex>
  %rho1 = func.call @sv_partial_trace(%psi1, %nq, %acc) : (!st, index, memref<?xindex>) -> memref<?x?xcomplex<f64>>
  %rho2 = func.call @sv_partial_trace(%psi2, %nq, %acc) : (!st, index, memref<?xindex>) -> memref<?x?xcomplex<f64>>
  %td = func.call @trace_distance_bound(%rho1, %rho2) : (memref<?x?xcomplex<f64>>, memref<?x?xcomplex<f64>>) -> f64
  %tol6 = arith.constant 1.0e-6 : f64
  %tol4 = arith.constant 1.0e-4 : f64
  %gd = arith.cmpf olt, %fid, %tol6 : f64
  %sd = arith.cmpf ogt, %td, %tol4 : f64
  %true = arith.constant true
  %nsd = arith.xori %sd, %true : i1
  %passed = arith.andi %gd, %nsd : i1
  %pass = arith.select %passed, %c2, %c0 : index
  %b = func.call @s_new() : () -> memref<?xi8>
  %pa = llvm.mlir.addressof @t11a : !llvm.ptr
  %pb = llvm.mlir.addressof @t11b : !llvm.ptr
  %pc = llvm.mlir.addressof @t11c : !llvm.ptr
  %pd = llvm.mlir.addressof @t11d : !llvm.ptr
  %l1 = func.call @s_cstr(%b, %c0, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l2 = func.call @s_bool(%b, %l1, %gd) : (memref<?xi8>, index, i1) -> index
  %l3 = func.call @s_cstr(%b, %l2, %pb) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l4 = func.call @s_bool(%b, %l3, %sd) : (memref<?xi8>, index, i1) -> index
  %l5 = func.call @s_cstr(%b, %l4, %pc) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l6 = func.call @s_repr(%b, %l5, %td) : (memref<?xi8>, index, f64) -> index
  %l7 = func.call @s_cstr(%b, %l6, %pd) : (memref<?xi8>, index, !llvm.ptr) -> index
  %l8 = func.call @s_bool(%b, %l7, %passed) : (memref<?xi8>, index, i1) -> index
  func.call @finish(%c10, %b, %l8, %c1, %pass, %c0, %c0, %c0) : (index, memref<?xi8>, index, index, index, index, index, index) -> ()
  func.call @assert_inv(%c7) : (index) -> ()
  func.call @assert_inv(%c5) : (index) -> ()
  return
}

func.func @put_idx(%b: memref<?xi8>, %l: index, %v: index) -> index {
  %sp = arith.constant 32 : i8
  %l1 = func.call @s_byte(%b, %l, %sp) : (memref<?xi8>, index, i8) -> index
  %v64 = arith.index_cast %v : index to i64
  %l2 = func.call @s_uint(%b, %l1, %v64) : (memref<?xi8>, index, i64) -> index
  return %l2 : index
}

func.func @main() -> i32 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c11 = arith.constant 11 : index
  %c19 = arith.constant 19 : index
  %c64 = arith.constant 64 : index
  %sp = arith.constant 32 : i8
  %q = arith.constant 39 : i8
  %t = llvm.mlir.addressof @a_title : !llvm.ptr
  %tb = func.call @s_new() : () -> memref<?xi8>
  %tl = func.call @s_cstr(%tb, %c0, %t) : (memref<?xi8>, index, !llvm.ptr) -> index
  func.call @s_print(%tb, %tl) : (memref<?xi8>, index) -> ()
  func.call @cas_reset() : () -> ()
  // dispatch: sorted agent ids, sequential (see header)
  %round = arith.constant 1 : i64
  func.call @w01() : () -> ()
  func.call @w02() : () -> ()
  func.call @w03() : () -> ()
  func.call @w04() : () -> ()
  func.call @w05() : () -> ()
  func.call @w06() : () -> ()
  func.call @w07(%round) : (i64) -> ()
  func.call @w08() : () -> ()
  func.call @w09() : () -> ()
  func.call @w10() : () -> ()
  func.call @w11() : () -> ()
  // deterministic merge
  %g0 = memref.get_global @r_block : memref<11xindex>
  %g1 = memref.get_global @r_pass : memref<11xindex>
  %g2 = memref.get_global @r_fail : memref<11xindex>
  %g3 = memref.get_global @r_notrun : memref<11xindex>
  %g4 = memref.get_global @r_proof : memref<11xindex>
  %g5 = memref.get_global @r_slot : memref<11xindex>
  %dg = memref.alloca() : memref<8xi32>
  %true = arith.constant true
  %tot:3 = scf.for %k = %c0 to %c11 step %c1 iter_args(%tp = %c0, %tf = %c0, %led = %true) -> (index, index, i1) {
    %b = func.call @s_new() : () -> memref<?xi8>
    %id = func.call @agent_id(%k) : (index) -> !llvm.ptr
    %l1 = func.call @s_cstr(%b, %c0, %id) : (memref<?xi8>, index, !llvm.ptr) -> index
    %blk = memref.load %g0[%k] : memref<11xindex>
    %ps = memref.load %g1[%k] : memref<11xindex>
    %fl = memref.load %g2[%k] : memref<11xindex>
    %nr = memref.load %g3[%k] : memref<11xindex>
    %pf = memref.load %g4[%k] : memref<11xindex>
    %sl = memref.load %g5[%k] : memref<11xindex>
    %l2 = func.call @put_idx(%b, %l1, %blk) : (memref<?xi8>, index, index) -> index
    %l3 = func.call @put_idx(%b, %l2, %ps) : (memref<?xi8>, index, index) -> index
    %l4 = func.call @put_idx(%b, %l3, %fl) : (memref<?xi8>, index, index) -> index
    %l5 = func.call @put_idx(%b, %l4, %nr) : (memref<?xi8>, index, index) -> index
    %l6 = func.call @s_byte(%b, %l5, %sp) : (memref<?xi8>, index, i8) -> index
    %pl = func.call @proof_lit(%pf) : (index) -> !llvm.ptr
    %l7 = func.call @s_cstr(%b, %l6, %pl) : (memref<?xi8>, index, !llvm.ptr) -> index
    %l8 = func.call @s_byte(%b, %l7, %sp) : (memref<?xi8>, index, i8) -> index
    func.call @cas_digest(%sl, %dg) : (index, memref<8xi32>) -> ()
    %l9 = func.call @s_hex(%b, %l8, %dg, %c64) : (memref<?xi8>, index, memref<8xi32>, index) -> index
    func.call @s_print(%b, %l9) : (memref<?xi8>, index) -> ()
    %b2 = func.call @s_new() : () -> memref<?xi8>
    %m1 = func.call @s_byte(%b2, %c0, %sp) : (memref<?xi8>, index, i8) -> index
    %m2 = func.call @s_byte(%b2, %m1, %sp) : (memref<?xi8>, index, i8) -> index
    %m3 = func.call @s_byte(%b2, %m2, %sp) : (memref<?xi8>, index, i8) -> index
    %m4 = func.call @s_byte(%b2, %m3, %q) : (memref<?xi8>, index, i8) -> index
    %doc:2 = func.call @cas_get(%sl) : (index) -> (memref<?xi8>, index)
    %m5 = func.call @s_slice(%b2, %m4, %doc#0, %c0, %doc#1) : (memref<?xi8>, index, memref<?xi8>, index, index) -> index
    %m6 = func.call @s_byte(%b2, %m5, %q) : (memref<?xi8>, index, i8) -> index
    func.call @s_print(%b2, %m6) : (memref<?xi8>, index) -> ()
    %ok = func.call @cas_verify(%sl) : (index) -> i1
    %nl = arith.andi %led, %ok : i1
    %ntp = arith.addi %tp, %ps : index
    %ntf = arith.addi %tf, %fl : index
    scf.yield %ntp, %ntf, %nl : index, index, i1
  }
  %sb = func.call @s_new() : () -> memref<?xi8>
  %pp = llvm.mlir.addressof @g_pass : !llvm.ptr
  %pfl = llvm.mlir.addressof @g_fail : !llvm.ptr
  %pa = llvm.mlir.addressof @g_art : !llvm.ptr
  %pld = llvm.mlir.addressof @g_led : !llvm.ptr
  %s1 = func.call @s_cstr(%sb, %c0, %pp) : (memref<?xi8>, index, !llvm.ptr) -> index
  %tp64 = arith.index_cast %tot#0 : index to i64
  %s2 = func.call @s_uint(%sb, %s1, %tp64) : (memref<?xi8>, index, i64) -> index
  %s3 = func.call @s_cstr(%sb, %s2, %pfl) : (memref<?xi8>, index, !llvm.ptr) -> index
  %tf64 = arith.index_cast %tot#1 : index to i64
  %s4 = func.call @s_uint(%sb, %s3, %tf64) : (memref<?xi8>, index, i64) -> index
  %s5 = func.call @s_cstr(%sb, %s4, %pa) : (memref<?xi8>, index, !llvm.ptr) -> index
  %na = func.call @cas_count() : () -> index
  %na64 = arith.index_cast %na : index to i64
  %s6 = func.call @s_uint(%sb, %s5, %na64) : (memref<?xi8>, index, i64) -> index
  %s7 = func.call @s_cstr(%sb, %s6, %pld) : (memref<?xi8>, index, !llvm.ptr) -> index
  %s8 = func.call @s_bool(%sb, %s7, %tot#2) : (memref<?xi8>, index, i1) -> index
  func.call @s_print(%sb, %s8) : (memref<?xi8>, index) -> ()
  // sorted(set(invariants)): insertion sort of literal indices, byte-wise
  %seen = memref.get_global @inv_seen : memref<19xi8>
  %ord = memref.alloca() : memref<19xindex>
  %zero8 = arith.constant 0 : i8
  %m = scf.for %k = %c0 to %c19 step %c1 iter_args(%n = %c0) -> (index) {
    %s = memref.load %seen[%k] : memref<19xi8>
    %on = arith.cmpi ne, %s, %zero8 : i8
    %nn = scf.if %on -> (index) {
      // shift larger entries right, then insert
      %pos = scf.while (%j = %n) : (index) -> index {
        %pos0 = arith.cmpi ugt, %j, %c0 : index
        %more = scf.if %pos0 -> (i1) {
          %jm = arith.subi %j, %c1 : index
          %prev = memref.load %ord[%jm] : memref<19xindex>
          %pp2 = func.call @inv_lit(%prev) : (index) -> !llvm.ptr
          %pk = func.call @inv_lit(%k) : (index) -> !llvm.ptr
          %lt = func.call @cstr_lt(%pk, %pp2) : (!llvm.ptr, !llvm.ptr) -> i1
          scf.yield %lt : i1
        } else {
          %f = arith.constant false
          scf.yield %f : i1
        }
        scf.condition(%more) %j : index
      } do {
      ^bb0(%j: index):
        %jm = arith.subi %j, %c1 : index
        %prev = memref.load %ord[%jm] : memref<19xindex>
        memref.store %prev, %ord[%j] : memref<19xindex>
        scf.yield %jm : index
      }
      memref.store %k, %ord[%pos] : memref<19xindex>
      %n1 = arith.addi %n, %c1 : index
      scf.yield %n1 : index
    } else {
      scf.yield %n : index
    }
    scf.yield %nn : index
  }
  %ib = func.call @s_new() : () -> memref<?xi8>
  %pi = llvm.mlir.addressof @g_inv : !llvm.ptr
  %psep = llvm.mlir.addressof @sep : !llvm.ptr
  %i1 = func.call @s_cstr(%ib, %c0, %pi) : (memref<?xi8>, index, !llvm.ptr) -> index
  %i2 = scf.for %j = %c0 to %m step %c1 iter_args(%l = %i1) -> (index) {
    %first = arith.cmpi eq, %j, %c0 : index
    %la = scf.if %first -> (index) {
      scf.yield %l : index
    } else {
      %x = func.call @s_cstr(%ib, %l, %psep) : (memref<?xi8>, index, !llvm.ptr) -> index
      scf.yield %x : index
    }
    %k = memref.load %ord[%j] : memref<19xindex>
    %lp = func.call @inv_lit(%k) : (index) -> !llvm.ptr
    %lb = func.call @s_byte(%ib, %la, %q) : (memref<?xi8>, index, i8) -> index
    %lc = func.call @s_cstr(%ib, %lb, %lp) : (memref<?xi8>, index, !llvm.ptr) -> index
    %ld = func.call @s_byte(%ib, %lc, %q) : (memref<?xi8>, index, i8) -> index
    scf.yield %ld : index
  }
  %rb = arith.constant 93 : i8
  %i3 = func.call @s_byte(%ib, %i2, %rb) : (memref<?xi8>, index, i8) -> index
  func.call @s_print(%ib, %i3) : (memref<?xi8>, index) -> ()
  %r = arith.constant 0 : i32
  return %r : i32
}
