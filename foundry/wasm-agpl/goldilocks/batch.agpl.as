// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Batch Goldilocks operations over linear memory slices.
// Layout at ptr: a[0..n) as u64, then b[0..n) as u64; results are written
// at ptr + 16*n as u64, except where a function documents otherwise.
// All values are canonical field elements in [0, p).
import { goldilocksAdd, goldilocksSub, goldilocksMul, goldilocksPow } from "./field.agpl.as";

// batchAdd: out[i] = a[i] + b[i] mod p.
export function batchAdd(ptr: usize, count: i32): void {
  for (let i = 0; i < count; i++) {
    const a = load<u64>(ptr + (i << 3));
    const b = load<u64>(ptr + ((count + i) << 3));
    store<u64>(ptr + ((2 * count + i) << 3), goldilocksAdd(a, b));
  }
}

// batchSub: out[i] = a[i] - b[i] mod p.
export function batchSub(ptr: usize, count: i32): void {
  for (let i = 0; i < count; i++) {
    const a = load<u64>(ptr + (i << 3));
    const b = load<u64>(ptr + ((count + i) << 3));
    store<u64>(ptr + ((2 * count + i) << 3), goldilocksSub(a, b));
  }
}

// batchMul: out[i] = a[i] * b[i] mod p.
export function batchMul(ptr: usize, count: i32): void {
  for (let i = 0; i < count; i++) {
    const a = load<u64>(ptr + (i << 3));
    const b = load<u64>(ptr + ((count + i) << 3));
    store<u64>(ptr + ((2 * count + i) << 3), goldilocksMul(a, b));
  }
}

// batchPow: out[i] = a[i]^exp mod p. Layout: a[0..n) at ptr, out[0..n)
// at ptr + 8*n.
export function batchPow(ptr: usize, count: i32, exp: u64): void {
  for (let i = 0; i < count; i++) {
    const a = load<u64>(ptr + (i << 3));
    store<u64>(ptr + ((count + i) << 3), goldilocksPow(a, exp));
  }
}

// vectorDot: sum of a[i] * b[i] mod p.
export function vectorDot(ptr: usize, count: i32): u64 {
  let acc: u64 = 0;
  for (let i = 0; i < count; i++) {
    const a = load<u64>(ptr + (i << 3));
    const b = load<u64>(ptr + ((count + i) << 3));
    acc = goldilocksAdd(acc, goldilocksMul(a, b));
  }
  return acc;
}
