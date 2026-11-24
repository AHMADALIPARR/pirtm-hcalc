NB. SPDX-License-Identifier: AGPL-3.0-only
NB. Also licensed under the SnapKitty Opaque License (LicenseRef-SnapKitty-Opaque-1.0); see README.md.
NB. Copyright (C) 2026 Ahmad Parr
NB.
NB. demo.ijs — prints the HCALC Core numbers (17 significant digits) and the
NB. Goldilocks checks that mlir/main/hcalc.mlir and mlir/main/goldilocks.mlir
NB. reproduce. Run from the project root:  jconsole j/demo.ijs

13!:0 ] 0
9!:11 ] 17
load 'j/hcalc.ijs'
load 'j/goldilocks.ijs'

show =: 4 : 'echo x , '' '' , ": y'

echo '== hcalc: x = 1 2 3 4 5, eps = 0.05, tol = 1e_6, max_steps = 80'
x =. 1. 2. 3. 4. 5.
'alpha' show tp_alpha_hcalc_ 5
'tp_from_p64' show tp_from_p64_hcalc_ x
'gershgorin_bound' show gershgorin_bound_cite_ diag_from_alpha_hcalc_ tp_alpha_hcalc_ 5
'q_of_tp' show q_of_tp_hcalc_ 5 , 0.05
'soft_project_scale' show soft_project_scale_hcalc_ (q_of_tp_hcalc_ 5 , 0.05) , 0.05
'c_op_norm' show c_op_norm_hcalc_ 5 , 0.05
'lam_m' show 0.05 lam_m_from_bound_hcalc_ 5
'step' show hcalc_step_hcalc_ x
'diagnostic' show to_foundry_step_diagnostic_hcalc_ x
r =. (80 ; 1e_6 ; 0.05 ; 1. ; '') hcalc_run_hcalc_ x
'run_converged' show 1 {:: r
'run_steps' show 2 {:: r
'run_x' show 0 {:: r
'run_last_residual' show 1 {:: > {: 3 {:: r
'power_iteration_2x2' show (2 2 $ 0.5 0.25 0.25 0.5) power_iteration_cite_ 100 1e_12
'spectral_2x2_radius' show sr_radius_cite_ (2 2 $ 0.5 0.25 0.25 0.5) spectral_analyze_cite_ 0.05
'spectral_refined_radius' show sr_radius_cite_ (2 2 $ 0.9 0.05 0.02 0.8) spectral_analyze_cite_ 0.01
'c_wrap_check' show c_wrap_check_hcalc_ ''

echo '== goldilocks'
P =. P_gl_
a =. 12345678901234567890x
b =. 9876543210987654321x
'p' show P
'add' show a gl_add_gl_ b
'sub' show a gl_sub_gl_ b
'sub_rev' show b gl_sub_gl_ a
'mul' show a gl_mul_gl_ b
'mul_ref_equal' show (a gl_mul_gl_ b) = a gl_mul_ref_gl_ b
'mul_pm1_sq' show (P - 1) gl_mul_gl_ P - 1
'pow_7_100' show 7 gl_pow_gl_ 100
'inv_a' show gl_inv_gl_ a
'a_times_inv_a' show a gl_mul_gl_ gl_inv_gl_ a
'fermat_a' show a gl_pow_gl_ P - 1
NB. fold agrees with (a*b) mod p on a deterministic sample
s =. P | 6364136223846793005x * 1 + i. 200
'fold_vs_ref_200' show *./ (s gl_mul_gl_ |. s) = s gl_mul_ref_gl_ |. s
exit 0
