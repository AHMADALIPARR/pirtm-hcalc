// SPDX-License-Identifier: AGPL-3.0-only
// Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
// Copyright (C) 2026 Ahmad Parr
//
// hcalc.mlir — HCALC Core math (port of j/hcalc.ijs and the j/cite.ijs hooks):
//   tp_alpha        α_j = 1 / (1 + ln p_{j mod 64})
//   gershgorin_bound, power_iteration, spectral_analyze  (radius only)
//   soft_project_scale  s = (1-ε)/q if q > 1-ε else 1
//   q_of_tp, c_op_norm, lam_m (Λm = min(1, (1-ε)/(‖C∘Tp‖ + δ)))
//   hcalc_step      X' = ξ·(Λm·C(Tp(X))) + g
//   to_foundry_step_diagnostic  ξ·x + Λm·(C∘Tp)(x) + g   (≠ hcalc_step)
//   hcalc_run       iterate until ‖X - step X‖_∞ < tol or max_steps
// Sums use Neumaier compensated summation (J's +/ on floats is compensated;
// for the inputs exercised here both give the correctly rounded sum).

!vec = memref<?xf64>
!mat2 = memref<?x?xf64>

memref.global "private" constant @p64 : memref<64xi64> = dense<[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311]>

func.func @nsum_step(%s: f64, %c: f64, %x: f64) -> (f64, f64) {
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
  return %t, %nc : f64, f64
}

func.func @vec_new(%n: index) -> !vec {
  %v = memref.alloc(%n) : !vec
  return %v : !vec
}

func.func @tp_alpha(%n: index) -> !vec {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c64 = arith.constant 64 : index
  %one = arith.constant 1.0 : f64
  %tab = memref.get_global @p64 : memref<64xi64>
  %a = memref.alloc(%n) : !vec
  scf.for %j = %c0 to %n step %c1 {
    %k = arith.remui %j, %c64 : index
    %p = memref.load %tab[%k] : memref<64xi64>
    %pf = arith.sitofp %p : i64 to f64
    %l = math.log %pf : f64
    %z = arith.addf %one, %l : f64
    %al = arith.divf %one, %z : f64
    memref.store %al, %a[%j] : !vec
  }
  return %a : !vec
}

func.func @diag_from_alpha(%a: !vec) -> !mat2 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %z = arith.constant 0.0 : f64
  %n = memref.dim %a, %c0 : !vec
  %m = memref.alloc(%n, %n) : !mat2
  scf.for %i = %c0 to %n step %c1 {
    scf.for %j = %c0 to %n step %c1 {
      memref.store %z, %m[%i, %j] : !mat2
    }
    %v = memref.load %a[%i] : !vec
    memref.store %v, %m[%i, %i] : !mat2
  }
  return %m : !mat2
}

func.func @gershgorin_bound(%m: !mat2) -> f64 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %z = arith.constant 0.0 : f64
  %n = memref.dim %m, %c0 : !mat2
  %ninf = arith.constant 0xFFF0000000000000 : f64
  %best = scf.for %i = %c0 to %n step %c1 iter_args(%b = %ninf) -> (f64) {
    %r:2 = scf.for %j = %c0 to %n step %c1 iter_args(%s = %z, %c = %z) -> (f64, f64) {
      %eq = arith.cmpi eq, %i, %j : index
      %v = memref.load %m[%i, %j] : !mat2
      %av = math.absf %v : f64
      %x = arith.select %eq, %z, %av : f64
      %o:2 = func.call @nsum_step(%s, %c, %x) : (f64, f64, f64) -> (f64, f64)
      scf.yield %o#0, %o#1 : f64, f64
    }
    %off = arith.addf %r#0, %r#1 : f64
    %d = memref.load %m[%i, %i] : !mat2
    %ad = math.absf %d : f64
    %t = arith.addf %ad, %off : f64
    %gt = arith.cmpf ogt, %t, %b : f64
    %nb = arith.select %gt, %t, %b : f64
    scf.yield %nb : f64
  }
  %empty = arith.cmpi eq, %n, %c0 : index
  %res = arith.select %empty, %z, %best : f64
  return %res : f64
}

func.func @dot(%a: !vec, %b: !vec) -> f64 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %z = arith.constant 0.0 : f64
  %n = memref.dim %a, %c0 : !vec
  %r:2 = scf.for %j = %c0 to %n step %c1 iter_args(%s = %z, %c = %z) -> (f64, f64) {
    %x = memref.load %a[%j] : !vec
    %y = memref.load %b[%j] : !vec
    %p = arith.mulf %x, %y : f64
    %o:2 = func.call @nsum_step(%s, %c, %p) : (f64, f64, f64) -> (f64, f64)
    scf.yield %o#0, %o#1 : f64, f64
  }
  %t = arith.addf %r#0, %r#1 : f64
  return %t : f64
}

func.func @matvec(%m: !mat2, %v: !vec) -> !vec {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %z = arith.constant 0.0 : f64
  %n = memref.dim %m, %c0 : !mat2
  %out = memref.alloc(%n) : !vec
  scf.for %i = %c0 to %n step %c1 {
    %r:2 = scf.for %j = %c0 to %n step %c1 iter_args(%s = %z, %c = %z) -> (f64, f64) {
      %x = memref.load %m[%i, %j] : !mat2
      %y = memref.load %v[%j] : !vec
      %p = arith.mulf %x, %y : f64
      %o:2 = func.call @nsum_step(%s, %c, %p) : (f64, f64, f64) -> (f64, f64)
      scf.yield %o#0, %o#1 : f64, f64
    }
    %t = arith.addf %r#0, %r#1 : f64
    memref.store %t, %out[%i] : !vec
  }
  return %out : !vec
}

// power_iteration(J, max_iters, tol) -> |eigenvalue estimate|
func.func @power_iteration(%m: !mat2, %maxit: index, %tol: f64) -> f64 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %z = arith.constant 0.0 : f64
  %one = arith.constant 1.0 : f64
  %tiny = arith.constant 1.0e-15 : f64
  %n = memref.dim %m, %c0 : !mat2
  %n64 = arith.index_cast %n : index to i64
  %nf = arith.sitofp %n64 : i64 to f64
  %inv = arith.divf %one, %nf : f64
  %v0e = math.sqrt %inv : f64
  %v0 = memref.alloc(%n) : !vec
  scf.for %j = %c0 to %n step %c1 {
    memref.store %v0e, %v0[%j] : !vec
  }
  %true = arith.constant true
  %false = arith.constant false
  // loop state: iteration, v, eigenvalue, running, result
  %res:5 = scf.while (%it = %c0, %v = %v0, %ev = %z, %run = %true, %out = %z) : (index, !vec, f64, i1, f64) -> (index, !vec, f64, i1, f64) {
    %lt = arith.cmpi ult, %it, %maxit : index
    %go = arith.andi %lt, %run : i1
    scf.condition(%go) %it, %v, %ev, %run, %out : index, !vec, f64, i1, f64
  } do {
  ^bb0(%it: index, %v: !vec, %ev: f64, %run: i1, %out: f64):
    %jv = func.call @matvec(%m, %v) : (!mat2, !vec) -> !vec
    %nev = func.call @dot(%v, %jv) : (!vec, !vec) -> f64
    %d = arith.subf %nev, %ev : f64
    %ad = math.absf %d : f64
    %conv = arith.cmpf ogt, %tol, %ad : f64
    %anev = math.absf %nev : f64
    %nn = func.call @dot(%jv, %jv) : (!vec, !vec) -> f64
    %norm = math.sqrt %nn : f64
    %small = arith.cmpf olt, %norm, %tiny : f64
    %it1 = arith.addi %it, %c1 : index
    %r:5 = scf.if %conv -> (index, !vec, f64, i1, f64) {
      scf.yield %it1, %v, %nev, %false, %anev : index, !vec, f64, i1, f64
    } else {
      %r2:5 = scf.if %small -> (index, !vec, f64, i1, f64) {
        %ae = math.absf %nev : f64
        scf.yield %it1, %v, %nev, %false, %ae : index, !vec, f64, i1, f64
      } else {
        %nv = memref.alloc(%n) : !vec
        scf.for %j = %c0 to %n step %c1 {
          %x = memref.load %jv[%j] : !vec
          %y = arith.divf %x, %norm : f64
          memref.store %y, %nv[%j] : !vec
        }
        %ae = math.absf %nev : f64
        scf.yield %it1, %nv, %nev, %true, %ae : index, !vec, f64, i1, f64
      }
      scf.yield %r2#0, %r2#1, %r2#2, %r2#3, %r2#4 : index, !vec, f64, i1, f64
    }
    scf.yield %r#0, %r#1, %r#2, %r#3, %r#4 : index, !vec, f64, i1, f64
  }
  return %res#4 : f64
}

// spectral_analyze(J, eps) -> spectral_radius field
func.func @spectral_analyze(%m: !mat2, %eps: f64) -> f64 {
  %one = arith.constant 1.0 : f64
  %k95 = arith.constant 0.95 : f64
  %b = func.call @gershgorin_bound(%m) : (!mat2) -> f64
  %t = arith.subf %one, %eps : f64
  %contr = arith.cmpf olt, %b, %t : f64
  %thr = arith.mulf %k95, %t : f64
  %hi = arith.cmpf ogt, %b, %thr : f64
  %refine = arith.andi %contr, %hi : i1
  %r = scf.if %refine -> (f64) {
    %c100 = arith.constant 100 : index
    %tol = arith.constant 1.0e-12 : f64
    %p = func.call @power_iteration(%m, %c100, %tol) : (!mat2, index, f64) -> f64
    scf.yield %p : f64
  } else {
    scf.yield %b : f64
  }
  return %r : f64
}

func.func @soft_project_scale(%q: f64, %eps: f64) -> f64 {
  %one = arith.constant 1.0 : f64
  %t = arith.subf %one, %eps : f64
  %gt = arith.cmpf ogt, %q, %t : f64
  %s = arith.divf %t, %q : f64
  %r = arith.select %gt, %s, %one : f64
  return %r : f64
}

func.func @q_of_tp(%n: index, %eps: f64) -> f64 {
  %a = func.call @tp_alpha(%n) : (index) -> !vec
  %m = func.call @diag_from_alpha(%a) : (!vec) -> !mat2
  %q = func.call @spectral_analyze(%m, %eps) : (!mat2, f64) -> f64
  return %q : f64
}

func.func @c_op_norm(%n: index, %eps: f64) -> f64 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %a = func.call @tp_alpha(%n) : (index) -> !vec
  %q = func.call @q_of_tp(%n, %eps) : (index, f64) -> f64
  %s = func.call @soft_project_scale(%q, %eps) : (f64, f64) -> f64
  %ninf = arith.constant 0xFFF0000000000000 : f64
  %r = scf.for %j = %c0 to %n step %c1 iter_args(%b = %ninf) -> (f64) {
    %x = memref.load %a[%j] : !vec
    %y = arith.mulf %s, %x : f64
    %ay = math.absf %y : f64
    %gt = arith.cmpf ogt, %ay, %b : f64
    %nb = arith.select %gt, %ay, %b : f64
    scf.yield %nb : f64
  }
  return %r : f64
}

func.func @lam_m(%n: index, %eps: f64) -> f64 {
  %c1 = arith.constant 1 : index
  %one = arith.constant 1.0 : f64
  %z = arith.constant 0.0 : f64
  %delta = arith.constant 1.0e-12 : f64
  %small = arith.cmpi ult, %n, %c1 : index
  %r = scf.if %small -> (f64) {
    scf.yield %z : f64
  } else {
    %op = func.call @c_op_norm(%n, %eps) : (index, f64) -> f64
    %t = arith.subf %one, %eps : f64
    %den = arith.addf %op, %delta : f64
    %q = arith.divf %t, %den : f64
    %m = arith.minimumf %one, %q : f64
    scf.yield %m : f64
  }
  return %r : f64
}

func.func @tp_from_p64(%x: !vec) -> !vec {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %n = memref.dim %x, %c0 : !vec
  %a = func.call @tp_alpha(%n) : (index) -> !vec
  %o = memref.alloc(%n) : !vec
  scf.for %j = %c0 to %n step %c1 {
    %p = memref.load %a[%j] : !vec
    %v = memref.load %x[%j] : !vec
    %y = arith.mulf %p, %v : f64
    memref.store %y, %o[%j] : !vec
  }
  return %o : !vec
}

func.func @c_wrap(%x: !vec, %eps: f64) -> !vec {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %n = memref.dim %x, %c0 : !vec
  %q = func.call @q_of_tp(%n, %eps) : (index, f64) -> f64
  %s = func.call @soft_project_scale(%q, %eps) : (f64, f64) -> f64
  %o = memref.alloc(%n) : !vec
  scf.for %j = %c0 to %n step %c1 {
    %v = memref.load %x[%j] : !vec
    %y = arith.mulf %s, %v : f64
    memref.store %y, %o[%j] : !vec
  }
  return %o : !vec
}

// hcalc_step with uniform ξ and zero g: ξ·(Λm·C(Tp(X))) + g
func.func @hcalc_step(%x: !vec, %eps: f64, %xi: f64, %g: !vec) -> !vec {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %n = memref.dim %x, %c0 : !vec
  %tpx = func.call @tp_from_p64(%x) : (!vec) -> !vec
  %cx = func.call @c_wrap(%tpx, %eps) : (!vec, f64) -> !vec
  %lam = func.call @lam_m(%n, %eps) : (index, f64) -> f64
  %o = memref.alloc(%n) : !vec
  scf.for %j = %c0 to %n step %c1 {
    %v = memref.load %cx[%j] : !vec
    %mid = arith.mulf %lam, %v : f64
    %s = arith.mulf %xi, %mid : f64
    %gj = memref.load %g[%j] : !vec
    %y = arith.addf %s, %gj : f64
    memref.store %y, %o[%j] : !vec
  }
  return %o : !vec
}

func.func @to_foundry_step_diagnostic(%x: !vec, %eps: f64, %xi: f64, %g: !vec) -> !vec {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %n = memref.dim %x, %c0 : !vec
  %lam = func.call @lam_m(%n, %eps) : (index, f64) -> f64
  %tpx = func.call @tp_from_p64(%x) : (!vec) -> !vec
  %tx = func.call @c_wrap(%tpx, %eps) : (!vec, f64) -> !vec
  %o = memref.alloc(%n) : !vec
  scf.for %j = %c0 to %n step %c1 {
    %v = memref.load %x[%j] : !vec
    %a = arith.mulf %xi, %v : f64
    %t = memref.load %tx[%j] : !vec
    %b = arith.mulf %lam, %t : f64
    %gj = memref.load %g[%j] : !vec
    // J evaluates right to left: (ξ·x) + ((Λm·Tx) + g)
    %bg = arith.addf %b, %gj : f64
    %y = arith.addf %a, %bg : f64
    memref.store %y, %o[%j] : !vec
  }
  return %o : !vec
}

func.func @residual_linf(%a: !vec, %b: !vec) -> f64 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %n = memref.dim %a, %c0 : !vec
  %ninf = arith.constant 0xFFF0000000000000 : f64
  %r = scf.for %j = %c0 to %n step %c1 iter_args(%m = %ninf) -> (f64) {
    %x = memref.load %a[%j] : !vec
    %y = memref.load %b[%j] : !vec
    %d = arith.subf %x, %y : f64
    %ad = math.absf %d : f64
    %gt = arith.cmpf ogt, %ad, %m : f64
    %nm = arith.select %gt, %ad, %m : f64
    scf.yield %nm : f64
  }
  return %r : f64
}

// hcalc_run -> (x_final, converged, steps, last residual)
func.func @hcalc_run(%x0: !vec, %maxs: index, %tol: f64, %eps: f64, %xi: f64, %g: !vec) -> (!vec, i1, index, f64) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %z = arith.constant 0.0 : f64
  %true = arith.constant true
  %false = arith.constant false
  %r:4 = scf.while (%t = %c0, %x = %x0, %conv = %false, %res = %z) : (index, !vec, i1, f64) -> (index, !vec, i1, f64) {
    %lt = arith.cmpi ult, %t, %maxs : index
    %nc = arith.xori %conv, %true : i1
    %go = arith.andi %lt, %nc : i1
    scf.condition(%go) %t, %x, %conv, %res : index, !vec, i1, f64
  } do {
  ^bb0(%t: index, %x: !vec, %conv: i1, %res: f64):
    %xn = func.call @hcalc_step(%x, %eps, %xi, %g) : (!vec, f64, f64, !vec) -> !vec
    %rs = func.call @residual_linf(%x, %xn) : (!vec, !vec) -> f64
    %t1 = arith.addi %t, %c1 : index
    %cv = arith.cmpf olt, %rs, %tol : f64
    scf.yield %t1, %xn, %cv, %rs : index, !vec, i1, f64
  }
  return %r#1, %r#2, %r#0, %r#3 : !vec, i1, index, f64
}
