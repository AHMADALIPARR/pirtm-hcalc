NB. SPDX-License-Identifier: AGPL-3.0-only
NB. Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
NB. Copyright (C) 2026 Ahmad Parr
NB.
NB. cite.ijs — the small set of numeric "cite hooks" HCALC Core calls:
NB.   P64 (first 64 primes), gershgorin_bound, gershgorin_check,
NB.   power_iteration, power_iteration_check, spectral_analyze, sr_* accessors.
NB. Written for this project so HCALC Core has no external J dependency.
NB. SpectralResult (open) = spectral_radius ; contractive ; gershgorin_bound ;
NB.                         power_iter_bound ; used_power_iteration
NB. Producers return it in one outer box.
NB. Locale: cite

cocurrent 'cite'

NB. first 64 primes, computed (p: is J's n-th prime primitive)
P64 =: p: i. 64

NB. gershgorin_bound J — max_i ( |J_ii| + sum_{j~:i} |J_ij| )
gershgorin_bound =: 3 : 0
  J =. y
  n =. # J
  if. 0 = n do. 0 return. end.
  off =. +/"1 | J * -. =/~ i. n
  dg  =. | (<0 1) |: J
  >./ dg + off
)

NB. J gershgorin_check eps — contractive iff bound < 1-eps
gershgorin_check =: 4 : 0
  b =. gershgorin_bound x
  < b ; (b < 1 - y) ; b ; b ; 0
)

NB. J power_iteration (max_iters , tol) — Rayleigh-quotient power iteration,
NB. start vector n $ 1/sqrt n; returns |eigenvalue estimate|
power_iteration =: 4 : 0
  J =. x
  'max_iters tol' =. 2 {. (, y) , 100 1e_12
  n =. # J
  if. 0 = n do. 0 return. end.
  v =. n $ %: % n
  ev =. 0.
  for_k. i. max_iters do.
    Jv =. J +/ . * v
    nev =. v +/ . * Jv
    if. tol > | nev - ev do. | nev return. end.
    ev =. nev
    nrm =. %: Jv +/ . * Jv
    if. nrm < 1e_15 do. break. end.
    v =. Jv % nrm
  end.
  | ev
)

NB. J power_iteration_check (eps , max_iters)
power_iteration_check =: 4 : 0
  'eps max_iters' =. 2 {. (, y) , 0.1 100
  b =. x power_iteration max_iters , 1e_12
  < b ; (b < 1 - eps) ; (gershgorin_bound x) ; b ; 1
)

NB. J spectral_analyze eps — Gershgorin first; if contractive but the bound is
NB. above 0.95*(1-eps), refine with power iteration
spectral_analyze =: 4 : 0
  r =. > x gershgorin_check y
  if. (1 {:: r) *. (2 {:: r) > 0.95 * 1 - y do.
    r =. > x power_iteration_check y , 100
  end.
  < r
)

sr_fields      =: 3 : 'if. 1 < L. y do. > y else. y end.'
sr_radius      =: 0 {:: sr_fields
sr_contractive =: 1 {:: sr_fields
sr_gersh       =: 2 {:: sr_fields
sr_power       =: 3 {:: sr_fields
sr_used_pi     =: 4 {:: sr_fields

cocurrent 'base'
