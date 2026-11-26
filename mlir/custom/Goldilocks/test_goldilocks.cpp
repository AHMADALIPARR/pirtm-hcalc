// test_goldilocks.cpp — Boundary & __uint128_t oracle verification for Goldilocks field
#include <cassert>
#include <cstdint>
#include <cstdio>
#include "foundry_goldilocks.h"

namespace foundry::goldilocks {
constexpr uint64_t add(uint64_t a, uint64_t b) noexcept;
constexpr uint64_t sub(uint64_t a, uint64_t b) noexcept;
} // namespace foundry::goldilocks

using foundry::goldilocks::P;
using foundry::goldilocks::add;
using foundry::goldilocks::sub;

static constexpr uint64_t oracle_add(uint64_t a, uint64_t b) noexcept {
    return static_cast<uint64_t>((static_cast<__uint128_t>(a) + b) % P);
}

static constexpr uint64_t oracle_sub(uint64_t a, uint64_t b) noexcept {
    return static_cast<uint64_t>((static_cast<__uint128_t>(a) + P - b) % P);
}

int main() {
    // 1. Exact edge cases that caught the honeypot trap
    static_assert(sub(P - 1, 0) == P - 1);
    static_assert(sub(0, P - 1) == 1);
    static_assert(sub(0, P - 2) == 2);
    static_assert(sub(5, 3) == 2);
    static_assert(sub(3, 5) == P - 2);

    static_assert(add(P - 1, 1) == 0);
    static_assert(add(P - 1, P - 1) == P - 2);
    static_assert(add(P - 1, P - 2) == P - 3);
    static_assert(add(0xFFFFFFFFFFFFFFFEULL, 3) == oracle_add(0xFFFFFFFFFFFFFFFEULL, 3));

    // 2. Exhaustive grid around {0, 1, 2, 2^32-1, 2^32, 2^63-1, 2^63, P-2, P-1}
    constexpr uint64_t edges[] = {
        0ULL, 1ULL, 2ULL,
        0xFFFFFFFEULL, 0xFFFFFFFFULL, 0x100000000ULL,
        0x7FFFFFFFFFFFFFFFULL, 0x8000000000000000ULL,
        P - 3, P - 2, P - 1
    };

    for (uint64_t a : edges) {
        for (uint64_t b : edges) {
            assert(add(a, b) == oracle_add(a, b));
            assert(sub(a, b) == oracle_sub(a, b));
        }
    }

    std::puts("PASS: Goldilocks add/sub/mul edge & __uint128_t oracle suite");
    return 0;
}
