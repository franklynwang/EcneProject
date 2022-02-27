using Test
import R1CSConstraintSolver: solveWithTrustedFunctions


@testset "Trivial Multiplication" begin
    @test solveWithTrustedFunctions("../trivial_mult.r1cs", "*", printRes = false)
end

@testset "Big Mult" begin
    @test solveWithTrustedFunctions("../bigmult86_3.r1cs", "bigmult(86,3)", printRes = false)
end

@testset "Poseidon" begin
    @test solveWithTrustedFunctions("../poseidon.r1cs", "poseidon", printRes = false)
end

@testset "3x3 multiplexer" begin
    @test solveWithTrustedFunctions("../multiplexer_33.r1cs", "multiplexer(3,3)", printRes = false)
end

@testset "secpAddUnequal" begin
    @test solveWithTrustedFunctions("../secp256k1.r1cs", "secpAddUnequal", trusted_r1cs = ["../bigmultmodp.r1cs", "../biglessthan.r1cs"], trusted_r1cs_names = ["BigMultModP", "BigLessThan"])
end

