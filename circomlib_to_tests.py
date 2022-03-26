from collections import defaultdict

with open("/Users/franklyn/Dropbox/Circom_Testing/circomlib/circuits/all_funcs.txt") as f:
    content = f.readlines()
    default_values = defaultdict(lambda: 2)
    for i in range(len(content)):
        s = content[i].rstrip()
        print(s)
        filename = s.split(":")[0]
        function_signature = "".join(s.split(":")[1].split()[1:-1])
        print(function_signature)
        function_name = function_signature.split("(")[0]
        function_args = function_signature.split(
            "(")[1].split(")")[0].split(",")
        print(function_name)
        print(function_args)
        function_args = [x for x in function_args if x != ""]
        # print("")
        # with open("")
        test_filename = "ecne_circomlib_tests/" + \
            function_name + "@" + filename.split(".")[0] + ".circom"
        print(test_filename)
        file_text = f"""pragma circom 2.0.0;

include \"{"../Circom_Functions/circomlib/circuits/" + filename}\";

component main = {function_name}({",".join(map(str, map(lambda x: default_values[x], function_args)))});
        """
        print(file_text)
        with open(test_filename, "w") as f:
            f.write(file_text)
