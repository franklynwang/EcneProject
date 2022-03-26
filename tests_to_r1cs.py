import subprocess
from os import listdir, chdir
from os.path import isfile, join
all_files = [f for f in listdir("ecne_circomlib_tests") if isfile(
    join("ecne_circomlib_tests", f))]
all_files = filter(lambda x: x.endswith(".circom"), all_files)

chdir("ecne_circomlib_tests")


for i in all_files:
    print(i)
    subprocess.run(["circom", i, "--r1cs", "--O0"])
