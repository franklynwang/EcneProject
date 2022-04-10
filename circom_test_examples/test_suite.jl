using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

@assert solveWithTrustedFunctions("Circom_Functions/circomlib/circuits/tests/aliaschecktest.r1cs", "AliasCheck")
#@assert solveWithTrustedFunctions("Circom_Functions/circomlib/circuits/tests/babyjubtest_BabyAdd.r1cs", "BabyAdd", [""])
@assert solveWithTrustedFunctions("Circom_Functions/circomlib/circuits/tests/babyjubtest_BabyCheck.r1cs", "BabyCheck", trusted_r1cs = ["Circom_Functions/circomlib/circuits/tests/babyjubtest_BabyAdd.r1cs"], trusted_r1cs_names = ["BabyAdd"])
#@assert solveWithTrustedFunctions("Circom_Functions/circomlib/circuits/tests/babyjubtest_BabyDbl.r1cs", "BabyDbl")
#@assert solveWithTrustedFunctions("Circom_Functions/circomlib/circuits/tests/babyjubtest_BabyPbk.r1cs", "BabyPbk")
@assert solveWithTrustedFunctions("Circom_Functions/circomlib/circuits/tests/binsubtest.r1cs", "BinSub")
@assert solveWithTrustedFunctions("Circom_Functions/circomlib/circuits/tests/binsumtest.r1cs", "BinSum")





