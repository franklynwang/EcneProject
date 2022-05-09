using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

@assert solveWithTrustedFunctions("Hermez_Circuits/src/rollup-main-mini.r1cs", "rollup_main", input_sym="Hermez_Circuits/src/rollup-main-mini.sym", trusted_r1cs=["ecne_circomlib_tests/Bits2Point_Strict@pointbits.r1cs", "ecne_circomlib_tests/BabyDbl@babyjub.r1cs"], trusted_r1cs_names=["Bits2Point_Strict", "BabyDbl"])

#@assert solveWithTrustedFunctions("Hermez_Circuits/src/withdraw.r1cs", "rollup_withdraw", input_sym="Hermez_Circuits/src/withdraw.sym")






