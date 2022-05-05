using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions

try
    solveWithTrustedFunctions("target/division.r1cs", "division!", input_sym="target/division.sym")
catch e
    println(e)
end