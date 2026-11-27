// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// Library test for hardware/c11/beal_check.h (the u32 Beal-instance
// checker). Exercises the public API and asserts the expected status
// for each input. Every check is asserted, and any failure exits non-zero.
#include <stdio.h>
#include <stdint.h>
#include "beal_check.h"

static int checks = 0;
static int failures = 0;

static void expect_status(const char *name, beal32_status got,
                          beal32_status want) {
    ++checks;
    if (got != want) {
        ++failures;
        printf("FAIL %s: got %d, want %d\n", name, (int)got, (int)want);
    }
}

static void expect_bool(const char *name, bool got, bool want) {
    ++checks;
    if (got != want) {
        ++failures;
        printf("FAIL %s: got %d, want %d\n", name, (int)got, (int)want);
    }
}

static void expect_u32(const char *name, uint32_t got, uint32_t want) {
    ++checks;
    if (got != want) {
        ++failures;
        printf("FAIL %s: got %u, want %u\n", name, got, want);
    }
}

int main(void) {
    uint32_t out = 0;

    /* Checked multiply. */
    expect_bool("mul 2*3", beal_checked_mul_u32(2, 3, &out), true);
    expect_u32("mul 2*3 value", out, 6);
    expect_bool("mul max*2 overflow", beal_checked_mul_u32(UINT32_MAX, 2, &out), false);
    expect_bool("mul 0*5", beal_checked_mul_u32(0, 5, &out), true);
    expect_u32("mul 0*5 value", out, 0);
    expect_bool("mul 65535*65535", beal_checked_mul_u32(65535, 65535, &out), true);
    expect_u32("mul 65535*65535 value", out, 4294836225u);
    expect_bool("mul 65536*65536 overflow", beal_checked_mul_u32(65536, 65536, &out), false);

    /* Checked add. */
    expect_bool("add 2+3", beal_checked_add_u32(2, 3, &out), true);
    expect_u32("add 2+3 value", out, 5);
    expect_bool("add max+1 overflow", beal_checked_add_u32(UINT32_MAX, 1, &out), false);
    expect_bool("add 0+0", beal_checked_add_u32(0, 0, &out), true);
    expect_u32("add 0+0 value", out, 0);

    /* Power. */
    expect_bool("pow 2^3", beal_pow_u32(2, 3, &out), true);
    expect_u32("pow 2^3 value", out, 8);
    expect_bool("pow 3^3", beal_pow_u32(3, 3, &out), true);
    expect_u32("pow 3^3 value", out, 27);
    expect_bool("pow 2^32 overflow", beal_pow_u32(2, 32, &out), false);
    expect_bool("pow 0^0", beal_pow_u32(0, 0, &out), true);
    expect_u32("pow 0^0 value", out, 1);
    expect_bool("pow 0^5", beal_pow_u32(0, 5, &out), true);
    expect_u32("pow 0^5 value", out, 0);
    expect_bool("pow 1^100", beal_pow_u32(1, 100, &out), true);
    expect_u32("pow 1^100 value", out, 1);
    expect_bool("pow 65536^2 overflow", beal_pow_u32(65536, 2, &out), false);

    /* Instance check: the Beal example 3^3 + 6^3 = 3^5 (27 + 216 = 243). */
    expect_status("3^3+6^3=3^5", beal_check_u32(3, 6, 3, 3, 3, 5), BEAL32_EQUAL);
    /* Non-solutions. */
    expect_status("2^3+3^3=5^3", beal_check_u32(2, 3, 5, 3, 3, 3), BEAL32_NOT_EQUAL);
    expect_status("1^3+1^3=2^3", beal_check_u32(1, 1, 2, 3, 3, 3), BEAL32_NOT_EQUAL);
    expect_status("256^3+256^3=256^3", beal_check_u32(256, 256, 256, 3, 3, 3), BEAL32_NOT_EQUAL);
    /* Invalid inputs: zero base, exponent below 3. */
    expect_status("base 0", beal_check_u32(0, 6, 3, 3, 3, 5), BEAL32_INVALID);
    expect_status("exp 2", beal_check_u32(3, 6, 3, 2, 2, 2), BEAL32_INVALID);
    expect_status("exp 0", beal_check_u32(3, 6, 3, 0, 3, 5), BEAL32_INVALID);
    /* Overflow: a power exceeds u32, and a sum that exceeds u32. */
    expect_status("2^32 overflow", beal_check_u32(2, 3, 5, 32, 3, 3), BEAL32_OVERFLOW);
    expect_status("65536^3 overflow", beal_check_u32(65536, 3, 5, 3, 3, 3), BEAL32_OVERFLOW);
    expect_status("1500^3+1500^3 sum overflow",
                  beal_check_u32(1500, 1500, 1500, 3, 3, 3), BEAL32_OVERFLOW);

    printf("beal_check_u32_test: %d checks, %d failures\n", checks, failures);
    return failures == 0 ? 0 : 1;
}
