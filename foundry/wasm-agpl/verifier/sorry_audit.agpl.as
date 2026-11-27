// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Lean sorry counter and proof status check over a normalized proof text
// held in linear memory. Counts are non-overlapping substring tallies.
// Status codes: 0 = CLEAN, 1 = HAS_SORRY, 2 = HAS_ADMIT,
// 3 = NO_THEOREM, 4 = INVALID (empty or negative-length input).
export const PROOF_CLEAN: i32 = 0;
export const PROOF_HAS_SORRY: i32 = 1;
export const PROOF_HAS_ADMIT: i32 = 2;
export const PROOF_NO_THEOREM: i32 = 3;
export const PROOF_INVALID: i32 = 4;

const SORRY: StaticArray<u8> = [0x73, 0x6f, 0x72, 0x72, 0x79];
const ADMIT: StaticArray<u8> = [0x61, 0x64, 0x6d, 0x69, 0x74];
const THEOREM: StaticArray<u8> = [0x74, 0x68, 0x65, 0x6f, 0x72, 0x65, 0x6d];
const LEMMA: StaticArray<u8> = [0x6c, 0x65, 0x6d, 0x6d, 0x61];

function countSub(ptr: usize, len: i32, needle: StaticArray<u8>): i32 {
  const n = needle.length;
  if (len < n) return 0;
  let count = 0;
  for (let i = 0; i + n <= len; i++) {
    let hit = true;
    for (let j = 0; j < n; j++) {
      if (load<u8>(ptr + i + j) != needle[j]) {
        hit = false;
        break;
      }
    }
    if (hit) {
      count++;
      i += n - 1;
    }
  }
  return count;
}

// countSorry: number of "sorry" occurrences in the input.
export function countSorry(ptr: usize, len: i32): i32 {
  if (len < 0) return -1;
  return countSub(ptr, len, SORRY);
}

// countAdmit: number of "admit" occurrences in the input.
export function countAdmit(ptr: usize, len: i32): i32 {
  if (len < 0) return -1;
  return countSub(ptr, len, ADMIT);
}

// proofStatus: the L2/L4 gate decision for the input text.
export function proofStatus(ptr: usize, len: i32): i32 {
  if (len <= 0) return PROOF_INVALID;
  if (countSub(ptr, len, SORRY) > 0) return PROOF_HAS_SORRY;
  if (countSub(ptr, len, ADMIT) > 0) return PROOF_HAS_ADMIT;
  if (countSub(ptr, len, THEOREM) == 0 && countSub(ptr, len, LEMMA) == 0) {
    return PROOF_NO_THEOREM;
  }
  return PROOF_CLEAN;
}
