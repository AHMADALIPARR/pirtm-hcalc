// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// qmat.mlir — dense-matrix quantum engine: port of pirtm/quantum/gates.py and
// pirtm/quantum/circuit.py (QuantumCircuit full-unitary path, QuantumState
// helpers and ClassicalReversibleBaseline).

!mat = memref<?x?xcomplex<f64>>

func.func @mat_new(%r: index, %c: index) -> !mat {
  %m = memref.alloc(%r, %c) : !mat
  %z = arith.constant 0.0 : f64
  %zc = complex.create %z, %z : complex<f64>
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  scf.for %i = %c0 to %r step %one {
    scf.for %j = %c0 to %c step %one {
      memref.store %zc, %m[%i, %j] : !mat
    }
  }
  return %m : !mat
}

func.func @mat_set(%m: !mat, %i: index, %j: index, %re: f64, %im: f64) {
  %c = complex.create %re, %im : complex<f64>
  memref.store %c, %m[%i, %j] : !mat
  return
}

func.func @mat_identity(%n: index) -> !mat {
  %m = func.call @mat_new(%n, %n) : (index, index) -> !mat
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %o = arith.constant 1.0 : f64
  %z = arith.constant 0.0 : f64
  scf.for %i = %c0 to %n step %one {
    func.call @mat_set(%m, %i, %i, %o, %z) : (!mat, index, index, f64, f64) -> ()
  }
  return %m : !mat
}

func.func @c_is_zero(%a: complex<f64>) -> i1 {
  %z = arith.constant 0.0 : f64
  %re = complex.re %a : complex<f64>
  %im = complex.im %a : complex<f64>
  %r = arith.cmpf oeq, %re, %z : f64
  %i = arith.cmpf oeq, %im, %z : f64
  %b = arith.andi %r, %i : i1
  return %b : i1
}

// matrix_mult (skips a[i][k] == 0 exactly as the source)
func.func @mat_mult(%a: !mat, %b: !mat) -> !mat {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %ra = memref.dim %a, %c0 : !mat
  %ca = memref.dim %a, %one : !mat
  %cb = memref.dim %b, %one : !mat
  %out = func.call @mat_new(%ra, %cb) : (index, index) -> !mat
  %true = arith.constant true
  scf.for %i = %c0 to %ra step %one {
    scf.for %k = %c0 to %ca step %one {
      %aik = memref.load %a[%i, %k] : !mat
      %z = func.call @c_is_zero(%aik) : (complex<f64>) -> i1
      %nz = arith.xori %z, %true : i1
      scf.if %nz {
        scf.for %j = %c0 to %cb step %one {
          %bkj = memref.load %b[%k, %j] : !mat
          %p = complex.mul %aik, %bkj : complex<f64>
          %o = memref.load %out[%i, %j] : !mat
          %n = complex.add %o, %p : complex<f64>
          memref.store %n, %out[%i, %j] : !mat
        }
      }
    }
  }
  return %out : !mat
}

func.func @mat_dagger(%m: !mat) -> !mat {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %r = memref.dim %m, %c0 : !mat
  %c = memref.dim %m, %one : !mat
  %out = func.call @mat_new(%c, %r) : (index, index) -> !mat
  scf.for %i = %c0 to %c step %one {
    scf.for %j = %c0 to %r step %one {
      %x = memref.load %m[%j, %i] : !mat
      %y = complex.conj %x : complex<f64>
      memref.store %y, %out[%i, %j] : !mat
    }
  }
  return %out : !mat
}

// tensor_product (Kronecker)
func.func @mat_tensor(%a: !mat, %b: !mat) -> !mat {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %ra = memref.dim %a, %c0 : !mat
  %ca = memref.dim %a, %one : !mat
  %rb = memref.dim %b, %c0 : !mat
  %cb = memref.dim %b, %one : !mat
  %r = arith.muli %ra, %rb : index
  %c = arith.muli %ca, %cb : index
  %out = func.call @mat_new(%r, %c) : (index, index) -> !mat
  scf.for %i = %c0 to %ra step %one {
    scf.for %j = %c0 to %ca step %one {
      scf.for %k = %c0 to %rb step %one {
        scf.for %l = %c0 to %cb step %one {
          %x = memref.load %a[%i, %j] : !mat
          %y = memref.load %b[%k, %l] : !mat
          %p = complex.mul %x, %y : complex<f64>
          %ir = arith.muli %i, %rb : index
          %row = arith.addi %ir, %k : index
          %jc = arith.muli %j, %cb : index
          %col = arith.addi %jc, %l : index
          memref.store %p, %out[%row, %col] : !mat
        }
      }
    }
  }
  return %out : !mat
}

// is_unitary: M * M^dagger == I within tolerance
func.func @mat_is_unitary(%m: !mat, %tol: f64) -> i1 {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %r = memref.dim %m, %c0 : !mat
  %c = memref.dim %m, %one : !mat
  %sq = arith.cmpi eq, %r, %c : index
  %d = func.call @mat_dagger(%m) : (!mat) -> !mat
  %p = func.call @mat_mult(%m, %d) : (!mat, !mat) -> !mat
  %o = arith.constant 1.0 : f64
  %z = arith.constant 0.0 : f64
  %true_c = arith.constant true
  %ok = scf.for %i = %c0 to %r step %one iter_args(%acc = %sq) -> (i1) {
    %ok2 = scf.for %j = %c0 to %c step %one iter_args(%acc2 = %acc) -> (i1) {
      %x = memref.load %p[%i, %j] : !mat
      %diag = arith.cmpi eq, %i, %j : index
      %e = arith.select %diag, %o, %z : f64
      %ec = complex.create %e, %z : complex<f64>
      %df = complex.sub %x, %ec : complex<f64>
      %ab = complex.abs %df : complex<f64>
      %bad = arith.cmpf ogt, %ab, %tol : f64
      %good = arith.xori %bad, %true_c : i1
      %n = arith.andi %acc2, %good : i1
      scf.yield %n : i1
    }
    scf.yield %ok2 : i1
  }
  return %ok : i1
}

// ------------------------------------------------------------- gate constants
// kinds: H=0 X=1 Y=2 Z=3 S=4 Sdag=5 CNOT=6 T=7
func.func @gate_matrix(%kind: index) -> !mat {
  %c2 = arith.constant 2 : index
  %c4 = arith.constant 4 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c3 = arith.constant 3 : index
  %z = arith.constant 0.0 : f64
  %nz = arith.constant -0.0 : f64
  %o = arith.constant 1.0 : f64
  %mo = arith.constant -1.0 : f64
  %r = scf.index_switch %kind -> !mat
  case 0 {
    %m = func.call @mat_new(%c2, %c2) : (index, index) -> !mat
    %s = func.call @sqrt2_inv() : () -> f64
    %ns = arith.negf %s : f64
    func.call @mat_set(%m, %c0, %c0, %s, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c0, %c1, %s, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c1, %c0, %s, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c1, %c1, %ns, %z) : (!mat, index, index, f64, f64) -> ()
    scf.yield %m : !mat
  }
  case 1 {
    %m = func.call @mat_new(%c2, %c2) : (index, index) -> !mat
    func.call @mat_set(%m, %c0, %c1, %o, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c1, %c0, %o, %z) : (!mat, index, index, f64, f64) -> ()
    scf.yield %m : !mat
  }
  case 2 {
    %m = func.call @mat_new(%c2, %c2) : (index, index) -> !mat
    func.call @mat_set(%m, %c0, %c1, %z, %mo) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c1, %c0, %z, %o) : (!mat, index, index, f64, f64) -> ()
    scf.yield %m : !mat
  }
  case 3 {
    %m = func.call @mat_new(%c2, %c2) : (index, index) -> !mat
    func.call @mat_set(%m, %c0, %c0, %o, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c1, %c1, %mo, %z) : (!mat, index, index, f64, f64) -> ()
    scf.yield %m : !mat
  }
  case 4 {
    %m = func.call @mat_new(%c2, %c2) : (index, index) -> !mat
    func.call @mat_set(%m, %c0, %c0, %o, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c1, %c1, %z, %o) : (!mat, index, index, f64, f64) -> ()
    scf.yield %m : !mat
  }
  case 5 {
    %m = func.call @mat_new(%c2, %c2) : (index, index) -> !mat
    func.call @mat_set(%m, %c0, %c0, %o, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c1, %c1, %z, %mo) : (!mat, index, index, f64, f64) -> ()
    scf.yield %m : !mat
  }
  case 6 {
    %m = func.call @mat_new(%c4, %c4) : (index, index) -> !mat
    func.call @mat_set(%m, %c0, %c0, %o, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c1, %c1, %o, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c2, %c3, %o, %z) : (!mat, index, index, f64, f64) -> ()
    func.call @mat_set(%m, %c3, %c2, %o, %z) : (!mat, index, index, f64, f64) -> ()
    scf.yield %m : !mat
  }
  default {
    // T = phase_gate(pi/4)
    %pi4 = arith.constant 0.78539816339744828 : f64
    %m = func.call @phase_gate(%pi4) : (f64) -> !mat
    scf.yield %m : !mat
  }
  return %r : !mat
}

// phase_gate(phi) = diag(1, e^{i phi})
func.func @phase_gate(%phi: f64) -> !mat {
  %c2 = arith.constant 2 : index
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %z = arith.constant 0.0 : f64
  %o = arith.constant 1.0 : f64
  %m = func.call @mat_new(%c2, %c2) : (index, index) -> !mat
  %cs = math.cos %phi : f64
  %sn = math.sin %phi : f64
  func.call @mat_set(%m, %c0, %c0, %o, %z) : (!mat, index, index, f64, f64) -> ()
  func.call @mat_set(%m, %c1, %c1, %cs, %sn) : (!mat, index, index, f64, f64) -> ()
  return %m : !mat
}

// QuantumCircuit._build_full_gate_matrix
func.func @qc_full_gate(%nq: index, %kind: index, %q0: index, %q1: index) -> !mat {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %c6 = arith.constant 6 : index
  %dim = arith.shli %one, %nq : index
  %full = func.call @mat_new(%dim, %dim) : (index, index) -> !mat
  %nm1 = arith.subi %nq, %one : index
  %iscnot = arith.cmpi eq, %kind, %c6 : index
  scf.if %iscnot {
    %cp = arith.subi %nm1, %q0 : index
    %tp = arith.subi %nm1, %q1 : index
    %tm = arith.shli %one, %tp : index
    %o = arith.constant 1.0 : f64
    %z = arith.constant 0.0 : f64
    scf.for %i = %c0 to %dim step %one {
      %cv0 = arith.shrui %i, %cp : index
      %cv = arith.andi %cv0, %one : index
      %on = arith.cmpi eq, %cv, %one : index
      %fl = arith.xori %i, %tm : index
      %j = arith.select %on, %fl, %i : index
      func.call @mat_set(%full, %j, %i, %o, %z) : (!mat, index, index, f64, f64) -> ()
    }
  } else {
    %sub = func.call @gate_matrix(%kind) : (index) -> !mat
    %bp = arith.subi %nm1, %q0 : index
    %bm = arith.shli %one, %bp : index
    %all = arith.constant -1 : index
    %nbm = arith.xori %bm, %all : index
    %c2 = arith.constant 2 : index
    scf.for %i = %c0 to %dim step %one {
      %bv0 = arith.shrui %i, %bp : index
      %bv = arith.andi %bv0, %one : index
      scf.for %nb = %c0 to %c2 step %one {
        %cl = arith.andi %i, %nbm : index
        %sh = arith.shli %nb, %bp : index
        %j = arith.ori %cl, %sh : index
        %x = memref.load %sub[%nb, %bv] : !mat
        %old = memref.load %full[%j, %i] : !mat
        %n = complex.add %old, %x : complex<f64>
        memref.store %n, %full[%j, %i] : !mat
      }
    }
  }
  return %full : !mat
}

// QuantumCircuit.to_unitary
func.func @qc_to_unitary(%nq: index, %circ: memref<?x3xindex>) -> !mat {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %dim = arith.shli %one, %nq : index
  %u0 = func.call @mat_identity(%dim) : (index) -> !mat
  %n = memref.dim %circ, %c0 : memref<?x3xindex>
  %u = scf.for %g = %c0 to %n step %one iter_args(%acc = %u0) -> (!mat) {
    %k = memref.load %circ[%g, %c0] : memref<?x3xindex>
    %a = memref.load %circ[%g, %one] : memref<?x3xindex>
    %b = memref.load %circ[%g, %c2] : memref<?x3xindex>
    %gm = func.call @qc_full_gate(%nq, %k, %a, %b) : (index, index, index, index) -> !mat
    %nu = func.call @mat_mult(%gm, %acc) : (!mat, !mat) -> !mat
    scf.yield %nu : !mat
  }
  return %u : !mat
}

// QuantumCircuit.run (dense mat-vec, skipping zero matrix entries)
func.func @qc_run(%nq: index, %circ: memref<?x3xindex>, %init: memref<?xcomplex<f64>>) -> memref<?xcomplex<f64>> {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %dim = arith.shli %one, %nq : index
  %n = memref.dim %circ, %c0 : memref<?x3xindex>
  %z = arith.constant 0.0 : f64
  %zc = complex.create %z, %z : complex<f64>
  %true = arith.constant true
  %res = scf.for %g = %c0 to %n step %one iter_args(%amps = %init) -> (memref<?xcomplex<f64>>) {
    %k = memref.load %circ[%g, %c0] : memref<?x3xindex>
    %a = memref.load %circ[%g, %one] : memref<?x3xindex>
    %b = memref.load %circ[%g, %c2] : memref<?x3xindex>
    %gm = func.call @qc_full_gate(%nq, %k, %a, %b) : (index, index, index, index) -> !mat
    %new = memref.alloc(%dim) : memref<?xcomplex<f64>>
    scf.for %r = %c0 to %dim step %one {
      %s = scf.for %c = %c0 to %dim step %one iter_args(%acc = %zc) -> (complex<f64>) {
        %x = memref.load %gm[%r, %c] : !mat
        %iz = func.call @c_is_zero(%x) : (complex<f64>) -> i1
        %v = scf.if %iz -> (complex<f64>) {
          scf.yield %acc : complex<f64>
        } else {
          %y = memref.load %amps[%c] : memref<?xcomplex<f64>>
          %p = complex.mul %x, %y : complex<f64>
          %t = complex.add %acc, %p : complex<f64>
          scf.yield %t : complex<f64>
        }
        scf.yield %v : complex<f64>
      }
      memref.store %s, %new[%r] : memref<?xcomplex<f64>>
    }
    scf.yield %new : memref<?xcomplex<f64>>
  }
  return %res : memref<?xcomplex<f64>>
}

// QuantumState.probabilities (normalised by the total)
func.func @qs_probabilities(%s: memref<?xcomplex<f64>>) -> memref<?xf64> {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %p = func.call @sv_probabilities(%s) : (memref<?xcomplex<f64>>) -> memref<?xf64>
  %dim = memref.dim %p, %c0 : memref<?xf64>
  %z = arith.constant 0.0 : f64
  %tot = scf.for %i = %c0 to %dim step %one iter_args(%acc = %z) -> (f64) {
    %x = memref.load %p[%i] : memref<?xf64>
    %n = arith.addf %acc, %x : f64
    scf.yield %n : f64
  }
  %pos = arith.cmpf ogt, %tot, %z : f64
  scf.if %pos {
    scf.for %i = %c0 to %dim step %one {
      %x = memref.load %p[%i] : memref<?xf64>
      %y = arith.divf %x, %tot : f64
      memref.store %y, %p[%i] : memref<?xf64>
    }
  }
  return %p : memref<?xf64>
}

// QuantumState.sample_measurement with the uniform draw r supplied explicitly
func.func @qs_sample(%s: memref<?xcomplex<f64>>, %r: f64) -> index {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %p = func.call @qs_probabilities(%s) : (memref<?xcomplex<f64>>) -> memref<?xf64>
  %dim = memref.dim %p, %c0 : memref<?xf64>
  %last = arith.subi %dim, %one : index
  %z = arith.constant 0.0 : f64
  %false = arith.constant false
  %true_c = arith.constant true
  %res:3 = scf.for %i = %c0 to %dim step %one iter_args(%cum = %z, %found = %false, %idx = %last) -> (f64, i1, index) {
    %x = memref.load %p[%i] : memref<?xf64>
    %c = arith.addf %cum, %x : f64
    %le = arith.cmpf ole, %r, %c : f64
    %nf = arith.xori %found, %true_c : i1
    %take = arith.andi %le, %nf : i1
    %ni = arith.select %take, %i, %idx : index
    %f2 = arith.ori %found, %take : i1
    scf.yield %c, %f2, %ni : f64, i1, index
  }
  return %res#2 : index
}

// ClassicalReversibleBaseline over an i8 bit array (bit 0 = leftmost)
func.func @cr_not(%bits: memref<?xi8>, %b: index) {
  %one = arith.constant 1 : i8
  %v = memref.load %bits[%b] : memref<?xi8>
  %n = arith.xori %v, %one : i8
  memref.store %n, %bits[%b] : memref<?xi8>
  return
}

func.func @cr_cnot(%bits: memref<?xi8>, %c: index, %t: index) {
  %one = arith.constant 1 : i8
  %v = memref.load %bits[%c] : memref<?xi8>
  %on = arith.cmpi eq, %v, %one : i8
  scf.if %on {
    func.call @cr_not(%bits, %t) : (memref<?xi8>, index) -> ()
  }
  return
}

func.func @cr_toffoli(%bits: memref<?xi8>, %c1: index, %c2: index, %t: index) {
  %one = arith.constant 1 : i8
  %v1 = memref.load %bits[%c1] : memref<?xi8>
  %v2 = memref.load %bits[%c2] : memref<?xi8>
  %a = arith.cmpi eq, %v1, %one : i8
  %b = arith.cmpi eq, %v2, %one : i8
  %on = arith.andi %a, %b : i1
  scf.if %on {
    func.call @cr_not(%bits, %t) : (memref<?xi8>, index) -> ()
  }
  return
}

func.func @cr_state_int(%bits: memref<?xi8>) -> i64 {
  %c0 = arith.constant 0 : index
  %one = arith.constant 1 : index
  %n = memref.dim %bits, %c0 : memref<?xi8>
  %z = arith.constant 0 : i64
  %c1 = arith.constant 1 : i64
  %r = scf.for %i = %c0 to %n step %one iter_args(%v = %z) -> (i64) {
    %b = memref.load %bits[%i] : memref<?xi8>
    %b64 = arith.extui %b : i8 to i64
    %s = arith.shli %v, %c1 : i64
    %o = arith.ori %s, %b64 : i64
    scf.yield %o : i64
  }
  return %r : i64
}
