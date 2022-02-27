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
    @assert solveWithTrustedFunctions("trivial_mult.r1cs", "*", printRes = false)
end

@run_bench "Big Mult Benchmark" begin
    @assert solveWithTrustedFunctions("bigmult86_3.r1cs", "bigmult(86,3)", printRes = false)
end

@run_bench "Poseidon Benchmark" begin
    @assert solveWithTrustedFunctions("poseidon.r1cs", "poseidon", printRes = false)
end

@run_bench "3x3 multiplexer Benchmark" begin
    @assert solveWithTrustedFunctions("multiplexer_33.r1cs", "multiplexer(3,3)", printRes = false)
end


