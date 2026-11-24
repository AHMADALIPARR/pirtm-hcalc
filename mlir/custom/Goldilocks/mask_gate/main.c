/* main.c 
 * Calls the user's sha256_hash through the SysV->Win64 wrapper and checks
 * the output against vectors verified with the system sha256sum.
 * Prints a marker (flushed) before each call so a crash is attributable.
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

void sha256_hash_linux(const uint8_t* data, size_t len, uint8_t out[32]);

static void to_hex(const uint8_t* in, char* out) {
    static const char* h = "0123456789abcdef";
    for (int i = 0; i < 32; ++i) {
        out[2*i] = h[in[i] >> 4];
        out[2*i+1] = h[in[i] & 15];
    }
    out[64] = 0;
}

static int run(const char* name, const uint8_t* data, size_t len, const char* want) {
    uint8_t out[32];
    char hex[65];
    printf("calling sha256_hash on %s (%zu bytes)...\n", name, len);
    fflush(stdout);
    memset(out, 0, sizeof out);
    sha256_hash_linux(data, len, out);
    printf("returned from sha256_hash on %s\n", name);
    fflush(stdout);
    to_hex(out, hex);
    if (strcmp(hex, want) == 0) {
        printf("PASS %s: %s\n", name, hex);
        return 0;
    }
    printf("FAIL %s: got %s want %s\n", name, hex, want);
    return 1;
}

int main(void) {
    int fails = 0;
    fails += run("empty", (const uint8_t*)"", 0,
                 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    fails += run("abc", (const uint8_t*)"abc", 3,
                 "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    fails += run("long56",
                 (const uint8_t*)"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 56,
                 "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
    printf("failures=%d\n", fails);
    return fails ? 1 : 0;
}
