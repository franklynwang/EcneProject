using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

solveWithTrustedFunctions("bad_bd_check.r1cs", "Bad Bound Check", debug=true, printRes=true)

solveWithTrustedFunctions("good_bd_check.r1cs", "Good Bound Check", debug=true, printRes=true)