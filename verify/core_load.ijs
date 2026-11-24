NB. SPDX-License-Identifier: AGPL-3.0-only
NB. Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
NB. Copyright (C) 2026 Ahmad Parr
NB. Load HCALC Core (j/hcalc.ijs) and its cite hooks (j/cite.ijs).
NB. Paths are relative to the project root; run the suite from there
NB. (lake script verify does).
NB. The Alloy model is ported to Lean: the A7 document probe reads the Lean
NB. port PirtmHcalc/Alloy/Hcalc.lean instead of the old .als file.

CORE_LOADED =: 0
CORE_PATH   =: 'j/hcalc.ijs'
CITE_PATH   =: 'j/cite.ijs'
PROD_PATH   =: 'spec/PRODUCTION.md'
ALLOY_ALS   =: 'PirtmHcalc/Alloy/Hcalc.lean'
LEAN_AXIOMS =: 'Hcalc/Axioms.lean'
LEAN_CONV   =: 'Hcalc/Convergence.lean'
LEAN_FOUND  =: 'Hcalc/Foundry.lean'

fexist =: 3 : '0 ~: # (1!:0 :: (''"_'')) < y'

core_available =: 3 : 0
  fexist CORE_PATH
)

fread_text =: 3 : 0
  p =. fread y
  if. p -: _1 do. '' else. p end.
)

prod_text =: 3 : 'fread_text PROD_PATH'
alloy_text =: 3 : 'fread_text ALLOY_ALS'
lean_axioms_text =: 3 : 'fread_text LEAN_AXIOMS'
lean_conv_text =: 3 : 'fread_text LEAN_CONV'
lean_found_text =: 3 : 'fread_text LEAN_FOUND'

has_substr =: 4 : 'x +./@E. y'

load_hcalc_core =: 3 : 0
  if. CORE_LOADED do. 1 return. end.
  if. -. core_available '' do. 0 return. end.
  if. -. fexist CITE_PATH do. 0 return. end.
  load CITE_PATH
  load CORE_PATH
  CORE_LOADED =: 1
  1
)
