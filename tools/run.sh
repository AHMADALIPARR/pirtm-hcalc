#!/usr/bin/env bash
# run.sh — driver for the new foundry harness.
#
# Full run: finds a J interpreter, runs the J driver
# (mlir/harness/foundry_harness.ijs), builds the NASM gate driver, hashes
# the run record through the gate, and writes output/cert.txt and
# output/status.txt.
#
#   bash mlir/harness/run.sh                 # full run
#   bash mlir/harness/run.sh --gate-check [file]
#                                            # gate path only: build the gate
#                                            # driver and hash the given file
#                                            # (or a dummy record when none
#                                            # is given). Skips the J stage.
#
# Exit codes: 0 full pass (J ran, record hashed); 1 J run failed or gate
# build failed; 2 no J interpreter found; 3 gate blocked (the gate crashed
# or never returned). The gate is the user's code and is never fixed here;
# a blocked gate is reported, not worked around.
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HARNESS_DIR="$ROOT/mlir/harness"
OUT="$HARNESS_DIR/output"
GATE_ASM="$ROOT/mlir/mask-gate/sha256.asm"
mkdir -p "$OUT"
STATUS_FILE="$OUT/status.txt"
: > "$STATUS_FILE"

say() {
  echo "$@" | tee -a "$STATUS_FILE"
}

find_j() {
  for c in jconsole j je; do
    if command -v "$c" >/dev/null 2>&1; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

build_gate() {
  if ! command -v nasm >/dev/null 2>&1; then
    say "GATE_BUILD_FAIL nasm not found"
    return 1
  fi
  if ! command -v gcc >/dev/null 2>&1; then
    say "GATE_BUILD_FAIL gcc not found"
    return 1
  fi
  if ! nasm -f elf64 "$GATE_ASM" -o "$OUT/sha256.o" 2> "$OUT/gate-build.err"; then
    say "GATE_BUILD_FAIL nasm mlir/mask-gate/sha256.asm"
    cat "$OUT/gate-build.err" >> "$STATUS_FILE"
    return 1
  fi
  if ! nasm -f elf64 "$HARNESS_DIR/mask_gate/call_gate.asm" -o "$OUT/call_gate.o" 2>> "$OUT/gate-build.err"; then
    say "GATE_BUILD_FAIL nasm mask_gate/call_gate.asm"
    return 1
  fi
  # -no-pie: the gate's .asm uses absolute 32-bit addressing, which the
  # default PIE link rejects (R_X86_64_32S against .bss). This is a link
  # flag for the harness driver only; the user's .asm is untouched.
  if ! gcc -no-pie "$HARNESS_DIR/mask_gate/hash_file.c" "$OUT/sha256.o" "$OUT/call_gate.o" -o "$OUT/hash_file" 2>> "$OUT/gate-build.err"; then
    say "GATE_BUILD_FAIL gcc link hash_file"
    return 1
  fi
  say "GATE_BUILD_OK"
  return 0
}

run_gate() {
  # $1 = file to hash. On success the hex digest lands in output/cert.txt.
  "$OUT/hash_file" "$1" > "$OUT/cert.txt" 2> "$OUT/gate.err"
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    say "GATE_BLOCKED hash_file exit $rc (the gate crashed or never returned)"
    say "GATE_BLOCKED cause: sha256_hash in mlir/mask-gate/sha256.asm has no ret; the file ends at pop rbx. See STATUS.md. The gate is the user's code; it is not fixed here."
    return 3
  fi
  say "GATE_PASS digest: $(cat "$OUT/cert.txt")"
  return 0
}

MODE="${1:-full}"

if [ "$MODE" = "--gate-check" ]; then
  TARGET="${2:-$OUT/dummy-record.txt}"
  if [ -z "${2:-}" ]; then
    printf 'foundry gate check\n' > "$TARGET"
  fi
  build_gate || exit 1
  run_gate "$TARGET" || exit 3
  say "GATE_CHECK_PASS"
  exit 0
fi

if [ "$MODE" != "full" ]; then
  echo "usage: run.sh [full | --gate-check [file]]" >&2
  exit 1
fi

J="$(find_j)" || {
  say "HARNESS_BLOCKED no-j-interpreter (j, jconsole, je all absent)"
  exit 2
}
say "J interpreter: $J"
"$J" "$HARNESS_DIR/foundry_harness.ijs" > "$OUT/console.log" 2>&1
jrc=$?
if [ "$jrc" -ne 0 ]; then
  say "HARNESS_FAIL j run exit $jrc (see mlir/harness/output/console.log)"
  exit 1
fi
if [ ! -f "$OUT/record.txt" ]; then
  say "HARNESS_FAIL no output/record.txt produced"
  exit 1
fi
say "J stage done: $(wc -l < "$OUT/record.txt") record lines"
build_gate || exit 1
run_gate "$OUT/record.txt" || exit 3
say "HARNESS_PASS"
exit 0
