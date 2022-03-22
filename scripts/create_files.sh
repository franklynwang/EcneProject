julia --project=. src/gen_benchmark.jl Circom_Functions/benchmarks/bigmod_10_2.r1cs > Circom_Functions/benchmarks/bigmod_10_2.txt

julia --project=. src/gen_benchmark.jl Circom_Functions/benchmarks/bigmod_5_2.r1cs > Circom_Functions/benchmarks/bigmod_5_2.txt

julia --project=. src/gen_benchmark.jl Circom_Functions/benchmarks/bigmod_86_3.r1cs > Circom_Functions/benchmarks/bigmod_86_3.txt

julia --project=. src/gen_benchmark.jl Circom_Functions/benchmarks/bigmult_86_3.r1cs > Circom_Functions/benchmarks/bigmult_86_3.txt