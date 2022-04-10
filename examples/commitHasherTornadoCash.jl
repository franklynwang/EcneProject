using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

@assert solveWithTrustedFunctions("tornadocash_circuits/merkleTree.r1cs", "MerkleTreeChecker")

@assert solveWithTrustedFunctions("tornadocash_circuits/commitHasher.r1cs", "CommitmentHasher", trusted_r1cs=["tornadocash_circuits/Pedersen248@pedersen.r1cs", "tornadocash_circuits/Pedersen496@pedersen.r1cs"], trusted_r1cs_names=["Pedersen248", "Pedersen496"])






