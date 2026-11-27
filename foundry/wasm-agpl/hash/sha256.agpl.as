// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// SHA-256 from FIPS 180-4: message padding, 64-word schedule expansion,
// and 64-round compression over fixed linear memory slices.
// No allocation happens during compression: the schedule, the block, and
// the state live in module-level static arrays, allocated once at
// instantiation, so execution time and memory footprint stay predictable.
const K: StaticArray<u32> = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
  0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
  0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
  0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
  0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const H_INIT: StaticArray<u32> = [
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

const W = new StaticArray<u32>(64);
const HSTATE = new StaticArray<u32>(8);
const BLOCK = new StaticArray<u8>(64);

function rotr(x: u32, n: u32): u32 {
  return (x >> n) | (x << (32 - n));
}

// One 64-round compression of the 64 bytes in BLOCK into HSTATE.
function compress(): void {
  for (let i = 0; i < 16; i++) {
    const o = i * 4;
    W[i] = ((BLOCK[o] as u32) << 24) | ((BLOCK[o + 1] as u32) << 16) |
      ((BLOCK[o + 2] as u32) << 8) | (BLOCK[o + 3] as u32);
  }
  for (let i = 16; i < 64; i++) {
    const s0 = rotr(W[i - 15], 7) ^ rotr(W[i - 15], 18) ^ (W[i - 15] >> 3);
    const s1 = rotr(W[i - 2], 17) ^ rotr(W[i - 2], 19) ^ (W[i - 2] >> 10);
    W[i] = W[i - 16] + s0 + W[i - 7] + s1;
  }
  let a = HSTATE[0];
  let b = HSTATE[1];
  let c = HSTATE[2];
  let d = HSTATE[3];
  let e = HSTATE[4];
  let f = HSTATE[5];
  let g = HSTATE[6];
  let h = HSTATE[7];
  for (let i = 0; i < 64; i++) {
    const s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
    const ch = (e & f) ^ (~e & g);
    const t1 = h + s1 + ch + K[i] + W[i];
    const s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
    const maj = (a & b) ^ (a & c) ^ (b & c);
    const t2 = s0 + maj;
    h = g;
    g = f;
    f = e;
    e = d + t1;
    d = c;
    c = b;
    b = a;
    a = t1 + t2;
  }
  HSTATE[0] += a;
  HSTATE[1] += b;
  HSTATE[2] += c;
  HSTATE[3] += d;
  HSTATE[4] += e;
  HSTATE[5] += f;
  HSTATE[6] += g;
  HSTATE[7] += h;
}

// sha256: one-shot digest of len bytes at ptr, 32 bytes written to outPtr.
export function sha256(ptr: usize, len: i32, outPtr: usize): void {
  for (let i = 0; i < 8; i++) HSTATE[i] = H_INIT[i];
  let off = 0;
  while (len - off >= 64) {
    for (let i = 0; i < 64; i++) BLOCK[i] = load<u8>(ptr + off + i);
    compress();
    off += 64;
  }
  const rem = len - off;
  for (let i = 0; i < 64; i++) BLOCK[i] = 0;
  for (let i = 0; i < rem; i++) BLOCK[i] = load<u8>(ptr + off + i);
  BLOCK[rem] = 0x80;
  if (rem >= 56) {
    compress();
    for (let i = 0; i < 64; i++) BLOCK[i] = 0;
  }
  const bits = (len as u64) << 3;
  for (let i = 0; i < 8; i++) {
    BLOCK[56 + i] = u8((bits >> (56 - 8 * i)) & 0xff);
  }
  compress();
  for (let i = 0; i < 8; i++) {
    const hv = HSTATE[i];
    store<u8>(outPtr + i * 4 + 0, u8((hv >> 24) & 0xff));
    store<u8>(outPtr + i * 4 + 1, u8((hv >> 16) & 0xff));
    store<u8>(outPtr + i * 4 + 2, u8((hv >> 8) & 0xff));
    store<u8>(outPtr + i * 4 + 3, u8(hv & 0xff));
  }
}
