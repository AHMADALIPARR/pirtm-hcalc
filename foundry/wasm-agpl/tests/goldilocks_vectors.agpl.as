// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Goldilocks vector tests: modulus boundaries, zero/one identities,
// inverse and power cases, batch operations. runTests returns the number
// of failing checks; firstFailure returns the id of the first failure.
import { P, goldilocksAdd, goldilocksSub, goldilocksNeg, goldilocksMul, goldilocksPow, goldilocksInv, goldilocksReduce } from "../goldilocks/field.agpl.as";
import { batchAdd, batchMul, vectorDot } from "../goldilocks/batch.agpl.as";

let failures: i32 = 0;
let first: i32 = 0;

function check(id: i32, got: u64, want: u64): void {
  if (got != want) {
    failures++;
    if (first == 0) first = id;
  }
}

export function runTests(): i32 {
  failures = 0;
  first = 0;
  // add
  check(1, goldilocksAdd(10, 20), 30);
  check(2, goldilocksAdd(P - 1, 1), 0);
  check(3, goldilocksAdd(P - 1, 2), 1);
  check(4, goldilocksAdd(P - 1, P - 1), P - 2);
  check(5, goldilocksAdd(0, 0), 0);
  // sub
  check(6, goldilocksSub(5, 9), P - 4);
  check(7, goldilocksSub(0, 1), P - 1);
  check(8, goldilocksSub(P - 1, P - 1), 0);
  // neg
  check(9, goldilocksNeg(0), 0);
  check(10, goldilocksNeg(1), P - 1);
  check(11, goldilocksNeg(P - 1), 1);
  // mul
  check(12, goldilocksMul(2, 3), 6);
  check(13, goldilocksMul(123456789, 987654321), 121932631112635269);
  check(14, goldilocksMul(P - 1, P - 1), 1);
  check(15, goldilocksMul(P - 1, 2), P - 2);
  check(16, goldilocksMul(0, 12345), 0);
  check(17, goldilocksMul(1, 1), 1);
  check(18, goldilocksMul(1 << 40, 1 << 33), 2199023255040);
  // pow
  check(19, goldilocksPow(3, 5), 243);
  check(20, goldilocksPow(7, 0), 1);
  check(21, goldilocksPow(2, 64), 4294967295);
  check(22, goldilocksPow(5, 100), 2554167064307250276);
  // inv
  check(23, goldilocksMul(goldilocksInv(2), 2), 1);
  check(24, goldilocksMul(goldilocksInv(1337), 1337), 1);
  check(25, goldilocksMul(goldilocksInv(P - 1), P - 1), 1);
  check(26, goldilocksInv(0), 0);
  // reduce
  check(27, goldilocksReduce(P), 0);
  check(28, goldilocksReduce(P + 5), 5);
  // batchAdd: a = [10, P-1], b = [20, 1] -> [30, 0]
  const ptr: usize = 0;
  store<u64>(ptr + 0, 10);
  store<u64>(ptr + 8, P - 1);
  store<u64>(ptr + 16, 20);
  store<u64>(ptr + 24, 1);
  batchAdd(ptr, 2);
  check(29, load<u64>(ptr + 32), 30);
  check(30, load<u64>(ptr + 40), 0);
  // batchMul: a = [2, P-1], b = [3, P-1] -> [6, 1]
  store<u64>(ptr + 0, 2);
  store<u64>(ptr + 8, P - 1);
  store<u64>(ptr + 16, 3);
  store<u64>(ptr + 24, P - 1);
  batchMul(ptr, 2);
  check(31, load<u64>(ptr + 32), 6);
  check(32, load<u64>(ptr + 40), 1);
  // vectorDot: a = [1,2,3], b = [4,5,6] -> 32
  store<u64>(ptr + 0, 1);
  store<u64>(ptr + 8, 2);
  store<u64>(ptr + 16, 3);
  store<u64>(ptr + 24, 4);
  store<u64>(ptr + 32, 5);
  store<u64>(ptr + 40, 6);
  check(33, vectorDot(ptr, 3), 32);
  return failures;
}

export function firstFailure(): i32 {
  return first;
}
