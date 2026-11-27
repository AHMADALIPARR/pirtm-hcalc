// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// SHA-256 vector tests: empty, single-block, and multi-block digests.
// runTests returns the number of failing checks; firstFailure returns the
// id of the first failure. Expected digests are the FIPS 180-4 / NIST
// vectors, written as big-endian u32 words.
import { sha256 } from "../hash/sha256.agpl.as";

let failures: i32 = 0;
let first: i32 = 0;

const IN: usize = 0;
const OUT: usize = 1024;

function bswap32(x: u32): u32 {
  return ((x & 0xff) << 24) | ((x & 0xff00) << 8) | ((x >> 8) & 0xff00) | (x >> 24);
}

function checkDigest(id: i32, want: StaticArray<u32>): void {
  let bad = 0;
  for (let i = 0; i < 8; i++) {
    // The digest bytes at OUT are big-endian; load<u32> reads little-endian.
    if (bswap32(load<u32>(OUT + i * 4)) != want[i]) bad++;
  }
  if (bad != 0) {
    failures++;
    if (first == 0) first = id;
  }
}

function fillA(len: i32): void {
  for (let i = 0; i < len; i++) store<u8>(IN + i, 0x61);
}

function writeStr(s: string): i32 {
  for (let i = 0; i < s.length; i++) store<u8>(IN + i, u8(s.charCodeAt(i)));
  return s.length;
}

export function runTests(): i32 {
  failures = 0;
  first = 0;
  // 1: empty
  sha256(IN, 0, OUT);
  checkDigest(1, [0xe3b0c442, 0x98fc1c14, 0x9afbf4c8, 0x996fb924, 0x27ae41e4, 0x649b934c, 0xa495991b, 0x7852b855]);
  // 2: "abc"
  let n = writeStr("abc");
  sha256(IN, n, OUT);
  checkDigest(2, [0xba7816bf, 0x8f01cfea, 0x414140de, 0x5dae2223, 0xb00361a3, 0x96177a9c, 0xb410ff61, 0xf20015ad]);
  // 3: 56-byte classic vector
  n = writeStr("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
  sha256(IN, n, OUT);
  checkDigest(3, [0x248d6a61, 0xd20638b8, 0xe5c02693, 0x0c3e6039, 0xa33ce459, 0x64ff2167, 0xf6ecedd4, 0x19db06c1]);
  // 4: 55 x 'a'
  fillA(55);
  sha256(IN, 55, OUT);
  checkDigest(4, [0x9f4390f8, 0xd30c2dd9, 0x2ec9f095, 0xb65e2b9a, 0xe9b0a925, 0xa5258e24, 0x1c9f1e91, 0x0f734318]);
  // 5: 56 x 'a'
  fillA(56);
  sha256(IN, 56, OUT);
  checkDigest(5, [0xb35439a4, 0xac6f0948, 0xb6d6f9e3, 0xc6af0f5f, 0x590ce20f, 0x1bde7090, 0xef797068, 0x6ec6738a]);
  // 6: 64 x 'a' (one full block plus padding block)
  fillA(64);
  sha256(IN, 64, OUT);
  checkDigest(6, [0xffe054fe, 0x7ae0cb6d, 0xc65c3af9, 0xb61d5209, 0xf439851d, 0xb43d0ba5, 0x997337df, 0x154668eb]);
  // 7: 65 x 'a'
  fillA(65);
  sha256(IN, 65, OUT);
  checkDigest(7, [0x635361c4, 0x8bb9eab1, 0x4198e76e, 0xa8ab7f1a, 0x41685d6a, 0xd62aa914, 0x6d301d4f, 0x17eb0ae0]);
  // 8: 128 x 'a' (two full blocks)
  fillA(128);
  sha256(IN, 128, OUT);
  checkDigest(8, [0x6836cf13, 0xbac400e9, 0x105071cd, 0x6af47084, 0xdfacad4e, 0x5e302c94, 0xbfed24e0, 0x13afb73e]);
  // 9: 200 x 'a' (three full blocks plus padding)
  fillA(200);
  sha256(IN, 200, OUT);
  checkDigest(9, [0xc2a908d9, 0x8f5df987, 0xade41b5f, 0xce213067, 0xefbcc21e, 0xf2240212, 0xa41e54b5, 0xe7c28ae5]);
  return failures;
}

export function firstFailure(): i32 {
  return first;
}
