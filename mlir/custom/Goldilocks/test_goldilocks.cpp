/ test_goldilocks.cpp — verification harness for the user's goldilocks.cpp.
// Oracle: exact __uint128_t arithmetic, (a op b) mod P, computed independently
// of the code under test. Deterministic test values: edge cases plus a fixed
// LCG sequence (seed 11). Prints PASS/FAIL per case; exits non-zero on failure.
// This harness is assistant-written; the code under test is the user's verbatim paste.

#include "goldilocks.h"
#include <cstdint>
#include <cstdio>
#include <cstring>

using pmc::Goldilocks;
using Elem = Goldilocks::Elem;

static constexpr uint64_t P = Goldilocks::P;
static int failures = 0;
static int checks = 0;

static uint64_t oracle_add(uint64_t a, uint64_t b) {
    return static_cast<uint64_t>((static_cast<__uint128_t>(a) + b) % P);
}
static uint64_t oracle_sub(uint64_t a, uint64_t b) {
    return static_cast<uint64_t>((static_cast<__uint128_t>(a) + P - b) % P);
}
static uint64_t oracle_mul(uint64_t a, uint64_t b) {
    return static_cast<uint64_t>((static_cast<__uint128_t>(a) * b) % P);
}

static void check(const char* name, uint64_t got, uint64_t want) {
    ++checks;
    if (got == want) {
        std::printf("PASS %s: %llu\n", name, (unsigned long long)got);
    } else {
        ++failures;
        std::printf("FAIL %s: got %llu want %llu\n", name,
                    (unsigned long long)got, (unsigned long long)want);
    }
}

int main() {
    // P value
    check("P == 0xFFFFFFFF00000001", P, 0xFFFFFFFF00000001ULL);

    // reduce
    check("reduce(0)", Goldilocks::reduce(0), 0);
    check("reduce(P-1)", Goldilocks::reduce(P - 1), P - 1);
    check("reduce(P)", Goldilocks::reduce(P), 0);
    check("reduce(2^64-1)", Goldilocks::reduce(0xFFFFFFFFFFFFFFFFULL),
          0xFFFFFFFFFFFFFFFFULL - P);

    // Fixed test values
    static const uint64_t vals[] = {
        0, 1, 2, 3, 0xFFFFFFFFULL, 0x100000000ULL,
        0x7FFFFFFFFFFFFFFFULL, 0xFFFFFFFF00000000ULL,
        P - 1, P - 2, 123456789ULL, 987654321987654321ULL,
    };
    const size_t nvals = sizeof(vals) / sizeof(vals[0]);

    // add / sub / mul against the oracle, all pairs of the edge values
    for (size_t i = 0; i < nvals; ++i) {
        for (size_t j = 0; j < nvals; ++j) {
            char name[96];
            std::snprintf(name, sizeof name, "add(%llu,%llu)",
                          (unsigned long long)vals[i], (unsigned long long)vals[j]);
            check(name, Goldilocks::add(Elem(vals[i]), Elem(vals[j])).v,
                  oracle_add(vals[i], vals[j]));
            std::snprintf(name, sizeof name, "sub(%llu,%llu)",
                          (unsigned long long)vals[i], (unsigned long long)vals[j]);
            check(name, Goldilocks::sub(Elem(vals[i]), Elem(vals[j])).v,
                  oracle_sub(vals[i], vals[j]));
            std::snprintf(name, sizeof name, "mul(%llu,%llu)",
                          (unsigned long long)vals[i], (unsigned long long)vals[j]);
            check(name, Goldilocks::mul(Elem(vals[i]), Elem(vals[j])).v,
                  oracle_mul(vals[i], vals[j]));
        }
    }

    // LCG pseudo-random values, fixed seed 11
    uint64_t s = 11;
    for (int k = 0; k < 64; ++k) {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        uint64_t a = s % P;
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        uint64_t b = s % P;
        char name[96];
        std::snprintf(name, sizeof name, "rand add #%d", k);
        check(name, Goldilocks::add(Elem(a), Elem(b)).v, oracle_add(a, b));
        std::snprintf(name, sizeof name, "rand sub #%d", k);
        check(name, Goldilocks::sub(Elem(a), Elem(b)).v, oracle_sub(a, b));
        std::snprintf(name, sizeof name, "rand mul #%d", k);
        check(name, Goldilocks::mul(Elem(a), Elem(b)).v, oracle_mul(a, b));
        // inverse: a * inv(a) == 1 for a != 0
        if (a != 0) {
            std::snprintf(name, sizeof name, "rand inv #%d", k);
            uint64_t inv = Goldilocks::inv(Elem(a)).v;
            check(name, oracle_mul(a, inv), 1);
        }
    }

    // pow
    check("pow(2,0)", Goldilocks::pow(Elem(2), 0).v, 1);
    check("pow(2,1)", Goldilocks::pow(Elem(2), 1).v, 2);
    check("pow(2,10)", Goldilocks::pow(Elem(2), 10).v, 1024);
    check("pow(3,5)", Goldilocks::pow(Elem(3), 5).v, 243);
    check("pow(P-1,2)", Goldilocks::pow(Elem(P - 1), 2).v, 1);
    check("pow(5,P-1)", Goldilocks::pow(Elem(5), P - 1).v, 1);
    check("inv(1)", Goldilocks::inv(Elem(1)).v, 1);
    check("inv(P-1)", Goldilocks::inv(Elem(P - 1)).v, P - 1);

    // batches
    {
        Elem a[4] = {Elem(1), Elem(P - 1), Elem(5), Elem(0xFFFFFFFFULL)};
        Elem b[4] = {Elem(2), Elem(P - 1), Elem(7), Elem(3)};
        Elem out[4];
        Goldilocks::add_batch(out, a, b, 4);
        for (int i = 0; i < 4; ++i) {
            char name[64];
            std::snprintf(name, sizeof name, "add_batch[%d]", i);
            check(name, out[i].v, oracle_add(a[i].v, b[i].v));
        }
        Goldilocks::mul_batch(out, a, b, 4);
        for (int i = 0; i < 4; ++i) {
            char name[64];
            std::snprintf(name, sizeof name, "mul_batch[%d]", i);
            check(name, out[i].v, oracle_mul(a[i].v, b[i].v));
        }
    }

    std::printf("has_sse2=%d has_avx2=%d (informational)\n",
                (int)Goldilocks::has_sse2(), (int)Goldilocks::has_avx2());
    std::printf("checks=%d failures=%d\n", checks, failures);
    return failures ? 1 : 0;
}
