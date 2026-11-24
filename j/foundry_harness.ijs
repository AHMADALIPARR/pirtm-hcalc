NB. =============================================================================
NB. foundry_harness.ijs — J driver for the new foundry harness.
NB. Loads the Pure-J Core (../../j/foundry/foundry.ijs), runs the stack's
NB. own checks, and writes the canonical record to output/record.txt.
NB. The shell driver (run.sh) then pipes the record through the NASM mask
NB. gate (SHA-256) as the certification and mask step.
NB.
NB. Unrun on this box: no J interpreter is installed here (j, jconsole, je
NB. all absent). Written from the verb signatures in j/foundry/*.ijs; every
NB. check below uses a real verb with its real argument shape. See
NB. mlir/harness/README.md.
NB. =============================================================================

here =. ({.~ i:&'/') > {: 4!:3 ''
if. 0 = # here do. here =. 1!:43 '' end.
load here , '../../j/foundry/foundry.ijs'

cocurrent 'foundry'

NB. --- record ---------------------------------------------------------------
RECORD =: 0 $ a:
OKS    =: 0 $ 0

NB. check (name ; ok) — append 'name 0/1' to the record and echo it
check =: 3 : 0
  'name ok' =. y
  OKS =: OKS , ok
  line =. name , ' ' , ": ok
  RECORD =: RECORD , <line
  echo line
)

NB. --- Goldilocks field (goldilocks.ijs) ------------------------------------
check 'fp_add' ; (5x = 2x fp_add 3x)
check 'fp_sub' ; (2x = 5x fp_sub 3x)
check 'fp_mul' ; (6x = 2x fp_mul 3x)
check 'fp_mulmod' ; (6x = 2x fp_mulmod 3x)
check 'fp_pow' ; (1024x = 2x fp_pow 10x)
check 'fp_inv_roundtrip' ; (1x = 7x fp_mul fp_inv 7x)
check 'fp_reduce_prime' ; (0x = fp_reduce p)
check 'fp_add_batch' ; ((2 3 4x) -: (1 2 3x) fp_add_batch 1 1 1x)
check 'fp_mul_batch' ; ((2 4 6x) -: (1 2 3x) fp_mul_batch 2 2 2x)

NB. --- PMat (pmat.ijs) -------------------------------------------------------
m =. 2 pmat_new 2
check 'pmat_new_shape' ; ((2 2) -: pmat_shape m)
pair =. m pmat_insert 0;1;1;0 0
check 'pmat_insert_ok' ; (1 = 1 {:: pair)
m2 =. 0 {:: pair
check 'pmat_conservation' ; ((0 0) -: pmat_conservation m2)
check 'pmat_frobenius' ; (1 = pmat_frobenius m2)
check 'pmat_validate_grading' ; (1 = pmat_validate_grading m2)

NB. --- Spectral governor (spectral.ijs) --------------------------------------
J =. 2 2 $ 0.5 0 0 0.5
check 'gershgorin_bound' ; (0.5 = gershgorin_bound J)
res =. J spectral_analyze 0.1
check 'spectral_analyze_contractive' ; (1 = sr_contractive res)
check 'spectral_analyze_radius' ; (0.5 = sr_radius res)

NB. --- Recurrence and certification (recurrence.ijs, certify.ijs) ------------
sched =. synth_weights 10;1;0
check 'synth_weights_two_schedules' ; (2 = # sched)
x0 =. 1 0.
hist =. x0 rec_run 10;1;0;1e_6;'[';'['
check 'rec_run_history_10' ; (10 = # hist)
cert =. hist ace_certify 0.01
check 'ace_certify_max_q_below_1' ; (1 > 0 {:: > cert)
check 'ace_certify_margin_near_0' ; (1e_12 > | 1 {:: > cert)

NB. --- Emission gate and CSL checks (gate.ijs) -------------------------------
out =. 1 2 3.
prev =. 0 0 0.
g =. out emit_apply prev;0.5;0;0.1
check 'emit_apply_passthrough' ; (out -: g)
x =. 0 1.
Tx =. 0 1.
check 'csl_neutrality_pass' ; (0 = x csl_neutrality Tx;0.1)
check 'csl_beneficence_pass' ; (0 = x csl_beneficence Tx;0;0.1)
check 'csl_commutation_pass' ; (0 = x csl_commutation '[';'[';0.1)

NB. --- write record -----------------------------------------------------------
RECORD =: RECORD , <'SUMMARY checks: ' , ": # RECORD
RECORD =: RECORD , <'SUMMARY fails: ' , ": +/ -. OKS
outdir =. here , 'output/'
text =. ; LF ,&.> RECORD
text 1!:2 < outdir , 'record.txt'
echo 'record written: ' , outdir , 'record.txt'
echo 'checks: ' , ": # RECORD
echo 'fails: ' , ": +/ -. OKS

cocurrent 'base'
