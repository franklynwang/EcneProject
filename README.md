# Ecne (R1CSConstraintSolver.jl)

## Introduction

zk-SNARKs are a method for generating zero-knowledge proofs of arbitrary functions, as long as these functions can be expressed as the result of a R1CS (a rank-one constraint system). However, one still needs to convert functions into R1CS form. As this is a laborious process (though still far easier than starting from scratch), Ecne, named after the Celtic god of wisdom, is a tool that can be used to translate functions into R1CS form, in its current form, by verifying that R1CS equations uniquely determine outputs given inputs (i.e. that the constraints are _sound_).

## What is Ecne?

The goal of Ecne is to make it easier to convert functions into R1CS form. As of right now, Ecne is used to verify that certain sets of R1CS constraints uniquely identify functions. Ecne also supports adding certain functions to a trusted codebase, so that they do not need to be re-verified after they've been verified once. Eventually, we hope to have Ecne not only show that R1CS constraints have unique solutions, but also show that they correspond to formally specified mathematical functions as well.

## API

The primary user facing function is `solveWithTrustedFunctions`. The function takes in the R1CS file of the equation you want (which specifies functions you want) and the r1cs files of Trusted functions with their names. It returns `true` when able to verify the soundness of the constraints, and `false` otherwise. Note that `false` does not mean that the constraints aren't sound, it just means that Ecne is unable to prove that the constraints are sound.

## Algorithm Details

See [here](https://hackmd.io/@ONwIGWrPRcutB_-IRIqcUQ/HkENkNtec) for algorithmic details.

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
