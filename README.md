# Ecne (R1CSConstraintSolver.jl)

## Introduction

zk-SNARKs are a method for generating zero-knowledge proofs of arbitrary functions, as long as these functions can be expressed as the result of a R1CS (a rank-one constraint system). However, one still needs to convert functions into R1CS form. As this is a laborious process (though still far easier than starting from scratch), Ecne, named after the Celtic god of wisdom, is a tool that can be used to translate functions into R1CS form, in its current form, by verifying that R1CS equations uniquely determine outputs given inputs (i.e. that the constraints are _sound_).

## What is Ecne?

The goal of Ecne is to make it easier to convert functions into R1CS form. As of right now, Ecne is used to verify that certain sets of R1CS constraints uniquely identify functions. Ecne also supports adding certain functions to a trusted codebase, so that they do not need to be re-verified after they've been verified once. Eventually, we hope to have Ecne not only show that R1CS constraints have unique solutions, but also show that they correspond to formally specified mathematical functions as well.

## API

The primary user facing function is `solveWithTrustedFunctions`. The function takes in the R1CS file of the equation you want (which specifies functions you want) and the r1cs files of Trusted functions with their names. It returns `true` when able to verify the soundness of the constraints, and `false` otherwise. Note that `false` does not mean that the constraints aren't sound, it just means that Ecne is unable to prove that the constraints are sound.

## Algorithm Details

The algorithm begins by finding instances of the trusted functions inside the input R1CS file, which allows us to turn the R1CS into _special constraints_ and _reduced constraints_. The reduced constraints are still in R1CS form (e.g. $$z = x * y$$), whereas the special constraints are in function form (i.e. $$y_3 = f(y_1, y_2)$$)

Then, we apply a series of rules to the reduced constraints, and the special constraints whenever appropriate as well. The rules on reduced constraints are as follows. Remember that we are working over a finite field!

- (Rule 1) If <img src="https://render.githubusercontent.com/render/math?math=cx = <unique>">, and <img src="https://render.githubusercontent.com/render/math?math=c \neq 0"> is a constant, then <img src="https://render.githubusercontent.com/render/math?math=x"> is also uniquely determined.
- (Rule 2a) If $(x-a) * (x-b) = 0$, then $x = [a, b]$. Namely, if $\{a,b\} = \{0,1\}$, then $0 \le x \le 1$ as well.
- (Rule 2b) If $a*x + b = 0$, then $x = -b/a$.
- (Rule 3) If $z = 2^0 x_0 + 2^1 x_1 + \ldots + 2^n x_n$, and $x_0, x_1, ... x_n$ are all in $[0,1]$, then $z \in [0, 2^{n+1}]$. Furthermore, if $z$ is uniquely determined, so are $x_0, x_1, ... x_n$.
- (Rule 4a) If $x = y$, then all properties from $x$ are copied to $y$.
- (Rule 4b) If $1 = x + y$, and $x \in [0,1]$ (or $y \in [0,1]$), then the other variable is also in $[0,1]$. Furthermore, if $x$ is uniquely determined, $y$ is uniquely determined as well.
- (Rule 5) If $z = x_0 + a_1 x_1 + \ldots + a_n x_n$, and $a_i \mid a_{i+1}$, and $x_i < a_{i+1} / a_i$ (and $x_n$ is less than $p / a_n - 1$, where $p$ is the prime of the finite field), then one can bound $z$ similarly to Rule 3, and if $z$ is uniquely determined, then $x_0, x_1, ... x_n$ are also uniquely determined.
- (Rule 6) This is a rule called the AllButOneZero rule, and considers groups of variables, all but at most one of which are zero. It's best illustrated with an example. If $y_1$ is uniquely determined, and
  $x_1 * y_1 = 0$
  $x_2 * (y_1 - 1) = 0$
  $x_3 * (y_1 - 2) = 0$
  $x_1 + x_2 + x_3 = z$
  Then assuming that $z$ is uniquely determined as well, we can uniquely determine $x_1, x_2, x_3$.
- (Rule 7) If $Ax = b$, where $A$ is a constant square matrix with nonzero determinant, and $b$ is a uniquely determined vector, then $x$ is uniquely determined as well.

These deduction rules are implemented by maintaining information on each variable in the `VariableState` object.

## Setup

First, clone the repository:

```bash
git clone https://github.com/franklynwang/EcneProject
```

Then, clone the circomlib library in Circom_Functions/

```bash
git clone https://github.com/iden3/circomlib
```

The following requirements must be present in your environment.

- [Julia 1.7+](https://julialang.org/)
- [Just](https://github.com/casey/just): a command runner

Then, run the following command to instantiate the Julia package environment.

```bash
just install
```

To run the interactive [Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/) or open a [Pluto](https://github.com/fonsp/Pluto.jl) notebook server, use the following commands:

```bash
just repl      # open Julia REPL (can add packages here)
just notebook  # start server (try opening hard_solve.jl)
```

If you make edits and would like to check that all tests still pass, please use

```bash
just test
```

## Verifications

To verify the correctness of the ECDSA privToPub circuit given the correctness of the SECP circuit, first, we will need to obtain the R1CS file for the ECDSA circuit, which is unfortunately too large to include in this repository. To generate it, you need the [Circom Library](https://docs.circom.io/getting-started/installation/), after which you run the following command in Circom_Functions:

```bash
circom ecdsa.circom --r1cs --O0
```

Note the O0 compilation is needed to make abstraction possible. **Note that this means using optimized constraints in production assumes the correctness of the Circom Compiler, and that the optimized constraints are equivalent to the non-optimized ones**.

Finally, simply run `julia --project=. examples/ecdsa_secp_abstraction.jl` to show that ECDSA has sound constraints given if we trust the `Secp256k1AddUnequal` command

To verify the correctness of the SECP circuit given BigMultModP and BigLessThan, simply run `julia --project=. examples/secpk1_abstraction.jl`

To see benchmarks on several circuits, run `just bench`.

## Authorship

Made by [Franklyn Wang](https://twitter.com/franklyn_wang)
