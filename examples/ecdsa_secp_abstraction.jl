using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

@assert solveWithTrustedFunctions("ecdsa.r1cs", "ECDSAprivToPub", trusted_r1cs = ["secp256k1.r1cs"], trusted_r1cs_names = ["Secp256k1AddUnequal"])




