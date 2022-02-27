julia := "julia --project=."

install:
    {{julia}} -e "import Pkg; Pkg.instantiate()"

repl:
    {{julia}}

notebook:
    {{julia}} -e "import Pluto; Pluto.run()"

format:
    {{julia}} -e "using JuliaFormatter; format(\"src\", verbose=true); format(\"test\", verbose=true); format(\"bench\", verbose=true)"

bench:
    {{julia}} bench/bench.jl

check:
    if [[ $(git diff --name-only) ]]; then \
        >&2 echo "Please run check on a clean Git working tree."; \
        exit 1; \
    fi
    just format
    files=$(git diff --name-only); \
    if [[ $files ]]; then \
        >&2 echo "Formatting issues found:"; \
        >&2 echo "$files"; \
        exit 1; \
    fi

test:
    {{julia}} -e "import Pkg; Pkg.test()"
