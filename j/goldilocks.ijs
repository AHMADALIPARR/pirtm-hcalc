NB. SPDX-License-Identifier: AGPL-3.0-only
NB. Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
NB. Copyright (C) 2026 Ahmad Parr
NB.
NB. goldilocks.ijs — Goldilocks field F_p, p = 2^64 - 2^32 + 1, on J extended
NB. integers. gl_mul uses the 2^64 = 2^32 - 1 (mod p) fold (the same
NB. algorithm as mlir/lib/goldilocks.mlir); gl_mul_ref is plain (a*b) mod p,
NB. used to check the fold.
NB. Locale: gl

cocurrent 'gl'

P     =: 18446744069414584321x      NB. 2^64 - 2^32 + 1
EPS   =: 4294967295x                NB. 2^32 - 1
TWO64 =: 2x ^ 64
TWO32 =: 2x ^ 32

gl_reduce =: 3 : 'P | x: y'"0
gl_add =: 4 : 0"0
  r =. (x: x) + x: y
  if. r >: P do. r - P else. r end.
)
gl_sub =: 4 : 0"0
  r =. (x: x) - x: y
  if. r < 0 do. r + P else. r end.
)
NB. fold: a*b = hi*2^64 + lo, hi = hh*2^32 + hl
NB.   2^64 = EPS, 2^96 = -1  =>  a*b = lo + hl*EPS - hh (mod P)
gl_mul =: 4 : 0"0
  t  =. (x: x) * x: y
  lo =. TWO64 | t
  hi =. t <.@% TWO64
  hl =. TWO32 | hi
  hh =. hi <.@% TWO32
  f  =. lo + hl * EPS
  r  =. f - hh
  if. r < 0 do. r =. r + P end.
  while. r >: P do. r =. r - P end.
  r
)
gl_mul_ref =: 4 : 'P | (x: x) * x: y'"0
gl_pow =: 4 : 0
  b =. x: x
  e =. x: y
  r =. 1x
  while. e > 0 do.
    if. 1 = 2 | e do. r =. r gl_mul b end.
    b =. b gl_mul b
    e =. e <.@% 2
  end.
  r
)
gl_inv =: 3 : 'y gl_pow P - 2'

cocurrent 'base'
