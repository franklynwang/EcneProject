from os.path import isfile, join
from os import listdir, chdir
header = """using Dates
import R1CSConstraintSolver: solveWithTrustedFunctions"""

all_files = [f for f in listdir("ecne_circomlib_tests") if isfile(
    join("ecne_circomlib_tests", f))]
all_files = filter(lambda x: x.endswith(".circom"), all_files)
complete_file = header

complete_file += """

"""
for filename in all_files:
    method_name = filename.split("@")[0]
    complete_file += f"""
try
    solveWithTrustedFunctions(\"ecne_circomlib_tests/{filename.replace(".circom", ".r1cs")}\", \"{method_name} from {filename.split("@")[1].split(".")[0]}.circom\")
catch e
    println("File didn't compile")
end
    """

with open("circom_test_examples/all_tests.jl", "w") as f:
    f.write(complete_file)
