// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Goldilocks field arithmetic over p = 2^64 - 2^32 + 1.
// Written from the field definition. Canonical representation: every value
// is in [0, p). No code carried over from any other implementation.

export const P: u64 = 0xffffffff00000001;
export const P_MINUS_ONE: u64 = 0xffffffff00000000;
export const P_MINUS_TWO: u64 = 0xfffffffeffffffff;

// reduce: x mod p for a single u64 x. x < 2^64 < 2p, so one subtraction
// suffices when x >= p.
export function goldilocksReduce(x: u64): u64 {
  if (x >= P) return x - P;
  return x;
}

// add: (a + b) mod p. a + b can exceed 2^64, so a plain u64 add wraps.
// When it wraps, s < a (for b > 0), and the true sum is s + 2^64;
// (s + 2^64) mod p = s + (2^64 - p) = s + (2^32 - 1).
export function goldilocksAdd(a: u64, b: u64): u64 {
  const x = a % P;
  const y = b % P;
  const s = x + y;
  if (s < x) return s + 0xffffffff;
  if (s >= P) return s - P;
  return s;
}

// sub: (a - b) mod p. When a < b the u64 subtraction wraps to
// 2^64 + a - b; adding p wraps back to a - b + p, which is in [1, p).
export function goldilocksSub(a: u64, b: u64): u64 {
  const x = a % P;
  const y = b % P;
  if (x >= y) return x - y;
  return x - y + P;
}

// neg: (-a) mod p.
export function goldilocksNeg(a: u64): u64 {
  const x = a % P;
  if (x == 0) return 0;
  return P - x;
}

// reduce128: (lo + hi * 2^64) mod p.
// 2^64 = 2^32 - 1 (mod p), so x = lo + hi * (2^32 - 1).
// hi * (2^32 - 1) = hi * 2^32 - hi, and hi * 2^32 splits into
// (hi << 32) plus (hi >> 32) * 2^64, whose 2^64 folds again to
// (hi >> 32) * (2^32 - 1). Every piece is reduced to [0, p) first,
// then combined with field add/sub.
function reduce128(lo: u64, hi: u64): u64 {
  const t = hi << 32;
  const c = hi >> 32;
  const u = c * 0xffffffff; // c < 2^32, so u < 2^64
  let r = goldilocksAdd(goldilocksReduce(lo), goldilocksReduce(t));
  r = goldilocksAdd(r, goldilocksReduce(u));
  r = goldilocksSub(r, goldilocksReduce(hi));
  return r;
}

// mul: (a * b) mod p, via the 128-bit product in 32-bit limbs.
// p0..p3 are the four partial products; the middle sum p1 + p2 can
// overflow by one bit (midCarry), and the low sum can carry once
// (loCarry). hi is the exact high word of the product.
export function goldilocksMul(a: u64, b: u64): u64 {
  const x = a % P;
  const y = b % P;
  const xLo = x & 0xffffffff;
  const xHi = x >> 32;
  const yLo = y & 0xffffffff;
  const yHi = y >> 32;
  const p0 = xLo * yLo;
  const p1 = xLo * yHi;
  const p2 = xHi * yLo;
  const p3 = xHi * yHi;
  const midLo = p1 + p2;
  const midCarry: u64 = midLo < p1 ? 1 : 0;
  const lo = p0 + (midLo << 32);
  const loCarry: u64 = lo < p0 ? 1 : 0;
  const hi = p3 + (midLo >> 32) + (midCarry << 32) + loCarry;
  return reduce128(lo, hi);
}

// pow: a^e mod p by square-and-multiply.
export function goldilocksPow(a: u64, e: u64): u64 {
  let base = a % P;
  let r: u64 = 1;
  let exp = e;
  while (exp > 0) {
    if ((exp & 1) == 1) r = goldilocksMul(r, base);
    base = goldilocksMul(base, base);
    exp >>= 1;
  }
  return r;
}

// inv: a^(p-2) mod p (Fermat). inv(0) = 0 by convention.
export function goldilocksInv(a: u64): u64 {
  const x = a % P;
  if (x == 0) return 0;
  return goldilocksPow(x, P - 2);
}
