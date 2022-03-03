using Test
import R1CSConstraintSolver: R1CSEquation, SolveConstraintsSymbolic, printEquation, R1CSUnOptimize, solveWithTrustedFunctions

equations_main, knowns_main, outs_main = R1CSUnOptimize("trivial_mult.r1cs")
for eq in equations_main
    printEquation(eq)
end

SolveConstraintsSymbolic(Vector{R1CSEquation}(equations_main), [], knowns_main, true, outs_main)