using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

@assert solveWithTrustedFunctions("Hermez_Circuits/src/rollup-main.r1cs", "rollup_main")

@assert solveWithTrustedFunctions("Hermez_Circuits/src/withdraw.r1cs", "rollup_withdraw")






