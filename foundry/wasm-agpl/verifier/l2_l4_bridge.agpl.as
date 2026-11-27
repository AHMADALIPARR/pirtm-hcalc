// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Foundry L2/L4 bridge: exported WASM entrypoints and the explicit linear
// memory layout shared with C and host harnesses. No browser runtime is
// involved: the host writes inputs at INPUT_PTR, calls an entrypoint, and
// reads outputs at RESULT_PTR.
//
// Linear memory layout (byte offsets, one 64 KiB page):
//   INPUT_PTR   0     input buffer, 4096 bytes
//   SCRATCH_PTR 4096  scratch space, 4096 bytes
//   RESULT_PTR  8192  result struct, 256 bytes
// Result struct at RESULT_PTR:
//   +0   u32  status
//   +4   u32  reserved
//   +8   u64  value
//   +16  u32  count
//   +20  u32  reserved
import { P, goldilocksAdd, goldilocksMul, goldilocksInv, goldilocksPow } from "../goldilocks/field.agpl.as";
import { batchAdd, batchMul, vectorDot } from "../goldilocks/batch.agpl.as";
import { sha256 } from "../hash/sha256.agpl.as";
import { banachGate, banachQ } from "./banach_q.agpl.as";
import { countSorry, proofStatus } from "./sorry_audit.agpl.as";

export const INPUT_PTR: usize = 0;
export const INPUT_LEN: i32 = 4096;
export const SCRATCH_PTR: usize = 4096;
export const SCRATCH_LEN: i32 = 4096;
export const RESULT_PTR: usize = 8192;
export const RESULT_LEN: i32 = 256;

export function inputPtr(): usize {
  return INPUT_PTR;
}
export function scratchPtr(): usize {
  return SCRATCH_PTR;
}
export function resultPtr(): usize {
  return RESULT_PTR;
}

// l2Gate: the L2 contractive criterion, bound < 1 - epsilon.
// Status: 0 = PASS, 1 = FAIL, 2 = INVALID.
export function l2Gate(bound: u64, epsilon: u64): i32 {
  if (bound >= P || epsilon >= P) return 2;
  const s = bound + epsilon;
  if (s < bound) return 1;
  return s < P ? 0 : 1;
}

// l4Gate: the L4 qEstimate contraction check. See banach_q.agpl.as.
export function l4Gate(xi: u64, lambda: u64, t: u64, epsilon: u64): i32 {
  return banachGate(xi, lambda, t, epsilon);
}

// l4Q: the L4 qEstimate value q = xi + lambda * t (mod p).
export function l4Q(xi: u64, lambda: u64, t: u64): u64 {
  return banachQ(xi, lambda, t);
}

// hashInput: SHA-256 of INPUT_PTR[0..len); digest at RESULT_PTR + 8,
// status 0 at RESULT_PTR + 0.
export function hashInput(len: i32): void {
  sha256(INPUT_PTR, len, RESULT_PTR + 8);
  store<u32>(RESULT_PTR, 0);
}

// auditInput: sorry count of INPUT_PTR[0..len); proof status at
// RESULT_PTR + 0, count at RESULT_PTR + 16. Returns the count.
export function auditInput(len: i32): i32 {
  const n = countSorry(INPUT_PTR, len);
  store<u32>(RESULT_PTR, proofStatus(INPUT_PTR, len));
  store<u32>(RESULT_PTR + 16, n);
  return n;
}

// batchAddAt / batchMulAt: batch field ops over SCRATCH_PTR.
export function batchAddAt(count: i32): void {
  batchAdd(SCRATCH_PTR, count);
}
export function batchMulAt(count: i32): void {
  batchMul(SCRATCH_PTR, count);
}
export function vectorDotAt(count: i32): u64 {
  return vectorDot(SCRATCH_PTR, count);
}

// Field ops, re-exported for C callers.
export function fieldAdd(a: u64, b: u64): u64 {
  return goldilocksAdd(a, b);
}
export function fieldMul(a: u64, b: u64): u64 {
  return goldilocksMul(a, b);
}
export function fieldInv(a: u64): u64 {
  return goldilocksInv(a);
}
export function fieldPow(a: u64, e: u64): u64 {
  return goldilocksPow(a, e);
}
