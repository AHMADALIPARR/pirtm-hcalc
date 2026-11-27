#!/usr/bin/env bash
# Deterministic WASM build & vector runner for foundry/wasm-agpl.
# - Pins assemblyscript 0.27.30 (installed once into a scratch deps dir).
# - Stages the canonical .agpl.as sources as .agpl.ts (asc appends .ts to
#   its entry file, so the rename happens in scratch, never in the repo).
# - Builds the three vector suites plus the L2/L4 bridge to build/*.wasm.
# - Runs every suite under node; any failure exits nonzero.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ASC_VERSION="0.27.30"
DEPS="${WASM_AGPL_DEPS:-${TMPDIR:-/tmp}/wasm-agpl-deps}"
STAGE="$(mktemp -d)"
BUILD="$ROOT/build"
mkdir -p "$BUILD"

# 1. Toolchain (pinned, reused across runs).
if [ ! -x "$DEPS/node_modules/.bin/asc" ]; then
  mkdir -p "$DEPS"
  (cd "$DEPS" && npm init -y >/dev/null 2>&1 && npm install "assemblyscript@$ASC_VERSION" --no-audit --no-fund)
fi
ASC="$DEPS/node_modules/.bin/asc"

# 2. Stage sources.
rm -rf "$STAGE/src"
mkdir -p "$STAGE/src"
(cd "$ROOT" && find goldilocks hash verifier tests -name '*.agpl.as') | while read -r f; do
  d="$STAGE/src/$(dirname "$f")"
  mkdir -p "$d"
  sed 's/\.agpl\.as/.agpl.ts/g' "$ROOT/$f" > "$STAGE/src/${f%.agpl.as}.agpl.ts"
done

# 3. Build.
for t in goldilocks_vectors sha256_vectors verifier_vectors; do
  "$ASC" "$STAGE/src/tests/$t.agpl.ts" \
    --target release --runtime stub --optimize --initialMemory 1 \
    --outFile "$BUILD/$t.wasm"
done
"$ASC" "$STAGE/src/verifier/l2_l4_bridge.agpl.ts" \
  --target release --runtime stub --optimize --initialMemory 1 \
  --outFile "$BUILD/l2_l4_bridge.wasm"

# 4. Run the vector suites.
cat > "$STAGE/run-vectors.mjs" <<'EOF'
import { readFileSync } from 'node:fs';

const build = process.argv[2];
let failed = 0;
// The stub runtime imports only env.abort (bounds-check failures).
const imports = { env: { abort(msg, file, line, col) { throw new Error(`abort at ${file}:${line}:${col}`); } } };

for (const name of ['goldilocks_vectors', 'sha256_vectors', 'verifier_vectors']) {
  const { instance } = await WebAssembly.instantiate(readFileSync(`${build}/${name}.wasm`), imports);
  const n = instance.exports.runTests();
  const first = instance.exports.firstFailure();
  console.log(`${name}: ${n === 0 ? 'PASS' : `FAIL (${n} failures, first check ${first})`}`);
  if (n !== 0) failed++;
}

// Bridge smoke: instantiate and check the L4 gate answers.
const bridge = (await WebAssembly.instantiate(readFileSync(`${build}/l2_l4_bridge.wasm`), imports)).instance;
const eps = 1844674406941458432n;
const g = bridge.exports.l4Gate(0n, 0n, 0n, eps);
console.log(`l2_l4_bridge: instantiate + l4Gate(0,0,0,eps) = ${g} (expect 0)`);
if (g !== 0) failed++;

process.exit(failed ? 1 : 0);
EOF
node "$STAGE/run-vectors.mjs" "$BUILD"

rm -rf "$STAGE"
echo "wasm-agpl: build + vectors OK"
