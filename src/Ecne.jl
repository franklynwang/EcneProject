# ecne command-line tool
# TODO: add support for trusted R1CS files

using Dates
using ArgParse

import R1CSConstraintSolver: solveWithTrustedFunctions

function main(args)

    s = ArgParseSettings(description = "Ecne command-line helper")

    @add_arg_table! s begin
        "--r1cs"
            help = "de-optimized R1CS file to verify"     
            required = true
        "--name"
            help = "Circuit name"     
            required = true
        "--sym"
            help = "symbol file with labels"
            required = true        
        "--trusted"
            help = "Optional trusted R1CS file"
   end

    parsed_args = parse_args(args, s)

    dict = Dict("result" => "empty", "constraints" => ["empty"])

    try
        solveWithTrustedFunctions(parsed_args["r1cs"], parsed_args["sym"], parsed_args["name"], dict)
    catch e
        println("Error while running solveWithTrustedFunctions", e)
    end
end

main(ARGS)

