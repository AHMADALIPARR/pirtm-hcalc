// goldilocks.h — assistant-reconstructed from goldilocks.cpp (NOT the user's original).
// The user supplied goldilocks.cpp only; it includes "goldilocks.h", which was
// not pasted. This header is reconstructed from the .cpp's usage: class
// Goldilocks in namespace pmc, Elem with a public uint64_t v, static constexpr
// P = 2^64 - 2^32 + 1, and the static member functions reduce, mulmod, add,
// sub, mul, inv, pow, add_batch, mul_batch, has_sse2, has_avx2. If the user's
// real header differs, replace this file with it.

#ifndef PIRTM_FOUNDRY_GOLDILOCKS_H
#define PIRTM_FOUNDRY_GOLDILOCKS_H

#include <cstddef>
#include <cstdint>

namespace pmc {

class Goldilocks {
public:
    // Goldilocks prime: p = 2^64 - 2^32 + 1 = 0xFFFFFFFF00000001
    static constexpr uint64_t P = 0xFFFFFFFF00000001ULL;

    struct Elem {
        uint64_t v;
        Elem() : v(0) {}
        explicit Elem(uint64_t v_) : v(v_) {}
    };

    static uint64_t reduce(uint64_t x);
    static uint64_t mulmod(uint64_t a, uint64_t b);
    static Elem add(Elem a, Elem b);
    static Elem sub(Elem a, Elem b);
    static Elem mul(Elem a, Elem b);
    static Elem inv(Elem a);
    static Elem pow(Elem a, uint64_t e);
    static void add_batch(Elem* out, const Elem* a, const Elem* b, size_t n);
    static void mul_batch(Elem* out, const Elem* a, const Elem* b, size_t n);
    static bool has_sse2();
    static bool has_avx2();
};

} // namespace pmc

#endif // PIRTM_FOUNDRY_GOLDILOCKS_H
