module R1CSConstraintSolver

using AbstractAlgebra
using Combinatorics
using DataStructures
using Profile
using Dates
using JSON
using CSV
using ProgressMeter
const bjj_p =
    BigInt(21888242871839275222246405745257275088548364400416034343698204186575808495617)

F = AbstractAlgebra.GF(bjj_p)

function nonzeroKeys(lin_term::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}})
    nzero = Set()
    for i in keys(lin_term)
        if lin_term[i] != F(0)
            push!(nzero, i)
        end
    end
    return nzero
end

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

function squareRoot(
    field::AbstractAlgebra.GFField{BigInt},
    a::AbstractAlgebra.GFElem{BigInt},
)::AbstractAlgebra.GFElem{BigInt}
    if a == 0
        return 0
    end
    m = bjj_p
    e = 0
    q = m - 1
    while (q % 2 == 0)
        e += 1
        q = div(q, 2)
    end
    pow2 = 2^(e - 1)
    z = 1
    while true
        x = field(rand(1:m-1))
        z = x^q
        if z^pow2 != field(1) # found QNR
            break
        end
    end
    y = z
    r = e
    x = a^(div(q - 1, 2))
    v = a * x
    w = v * x
    while (w != 1)
        k = 0
        temp_w = w
        while true
            temp_w *= temp_w
            k += 1
            if temp_w == 1
                break
            end
        end
        d = y^(2^(r - k - 1))
        y = d * d
        r = k
        v = d * v
        w = w * y
    end
    return v
end

function solveQuadratic(
    field::AbstractAlgebra.GFField{BigInt},
    a::AbstractAlgebra.GFElem{BigInt},
    b::AbstractAlgebra.GFElem{BigInt},
    c::AbstractAlgebra.GFElem{BigInt},
)
    if a == 0
        if b == 0
            if c == 0
                return "YES"
            else
                return "NO"
            end
        else
            return [AbstractAlgebra.divexact(-c, b)]
        end
    else
        disc = b * b - field(4) * a * c
        rt = squareRoot(field, disc)
        if rt != 0
            return [
                AbstractAlgebra.divexact(-b + disc, field(2) * a),
                AbstractAlgebra.divexact(-b - disc, field(2) * a),
            ]
        else
            return [AbstractAlgebra.divexact(-b, field(2) * a)]
        end
    end
end

mutable struct VariableState # This represents all the information known about variables. 
    index::Base.Int64
    is_known::Bool # have nonzero-information 
    unique::Bool # we know the value for sure
    values::Vector{AbstractAlgebra.GFElem{BigInt}} # A list of potential values that this variable can take. 
    lb::AbstractAlgebra.GFElem{BigInt}
    ub::AbstractAlgebra.GFElem{BigInt}
    bounds_negative::Bool
    abz::Base.Int64
    VariableState(a::Base.Int64) = begin
        new(a, false, false, [], F(0), F(-1), false, -1)
    end

    VariableState(
        a::Base.Int64,
        is_known::Bool,
        unique::Bool,
        values::Vector{AbstractAlgebra.GFElem{BigInt}},
        lb::AbstractAlgebra.GFElem{BigInt},
        ub::AbstractAlgebra.GFElem{BigInt},
        bounds_negative::Bool,
        abz::Base.Int64,
    ) = begin
        new(a, is_known, unique, values, lb, ub, bounds_negative, -1)
    end
end

begin
    function make_unique(a::VariableState)
        return VariableState(
            a.index,
            true,
            true,
            a.values,
            a.lb,
            a.ub,
            a.bounds_negative,
            a.abz,
        )
    end

    function make_values(
        a::VariableState,
        new_values::Vector{AbstractAlgebra.GFElem{BigInt}},
    )
        return VariableState(
            a.index,
            true,
            a.unique,
            new_values,
            a.lb,
            a.ub,
            a.bounds_negative,
            a.abz,
        )
    end

    function make_bounds(
        a::VariableState,
        lb::AbstractAlgebra.GFElem{BigInt},
        ub::AbstractAlgebra.GFElem{BigInt},
        neg_bounds::Bool=false,
    )
        # lies between lb and ub
        return VariableState(a.index, true, a.unique, a.values, lb, ub, neg_bounds, a.abz)
    end
end


# check if these two dictionaries have the same multiset of values
function checkNonZeroValues(
    map1::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}},
    map2::DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}},
)
    x1 = counter(values(map1))
    x2 = counter(values(map2))
    for ele in keys(x1)
        if ele != F(0)
            if x1[ele] != x2[ele]
                return false
            end
        end
    end
    for ele in keys(x2)
        if ele != F(0)
            if x1[ele] != x2[ele]
                return false
            end
        end
    end
    return true
end

function hash_r1cs_equation(
    e::R1CSEquation
)
    l = vcat(sort!([x.d for x in values(e.a)]), sort!([x.d for x in values(e.b)]), sort!([x.d for x in values(e.c)]))
    l = [x for x in l if x != 0]

    return hash(l)
end

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

function printState(x::VariableState)
    bounds = [x.lb.d, x.ub.d]
    if bounds[1] == 0 && bounds[2] == 21888242871839275222246405745257275088548364400416034343698204186575808495616
        bounds = []
    end
    println(
        "Uniquely Determined: ",
        x.unique)

    if bounds == []
        println("Bounds: None")
    else
        println("Bounds: [", bounds[1], ", ", bounds[2], "]")
    end
    println(
        "All possible values: ",
        [val.d for val in x.values]
    )

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
        function fix_signal(key)
            if key > 0
                return index_to_signal[key]
            else
                return 1
            end
        end
        return "(" *
               join(
                   [
                       string(fix_number(x[key].d)) * " * " * string(fix_signal(key - 1)) * ""
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

function readJSON(filename::String)
    dict = Dict()
    open(filename, "r") do f
        global dict
        dicttxt = readall(f)  # file information to string
        dict = JSON.parse(dicttxt)  # parse and transform data
    end
    return dict["constraints"], vcat([Int64(1)], [Int64(i) for i = 2+dict["nOutputs"]:1+dict["nOutputs"]+dict["nPubInputs"]+dict["nPrivInputs"]]), [Int64(i) for i = 2:1+dict["nOutputs"]], dict["nVars"]
end

function solveJSON(filename::String, debug::Bool)
    constraints, known_inputs, known_outputs, nVars = readJSON(filename)
    result = SolveConstraintsSymbolic(constraints, [], known_inputs, debug, known_outputs, nVars)
    if result == true
        if length(function_list) != 0
            if printRes
                println(
                    "R1CS function " *
                    input_r1cs_name *
                    " has sound constraints assuming trusted functions " *
                    join([trusted_r1cs_names[i] for i = 1:length(function_list)], ", "),
                )
            end
            return true
        else
            if printRes
                println(
                    "R1CS function " *
                    input_r1cs_name *
                    " has sound constraints (No trusted functions needed!)",
                )
            end
            return true
        end
    else
        if printRes
            println(
                "R1CS function " * input_r1cs_name * " has potentially unsound constraints",
            )
        end
        return false
    end
end

function solveWithTrustedFunctions(
    input_r1cs::String,
    input_r1cs_name::String;
    trusted_r1cs::Vector{String}=Vector{String}([]),
    trusted_r1cs_names::Vector{String}=Vector{String}([]),
    debug::Bool=false,
    printRes::Bool=true,
    abstractionOnly::Bool=false,
    input_sym::String="",
    secp_solve::Bool=false
)
    @assert (length(trusted_r1cs) == length(trusted_r1cs_names))
    equations_main, knowns_main, outs_main, num_variables = readR1CS(input_r1cs)
    function_list = []
    for i = 1:length(trusted_r1cs)
        equations_trusted, knowns_trusted, outs_trusted, _ = readR1CS(trusted_r1cs[i])
        push!(
            function_list,
            (trusted_r1cs_names[i], equations_trusted, knowns_trusted, outs_trusted),
        )
    end
    if debug
        println("file read")
    end
    function_list = sort(function_list, by=x -> -length(x[2]))
    # sort functions long to short, to prevent accidentally substituting a subroutine that prevents substituting a bigger function. 
    specials = []
    reduced = equations_main
    for i = 1:length(function_list)
        if printRes
            println("called abstraction")
        end
        new_specials, reduced = abstraction(
            function_list[i][1],
            reduced,
            function_list[i][3],
            function_list[i][2],
            function_list[i][4],
        )
        # abstract all of these away. 
        append!(specials, new_specials)
    end

    if abstractionOnly
        println(specials)
        return true
    end
    result = SolveConstraintsSymbolic(reduced, specials, knowns_main, debug, outs_main, num_variables, input_sym, secp_solve)
    if result == true
        if length(function_list) != 0
            if printRes
                println(
                    "R1CS function " *
                    input_r1cs_name *
                    " has sound constraints assuming trusted functions " *
                    join([trusted_r1cs_names[i] for i = 1:length(function_list)], ", "),
                )
            end
            return true
        else
            if printRes
                println(
                    "R1CS function " *
                    input_r1cs_name *
                    " has sound constraints (No trusted functions needed!)",
                )
            end
            return true
        end
    else
        if printRes
            println(
                "R1CS function " * input_r1cs_name * " has potentially unsound constraints",
            )
        end
        return false
    end
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

function SolveConstraintsSymbolic(
    constraints::Vector{R1CSEquation},
    special_constraints::Vector{Any},
    known_variables::Vector{Int64},
    debug::Bool=false,
    target_variables::Vector{Int64}=[],
    num_variables::Int=-1,
    input_sym::String="default.sym",
    secp_solve::Bool=false,
)
    num_unknowns =
        [length(setdiff(getVariables(x), Set(known_variables))) for x in constraints]
    in_queue = [false for x = 1:length(constraints)]
    equation_solved = [false for x in constraints]
    special_solved = [false for x in special_constraints]
    all_nontrivial_vars = Set()
    l = []
    for i in constraints
        for j in getVariables(i)
            push!(l, j)
        end
    end
    for i in special_constraints
        for j in i[2]
            push!(l, j)
        end
        for j in i[3]
            push!(l, j)
        end
    end
    all_nontrivial_vars = Set(l)
    println("all var length")
    println(length(all_nontrivial_vars))

    q = Queue{Int64}()
    for i = 1:length(constraints)
        if num_unknowns[i] <= 1
            push!(q, i)
            in_queue[i] = true
        end
    end
    #num_variables = maximum([
    #    maximum([
    #        maximum(keys(constraints[i].a)),
    #        maximum(keys(constraints[i].b)),
    #        maximum(keys(constraints[i].c)),
    #    ]) for i = 1:length(constraints)
    #])
    #println("num variables", num_variables)
    variable_to_indices = DefaultDict{Base.Int64,Vector{Int64}}(Vector{Int64})
    for i = 1:length(constraints)
        for j in getVariables(constraints[i])
            append!(variable_to_indices[j], i)
        end
    end
    if secp_solve
        # create a disjoint-set data structure for representing equal variables. 
        dsu = DataStructures.IntDisjointSet(num_variables)
        const_vals = Dict{BigInt,Int}()

        for eq in constraints
            if length(nonzeroKeys(eq.a)) == 0 && length(nonzeroKeys(eq.b)) == 0
                if length(eq.c) == 2
                    target_values = sort([1, bjj_p - 1])
                    # check if the equation is x == y
                    if sort([x.d for x in values(eq.c)]) == target_values
                        l = []
                        for i in nonzeroKeys(eq.c)
                            append!(l, i)
                        end
                        union!(dsu, l[1], l[2])
                    else
                        # check if the equation is of the form ax == b. 
                        l = []
                        constant_val = false
                        for i in nonzeroKeys(eq.c)
                            append!(l, i)
                            if i == 1
                                constant_val = true
                            end
                        end
                        non_one_value = l[1]
                        if l[1] == 1
                            non_one_value = l[2]
                        end

                        if !constant_val
                            continue
                        end
                        value = divexact(eq.c[1], -eq.c[non_one_value])
                        if !(value.d in keys(const_vals))
                            elem = push!(dsu)
                            const_vals[value.d] = elem
                        end
                        union!(dsu, non_one_value, const_vals[value.d])
                    end
                end
            end
        end
    end

    unknown_variable_count = num_variables
    variable_states = [VariableState(Int64(i)) for i = 1:num_variables]
    for i in known_variables
        if i == 1
            variable_states[i].values = Vector{AbstractAlgebra.GFElem{BigInt}}()
            push!(variable_states[i].values, F(1))
            variable_states[i].unique = true
            variable_states[i].is_known = true
        else
            variable_states[i].unique = true
            variable_states[i].is_known = true
        end
        unknown_variable_count -= 1
    end
    successful_steps = 0
    prev_successful_steps = -1
    prev_variable_count = num_variables
    prog_made = true
    nzk_a = [nonzeroKeys(constraints[i].a) for i = 1:length(constraints)]
    nzk_b = [nonzeroKeys(constraints[i].b) for i = 1:length(constraints)]
    nzk_c = [nonzeroKeys(constraints[i].c) for i = 1:length(constraints)]
    num_unique = 0
    display_eq = [true for i = 1:length(constraints)]
    while true
        prog_made = false
        if (prev_successful_steps == successful_steps)
            # means that no progress has been made, and thus we can continue. 
            break
        end
        prev_successful_steps = successful_steps
        if debug
            println("Successful steps before single equation rules ", successful_steps)
        end
        prev_variable_count = unknown_variable_count

        for i = 1:length(special_constraints)
            if !special_solved[i]
                solved = true
                for j in special_constraints[i][2]
                    if !variable_states[j].unique
                        solved = false
                        break
                    end
                end
                if !solved
                    continue
                end
                special_solved[i] = true
                successful_steps += 1
                for j in special_constraints[i][3]
                    if variable_states[j].unique
                        continue
                    end
                    variable_states[j].unique = true
                    variable_states[j].is_known = true
                    unknown_variable_count -= 1
                    for cons in variable_to_indices[j]
                        if !in_queue[cons]
                            push!(q, cons)
                            in_queue[cons] = true
                        end
                    end
                end
            end
        end
        # this checks for the particular arrangement
        # If a * b (mod p) = c and b < p, then and a, c, p are uniquely determined, then p is uniquely determined. 
        for i = 1:length(special_constraints)
            if special_constraints[i][1] != "BigMultModP"
                continue
            end
            for j = 1:length(special_constraints)
                if special_constraints[j][1] != "BigLessThan"
                    continue
                end
                constraint_i = special_constraints[i]
                constraint_j = special_constraints[j]
                same_set = true
                for k = 1:6
                    if !in_same_set(dsu, constraint_i[2][k+3], constraint_j[2][k])
                        same_set = false
                    end
                end
                if same_set
                    if variable_states[constraint_j[3][1]].values == [F(1)]
                        for idx = 1:length(constraint_i[3])
                            if !variable_states[constraint_i[3][idx]].unique
                                continue
                            end
                        end
                        for idx = 1:3
                            if !variable_states[constraint_i[2][idx]].unique
                                continue
                            end
                        end
                        for idx = 7:9
                            if !variable_states[constraint_i[2][idx]].unique
                                continue
                            end
                        end
                    end
                end
                for j in constraint_j[2][1:3]
                    if variable_states[j].unique
                        continue
                    end
                    variable_states[j].unique = true
                    variable_states[j].is_known = true
                    unknown_variable_count -= 1
                    for cons in variable_to_indices[j]
                        if !in_queue[cons]
                            push!(q, cons)
                            in_queue[cons] = true
                        end
                    end
                end
            end
        end

        a = Dates.now()
        prog = ProgressUnknown("Mode 1:")

        while length(q) >= 1
            ProgressMeter.next!(prog)
            if debug
                if (num_unique % 1000 == 0)
                    println("num_unique ", num_unique)
                end
            end
            if debug
                if successful_steps % 1000 == 0
                    println("Successful steps ", successful_steps)
                end
            end
            lead_idx = popfirst!(q)
            in_queue[lead_idx] = false

            if equation_solved[lead_idx] == true
                continue
            end

            true_equation = constraints[lead_idx]
            progress = false
            # Case 1: Direct Inference. Check if you have an equation of the form <unique> * <unique> = <unique> + nz * x_i, where nz is a nonzero variable, x_i is uniquely determined. 
            function check_unique()
                for i in nzk_b[lead_idx]
                    if !variable_states[i].unique
                        return false
                    end
                end
                for i in nzk_a[lead_idx]
                    if !variable_states[i].unique
                        return false
                    end
                end
                non_unique = -1
                for i in nzk_c[lead_idx]
                    if !variable_states[i].unique
                        if non_unique == -1
                            non_unique = i
                        else
                            return false
                        end
                    end
                end
                if non_unique == -1
                    return false
                end
                if debug
                    println("Case 1 success")
                    println("Before:")
                    printState(variable_states[non_unique])
                end
                # non_unique now must be uniquely determined. 
                variable_states[non_unique].unique = true
                num_unique += 1
                variable_states[non_unique].is_known = true
                successful_steps += 1
                for i in variable_to_indices[non_unique]
                    if !in_queue[i]
                        push!(q, i)
                        in_queue[i] = true
                    end
                end
                if debug
                    println("Case 1 After:")
                    printState(variable_states[non_unique])
                end
                return true
            end
            check_unique()
            # Case 2a: Solve basic quadratics. 
            function check_quadratic()
                if length(nzk_c[lead_idx]) >= 1 # nzk_c[lead_idx] must be zero.
                    return false
                end
                unknown_var = -1
                for i in getVariables(true_equation)
                    if !variable_states[i].is_known
                        if unknown_var == -1
                            unknown_var = i
                        else
                            return false
                        end
                    end
                end
                slope_a = F(0)
                intercept_a = F(0)
                for i in nzk_a[lead_idx]
                    if i == unknown_var
                        slope_a = true_equation.a[i]
                    elseif i == 1
                        intercept_a = true_equation.a[i]
                    else
                        return false
                    end
                end
                slope_b = F(0)
                intercept_b = F(0)
                for i in nzk_b[lead_idx]
                    if i == unknown_var
                        slope_b = true_equation.b[i]
                    elseif i == 1
                        intercept_b = true_equation.b[i]
                    else
                        return false
                    end
                end
                if debug
                    println("Case 2 success")
                    println("Before:")
                    printState(variable_states[unknown_var])
                end
                variable_states[unknown_var] = make_values(
                    variable_states[unknown_var],
                    [
                        AbstractAlgebra.divexact(-intercept_a, slope_a),
                        AbstractAlgebra.divexact(-intercept_b, slope_b),
                    ],
                )
                if (variable_states[unknown_var].values == [F(0), F(1)]) ||
                   (variable_states[unknown_var].values == [F(1), F(0)])
                    variable_states[unknown_var] =
                        make_bounds(variable_states[unknown_var], F(0), F(1))
                end
                for i in variable_to_indices[unknown_var]
                    if !in_queue[i]
                        push!(q, i)
                        in_queue[i] = true
                    end
                end
                equation_solved[lead_idx] = true
                successful_steps += 1
                if debug
                    println("Case 2 After:")
                    printState(variable_states[unknown_var])
                end
                return true
            end
            check_quadratic()
            # all equations after this are linear. 
            if (length(nzk_a[lead_idx]) >= 1) || (length(nzk_b[lead_idx]) >= 1)
                continue
            end

            # Case 2b: Check solutions to linear equations
            function check_linear()
                l = length(nzk_c[lead_idx])
                non_one_keys = []
                for i in nzk_c[lead_idx]
                    if i != 1
                        push!(non_one_keys, i)
                    end
                end
                if length(non_one_keys) != 1
                    return false
                end
                unknown_var = non_one_keys[1]
                true_value = AbstractAlgebra.divexact(
                    -true_equation.c[1],
                    true_equation.c[unknown_var],
                )
                new_info = false
                if variable_states[unknown_var].values != [true_value]
                    variable_states[unknown_var].values = [true_value]
                    successful_steps += 1
                    new_info = true
                end
                variable_states[unknown_var].lb = true_value
                variable_states[unknown_var].ub = true_value
                if !variable_states[unknown_var].unique
                    variable_states[unknown_var].unique = true
                    num_unique += 1
                    new_info = true
                end
                variable_states[unknown_var].is_known = true
                if new_info
                    for i in variable_to_indices[unknown_var]
                        if !in_queue[i]
                            push!(q, i)
                            in_queue[i] = true
                        end
                    end
                end
            end
            check_linear()

            # Case 3: Check if we have a binary representation. 
            function checkBinary()
                # check that the structure looks like 1, -(2^0), -(2^1), ... (-2^k)
                l = length(nzk_c[lead_idx])
                if l == 0
                    return false
                end
                # check that all the coefficients which are (-2^0), (-2^1), ... (-2^k) have lower bounds and upper bound of [0,1]

                target_values = sort(vcat([F(1).d], [(-F(2)^i).d for i = 0:l-2]))
                target_values_2 = sort(vcat([F(-1).d], [(F(2)^i).d for i = 0:l-2]))
                if (sort([x.d for x in values(true_equation.c)]) == target_values_2)
                    # the equation is flipped -- let's flip it. 
                    flipped_cons =
                        DefaultDict{Base.Int64,AbstractAlgebra.GFElem{BigInt}}(F(0))
                    for x in true_equation.c
                        flipped_cons[x[1]] = -x[2]
                    end
                    constraints[lead_idx] =
                        R1CSEquation(true_equation.a, true_equation.b, flipped_cons)
                    true_equation = constraints[lead_idx]
                end

                if (sort([x.d for x in values(true_equation.c)]) != target_values)
                    return false
                end
                display_eq[lead_idx] = false

                # check if we have binary variables. 
                new_key = -1
                for i in nzk_c[lead_idx]
                    if true_equation.c[i] == F(1)
                        new_key = i
                    else
                        if (variable_states[i].lb != F(0)) ||
                           (variable_states[i].ub != F(1))
                            return false
                        end
                    end
                end
                progress = false
                if !(
                    (variable_states[new_key].lb == F(0)) &&
                    (variable_states[new_key].ub == F(2)^(l - 1) - F(1))
                )
                    if variable_states[new_key].ub.d > BigInt(2)^(l - 1) - 1
                        variable_states[new_key].lb = F(0)
                        variable_states[new_key].ub = F(2)^(l - 1) - F(1)
                        variable_states[new_key].is_known = true
                        progress = true
                        successful_steps += 1
                        for i in variable_to_indices[new_key]
                            if !in_queue[i]
                                push!(q, i)
                                in_queue[i] = true
                            end
                        end
                    end
                end
                if variable_states[new_key].unique
                    for i in nzk_c[lead_idx]
                        if i != new_key
                            if !variable_states[i].unique
                                variable_states[i].unique = true
                                num_unique += 1
                                variable_states[i].is_known = true
                                progress = true
                                successful_steps += 1
                                for j in variable_to_indices[i]
                                    if !in_queue[j]
                                        push!(q, j)
                                        in_queue[j] = true
                                    end
                                end
                            end
                        end
                    end
                end
                if progress
                    if debug
                        println("Case 3 success")
                        printState(variable_states[new_key])
                    end
                end
                return progress
            end
            checkBinary()
            # Case 4a: Propagate bounds from x = y, so from x to y. 
            function checkpropagateBounds()
                if length(nzk_c[lead_idx]) >= 3
                    return false
                end
                target_values = sort([1, bjj_p - 1])
                if sort([x.d for x in values(true_equation.c)]) != target_values
                    return false
                end
                x = []
                for a in keys(true_equation.c)
                    push!(x, a)
                end
                display_eq[lead_idx] = false
                key_1 = x[1]
                key_2 = x[2]
                state_1 = variable_states[key_1]
                state_2 = variable_states[key_2]
                changed_vars = []
                if (state_2.ub != state_1.ub) ||
                   (state_2.lb != state_1.lb) ||
                   (state_2.unique != state_1.unique)
                    if (state_2.unique != state_1.unique)
                        if variable_states[key_1] != make_unique(state_1)
                            variable_states[key_1].is_known = true
                            variable_states[key_1].unique = true
                            push!(changed_vars, key_1)
                            num_unique += 1
                        end
                        if variable_states[key_2] != make_unique(state_2)
                            variable_states[key_1].is_known = true
                            variable_states[key_1].unique = true
                            num_unique += 1
                            push!(changed_vars, key_2)
                        end
                    end
                    mnub = min(state_1.ub.d, state_2.ub.d)
                    mxlb = max(state_1.lb.d, state_2.lb.d)

                    if (state_1.ub.d > mnub) || (state_1.lb.d < mxlb)
                        variable_states[key_1].is_known = true
                        variable_states[key_1].lb = F(mxlb)
                        variable_states[key_1].ub = F(mnub)
                        push!(changed_vars, key_1)
                    end
                    if (state_2.ub.d > mnub) || (state_2.lb.d < mxlb)
                        variable_states[key_2].is_known = true
                        variable_states[key_2].lb = F(mxlb)
                        variable_states[key_2].ub = F(mnub)
                        push!(changed_vars, key_2)
                    end

                    successful_steps += length(Set(changed_vars))
                    for j in Set(changed_vars)
                        if debug
                            println("Case 4 success")
                            printState(variable_states[j])
                        end
                        for i in variable_to_indices[j]
                            if !in_queue[i]
                                push!(q, i)
                                in_queue[i] = true
                            end
                        end
                    end
                    return true
                end
                return false
            end
            checkpropagateBounds()
            # Case 4b: 1 = x + y
            function checkOnePropagateBounds()
                # propogate binary bounds only
                if length(nzk_c[lead_idx]) >= 4
                    return false
                end
                # check if we have the equation x + y = 1. If x is in [0,1] then y is in [0,1] as well. 
                target_values = sort([1, bjj_p - 1, bjj_p - 1])
                if sort([x.d for x in values(true_equation.c)]) != target_values
                    return false
                end
                for i in true_equation.c
                    if i[2] == 1 && i[1] != 1
                        return false
                    end
                end
                key_1 = -1
                key_2 = -1
                for i in true_equation.c
                    if i[2] == F(-1)
                        if key_1 == -1
                            key_1 = i[1]
                        else
                            key_2 = i[1]
                        end
                    end
                end
                state_1 = variable_states[key_1]
                state_2 = variable_states[key_2]
                changed_vars = []
                if (state_2.ub != state_1.ub) ||
                   (state_2.lb != state_1.lb) ||
                   (state_2.unique != state_1.unique)
                    if (state_2.unique != state_1.unique)
                        if variable_states[key_1] != make_unique(state_1)
                            variable_states[key_1].is_known = true
                            variable_states[key_1].unique = true
                            push!(changed_vars, key_1)
                            num_unique += 1
                        end
                        if variable_states[key_2] != make_unique(state_2)
                            variable_states[key_2].is_known = true
                            variable_states[key_2].unique = true
                            num_unique += 1
                            push!(changed_vars, key_2)
                        end
                    end
                    mnub = min(state_1.ub.d, state_2.ub.d)
                    mxlb = max(state_1.lb.d, state_2.lb.d)
                    if (mnub != 1) || (mxlb != 0)
                        # if the bounds are not 0, 1 then we can't propogate. 
                        return false
                    end

                    if (state_1.ub.d > mnub) || (state_1.lb.d < mxlb)
                        variable_states[key_1].is_known = true
                        variable_states[key_1].lb = F(mxlb)
                        variable_states[key_1].ub = F(mnub)
                        variable_states[key_1].values = [F(mnub), F(mxlb)]
                        push!(changed_vars, key_1)
                    end
                    if (state_2.ub.d > mnub) || (state_2.lb.d < mxlb)
                        variable_states[key_2].is_known = true
                        variable_states[key_2].lb = F(mxlb)
                        variable_states[key_2].ub = F(mnub)
                        variable_states[key_2].values = [F(mnub), F(mxlb)]
                        push!(changed_vars, key_2)
                    end
                    successful_steps += length(Set(changed_vars))
                    for j in Set(changed_vars)
                        if debug
                            println("Case 7 success")
                            printState(variable_states[j])
                        end
                        for i in variable_to_indices[j]
                            if !in_queue[i]
                                push!(q, i)
                                in_queue[i] = true
                            end
                        end
                    end
                    return true
                end
                return false
            end
            checkOnePropagateBounds()
            # Case 5: This is a generalized base representation. 
            # If x + 2y + 6z = n, and x < 2, y < 3, z < 4, then n uniquely determines x, y, z. 
            function checkModularArithmetic()
                unknown_keys = []
                for a in nzk_c[lead_idx]
                    if !variable_states[a].unique
                        push!(unknown_keys, a)
                    end
                end
                if length(unknown_keys) == 0
                    return false
                end
                function flip_coeffs(x)
                    if x >
                       BigInt(20888242871839275222246405745257275088548364400416034343698204186575808495616)
                        return x -
                               BigInt(21888242871839275222246405745257275088548364400416034343698204186575808495617)
                    else
                        return x
                    end
                end
                keys = [unknown_keys[i] for i = 1:length(unknown_keys)]
                states = [variable_states[keys[i]] for i = 1:length(unknown_keys)]
                coeffs_d = [
                    abs(flip_coeffs(true_equation.c[keys[i]].d))
                    for i = 1:length(unknown_keys)
                ]
                for i = 1:length(states)
                    if !states[i].is_known
                        return false
                    end
                end
                r = sortperm(coeffs_d)
                for i = 1:length(r)-1
                    if (coeffs_d[r[i+1]] % coeffs_d[r[i]] != 0) || (
                        coeffs_d[r[i+1]] / coeffs_d[r[i]] <=
                        (states[r[i]].ub.d - states[r[i]].lb.d)
                    )
                        return false
                    end
                end
                if coeffs_d[r[length(r)]] * (states[r[length(r)]].ub.d + 1) > bjj_p
                    return false
                end
                successful_steps += length(unknown_keys)
                if debug
                    println("Case 5 Success ", unknown_keys)
                    println(constraints[lead_idx])
                    for i = 1:length(unknown_keys)
                        printState(variable_states[unknown_keys[i]])
                    end
                end
                for j in unknown_keys
                    variable_states[j].unique = true
                    num_unique += 1
                    variable_states[j].is_known = true
                    for i in variable_to_indices[j]
                        if !in_queue[i]
                            push!(q, i)
                            in_queue[i] = true
                        end
                    end
                end
                return true
            end
            checkModularArithmetic()
            # Case 6: All But One Zero. 
            # If x_1 * y_1 = 0
            # If x_2 * (y_1 - 1) = 0
            # If x_3 * (y_1 - 2) = 0
            # Then if y_1 is uniquely determined, whatever it is, then x_1 + x_2 + x_3 = n uniquely determines x_1, x_2, x_3. 
            function checkAllButOneZeroGroup()
                ABZ_index = -1
                ABZs = []
                for i in nzk_c[lead_idx]
                    if variable_states[i].unique
                        continue
                    else
                        if variable_states[i].abz != -1
                            if ABZ_index == -1
                                ABZ_index = variable_states[i].abz
                                push!(ABZs, i)
                            elseif variable_states[i].abz != ABZ_index
                                return false
                            else
                                push!(ABZs, i)
                            end
                        else
                            return false
                        end
                    end
                end
                if length(ABZs) == 0
                    return false
                end
                for i in ABZs
                    if variable_states[i].unique == true
                        continue
                    end
                    variable_states[i].unique = true
                    num_unique += 1
                    successful_steps += 1
                    variable_states[i].is_known = true
                    if debug
                        println("Case 6 success: ", i)
                        printState(variable_states[i])
                    end
                    for j in variable_to_indices[i]
                        if !in_queue[j]
                            push!(q, j)
                            in_queue[j] = true
                        end
                    end
                end
            end
            checkAllButOneZeroGroup()
        end
        b = Dates.now()
        if debug
            println("single equation phase ", b - a)
            println("Successful steps after single equation ", successful_steps)
        end
        c = Dates.now()
        ## Solve Ax = b, if A has a nonzero determinant and unique, and b is unique, then x is uniquely determined. 
        lin_freq =
            DefaultDict{Vector{Base.Int64},Vector{Vector{AbstractAlgebra.GFElem{BigInt}}}}([])
        for i = 1:length(constraints)
            all_vars = getVariables(constraints[i])
            unknown_vars = []
            linear_eq = true
            c_linear_eq = true
            for j in all_vars
                if !variable_states[j].unique
                    if (j in nzk_a[i]) && (j in nzk_b[i])
                        linear_eq = false
                        break
                    end
                    push!(unknown_vars, j)
                end
            end
            if !linear_eq
                continue
            end
            for j in all_vars
                if !variable_states[j].unique
                    if ((j in nzk_a[i]) || (j in nzk_b[i]) || !(j in nzk_c[i]))
                        c_linear_eq = false
                    end
                end
            end
            if !c_linear_eq
                continue
            end
            unknown_vars = sort(unknown_vars)
            push!(lin_freq[unknown_vars], [constraints[i].c[k] for k in unknown_vars])
            if length(lin_freq[unknown_vars]) == length(unknown_vars)
                function slow_det(mat)
                    # this is a slow det algorithm, which we need to use because julia's default det function doesn't work. 
                    res = 0
                    for perm in Combinatorics.permutations(1:size(mat, 1))
                        cur_term = F(1)
                        for j = 1:size(mat, 1)
                            cur_term *= F(mat[j, perm[j]])
                        end
                        res += F(Combinatorics.parity(perm)) * cur_term
                    end
                    return res
                end
                mat = mapreduce(permutedims, vcat, lin_freq[unknown_vars])
                if (slow_det(mat) != F(0)) || ((size(mat, 1) == 1) && mat[1] != F(0))
                    successful_steps += length(unknown_vars)
                    for new_var in unknown_vars
                        variable_states[new_var].unique = true
                        variable_states[new_var].is_known = true
                        unknown_variable_count -= 1
                        for j in variable_to_indices[new_var]
                            if !in_queue[j]
                                push!(q, j)
                                in_queue[j] = true
                            end
                        end
                    end
                end
            end
        end
        d = Dates.now()
        if debug
            println("linear solver phase ", d - c)
            println("Successful steps after linear: ", successful_steps)
        end
        # creating the ABZ groups. 
        e = Dates.now()
        bad_values = DefaultDict{Base.Int64,Set{AbstractAlgebra.GFElem{BigInt}}}(Set())
        for i = 1:length(constraints)
            if length(nzk_c[i]) != 0
                continue
            end
            unique_a = true
            for j in nzk_a[i]
                if !variable_states[j].unique
                    unique_a = false
                    break
                end
            end
            if length(nzk_b[i]) > 1
                continue
            end
            b_val = 0
            unique_b = true
            for j in nzk_b[i]
                if !variable_states[j].unique
                    unique_b = false
                    b_val = j
                end
            end
            if unique_b
                continue
            end
            if length(nzk_a[i]) > 2
                continue
            end
            ones = 0
            slope = F(0)
            intercept = F(0)
            slope_index = 0
            for j in nzk_a[i]
                if j == 1
                    ones += 1
                    intercept = constraints[i].a[j]
                else
                    slope = constraints[i].a[j]
                    slope_index = j
                end
            end
            root = AbstractAlgebra.divexact(-intercept, slope)
            if !(root in bad_values[slope_index])
                if variable_states[b_val].abz == -1
                    successful_steps += 1
                else
                    continue
                end
                variable_states[b_val].abz = slope_index
                variable_states[b_val].is_known = true
                for i in variable_to_indices[b_val]
                    if !in_queue[i]
                        push!(q, i)
                        in_queue[i] = true
                    end
                end
            end
        end
        f = Dates.now()
        if debug
            println("ABZ phase ", f - e)
            println("Successful steps after ABZ: ", successful_steps)
        end
        g = Dates.now()

        ## brute force check for isZero. 
        for i = 1:length(constraints)-1
            if length(nzk_c[i+1]) != 0
                continue
            end
            if length(nzk_b[i+1]) != 1
                continue
            end
            if length(nzk_c[i]) != 2
                continue
            end
            a_unique = true
            for j in nzk_a[i]
                if !variable_states[j].unique
                    a_unique = false
                    break
                end
            end
            if !a_unique
                continue
            end
            if constraints[i].a != constraints[i+1].a
                continue
            end
            is_not_one = false
            var_key = 0
            for j in nzk_b[i+1]
                if j != 1
                    is_not_one = true
                    var_key = j
                end
            end
            if !is_not_one
                continue
            end
            bad_key = false
            for j in nzk_c[i]
                if j != 1
                    if j != var_key
                        bad_key = true
                    end
                end
            end
            if bad_key
                continue
            end
            if !variable_states[var_key].unique
                variable_states[var_key].is_known = true
                variable_states[var_key].unique = true
                successful_steps += 1
                equation_solved[i] = true
                equation_solved[i+1] = true
                for i in variable_to_indices[var_key]
                    if !in_queue[i]
                        push!(q, i)
                        in_queue[i] = true
                    end
                end
            end
        end
        h = Dates.now()
        if debug
            println("isZero phase ", h - g)
            println("Successful steps after isZero: ", successful_steps)
        end
    end

    unique_variables = 0
    for i = 1:length(variable_states)
        if (variable_states[i].unique) && (i in all_nontrivial_vars)
            unique_variables += 1
        end
    end
    if true
        println(
            "Solved for ",
            unique_variables,
            " variables out of ",
            length(all_nontrivial_vars),
            " total variables",
        )
    end
    if debug
        for i in all_nontrivial_vars
            printState(variable_states[i])
        end
    end
    target_unique = 0
    for i in target_variables
        if variable_states[i].unique
            target_unique += 1
        end
    end

    if debug
        println(
            "Target variables solved for ",
            target_unique,
            " variables out of ",
            length(target_variables),
            " total variables",
        )
    end
    function_good = false
    if target_unique == length(target_variables)
        function_good = true
    end
    ## in this case, we solved for all the target variables, which means that we're in good shape. 

    ## parse sym file with csv reader

    csv_reader = CSV.File(input_sym; header=["i1", "i2", "i3", "signal"], skipto=0)
    index_to_signal = String[]

    for row in csv_reader
        push!(index_to_signal, "$(row.signal)")
    end

    for i = 1:length(constraints)
        all_unique = true
        for var in getVariables(constraints[i])
            if !variable_states[var].unique
                all_unique = false
            end
        end
        if all_unique
            continue
        end
        #if equation_solved[i]
        #    continue
        #end
        #if !display_eq[i]
        #    continue
        #end
        println("constraint #", i)
        printEquation(constraints[i], index_to_signal)
        for j in getVariables(constraints[i])
            if j == 1
                continue
            end
            if length(getVariables(constraints[i])) > 3
                continue
            end
            println(index_to_signal[j-1])
            printState(variable_states[j])
        end
    end
    for i in all_nontrivial_vars
        if i == 1
            continue
        end
        println(index_to_signal[i-1])
        printState(variable_states[i])
    end
    return function_good
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

export readR1CS, SolveConstraintsSymbolic, R1CSEquation, printEquation

end
