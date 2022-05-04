
module ParseR1CS

using AbstractAlgebra
using DataStructures
using ProgressMeter

const bjj_p =
    BigInt(21888242871839275222246405745257275088548364400416034343698204186575808495617)

F = AbstractAlgebra.GF(bjj_p)

struct R1CSEquation
    a::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}
    b::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}
    c::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}

    R1CSEquation(
        a::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}},
        b::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}},
        c::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}},
    ) = begin
        new(a, b, c)
    end
end

function readFour(obj)::UInt32
    @assert length(obj) == 4
    return obj[1] + obj[2] * 2^8 + obj[3] * 2^16 + obj[4] * 2^24
end

function readEight(obj)::UInt64
    @assert length(obj) == 8
    sum = 0
    for i = 1:8
        sum += obj[i] * 2^(8 * (i - 1))
    end
    return sum
end

function readArrInt(obj)::BigInt
    sum = 0
    for i = 1:length(obj)
        sum += BigInt(obj[i]) * BigInt(2)^(8 * (i - 1))
    end
    return sum
end


function readR1CS(filename::String)::Tuple{Vector{R1CSEquation},Vector{Int64},Vector{Int64},Int64}
    arr = []
    fsize = stat(filename).size
    s = open(filename, "r")
    arr = zeros(UInt8, fsize)
    readbytes!(s, arr, fsize)
    close(s)
    cur_idx = 5
    @assert readFour(arr[cur_idx:cur_idx+3]) == 1
    cur_idx = 9
    sections = readFour(arr[cur_idx:cur_idx+3])
    cur_idx += 4
    @assert sections == 3
    section_starts = [0, 0, 0]
    #println("first part of arr ", arr[1:100])
    #println("mid arr ", arr[cur_idx:cur_idx+11])
    for i = 1:sections
        #println("cur_idx ", cur_idx)
        cur_section = readFour(arr[cur_idx:cur_idx+3])
        @assert 1 <= cur_section <= 3
        section_starts[cur_section] = cur_idx
        cur_idx += 4
        #println("array length ", arr[cur_idx:cur_idx+7])
        sz = readArrInt(arr[cur_idx:cur_idx+7])
        cur_idx += (sz + 8)
    end
    ## parse first section
    pub_out = 0
    pub_in = 0
    priv_in = 0
    sec_1 = section_starts[1]
    sec_1 += 12
    field_size = readFour(arr[sec_1:sec_1+3])
    sec_1 += 4
    prime = readArrInt(arr[sec_1:sec_1+field_size-1])
    sec_1 += field_size
    num_wires = readFour(arr[sec_1:sec_1+3])
    sec_1 += 4
    pub_out = readFour(arr[sec_1:sec_1+3])
    sec_1 += 4
    pub_in = readFour(arr[sec_1:sec_1+3])
    sec_1 += 4
    priv_in = readFour(arr[sec_1:sec_1+3])
    sec_1 += 4
    num_labels = readEight(arr[sec_1:sec_1+7])
    sec_1 += 8
    constraints = readFour(arr[sec_1:sec_1+3])
    sec_2 = section_starts[2]
    sec_2 += 12
    equations = []
    @showprogress 1 "Reading Constraints" for _ = 1:constraints
        constraint_new = []
        for _ = 1:3
            num_elements = readFour(arr[sec_2:sec_2+3])
            sec_2 += 4
            cur_eq = DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(F(0))
            for _ = 1:num_elements
                idx = readFour(arr[sec_2:sec_2+3])
                sec_2 += 4
                coeff = readArrInt(arr[sec_2:sec_2+31])
                sec_2 += 32
                cur_eq[idx+1] = F(coeff)
            end
            if num_elements == 0
                cur_eq[1] = F(0)
            end
            push!(constraint_new, cur_eq)
        end
        push!(
            equations,
            R1CSEquation(constraint_new[1], constraint_new[2], constraint_new[3]),
        )
    end
    return equations, vcat([Int64(1)], [Int64(i) for i = 2+pub_out:1+pub_out+pub_in+priv_in]), [Int64(i) for i = 2:1+pub_out], num_wires + 1
end

function getVariables(equation::R1CSEquation)
    s = Set()
    for i in keys(equation.a)
        if equation.a[i] != F(0)
            push!(s, i)
        end
    end

    for i in keys(equation.b)
        if equation.b[i] != F(0)
            push!(s, i)
        end
    end

    for i in keys(equation.c)
        if equation.c[i] != F(0)
            push!(s, i)
        end
    end
    return s
end

function hash_r1cs_equation(
    e::R1CSEquation
)
    l = vcat(sort!([x.d for x in values(e.a)]), sort!([x.d for x in values(e.b)]), sort!([x.d for x in values(e.c)]))
    l = [x for x in l if x != 0]

    return hash(l)
end

function nonzeroKeys(lin_term::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}})
    nzero = Set()
    for i in keys(lin_term)
        if lin_term[i] != F(0)
            push!(nzero, i)
        end
    end
    return nzero
end

function fix_number(x::BigInt)
    if x > 21888242871839275222246405745257275088548363400416034343698204186575808495517
        return x -
               21888242871839275222246405745257275088548364400416034343698204186575808495617
    else
        return x
    end
end

# a utility for pretty printing equations 
function printEquation(x::R1CSEquation, index_to_signal::Array{String,1})
    function get_lin(x)
        if length(nonzeroKeys(x)) == 0
            return "0"
        end
        return "(" *
               join(
                   [
                       string(fix_number(x[key].d)) * " * " * string(index_to_signal[key-1]) * ""
                       for key in nonzeroKeys(x)
                   ],
                   " + ",
               ) * ")"
    end
    str1 = get_lin(x.a)
    str2 = get_lin(x.b)
    str3 = get_lin(x.c)
    println(str1 * " * " * str2 * " = " * str3)
end

export readFour, readEight, readArrInt, readR1CS, R1CSEquation, getVariables, hash_r1cs_equation, printEquation, nonzeroKeys

end