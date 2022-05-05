using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

solveWithTrustedFunctions("bad_bd_check.r1cs", "Bad Bound Check", input_sym="bad_bd_check.sym", debug=true, printRes=true)

solveWithTrustedFunctions("good_bd_check.r1cs", "Good Bound Check", input_sym="good_bd_check.sym", debug=true, printRes=true)