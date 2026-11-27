// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Goldilocks field test harness: known values and edge cases.
#include <cstdio>
#include <cstdint>
#include "goldilocks.h"
using pmc::Goldilocks;
using E = Goldilocks::Elem;
static const uint64_t P = Goldilocks::P;
static int fails = 0;
#define CHECK(name, got, want) do { uint64_t g = (got), w = (want); if (g != w) { printf("FAIL %s got %llu want %llu\n", name, (unsigned long long)g, (unsigned long long)w); fails++; } else printf("ok   %s\n", name); } while (0)
int main() {
    CHECK("add(10,20)", Goldilocks::add(E(10), E(20)).v, 30);
    CHECK("add(P-1,1)", Goldilocks::add(E(P-1), E(1)).v, 0);
    CHECK("add(P-1,2)", Goldilocks::add(E(P-1), E(2)).v, 1);
    CHECK("add(P-1,P-1)", Goldilocks::add(E(P-1), E(P-1)).v, P-2);
    CHECK("sub(5,9)", Goldilocks::sub(E(5), E(9)).v, P-4);
    CHECK("sub(0,1)", Goldilocks::sub(E(0), E(1)).v, P-1);
    CHECK("mul(2,3)", Goldilocks::mul(E(2), E(3)).v, 6);
    CHECK("mul(123456789,987654321)", Goldilocks::mul(E(123456789), E(987654321)).v, 121932631112635269ULL);
    CHECK("mul(P-1,P-1)", Goldilocks::mul(E(P-1), E(P-1)).v, 1);
    CHECK("mulmod(2^40,2^33)", Goldilocks::mulmod(1ULL<<40, 1ULL<<33), 2199023255040ULL);
    CHECK("pow(3,5)", Goldilocks::pow(E(3), 5).v, 243);
    CHECK("pow(7,0)", Goldilocks::pow(E(7), 0).v, 1);
    CHECK("inv(2)*2", Goldilocks::mul(Goldilocks::inv(E(2)), E(2)).v, 1);
    CHECK("inv(1337)*1337", Goldilocks::mul(Goldilocks::inv(E(1337)), E(1337)).v, 1);
    CHECK("inv(P-1)*(P-1)", Goldilocks::mul(Goldilocks::inv(E(P-1)), E(P-1)).v, 1);
    printf(fails ? "GOLDILOCKS: %d FAILURES\n" : "GOLDILOCKS: ALL PASS\n", fails);
    return fails ? 1 : 0;
}
