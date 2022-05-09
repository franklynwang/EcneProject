
module VariableStateStructure

using AbstractAlgebra
using DataStructures
using ProgressMeter

const bjj_p =
    BigInt(21888242871839275222246405745257275088548364400416034343698204186575808495617)

F = AbstractAlgebra.GF(bjj_p)


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

function printState(x::VariableState)
    bounds = [x.lb.d, x.ub.d]
    if bounds[1] == 0 && bounds[2] == 21888242871839275222246405745257275088548364400416034343698204186575808495616
        bounds = []
    end
    println(
        "idx: ",
        x.index,
        "\n",
        #" unique: ",
        #x.unique,
        #"\n",
        " All possible values: ",
        [val.d for val in x.values],
        "\n",
        " bounds: ",
        bounds,
        "\n",
    )
end

export VariableState, printState

end