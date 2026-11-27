; Copyright (C) 2026 AHMADALIPARR
; SPDX-License-Identifier: AGPL-3.0-only
; SysV -> Win64 shim, test-only. Not part of the shipped module.
; SysV -> Win64 shim for testing only (not part of the repo).
; C caller: shim_sha256(rdi=data, rsi=len, rdx=out)
; asm wants: rcx=data, rdx=len, r8=out
bits 64
default rel
global shim_sha256
extern sha256_hash
section .text
shim_sha256:
    mov rcx, rdi
    mov r8, rdx
    mov rdx, rsi
    jmp sha256_hash
