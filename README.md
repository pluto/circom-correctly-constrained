<h1 align="center">
  A succinct reference to correctly constraining circuits
</h1>

<!-- <div align="center"> -->
  <!-- <a href="https://github.com/pluto/circom-correctly-constrained/graphs/contributors"> -->
  <!--   <img src="https://img.shields.io/github/contributors/pluto/circom-correctly-constrained?style=flat-square&logo=github&logoColor=8b949e&labelColor=282f3b&color=32c955" alt="Contributors" /> -->
  <!-- </a> -->
  <!-- <a href="https://github.com/pluto/circom-correctly-constrained/actions/workflows/circom.yaml"> -->
    <!-- <img src="https://img.shields.io/badge/tests-passing-32c955?style=flat-square&logo=github-actions&logoColor=8b949e&labelColor=282f3b" alt="Tests" /> -->
  <!-- </a> -->
  <!-- <a href="https://github.com/pluto/circom-correctly-constrained/actions/workflows/lint.yaml"> -->
    <!-- <img src="https://img.shields.io/badge/lint-passing-32c955?style=flat-square&logo=github-actions&logoColor=8b949e&labelColor=282f3b" alt="Lint" /> -->
  <!-- </a> -->
<!-- </div> -->

## Overview
This repo is a reference on correctly testing and constraining circom circuits, with example workflows and reference patterns.

TLDR: use `circom --inspect $circuit_path` and `circomspect $circuit_path` for automated circuit underconstraint static analysis, and `circomkit` for testing.

## Recommended Tools

###  [circom docs: --inspect option](https://docs.circom.io/circom-language/code-quality/inspect/)
The circom compiler has an option to look for underconstrained templates and unused signals. It requires little setup, beyond specifying a main component.

The linked documentation is one of the better guides I've seen on how to guide the compiler how to properly constrain circuits, or else tell the compiler that a signal is unimportant to constrain.

Usage:
```sh 
# with UnusedSignalMultiplier as main
❯ mkdir target 
❯ circom --inspect circuits/multiplier.circom -o target
warning[CA01]: In template "UnusedSignalMultiplier()": Local signal unused does not appear in any constraint

# with UnderconstrainedMultiplier2 as main
warning[T3002]: Consider using <== instead of <-- to add the corresponding constraint.
 The constraint representing the assignment satisfies the R1CS format and can be added to the constraint system.
   ┌─ "circuits/multiplier.circom":45:5
   │
45 │     c <-- intermediary;
   │     ^^^^^^^^^^^^^^^^^^ found here
   │
   = call trace:
     ->UnderconstrainedMultiplier2

warning[CA01]: In template "UnderconstrainedMultiplier2()": Local signal c does not appear in any constraint

# with UnderconstrainedMultiplier1 as main
warning[T3002]: Consider using <== instead of <-- to add the corresponding constraint.
 The constraint representing the assignment satisfies the R1CS format and can be added to the constraint system.
   ┌─ "circuits/multiplier.circom":33:5
   │
33 │     intermediary <-- a * b;
   │     ^^^^^^^^^^^^^^^^^^^^^^ found here
   │
   = call trace:
     ->UnderconstrainedMultiplier1

warning[CA01]: In template "UnderconstrainedMultiplier1()": Local signal a does not appear in any constraint
```

### [circomspect static analyzer and linter for circom](https://github.com/trailofbits/circomspect)
`circomspect` is a static analyzer and linter for Circom.
- install: `cargo install circomspect`
- run: `circomspect $CIRCUIT_PATH`
    - e.g.: `circomspect circuits/multiplier.circom`. `circomspect` will flag underconstrained templates, but will not flag the overconstrained circuit.

`circomspect` seems powerful and straightforward to use, requiring very little extra context for the developer to use the tool.

More about `circomspect` by Trail of Bits, in a few blog posts. These blog posts briefly describe the tool and a few of the passes performed by `circomspect`. They are summaries of the `circomspect` in context, but not important for using the tool.
- [ToB blog: it pays to be circomspect](https://blog.trailofbits.com/2022/09/15/it-pays-to-be-circomspect/)
- [ToB blog: circomspect has more passes](https://blog.trailofbits.com/2023/03/21/circomspect-static-analyzer-circom-more-passes/)

It would be good if there were CI to run circomspect, but that does not currently seem to be available. There is no fast way to install circomspect, so it would be slightly costly to run in CI today.

Circomspect produces the following output on `multiplier.circom`:
```sh
❯ circomspect circuits/multiplier.circom 
circomspect: analyzing template 'Multiplier'
circomspect: analyzing template 'OverconstrainedMultiplier'

circomspect: analyzing template 'UnderconstrainedMultiplier1'
warning: Using the signal assignment operator `<--` is not necessary here.
   ┌─ /home/thor/tmp/circom-correctly-constrained/circuits/multiplier.circom:33:5
   │
33 │     intermediary <-- a * b;
   │     ^^^^^^^^^^^^^^^^^^^^^^ The expression assigned to `intermediary` is quadratic.
   │
   = Consider rewriting the statement using the constraint assignment operator `<==`.
   = For more details, see https://github.com/trailofbits/circomspect/blob/main/doc/analysis_passes.md#unnecessary-signal-assignment.

warning: Intermediate signals should typically occur in at least two separate constraints.
   ┌─ /home/thor/tmp/circom-correctly-constrained/circuits/multiplier.circom:31:5
   │
31 │     signal intermediary;
   │     ^^^^^^^^^^^^^^^^^^^ The intermediate signal `intermediary` is declared here.
   ·
34 │     c <== intermediary;
   │     ------------------ The intermediate signal `intermediary` is constrained here.
   │
   = For more details, see https://github.com/trailofbits/circomspect/blob/main/doc/analysis_passes.md#under-constrained-signal.

circomspect: analyzing template 'UnderconstrainedMultiplier2'
warning: Using the signal assignment operator `<--` is not necessary here.
   ┌─ /home/thor/tmp/circom-correctly-constrained/circuits/multiplier.circom:45:5
   │
45 │     c <-- intermediary;
   │     ^^^^^^^^^^^^^^^^^^ The expression assigned to `c` is quadratic.
   │
   = Consider rewriting the statement using the constraint assignment operator `<==`.
   = For more details, see https://github.com/trailofbits/circomspect/blob/main/doc/analysis_passes.md#unnecessary-signal-assignment.

warning: The signal `c` is not constrained by the template.
   ┌─ /home/thor/tmp/circom-correctly-constrained/circuits/multiplier.circom:41:5
   │
41 │     signal output c;
   │     ^^^^^^^^^^^^^^^ This signal does not occur in a constraint.

warning: Intermediate signals should typically occur in at least two separate constraints.
   ┌─ /home/thor/tmp/circom-correctly-constrained/circuits/multiplier.circom:42:5
   │
42 │     signal intermediary;
   │     ^^^^^^^^^^^^^^^^^^^ The intermediate signal `intermediary` is declared here.
43 │
44 │     intermediary <== a * b;
   │     ---------------------- The intermediate signal `intermediary` is constrained here.
   │
   = For more details, see https://github.com/trailofbits/circomspect/blob/main/doc/analysis_passes.md#under-constrained-signal.

circomspect: analyzing template 'UnusedSignalMultiplier'
warning: The signal `unused` is not used by the template.
   ┌─ /home/thor/tmp/circom-correctly-constrained/circuits/multiplier.circom:54:5
   │
54 │     signal unused;
   │     ^^^^^^^^^^^^^ This signal is unused and could be removed.
   │
   = For more details, see https://github.com/trailofbits/circomspect/blob/main/doc/analysis_passes.md#unused-variable-or-parameter.

warning: Intermediate signals should typically occur in at least two separate constraints.
   ┌─ /home/thor/tmp/circom-correctly-constrained/circuits/multiplier.circom:54:5
   │
54 │     signal unused;
   │     ^^^^^^^^^^^^^ The intermediate signal `unused` is declared here.
   │
   = For more details, see https://github.com/trailofbits/circomspect/blob/main/doc/analysis_passes.md#under-constrained-signal.

circomspect: 7 issues found.
```

### [circomkit circom testing suite](https://github.com/erhant/circomkit)
A typescript-based suite of testing tools for circom. The circomkit readme does a better job of summarizing the tool than I could here.

Circomkit theoretically could be used to [test passing and failing witnesses](https://github.com/erhant/circomkit?tab=readme-ov-file#witness-tester) for circuits, though this seems inelegant as provided, and seems really only designed for one-off soundness checks.

See the [short circomkit usage example in this repo](https://github.com/pluto/circom-correctly-constrained/blob/main/circuits/test/multiplier.test.ts) for a demonstration of circomkit, or [circomkit-examples](https://github.com/erhant/circomkit-examples) for further examples.

## Not recommended
The following tools were examined and found eclipsed in utility by other tools (circomscribe), failed to build (picus), or exceedingly complex to understand [(circom-mutator)](https://github.com/aviggiano/circom-mutator).

### [zksecurity circomscribe - demo playground, visualize constraints ](https://www.circomscribe.dev/)
Circomscribe is the circom compiler, run in WASM in the browser in an online playground tool. The tool emits information about the circom compilation process. This is a clunky workflow, copy pasting code into a browser. 

The main context where this tool could be useful would be to see explicitly what constraints are produced by circom snippet, which could be useful for obtaining greater granularity of depth. This tool would be annoying to use if the template had more than one or two dependency templates.

Run on each of the multipliers in `circuits/multiplier.circom`, Circomscribe produces the following outputs. Note that the underconstrained circuits each only have 1 line of constraint rather than 2.
```ts
(- 1 * Multiplier.a )*(Multiplier.b ) = - 1 * Multiplier.intermediary
- 1 * Multiplier.c + Multiplier.intermediary = 0

(- 1 * OverconstrainedMultiplier.a )*(OverconstrainedMultiplier.b ) = - 1 * OverconstrainedMultiplier.intermediary
- 1 * OverconstrainedMultiplier.c + OverconstrainedMultiplier.intermediary = 0

- 1 * UnderconstrainedMultiplier1.c + UnderconstrainedMultiplier1.intermediary = 0

(- 1 * UnderconstrainedMultiplier2.a )*(UnderconstrainedMultiplier2.b ) = - 1 * UnderconstrainedMultiplier2.intermediary 
```

Circomscribe's announcement blog post briefly introduces the tool.
- [blog post about circomscribe](https://www.zksecurity.xyz/blog/posts/circomscribe/)

### [Picus QED uniqueness property underconstraint checker](https://github.com/Veridise/Picus)
Picus is a tool by Veridise for checking under-constrained signals of circuits. I couldn't install Picus (in a half hour of trying). The docker build script fails for me with error:
```
ERROR: failed to solve: process "/bin/bash -c raco make picus.rkt" did not complete successfully: failed to create endpoint m4k1rddek6olk2zpiynatvsz5 on network bridge: failed to add the host (veth7b01635) <=> sandbox (veth4ac65fd) pair interfaces: operation not supported
```

I tried a few things including restarting my Docker daemon, then attempting a build from scratch by installing z3 and cvc5, but these took too long, so I'm moving on after leaving an issue. Just kidding, they disabled issues for their repo, big oof.

It could be worthwhile to come back and try to get this tool to work, but it's hard to say whether the tool is actually user-ready.

## more reading about underconstrained circuits
- [circom constraining docs](https://docs.circom.io/circom-language/constraint-generation/)
- [veridise blog: circom pairing](https://medium.com/veridise/circom-pairing-a-million-dollar-zk-bug-caught-early-c5624b278f25)
- [dacian: exploiting under-constrained zk circuits](https://dacian.me/exploiting-under-constrained-zk-circuits)
- [blockdev: tips for safe circom circuits](https://hackmd.io/@blockdev/Bk_-jRkXa)
- [circom101 book by erhant, author of circomkit](https://github.com/erhant/circom101/tree/main)
- [0xparc: circom workshop series](https://learn.0xparc.org/materials/circom/learning-group-1/intro-zkp)
- [paper by veridise on underconstrained circuits](https://eprint.iacr.org/2023/512.pdf)

## License

Licensed under the Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)

## Contributing

We welcome contributions to our open-source projects. If you want to contribute or follow along with contributor discussions, join our [main Telegram channel](https://t.me/pluto_xyz/1) to chat about Pluto's development.

Our contributor guidelines can be found in [CONTRIBUTING.md](./CONTRIBUTING.md). A good starting point is issues labelled 'bounty' in our repositories.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be licensed as above, without any additional terms or conditions.
