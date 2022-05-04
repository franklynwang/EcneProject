
# This module contains functions that are not used by ECNE

module Auxiliary

using AbstractAlgebra
using DataStructures
using ProgressMeter

const bjj_p =
    BigInt(21888242871839275222246405745257275088548364400416034343698204186575808495617)

F = AbstractAlgebra.GF(bjj_p)

function abstraction(
    function_name::String,
    constraints::Array{R1CSEquation},
    known_inputs::Array{Base.Int64},
    sub_equation::Array{R1CSEquation},
    known_outputs::Array{Base.Int64},
    printRes::Bool=false,
)
    if printRes
        println("known inputs", known_inputs)
        println("called abstraction")
        println("big #: ", length(constraints))
        println("small #: ", length(sub_equation))
    end
    a = time()
    hashed_constraints = [hash_r1cs_equation(x) for x in constraints]
    hashed_sub_equation = [hash_r1cs_equation(x) for x in sub_equation]
    f = time()
    if printRes
        println("compute hash ", f - a)
    end
    candidates = []
    for i in 1:length(constraints)-length(sub_equation)+1
        matches = true
        for j in 1:length(sub_equation)-1
            if hashed_constraints[i+j-1] != hashed_sub_equation[j]
                matches = false
                break
            end
        end
        if matches
            push!(candidates, i)
        end
    end
    b = time()
    if printRes
        println("hash match ", b - f)
    end
    matches = [] # contains index, as well as (orig_var -> new_var maps)
    appearance_map_orig = DefaultDict{
        Base.Int64,
        Vector{Tuple{Base.Int64,AbstractAlgebra.GFElem{BigInt}}},
    }(Vector{Tuple{Base.Int64,AbstractAlgebra.GFElem{BigInt}}})
    sub_eq_counter = 1
    # one can also do this witha a Rabin-Karp Hash.
    for j = 1:length(sub_equation)
        for eq in [sub_equation[j].a, sub_equation[j].b, sub_equation[j].c]
            for term in eq
                if term[2] != F(0)
                    tup = (sub_eq_counter, F(term[2]))
                    push!(appearance_map_orig[term[1]], tup)
                end
            end
            sub_eq_counter += 1
        end
    end
    for i in candidates
        # try each of the things that the hash matches. 
        works = true
        appearance_map_cur = DefaultDict{
            Base.Int64,
            Vector{Tuple{Base.Int64,AbstractAlgebra.GFElem{BigInt}}},
        }(Vector{Tuple{Base.Int64,AbstractAlgebra.GFElem{BigInt}}})
        app_counter = 0
        function addEquation(eq1, eq2)
            if !checkNonZeroValues(eq1, eq2)
                return false
            end
            for term in eq1
                if term[2] != F(0)
                    tup = (app_counter, F(term[2]))
                    push!(appearance_map_cur[term[1]], tup)
                end
            end
            return true
        end
        for j = 1:length(sub_equation)
            app_counter += 1
            if !addEquation(constraints[i+j-1].a, sub_equation[j].a)
                works = false
                break
            end
            app_counter += 1
            if !addEquation(constraints[i+j-1].b, sub_equation[j].b)
                works = false
                break
            end
            app_counter += 1
            if !addEquation(constraints[i+j-1].c, sub_equation[j].c)
                works = false
                break
            end
        end
        if !works
            continue
        end

        l1 = sort(collect(appearance_map_cur), by=x -> [(y[1], y[2].d) for y in x[2]])
        l2 = sort(collect(appearance_map_orig), by=x -> [(y[1], y[2].d) for y in x[2]])
        if length(l1) != length(l2)
            continue
        else
            works = true
            for i = 1:length(l1)
                if l1[i][2] != l2[i][2]
                    works = false
                    break
                end
            end
            if !works
                continue
            end
        end
        # first appearances check 
        push!(matches, (i, Dict(l2[x][1] => l1[x][1] for x = 1:length(l1))))
    end
    c = time()
    if printRes
        println("found matches ", c - b)
    end
    red_cons = []
    special_cons = []
    cur_idx = 1
    i = 1
    total_vars = maximum([
        maximum([
            maximum(keys(constraints[i].a)),
            maximum(keys(constraints[i].b)),
            maximum(keys(constraints[i].c)),
        ]) for i = 1:length(constraints)
    ])
    while i <= length(constraints)
        #println(i)
        if ((cur_idx > length(matches)) || (i != matches[cur_idx][1]))
            push!(red_cons, constraints[i])
            i += 1
        else
            # the transformed inputs / outputs under matches[cur_idx][2]. 
            #println("known inputs", known_inputs)
            #println("known outputs", known_outputs)
            push!(
                special_cons,
                (
                    function_name,
                    [matches[cur_idx][2][x] for x in known_inputs if x != 1],
                    [matches[cur_idx][2][x] for x in known_outputs],
                ),
            )
            i += length(sub_equation)
            cur_idx += 1
        end
    end
    d = time()
    if printRes
        println("solved question ", d - c)
        println("abstractions found ", length(special_cons))
    end
    return (special_cons), Array{R1CSEquation}(red_cons)
end


function flip_keys(input_map::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}})
    output_map = DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(
        F(0)
    )
    for key in keys(input_map)
        output_map[key] = -input_map[key]
    end
    return output_map
end

# Unoptimize function: Allows us to convert optimized circuits into unoptimized circuits, which means we don't sacrifice any speed at runtime, but verification is made substantially easier. 
function R1CSUnOptimize(
    input_r1cs::String,
)
    equations_main, knowns_main, outs_main = readR1CS(input_r1cs)
    all_equations = []
    num_variables = maximum([
        maximum([
            maximum(keys(equations_main[i].a)),
            maximum(keys(equations_main[i].b)),
            maximum(keys(equations_main[i].c)),
        ]) for i = 1:length(equations_main)
    ])
    cur_var = num_variables + 1
    macro_vars = Dict{DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}},Base.Int64}()
    for i = 1:length(equations_main)
        if (length(nonzeroKeys(equations_main[i].a)) == 0) && (length(nonzeroKeys(equations_main[i].b)) == 0)
            push!(all_equations, equations_main[i])
        else
            new_eqs = [equations_main[i].a, equations_main[i].b]
            var_values = []
            for eq in new_eqs
                eq1 = eq
                var_index = 0
                update_var = false
                if eq1 in keys(macro_vars)
                    var_index = macro_vars[eq1]
                else
                    var_index = cur_var
                    macro_vars[eq1] = var_index
                    update_var = true
                end
                push!(var_values, var_index)
                macro_vars[eq1] = cur_var
                eq1[cur_var] = F(-1)
                new_eq_1 = R1CSEquation(
                    DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(F(0), 1 => F(0)),
                    DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(F(0), 1 => F(0)),
                    eq1,
                )
                eq2 = flip_keys(eq)
                eq2[cur_var] = F(1)
                new_eq_2 = R1CSEquation(
                    DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(F(0), 1 => F(0)),
                    DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(F(0), 1 => F(0)),
                    eq2,
                )
                if update_var
                    cur_var += 1
                    push!(all_equations, new_eq_1)
                    push!(all_equations, new_eq_2)
                end
            end
            var_1 = DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(F(0))
            var_1[var_values[1]] = F(1)
            var_2 = DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(F(0))
            var_2[var_values[2]] = F(1)

            push!(all_equations, R1CSEquation(var_1, var_2,
                equations_main[i].c
            ))
        end
    end
    return all_equations, knowns_main, outs_main
end

export abstraction, R1CSUnOptimize

end