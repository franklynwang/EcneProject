using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions



try
    solveWithTrustedFunctions("division.r1cs",  "division!")
catch e
    println(e)
    println("File didn't compile")
end
