// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// beal_check: bounded Beal-instance checker over 32-bit unsigned operands.
// General library implementation. Checked arithmetic widens to 64 bits;
// overflow is reported, never wrapped. Bases 0 and 1 take a fast path so
// a huge exponent cannot spin the power loop.
#include "beal_check.h"

bool beal_checked_mul_u32(uint32_t a, uint32_t b, uint32_t *out) {
    uint64_t wide = (uint64_t)a * (uint64_t)b;
    if (wide > UINT32_MAX) return false;
    *out = (uint32_t)wide;
    return true;
}

bool beal_checked_add_u32(uint32_t a, uint32_t b, uint32_t *out) {
    uint64_t wide = (uint64_t)a + (uint64_t)b;
    if (wide > UINT32_MAX) return false;
    *out = (uint32_t)wide;
    return true;
}

bool beal_pow_u32(uint32_t base, uint32_t exp, uint32_t *out) {
    if (base == 0) {
        *out = (exp == 0) ? 1u : 0u;
        return true;
    }
    if (base == 1) {
        *out = 1u;
        return true;
    }
    uint32_t acc = 1;
    for (uint32_t i = 0; i < exp; ++i) {
        if (!beal_checked_mul_u32(acc, base, &acc)) return false;
    }
    *out = acc;
    return true;
}

beal32_status beal_check_u32(uint32_t a, uint32_t b, uint32_t c,
                             uint32_t x, uint32_t y, uint32_t z) {
    if (a == 0 || b == 0 || c == 0) return BEAL32_INVALID;
    if (x < 3 || y < 3 || z < 3) return BEAL32_INVALID;
    uint32_t ax, by, cz, sum;
    if (!beal_pow_u32(a, x, &ax) || !beal_pow_u32(b, y, &by) ||
        !beal_pow_u32(c, z, &cz) || !beal_checked_add_u32(ax, by, &sum))
        return BEAL32_OVERFLOW;
    return (sum == cz) ? BEAL32_EQUAL : BEAL32_NOT_EQUAL;
}
