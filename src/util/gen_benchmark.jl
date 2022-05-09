using Test
import R1CSConstraintSolver: R1CSEquation, SolveConstraintsSymbolic, printEquation, R1CSUnOptimize, solveWithTrustedFunctions, printEquation

filename = ARGS[1]

equations_main, knowns_main, outs_main = R1CSUnOptimize(filename)
println("KNOWN VARIABLES")
for known in 1:length(knowns_main)
    print(knowns_main[known])
    if known != length(knowns_main)
        print(" ")
    end
end
println()
println("OUTPUT VARIABLES")
for out in 1:length(outs_main)
    print(outs_main[out])
    if out != length(outs_main)
        print(" ")
    end
end
println()
for eq in equations_main
    printEquation(eq)
end