// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// beal_check: bounded Beal-instance checker over 32-bit unsigned operands.
// A general library: no main, no hardcoded instance. Callers pass the
// bases and exponents; the checker reports EQUAL, NOT_EQUAL, OVERFLOW,
// or INVALID (a zero base, or an exponent below 3, which is outside Beal).
// Checked arithmetic widens to 64 bits so overflow is detected, never
// wrapped.
#ifndef BEAL_CHECK_H
#define BEAL_CHECK_H

#include <stdint.h>
#include <stdbool.h>

typedef enum {
  BEAL32_EQUAL = 0,
  BEAL32_NOT_EQUAL = 1,
  BEAL32_OVERFLOW = 2,
  BEAL32_INVALID = 3
} beal32_status;

bool beal_checked_mul_u32(uint32_t a, uint32_t b, uint32_t *out);
bool beal_checked_add_u32(uint32_t a, uint32_t b, uint32_t *out);
bool beal_pow_u32(uint32_t base, uint32_t exp, uint32_t *out);
beal32_status beal_check_u32(uint32_t a, uint32_t b, uint32_t c,
                             uint32_t x, uint32_t y, uint32_t z);

#endif /* BEAL_CHECK_H */
