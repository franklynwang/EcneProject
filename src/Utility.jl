
module Utility

using AbstractAlgebra
using DataStructures
using ProgressMeter

const bjj_p =
    BigInt(21888242871839275222246405745257275088548364400416034343698204186575808495617)

F = AbstractAlgebra.GF(bjj_p)




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

export checkNonZeroValues

end