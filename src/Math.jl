

module Math

using AbstractAlgebra
using DataStructures
using ProgressMeter

const bjj_p =
    BigInt(21888242871839275222246405745257275088548364400416034343698204186575808495617)

F = AbstractAlgebra.GF(bjj_p)

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


export squareRoot, solveQuadratic

end