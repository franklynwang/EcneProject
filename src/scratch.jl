
function solve_constraints(field::AbstractAlgebra.GFField{BigInt}, constraints::Array{R1CSEquation})
    num_unknowns = [length(setdiff(getVariables(x), Set(1))) for x in constraints]
    q = Queue{Int64}()
    for i in 1:length(constraints)
        if num_unknowns[i] <= 1
            enqueue!(q, i)
        end
    end

    num_variables = maximum([maximum([maximum(keys(constraints[i].a)), maximum(keys(constraints[i].b)), maximum(keys(constraints[i].c))]) for i in 1:length(constraints)])

    variables = [VariableState(i) for i in 1:num_variables]
    variables[1] = oneVar(variables[1], field(1)) # set variable to one
    variable_to_indices = DefaultDict{Base.Int64,Vector{Int64}}(Vector{Int64})
    for i in 1:length(constraints)
        for j in getVariables(constraints[i])
            append!(variable_to_indices[j], i)
        end
    end
    num_iter = 0
    while length(q) >= 1
        lead_idx = dequeue!(q)
        num_iter += 1
        if num_iter > 1000000
            println("Too many iterations")
            break
        end
        unknown_count = num_unknowns[lead_idx]
        true_equation = constraints[lead_idx]
        if unknown_count == 1
            vars = getVariables(true_equation)
            unknown_index = -1
            all_unique = true
            for index in vars
                if !variables[index].unique
                    all_unique = false
                end
                if variables[index].values == []
                    unknown_index = index
                    break
                end
            end
            successful = true
            for index in vars
                if variables[index].values == []
                    continue
                elseif length(variables[index].values) == 1
                    continue
                else
                    successful = false
                end
            end
            if !successful
                enqueue!(q, lead_idx)
            end
            function getSlopeIntercept(equation)
                slope = equation[unknown_index]
                intercept = field(0)
                for index in vars
                    if index != unknown_index
                        intercept += equation[index] * variables[index].values[1]
                    end
                end
                return slope, intercept
            end
            aslope, aintercept = getSlopeIntercept(true_equation.a)
            bslope, bintercept = getSlopeIntercept(true_equation.b)
            cslope, cintercept = getSlopeIntercept(true_equation.c)
            quadA = aslope * bslope
            quadB = aslope * bintercept + bslope * aintercept - cslope
            quadC = aintercept * bintercept - cintercept
            l = solveQuadratic(field, quadA, quadB, quadC)
            if l == "YES"
                continue
            elseif l == "NO"
                println("Inconsistent!")
                return
            elseif length(l) == 2
                variables[unknown_index] = VariableState(unknown_index, true, l)
            elseif length(l) == 1
                variables[unknown_index] = VariableState(unknown_index, true, [l[1]])
            end
            for k in variable_to_indices[unknown_index]
                global num_unknowns[k] -= 1
                if num_unknowns[k] <= 1
                    enqueue!(q, k)
                end
            end
        end
        if unknown_count == 0
            unknown_count = num_unknowns[lead_idx]
            true_equation = constraints[lead_idx]
            var_indices = collect(getVariables(true_equation))
            ambiguous_vars = []
            for i in 1:length(var_indices)
                if length(variables[var_indices[i]].values) == 2
                    push!(ambiguous_vars, var_indices[i])
                end
            end
            if length(ambiguous_vars) == 0
                continue # there's nothing to learn...
            end
            assignments = []
            num_valid = 0
            for x in powerset(ambiguous_vars)
                function get_value(equation)
                    res = field(0)
                    for i in equation
                        if !(i[1] in ambiguous_vars)
                            res += equation[i[1]] * variables[i[1]].values[1]
                        elseif (i[1] in x)
                            res += equation[i[1]] * variables[i[1]].values[2]
                        else
                            res += equation[i[1]] * variables[i[1]].values[1]
                        end
                    end
                    return res
                end

                if get_value(true_equation.a) * get_value(true_equation.b) == get_value(true_equation.c)
                    if length(assignments) == 0
                        push!(assignments, x)
                    end
                    num_valid += 1
                    if num_valid == 2
                        break
                    end
                end
            end
            if num_valid == 0
                println("No valid assignments")
            elseif num_valid == 1
                for i in ambiguous_vars
                    if i in assignments[1]
                        variables[i] = oneVar(variables[i], variables[i].values[2])
                    else
                        variables[i] = oneVar(variables[i], variables[i].values[1])
                    end
                end
            end
        end
        if length(q) == 0
            break
        end
    end
end