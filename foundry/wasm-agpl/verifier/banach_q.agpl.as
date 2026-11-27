// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Contraction ratio (banachQ) and the q < 1 - epsilon gate, matching the
// Foundry L4 qEstimate contract.
// Fixed-point reading: every quantity is a canonical field element, the
// real value of v is v / p, and 1 corresponds to p. So q < 1 - epsilon
// is exactly q + epsilon < p as integers.
// Status codes: 0 = PASS, 1 = FAIL, 2 = INVALID (an input is not canonical).
import { P, goldilocksAdd, goldilocksMul } from "../goldilocks/field.agpl.as";

export const BANACH_PASS: i32 = 0;
export const BANACH_FAIL: i32 = 1;
export const BANACH_INVALID: i32 = 2;

// banachQ: q = xi + lambda * t (mod p), the L4 qEstimate value.
export function banachQ(xi: u64, lambda: u64, t: u64): u64 {
  return goldilocksAdd(xi, goldilocksMul(lambda, t));
}

// banachGate: PASS when q < 1 - epsilon, FAIL otherwise, INVALID when any
// input is not a canonical field element. Returns a status code, never a
// thrown string.
export function banachGate(xi: u64, lambda: u64, t: u64, epsilon: u64): i32 {
  if (xi >= P || lambda >= P || t >= P || epsilon >= P) return BANACH_INVALID;
  const q = banachQ(xi, lambda, t);
  const s = q + epsilon;
  if (s < q) return BANACH_FAIL; // q + epsilon >= 2^64, so >= p
  return s < P ? BANACH_PASS : BANACH_FAIL;
}
