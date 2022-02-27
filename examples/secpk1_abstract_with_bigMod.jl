### A Pluto.jl notebook ###
# v0.17.1


using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

@assert solveWithTrustedFunctions("secp256k1.r1cs", "Secp256k1AddUnequal", ["bigmultmodp.r1cs", "biglessthan.r1cs"], ["BigMultModP", "BigLessThan"])