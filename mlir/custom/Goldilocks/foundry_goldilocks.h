#include <cstdint>

namespace foundry::goldilocks {

inline constexpr uint64_t P   = 0xFFFFFFFF00000001ULL; // 2^64 - 2^32 + 1
inline constexpr uint64_t EPS = 0xFFFFFFFFULL;         // 2^32 - 1

[[nodiscard]] constexpr uint64_t add(uint64_t a, uint64_t b) noexcept {
    // Matches MLIR i128 widening and J/Lean exact integer semantics
    const __uint128_t sum = static_cast<__uint128_t>(a) + static_cast<__uint128_t>(b);
    return static_cast<uint64_t>(sum >= P ? sum - P : sum);
}

[[nodiscard]] constexpr uint64_t sub(uint64_t a, uint64_t b) noexcept {
    // Unsigned borrow compare matching MLIR gl_sub (a < b)
    const uint64_t diff = a - b;
    return (a < b) ? (diff + P) : diff;
}

} // namespace foundry::goldilocks
