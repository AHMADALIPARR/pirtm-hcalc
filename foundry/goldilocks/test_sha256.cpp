// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// SHA-256 C++ portable-path test: NIST vectors.
#include <cstdio>
#include <cstring>
#include "sha256.h"
static int fails = 0;
static void check(const char* n, const uint8_t* d, size_t l, const char* w) {
    auto h = pmc::SHA256::hash(d, l); char g[65];
    for (int i = 0; i < 32; i++) sprintf(g + 2*i, "%02x", h[i]);
    if (strcmp(g, w)) { printf("FAIL %s\n  got:  %s\n  want: %s\n", n, g, w); fails++; }
    else printf("ok   %s\n", n);
}
int main() {
    check("cpp sha256('')", (const uint8_t*)"", 0, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    check("cpp sha256('abc')", (const uint8_t*)"abc", 3, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    check("cpp sha256(56-byte)", (const uint8_t*)"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 56, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
    printf(fails ? "SHA256-CPP: %d FAILURES\n" : "SHA256-CPP: ALL PASS\n", fails);
    return fails ? 1 : 0;
}
