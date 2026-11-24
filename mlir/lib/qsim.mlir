// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// qsim.mlir — state-vector simulation: port of PIRTM pirtm/quantum/hilbert11.py
// (in-place butterfly simulator, fidelity, partial trace, trace-distance bound)
// generalised to nq qubits (qubit 0 = most significant bit, as in the source).
// Every gate function mutates the state in place and returns it, so the custom
// `pirtm` dialect's value-semantics ops lower 1:1 onto these calls.

!st = memref<?xcomplex<f64>>

func.func @sv_alloc(%nq: index) -> !st {
  %one = arith.constant 1 : index
  %dim = arith.shli %one, %nq : index
  %s = memref.alloc(%dim) : !st
  %z = arith.constant 0.0 : f64
  %zc = complex.create %z, %z : complex<f64>
  %c0 = arith.constant 0 : index
  scf.for %i = %c0 to %dim step %one {
    memref.store %zc, %s[%i] : !st
  }
  return %s : !st
}

func.func @sv_basis(%nq: index, %idx: index) -> !st {
  %s = func.call @sv_alloc(%nq) : (index) -> !st
  %o = arith.constant 1.0 : f64
  %z = arith.constant 0.0 : f64
  %c = complex.create %o, %z : complex<f64>
  memref.store %c, %s[%idx] : !st
  return %s : !st
}

func.func @sv_copy(%s: !st) -> !st {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %dim = memref.dim %s, %c0 : !st
  %t = memref.alloc(%dim) : !st
  memref.copy %s, %t : !st to !st
  return %t : !st
}

func.func @sv_set(%s: !st, %idx: index, %re: f64, %im: f64) -> !st {
  %c = complex.create %re, %im : complex<f64>
  memref.store %c, %s[%idx] : !st
  return %s : !st
}

// Hilbert11Simulator.apply_single_qubit
func.func @sv_apply1(%s: !st, %nq: index, %target: index,
                     %u00: complex<f64>, %u01: complex<f64>,
                     %u10: complex<f64>, %u11: complex<f64>) -> !st {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %dim = memref.dim %s, %c0 : !st
  %nm1 = arith.subi %nq, %one : index
  %bit = arith.subi %nm1, %target : index
  %bp1 = arith.addi %bit, %one : index
  %step = arith.shli %one, %bp1 : index
  %half = arith.shli %one, %bit : index
  scf.for %i = %c0 to %dim step %step {
    %end = arith.addi %i, %half : index
    scf.for %j = %i to %end step %one {
      %i1 = arith.addi %j, %half : index
      %a0 = memref.load %s[%j] : !st
      %a1 = memref.load %s[%i1] : !st
      %p00 = complex.mul %u00, %a0 : complex<f64>
      %p01 = complex.mul %u01, %a1 : complex<f64>
      %p10 = complex.mul %u10, %a0 : complex<f64>
      %p11 = complex.mul %u11, %a1 : complex<f64>
      %n0 = complex.add %p00, %p01 : complex<f64>
      %n1 = complex.add %p10, %p11 : complex<f64>
      memref.store %n0, %s[%j] : !st
      memref.store %n1, %s[%i1] : !st
    }
  }
  return %s : !st
}

func.func @cplx(%re: f64, %im: f64) -> complex<f64> {
  %c = complex.create %re, %im : complex<f64>
  return %c : complex<f64>
}

func.func @sqrt2_inv() -> f64 {
  %two = arith.constant 2.0 : f64
  %one = arith.constant 1.0 : f64
  %r = math.sqrt %two : f64
  %v = arith.divf %one, %r : f64
  return %v : f64
}

func.func @sv_h(%s: !st, %nq: index, %t: index) -> !st {
  %r = func.call @sqrt2_inv() : () -> f64
  %z = arith.constant 0.0 : f64
  %nz = arith.constant -0.0 : f64
  %nr = arith.negf %r : f64
  %a = complex.create %r, %z : complex<f64>
  %b = complex.create %nr, %nz : complex<f64>
  %o = func.call @sv_apply1(%s, %nq, %t, %a, %a, %a, %b) : (!st, index, index, complex<f64>, complex<f64>, complex<f64>, complex<f64>) -> !st
  return %o : !st
}

func.func @sv_x(%s: !st, %nq: index, %t: index) -> !st {
  %z = arith.constant 0.0 : f64
  %one = arith.constant 1.0 : f64
  %c0 = complex.create %z, %z : complex<f64>
  %c1 = complex.create %one, %z : complex<f64>
  %o = func.call @sv_apply1(%s, %nq, %t, %c0, %c1, %c1, %c0) : (!st, index, index, complex<f64>, complex<f64>, complex<f64>, complex<f64>) -> !st
  return %o : !st
}

func.func @sv_y(%s: !st, %nq: index, %t: index) -> !st {
  %z = arith.constant 0.0 : f64
  %nz = arith.constant -0.0 : f64
  %one = arith.constant 1.0 : f64
  %mone = arith.constant -1.0 : f64
  %c0 = complex.create %z, %z : complex<f64>
  %mi = complex.create %nz, %mone : complex<f64>
  %pi = complex.create %z, %one : complex<f64>
  %o = func.call @sv_apply1(%s, %nq, %t, %c0, %mi, %pi, %c0) : (!st, index, index, complex<f64>, complex<f64>, complex<f64>, complex<f64>) -> !st
  return %o : !st
}

func.func @sv_z(%s: !st, %nq: index, %t: index) -> !st {
  %z = arith.constant 0.0 : f64
  %one = arith.constant 1.0 : f64
  %mone = arith.constant -1.0 : f64
  %c0 = complex.create %z, %z : complex<f64>
  %c1 = complex.create %one, %z : complex<f64>
  %m1 = complex.create %mone, %z : complex<f64>
  %o = func.call @sv_apply1(%s, %nq, %t, %c1, %c0, %c0, %m1) : (!st, index, index, complex<f64>, complex<f64>, complex<f64>, complex<f64>) -> !st
  return %o : !st
}

func.func @sv_s(%s: !st, %nq: index, %t: index) -> !st {
  %z = arith.constant 0.0 : f64
  %one = arith.constant 1.0 : f64
  %c0 = complex.create %z, %z : complex<f64>
  %c1 = complex.create %one, %z : complex<f64>
  %pi = complex.create %z, %one : complex<f64>
  %o = func.call @sv_apply1(%s, %nq, %t, %c1, %c0, %c0, %pi) : (!st, index, index, complex<f64>, complex<f64>, complex<f64>, complex<f64>) -> !st
  return %o : !st
}

func.func @sv_sdg(%s: !st, %nq: index, %t: index) -> !st {
  %z = arith.constant 0.0 : f64
  %nz = arith.constant -0.0 : f64
  %one = arith.constant 1.0 : f64
  %mone = arith.constant -1.0 : f64
  %c0 = complex.create %z, %z : complex<f64>
  %c1 = complex.create %one, %z : complex<f64>
  %mi = complex.create %nz, %mone : complex<f64>
  %o = func.call @sv_apply1(%s, %nq, %t, %c1, %c0, %c0, %mi) : (!st, index, index, complex<f64>, complex<f64>, complex<f64>, complex<f64>) -> !st
  return %o : !st
}

// Hilbert11Simulator.apply_cnot (swap pairs with control=1, target=0)
func.func @sv_cnot(%s: !st, %nq: index, %c: index, %t: index) -> !st {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %dim = memref.dim %s, %c0 : !st
  %nm1 = arith.subi %nq, %one : index
  %cb = arith.subi %nm1, %c : index
  %tb = arith.subi %nm1, %t : index
  %cm = arith.shli %one, %cb : index
  %tm = arith.shli %one, %tb : index
  scf.for %i = %c0 to %dim step %one {
    %ci = arith.andi %i, %cm : index
    %ti = arith.andi %i, %tm : index
    %hasc = arith.cmpi ne, %ci, %c0 : index
    %not = arith.cmpi eq, %ti, %c0 : index
    %go = arith.andi %hasc, %not : i1
    scf.if %go {
      %j = arith.xori %i, %tm : index
      %ai = memref.load %s[%i] : !st
      %aj = memref.load %s[%j] : !st
      memref.store %aj, %s[%i] : !st
      memref.store %ai, %s[%j] : !st
    }
  }
  return %s : !st
}

// gate list: rows (opcode, q0, q1); opcodes H=0 X=1 Y=2 Z=3 S=4 Sdag=5 CNOT=6
func.func @sv_apply_op(%s: !st, %nq: index, %op: index, %q0: index, %q1: index) -> !st {
  %r = scf.index_switch %op -> !st
  case 0 {
    %o = func.call @sv_h(%s, %nq, %q0) : (!st, index, index) -> !st
    scf.yield %o : !st
  }
  case 1 {
    %o = func.call @sv_x(%s, %nq, %q0) : (!st, index, index) -> !st
    scf.yield %o : !st
  }
  case 2 {
    %o = func.call @sv_y(%s, %nq, %q0) : (!st, index, index) -> !st
    scf.yield %o : !st
  }
  case 3 {
    %o = func.call @sv_z(%s, %nq, %q0) : (!st, index, index) -> !st
    scf.yield %o : !st
  }
  case 4 {
    %o = func.call @sv_s(%s, %nq, %q0) : (!st, index, index) -> !st
    scf.yield %o : !st
  }
  case 5 {
    %o = func.call @sv_sdg(%s, %nq, %q0) : (!st, index, index) -> !st
    scf.yield %o : !st
  }
  case 6 {
    %o = func.call @sv_cnot(%s, %nq, %q0, %q1) : (!st, index, index, index) -> !st
    scf.yield %o : !st
  }
  default {
    scf.yield %s : !st
  }
  return %r : !st
}

// Hilbert11Simulator.evolve
func.func @sv_evolve(%s: !st, %nq: index, %circ: memref<?x3xindex>) -> !st {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %n = memref.dim %circ, %c0 : memref<?x3xindex>
  %r = scf.for %g = %c0 to %n step %one iter_args(%cur = %s) -> (!st) {
    %op = memref.load %circ[%g, %c0] : memref<?x3xindex>
    %q0 = memref.load %circ[%g, %one] : memref<?x3xindex>
    %q1 = memref.load %circ[%g, %c2] : memref<?x3xindex>
    %o = func.call @sv_apply_op(%cur, %nq, %op, %q0, %q1) : (!st, index, index, index, index) -> !st
    scf.yield %o : !st
  }
  return %r : !st
}

// GateOp.dagger: S <-> S_dag, every other supported gate is self-inverse
func.func @op_dagger(%op: index) -> index {
  %c4 = arith.constant 4 : index
  %c5 = arith.constant 5 : index
  %is4 = arith.cmpi eq, %op, %c4 : index
  %is5 = arith.cmpi eq, %op, %c5 : index
  %a = arith.select %is4, %c5, %op : index
  %b = arith.select %is5, %c4, %a : index
  return %b : index
}

// Hilbert11Simulator.evolve_inverse
func.func @sv_evolve_inverse(%s: !st, %nq: index, %circ: memref<?x3xindex>) -> !st {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %n = memref.dim %circ, %c0 : memref<?x3xindex>
  %r = scf.for %k = %c0 to %n step %one iter_args(%cur = %s) -> (!st) {
    %nk = arith.subi %n, %k : index
    %g = arith.subi %nk, %one : index
    %op0 = memref.load %circ[%g, %c0] : memref<?x3xindex>
    %op = func.call @op_dagger(%op0) : (index) -> index
    %q0 = memref.load %circ[%g, %one] : memref<?x3xindex>
    %q1 = memref.load %circ[%g, %c2] : memref<?x3xindex>
    %o = func.call @sv_apply_op(%cur, %nq, %op, %q0, %q1) : (!st, index, index, index, index) -> !st
    scf.yield %o : !st
  }
  return %r : !st
}

func.func @sv_norm2(%s: !st) -> f64 {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %dim = memref.dim %s, %c0 : !st
  %z = arith.constant 0.0 : f64
  %r = scf.for %i = %c0 to %dim step %one iter_args(%acc = %z) -> (f64) {
    %a = memref.load %s[%i] : !st
    %re = complex.re %a : complex<f64>
    %im = complex.im %a : complex<f64>
    %rr = arith.mulf %re, %re : f64
    %ii = arith.mulf %im, %im : f64
    %t = arith.addf %rr, %ii : f64
    %n = arith.addf %acc, %t : f64
    scf.yield %n : f64
  }
  return %r : f64
}

// state_fidelity: |<s1|s2>|^2
func.func @sv_fidelity(%a: !st, %b: !st) -> f64 {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %dim = memref.dim %a, %c0 : !st
  %z = arith.constant 0.0 : f64
  %zc = complex.create %z, %z : complex<f64>
  %dot = scf.for %i = %c0 to %dim step %one iter_args(%acc = %zc) -> (complex<f64>) {
    %x = memref.load %a[%i] : !st
    %y = memref.load %b[%i] : !st
    %xc = complex.conj %x : complex<f64>
    %p = complex.mul %xc, %y : complex<f64>
    %n = complex.add %acc, %p : complex<f64>
    scf.yield %n : complex<f64>
  }
  %re = complex.re %dot : complex<f64>
  %im = complex.im %dot : complex<f64>
  %rr = arith.mulf %re, %re : f64
  %ii = arith.mulf %im, %im : f64
  %f = arith.addf %rr, %ii : f64
  return %f : f64
}

// Born probabilities |c_i|^2 (unnormalised, as Hilbert11State.probabilities)
func.func @sv_probabilities(%s: !st) -> memref<?xf64> {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %dim = memref.dim %s, %c0 : !st
  %p = memref.alloc(%dim) : memref<?xf64>
  scf.for %i = %c0 to %dim step %one {
    %a = memref.load %s[%i] : !st
    %re = complex.re %a : complex<f64>
    %im = complex.im %a : complex<f64>
    %rr = arith.mulf %re, %re : f64
    %ii = arith.mulf %im, %im : f64
    %t = arith.addf %rr, %ii : f64
    memref.store %t, %p[%i] : memref<?xf64>
  }
  return %p : memref<?xf64>
}

// sub-index of basis element i restricted to accessible qubits (MSB first)
func.func @sub_index(%i: index, %nq: index, %acc: memref<?xindex>) -> index {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %k = memref.dim %acc, %c0 : memref<?xindex>
  %nm1 = arith.subi %nq, %one : index
  %km1 = arith.subi %k, %one : index
  %r = scf.for %b = %c0 to %k step %one iter_args(%sub = %c0) -> (index) {
    %q = memref.load %acc[%b] : memref<?xindex>
    %pos = arith.subi %nm1, %q : index
    %sh = arith.shrui %i, %pos : index
    %bit = arith.andi %sh, %one : index
    %set = arith.cmpi ne, %bit, %c0 : index
    %e = arith.subi %km1, %b : index
    %m = arith.shli %one, %e : index
    %o = arith.ori %sub, %m : index
    %n = arith.select %set, %o, %sub : index
    scf.yield %n : index
  }
  return %r : index
}

// mask of environment (non-accessible) bit positions
func.func @env_mask(%nq: index, %acc: memref<?xindex>) -> index {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %k = memref.dim %acc, %c0 : memref<?xindex>
  %nm1 = arith.subi %nq, %one : index
  %all0 = arith.shli %one, %nq : index
  %all = arith.subi %all0, %one : index
  %r = scf.for %b = %c0 to %k step %one iter_args(%m = %all) -> (index) {
    %q = memref.load %acc[%b] : memref<?xindex>
    %pos = arith.subi %nm1, %q : index
    %bm = arith.shli %one, %pos : index
    %inv = arith.xori %bm, %all : index
    %n = arith.andi %m, %inv : index
    scf.yield %n : index
  }
  return %r : index
}

// partial_trace(state, accessible_qubits) -> rho_A (2^k x 2^k)
func.func @sv_partial_trace(%s: !st, %nq: index, %acc: memref<?xindex>) -> memref<?x?xcomplex<f64>> {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %dim = memref.dim %s, %c0 : !st
  %k = memref.dim %acc, %c0 : memref<?xindex>
  %da = arith.shli %one, %k : index
  %rho = memref.alloc(%da, %da) : memref<?x?xcomplex<f64>>
  %z = arith.constant 0.0 : f64
  %zc = complex.create %z, %z : complex<f64>
  scf.for %i = %c0 to %da step %one {
    scf.for %j = %c0 to %da step %one {
      memref.store %zc, %rho[%i, %j] : memref<?x?xcomplex<f64>>
    }
  }
  %true = arith.constant true
  %em = func.call @env_mask(%nq, %acc) : (index, memref<?xindex>) -> index
  scf.for %i = %c0 to %dim step %one {
    %ai = memref.load %s[%i] : !st
    %air = complex.re %ai : complex<f64>
    %aii = complex.im %ai : complex<f64>
    %r0 = arith.cmpf oeq, %air, %z : f64
    %i0 = arith.cmpf oeq, %aii, %z : f64
    %iz = arith.andi %r0, %i0 : i1
    %nzi = arith.xori %iz, %true : i1
    scf.if %nzi {
      %si = func.call @sub_index(%i, %nq, %acc) : (index, index, memref<?xindex>) -> index
      %ei = arith.andi %i, %em : index
      scf.for %j = %c0 to %dim step %one {
        %aj = memref.load %s[%j] : !st
        %ajr = complex.re %aj : complex<f64>
        %aji = complex.im %aj : complex<f64>
        %r1 = arith.cmpf oeq, %ajr, %z : f64
        %i1 = arith.cmpf oeq, %aji, %z : f64
        %jz = arith.andi %r1, %i1 : i1
        %ej = arith.andi %j, %em : index
        %same = arith.cmpi eq, %ei, %ej : index
        %nzj = arith.xori %jz, %true : i1
        %go = arith.andi %nzj, %same : i1
        scf.if %go {
          %sj = func.call @sub_index(%j, %nq, %acc) : (index, index, memref<?xindex>) -> index
          %ajc = complex.conj %aj : complex<f64>
          %p = complex.mul %ai, %ajc : complex<f64>
          %old = memref.load %rho[%si, %sj] : memref<?x?xcomplex<f64>>
          %n = complex.add %old, %p : complex<f64>
          memref.store %n, %rho[%si, %sj] : memref<?x?xcomplex<f64>>
        }
      }
    }
  }
  return %rho : memref<?x?xcomplex<f64>>
}

// density_matrix_trace_distance: 0.5 * Frobenius norm of the difference (as in the source)
func.func @trace_distance_bound(%a: memref<?x?xcomplex<f64>>, %b: memref<?x?xcomplex<f64>>) -> f64 {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %d = memref.dim %a, %c0 : memref<?x?xcomplex<f64>>
  %z = arith.constant 0.0 : f64
  %sum = scf.for %i = %c0 to %d step %one iter_args(%acc = %z) -> (f64) {
    %row = scf.for %j = %c0 to %d step %one iter_args(%acc2 = %acc) -> (f64) {
      %x = memref.load %a[%i, %j] : memref<?x?xcomplex<f64>>
      %y = memref.load %b[%i, %j] : memref<?x?xcomplex<f64>>
      %df = complex.sub %x, %y : complex<f64>
      %re = complex.re %df : complex<f64>
      %im = complex.im %df : complex<f64>
      %rr = arith.mulf %re, %re : f64
      %ii = arith.mulf %im, %im : f64
      %t = arith.addf %rr, %ii : f64
      %n = arith.addf %acc2, %t : f64
      scf.yield %n : f64
    }
    scf.yield %row : f64
  }
  %sq = math.sqrt %sum : f64
  %h = arith.constant 0.5 : f64
  %r = arith.mulf %sq, %h : f64
  return %r : f64
}

// circuit row helper: circ[row] = (op, q0, q1)
func.func @set_gate(%c: memref<?x3xindex>, %row: index, %op: index, %q0: index, %q1: index) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  memref.store %op, %c[%row, %c0] : memref<?x3xindex>
  memref.store %q0, %c[%row, %c1] : memref<?x3xindex>
  memref.store %q1, %c[%row, %c2] : memref<?x3xindex>
  return
}


// n-row gate table (opcode, q0, q1); target of the `pirtm.circuit` op
func.func @circ_new(%n: index) -> memref<?x3xindex> {
  %c = memref.alloc(%n) : memref<?x3xindex>
  return %c : memref<?x3xindex>
}
