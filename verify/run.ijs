NB. SPDX-License-Identifier: AGPL-3.0-only
NB. Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
NB. Copyright (C) 2026 Ahmad Parr
NB. HCALC Verify — measured harness (spec/PRODUCTION.md + Core j/hcalc.ijs).
NB. Run from the project root:  jconsole verify/run.ijs

13!:0 ] 0

echo 'HCALC — Verification Harness'
echo '═══════════════════════════════════════'
echo 'jconsole: ' , 9!:14 ''
echo 'core: j/hcalc.ijs (cite hooks: j/cite.ijs)'
echo 'rule: FAIL-open; InstanceBridge witness ≠ identity'
echo ''

load 'verify/harness.ijs'
load 'verify/core_load.ijs'

echo 'PRODUCTION.md present: ' , ": 0 < # prod_text ''
echo 'Core present: ' , ": core_available ''
echo ''

echo '── H-* properties + SKIP registry ──'
load 'verify/tests/props.ijs'

harness_finish ''
