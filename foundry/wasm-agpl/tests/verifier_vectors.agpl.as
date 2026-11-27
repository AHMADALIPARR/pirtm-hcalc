// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Verifier vector tests: boundary q values, epsilon margins, and sorry
// tallies. runTests returns the number of failing checks; firstFailure
// returns the id of the first failure.
import { P } from "../goldilocks/field.agpl.as";
import { banachQ, banachGate } from "../verifier/banach_q.agpl.as";
import { countSorry, countAdmit, proofStatus } from "../verifier/sorry_audit.agpl.as";
import { l2Gate } from "../verifier/l2_l4_bridge.agpl.as";

let failures: i32 = 0;
let first: i32 = 0;

const IN: usize = 0;
const EPS: u64 = 1844674406941458432; // p / 10, the 10% tier epsilon

function check(id: i32, got: i64, want: i64): void {
  if (got != want) {
    failures++;
    if (first == 0) first = id;
  }
}

function writeStr(s: string): i32 {
  for (let i = 0; i < s.length; i++) store<u8>(IN + i, u8(s.charCodeAt(i)));
  return s.length;
}

export function runTests(): i32 {
  failures = 0;
  first = 0;
  // banachQ values
  check(1, banachQ(10, 3, 5) as i64, 25);
  check(2, banachQ(0, P - 1, P - 1) as i64, 1);
  // banachGate boundaries (epsilon = p / 10)
  check(3, banachGate(0, 0, 0, EPS), 0); // q = 0, well below
  check(4, banachGate(P - EPS - 1, 0, 0, EPS), 0); // q + eps = p - 1
  check(5, banachGate(P - EPS, 0, 0, EPS), 1); // q + eps = p, at the gate
  check(6, banachGate(P - 1, 0, 0, EPS), 1); // q + eps > p
  check(7, banachGate(0, 0, 0, 0), 0); // epsilon 0, q = 0
  check(8, banachGate(P - 1, 0, 0, 0), 0); // epsilon 0, q = p - 1 < p
  check(9, banachGate(0, P - 1, P - 1, EPS), 0); // q = 1 via (p-1)^2
  check(10, banachGate(P, P - 1, 0, EPS), 2); // xi not canonical
  check(11, banachGate(0, 0, 0, P), 2); // epsilon not canonical
  // l2Gate through the bridge
  check(12, l2Gate(P - EPS - 1, EPS), 0);
  check(13, l2Gate(P - EPS, EPS), 1);
  // sorry tallies
  let n = writeStr("theorem foo : True := by sorry");
  check(14, countSorry(IN, n), 1);
  check(15, proofStatus(IN, n), 1);
  n = writeStr("theorem foo : True := by trivial");
  check(16, countSorry(IN, n), 0);
  check(17, proofStatus(IN, n), 0);
  n = writeStr("sorry sorry sorry");
  check(18, countSorry(IN, n), 3);
  check(19, proofStatus(IN, n), 1);
  n = writeStr("theorem x := by admit");
  check(20, countAdmit(IN, n), 1);
  check(21, proofStatus(IN, n), 2);
  check(22, proofStatus(IN, 0), 4);
  n = writeStr("def x := 1");
  check(23, proofStatus(IN, n), 3);
  n = writeStr("sorryAx");
  check(24, countSorry(IN, n), 1);
  n = writeStr("theorem t : P := by sorry\ntheorem u : Q := by sorry");
  check(25, countSorry(IN, n), 2);
  return failures;
}

export function firstFailure(): i32 {
  return first;
}
