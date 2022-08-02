using BenchmarkTools
import R1CSConstraintSolver: solveWithTrustedFunctions


macro run_bench(name, expr, args...)
    quote
        printstyled("Benchmark: ", $name, "\n"; color = :yellow)
        display(@benchmark esc($expr) $(args...))
        println("\n\n")
    end
end

@run_bench "Trivial Multiplication Benchmark" begin
    solveWithTrustedFunctions("target/division.r1cs", "division")
end


