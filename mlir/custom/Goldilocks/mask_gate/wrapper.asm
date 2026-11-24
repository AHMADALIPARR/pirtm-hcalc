 wrapper.asm 
; Adapts the Linux System V calling convention to the Windows x64 calling
; convention the user's sha256_hash expects:
;   SysV:  RDI = data, RSI = len, RDX = out
;   Win64: RCX = data, RDX = len, R8  = out
; void sha256_hash_linux(const uint8_t* data, size_t len, uint8_t out[32]);

bits 64
default rel

global sha256_hash_linux
extern sha256_hash

section .text
sha256_hash_linux:
    mov r8, rdx        ; out -> R8 (before RDX is overwritten)
    mov rcx, rdi       ; data -> RCX
    mov rdx, rsi       ; len -> RDX
    call sha256_hash
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
