// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// SHA-256 NASM test driver: NIST vectors incl. the 1M-byte case.
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
extern void shim_sha256(const uint8_t *data, size_t len, uint8_t out[32]);
static void hex(const uint8_t *d, char *o) { for (int i = 0; i < 32; i++) sprintf(o + 2*i, "%02x", d[i]); }
static int fails = 0;
static void check(const char *name, const uint8_t *data, size_t len, const char *want) {
    uint8_t out[32]; char got[65];
    shim_sha256(data, len, out); hex(out, got);
    if (strcmp(got, want)) { printf("FAIL %s\n  got:  %s\n  want: %s\n", name, got, want); fails++; }
    else printf("ok   %s\n", name);
}
int main(void) {
    check("sha256('')", (const uint8_t*)"", 0, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    check("sha256('abc')", (const uint8_t*)"abc", 3, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    check("sha256(56-byte)", (const uint8_t*)"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 56, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
    uint8_t *m = malloc(1000000); memset(m, 'a', 1000000);
    check("sha256(1M x 'a')", m, 1000000, "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0");
    free(m);
    printf(fails ? "SHA256-NASM: %d FAILURES\n" : "SHA256-NASM: ALL PASS\n", fails);
    return fails ? 1 : 0;
}
