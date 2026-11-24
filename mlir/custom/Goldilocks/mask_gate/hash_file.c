/* hash_file.c — new-harness gate driver 
 * Reads a file and prints its SHA-256 as computed by the user's NASM mask
 * gate (sha256_hash) through the SysV->Win64 adapter in call_gate.asm.
 * Usage: hash_file <path>
 * Markers go to stderr (flushed) so a crash is attributable; the digest
 * goes to stdout alone. Exit 0 on success. If the gate never returns
 * (it currently has no ret), this process dies with the gate's signal
 * instead of printing a digest.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

extern void hash_via_gate(const uint8_t *data, size_t len, uint8_t out[32]);

int main(int argc, char **argv) {
    FILE *f;
    uint8_t *data = NULL;
    size_t len = 0, cap = 0, n;
    uint8_t out[32];
    int i;

    if (argc != 2) {
        fprintf(stderr, "usage: hash_file <path>\n");
        return 2;
    }
    f = fopen(argv[1], "rb");
    if (!f) {
        fprintf(stderr, "hash_file: cannot open %s\n", argv[1]);
        return 2;
    }
    cap = 4096;
    data = malloc(cap);
    if (!data) {
        fclose(f);
        return 2;
    }
    while ((n = fread(data + len, 1, cap - len, f)) > 0) {
        len += n;
        if (len == cap) {
            cap *= 2;
            data = realloc(data, cap);
            if (!data) {
                fclose(f);
                return 2;
            }
        }
    }
    fclose(f);
    fprintf(stderr, "calling sha256_hash on %s (%zu bytes)...\n", argv[1], len);
    fflush(stderr);
    hash_via_gate(data, len, out);
    fprintf(stderr, "returned from sha256_hash\n");
    fflush(stderr);
    for (i = 0; i < 32; ++i) {
        printf("%02x", out[i]);
    }
    printf("\n");
    free(data);
    return 0;
}
