using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions


try
    solveWithTrustedFunctions("ecne_circomlib_tests/EscalarMulWindow@escalarmul.r1cs", "EscalarMulWindow from escalarmul.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Num2Bits@bitify.r1cs", "Num2Bits from bitify.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Mux1@mux1.r1cs", "Mux1 from mux1.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Multiplexor2@escalarmulany.r1cs", "Multiplexor2 from escalarmulany.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/NOT@gates.r1cs", "NOT from gates.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/BabyAdd@babyjub.r1cs", "BabyAdd from babyjub.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/SegmentMulFix@escalarmulfix.r1cs", "SegmentMulFix from escalarmulfix.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Bits2Point_Strict@pointbits.r1cs", "Bits2Point_Strict from pointbits.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Montgomery2Edwards@montgomery.r1cs", "Montgomery2Edwards from montgomery.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Decoder@multiplexer.r1cs", "Decoder from multiplexer.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/EscalarMulFix@escalarmulfix.r1cs", "EscalarMulFix from escalarmulfix.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/EscalarMul@escalarmul.r1cs", "EscalarMul from escalarmul.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/BabyPbk@babyjub.r1cs", "BabyPbk from babyjub.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/NOR@gates.r1cs", "NOR from gates.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/CompConstant@compconstant.r1cs", "CompConstant from compconstant.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Poseidon@poseidon.r1cs", "Poseidon from poseidon.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/BabyCheck@babyjub.r1cs", "BabyCheck from babyjub.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/BabyDbl@babyjub.r1cs", "BabyDbl from babyjub.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/WindowMulFix@escalarmulfix.r1cs", "WindowMulFix from escalarmulfix.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MultiMux1@mux1.r1cs", "MultiMux1 from mux1.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/BitElementMulAny@escalarmulany.r1cs", "BitElementMulAny from escalarmulany.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Window4@pedersen.r1cs", "Window4 from pedersen.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/AliasCheck@aliascheck.r1cs", "AliasCheck from aliascheck.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/EdDSAPoseidonVerifier@eddsaposeidon.r1cs", "EdDSAPoseidonVerifier from eddsaposeidon.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MultiAND@gates.r1cs", "MultiAND from gates.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Bits2Num_strict@bitify.r1cs", "Bits2Num_strict from bitify.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Sign@sign.r1cs", "Sign from sign.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Pedersen@pedersen_old.r1cs", "Pedersen from pedersen_old.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/GreaterThan@comparators.r1cs", "GreaterThan from comparators.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Multiplexer@multiplexer.r1cs", "Multiplexer from multiplexer.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/OR@gates.r1cs", "OR from gates.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Bits2Point@pointbits.r1cs", "Bits2Point from pointbits.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Pedersen@pedersen.r1cs", "Pedersen from pedersen.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Point2Bits_Strict@pointbits.r1cs", "Point2Bits_Strict from pointbits.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Segment@pedersen.r1cs", "Segment from pedersen.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/IsZero@comparators.r1cs", "IsZero from comparators.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/NAND@gates.r1cs", "NAND from gates.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Mix@poseidon.r1cs", "Mix from poseidon.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Num2Bits_strict@bitify.r1cs", "Num2Bits_strict from bitify.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/AND@gates.r1cs", "AND from gates.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/ForceEqualIfEnabled@comparators.r1cs", "ForceEqualIfEnabled from comparators.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/EdDSAMiMCVerifier@eddsamimc.r1cs", "EdDSAMiMCVerifier from eddsamimc.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MiMCFeistel@mimcsponge.r1cs", "MiMCFeistel from mimcsponge.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/EdDSAMiMCSpongeVerifier@eddsamimcsponge.r1cs", "EdDSAMiMCSpongeVerifier from eddsamimcsponge.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/XOR@gates.r1cs", "XOR from gates.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/LessEqThan@comparators.r1cs", "LessEqThan from comparators.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/LessThan@comparators.r1cs", "LessThan from comparators.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MiMC7@mimc.r1cs", "MiMC7 from mimc.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MontgomeryDouble@montgomery.r1cs", "MontgomeryDouble from montgomery.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Edwards2Montgomery@montgomery.r1cs", "Edwards2Montgomery from montgomery.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Sigma@poseidon.r1cs", "Sigma from poseidon.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MontgomeryAdd@montgomery.r1cs", "MontgomeryAdd from montgomery.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/EscalarProduct@multiplexer.r1cs", "EscalarProduct from multiplexer.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/GreaterEqThan@comparators.r1cs", "GreaterEqThan from comparators.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/BinSum@binsum.r1cs", "BinSum from binsum.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MultiMux3@mux3.r1cs", "MultiMux3 from mux3.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Mux4@mux4.r1cs", "Mux4 from mux4.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/EscalarMulAny@escalarmulany.r1cs", "EscalarMulAny from escalarmulany.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/IsEqual@comparators.r1cs", "IsEqual from comparators.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/IsZero@isZero.r1cs", "IsZero from isZero.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Mux2@mux2.r1cs", "Mux2 from mux2.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Bits2Num@bitify.r1cs", "Bits2Num from bitify.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/SegmentMulAny@escalarmulany.r1cs", "SegmentMulAny from escalarmulany.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MiMCSponge@mimcsponge.r1cs", "MiMCSponge from mimcsponge.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MultiMiMC7@mimc.r1cs", "MultiMiMC7 from mimc.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MultiMux2@mux2.r1cs", "MultiMux2 from mux2.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Num2BitsNeg@bitify.r1cs", "Num2BitsNeg from bitify.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/BinSub@binsub.r1cs", "BinSub from binsub.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Switcher@switcher.r1cs", "Switcher from switcher.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Point2Bits@pointbits.r1cs", "Point2Bits from pointbits.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Ark@poseidon.r1cs", "Ark from poseidon.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/Mux3@mux3.r1cs", "Mux3 from mux3.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/MultiMux4@mux4.r1cs", "MultiMux4 from mux4.circom")
catch e
    println("File didn't compile")
end
    
try
    solveWithTrustedFunctions("ecne_circomlib_tests/EdDSAVerifier@eddsa.r1cs", "EdDSAVerifier from eddsa.circom")
catch e
    println("File didn't compile")
end
    