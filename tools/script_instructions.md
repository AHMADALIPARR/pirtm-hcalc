# New harness — full J stack plus the NASM mask gate

This harness replaces the two assistant-written harnesses. It runs the
J stack's own checks and pipes the run record through the NASM mask
gate (SHA-256) as the certification and mask step. The old harnesses
are not deleted: `mlir/goldilocks/test_goldilocks.cpp` and
`mlir/mask-gate/tests/` stay in place, marked superseded in STATUS.md,
with their recorded results kept.

## Layout

- `foundry_harness.ijs` — the J driver. Loads
  `../../j/foundry/foundry.ijs`, runs the stack's own checks (field
  identities, PMat insert and conservation, Gershgorin and spectral
  analysis, a recurrence run with identity hooks, the emission gate and
  CSL checks, Ace certification), and writes the canonical record to
  `output/record.txt`.
- `run.sh` — the shell driver. Finds a J interpreter, runs the J driver,
  builds the gate driver, hashes the record through the NASM gate, and
  writes `output/cert.txt` and `output/status.txt`.
- `mask_gate/hash_file.c` — C driver: reads a file, calls the gate, prints
  the hex digest. Assistant-written; not the user's code.
- `mask_gate/call_gate.asm` — NASM adapter, SysV to Windows x64 calling
  convention, for the gate's `sha256_hash`. Assistant-written; not the
  user's code.
- `output/` — created by `run.sh`; holds `record.txt`, `console.log`,
  `cert.txt`, `status.txt`, and the gate build objects.

## Run

    bash mlir/harness/run.sh

Modes: `run.sh --gate-check [file]` skips the J stage and checks only
the gate path (builds the gate driver and hashes the given file, or a
built-in dummy record when no file is given). Exit codes: 0 full pass
(J ran, record hashed); 1 J run failed or gate build failed; 2 no J
interpreter found; 3 gate blocked (the gate crashed or never returned).

## What can and cannot run on this box

- No J interpreter is installed here (`j`, `jconsole`, `je` all absent),
  so the J stage cannot run here. The `.ijs` driver is written from the
  verb signatures in `j/foundry/*.ijs` and is unrun; `run.sh` reports
  exit 2 here.
- The NASM gate cannot run yet: `sha256_hash` in
  `mlir/mask-gate/sha256.asm` has no `ret` (the file ends at `pop rbx`),
  so it segfaults on first call. `run.sh --gate-check` demonstrates
  this: the gate driver builds, the call never returns, exit 139. The
  certification step is blocked until the `.asm` is fixed. The gate is
  the user's code; fixes are offered, never installed as default, so the
  `.asm` is left exactly as supplied.
