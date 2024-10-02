<h1 align="center">
  A succinct reference to correctly constraining circuits
</h1>

## Table of Contents
- [Overview](#overview)
- [Recommended Tools](#recommended-tools)
  - [circom docs: --inspect option](#circom-docs---inspect-option)
  - [circomspect static analyzer and linter for circom](#circomspect-static-analyzer-and-linter-for-circom)
  - [circomkit circom testing suite](#circomkit-circom-testing-suite)
- [Not recommended](#not-recommended)
  - [zksecurity circomscribe - demo playground, visualize constraints](#zksecurity-circomscribe---demo-playground-visualize-constraints-)
  - [Picus QED uniqueness property underconstraint checker](#picus-qed-uniqueness-property-underconstraint-checker)
  - [Backlog list of further tools to examine](#backlog-list-of-further-tools-to-examine)
- [Everything you should know about correctly assigning constraints](#everything-you-should-know-about-correctly-assigning-constraints)
  - [The basics](#the-basics)
  - [When may a developer choose to use `<--` assignment over `<==`?](#when-may-a-developer-choose-to-use----assignment-over-)
- [Common mistakes in underconstraining circuits](#common-mistakes-in-underconstraining-circuits)
- [Further Reading](#further-reading)
  - [Recommended short reading](#recommended-short-reading)
  - [Recommended longer reading](#recommended-longer-reading)
  - [Also reviewed in preparation for this post](#also-reviewed-in-preparation-for-this-post)
- [License](#license)
- [Contributing](#contributing)

## Overview
This repo is a reference on correctly testing and constraining circom circuits, with example workflows and reference patterns.

TLDR: use `circom --inspect $circuit_path` and `circomspect $circuit_path` for automated circuit underconstraint static analysis, and `circomkit` for testing.

Skim down to "Everything you should know..." for a primer for circom authors on constraining and optimizing circuits.

## Recommended Tools

###  [circom docs: --inspect option](https://docs.circom.io/circom-language/code-quality/inspect/)
The circom compiler has an option to look for underconstrained templates and unused signals. It requires little setup, beyond specifying a main component.

The linked documentation is one of the better guides I've seen on how to guide the compiler how to properly constrain circuits, or else tell the compiler that a signal is unimportant to constrain.

#### Example
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
 `circomspect` is a static analyzer and linter for Circom, similar to `circom --inspect`, but with a greater area of checks, and more verbose error logs.

- install: `cargo install circomspect`
- run: `circomspect $CIRCUIT_PATH`
    - e.g.: `circomspect circuits/multiplier.circom`. `circomspect` will flag underconstrained templates, but will not flag the overconstrained circuit.

`circomspect` is powerful and straightforward to use, requiring very little extra context for the developer to use the tool.

More about `circomspect` by Trail of Bits, in a few blog posts. These blog posts briefly describe the tool and a few of the passes performed by `circomspect`. They are summaries of the `circomspect` in context, but are inessential for using the tool.
- [ToB blog: it pays to be circomspect](https://blog.trailofbits.com/2022/09/15/it-pays-to-be-circomspect/)
- [ToB blog: circomspect has more passes](https://blog.trailofbits.com/2023/03/21/circomspect-static-analyzer-circom-more-passes/)

It would be good if there were CI to run circomspect, but that does not currently seem to be available. There is no fast way to install circomspect, so it would be slightly costly to run in CI today.

#### Example
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
A typescript-based suite of testing tools for circom. The circomkit README does a better job of summarizing the tool than I could here.

Circomkit theoretically could be used to [test passing and failing witnesses](https://github.com/erhant/circomkit?tab=readme-ov-file#witness-tester) for circuits, though this seems inelegant as provided, and seems really only designed for one-off soundness checks.

See the [short circomkit usage example in this repo](https://github.com/pluto/circom-correctly-constrained/blob/main/circuits/test/multiplier.test.ts) for a demonstration of circomkit, or [circomkit-examples](https://github.com/erhant/circomkit-examples) for further examples.

## Not recommended
The following tools were examined and found eclipsed in utility by other tools (circomscribe), failed to build (picus), or exceedingly complex to understand [(circom-mutator)](https://github.com/aviggiano/circom-mutator).

### [zksecurity circomscribe - demo playground, visualize constraints ](https://www.circomscribe.dev/)
Circomscribe is the circom compiler, run in WASM in the browser in an online playground tool. The tool emits information about the circom compilation process. This is a clunky workflow, pasting code into a browser. 

The main context where this tool could be useful would be to see explicitly what constraints are produced by circom snippet, which could be useful for obtaining greater granularity of depth. This tool would be annoying to use if the template had more than one or two dependency templates.

Run on each of the multipliers in `circuits/multiplier.circom`, Circomscribe produces the following outputs. Note that the underconstrained circuits each only have 1 line of constraint, rather than 2.
```sh
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

### Backlog list of further tools to examine
- [Ecne - an engine for verifying R1CS soundness](https://github.com/franklynwang/EcneProject)

## Everything you should know about correctly assigning constraints

### The basics
Circom allows the developer to specify constraints in two ways:
```rust
// 1. equality constraint operators: ===, <==, ==> 
signal_b <== signal_or_var_a;
// the above line is equivalent to the following two lines:
signal_b <-- signal_or_var_a; // assigns, but does not constrain
signal_b === signal_or_var_a;

// 2. the assert keyword
// if all values are known at compile-time the assertion is checked then
// otherwise, the assertion creates a constraint.
assert(a <= b);
assert(a * a == b);
```

Recall that, due to the construction of the R1CS circuit layout, Circom cannot express greater-than-quadratic constraints:
- this is fine: `assert(a*a == b)`
- this is a cubic constraint (no go): `assert(a*a*a == b)

so we may express higher degree constraints as such:
```rust
a2 <== a*a;
a2*a === b; // equivalently, assert(a2*a == b);
```

### When may a developer choose to use `<--` assignment over `<==`?
> assigning a value to a signal using <-- and --> is considered dangerous and should, in general, be combined with adding constraints with \=\=\=, which describe by means of constraints which the assigned values are. 
> https://docs.circom.io/circom-language/constraint-generation/

As stated in the circom docs, generally avoid using `<--`, at least until an optimization code pass. The operator may save a few gates, but risks underconstraining the circuit. A developer may incorrectly use `<--` to allow assignment for would-be non-quadratic assignments; this is a [footgun](https://en.wiktionary.org/wiki/footgun).

Use of `<--` allows the developer to reason extra constraints out of their circuits, thereby improving proving times. When optimizing code with `<--`, use tools like `circom --inspect` (which searches the codebase for `<--` that can be transformed into `<==`) and `circomspect` to check for correctly constrained circuits.

Documentation as to how to correctly use `<--` is sparse, but as best as this author can infer, there are essentially two reasons to use assignment without assertion:
1. **avoid unnecessary constraints on intermediate calculations**
2. **defer constraint checks to a final value assertion**
3. **check a more general constraint**

Two examples applying `<--` are given in the [circom documentation](https://docs.circom.io/circom-language/basic-operators/#examples-using-operators-from-the-circom-library).

#### Circom docs example 1: avoid unnecessary constraints on intermediate calculations
```rust
pragma circom 2.0.0;

template IsZero() {
    signal input in;
    signal output out;
    signal inv;
    // avoid unnecessary constraint on intermediate signal inv
    // recall: / is multiplication by the inverse modulo p
    inv <-- in!=0 ? 1/in : 0; 
    out <== -in*inv +1;
    in*out === 0;
}
component main {public [in]}= IsZero();
```

> This template checks if the input signal `in` is `0`. In case it is, the value of output signal`out` is `1`. `0`, otherwise. Note here that we use the intermediate signal `inv` to compute the inverse of the value of `in` or `0` if it does not exist. If `in`is 0, then `in*inv` is 0, and the value of `out` is `1`. Otherwise, `in*inv` is always `1`, then `out` is `0`.

That is, this template computes the function:
$$\text{out} =\cases{1 &\text{if in = 0}\\ 0 & \text{if in $\ne$ 0 }}$$
Which can be expressed in two constraints; assigning a value to `out` from the value of `in`, and checking that the value assigned matches the function described above.

The value of `inv` is an intermediate calculation, and does not require a constraint.

#### Circom docs example 2: check a more general constraint, and defer constraint checks
```rust
pragma circom 2.0.0;

template Num2Bits(n) {
    signal input in;
    signal output out[n];
    var lc1=0;
    var e2=1;
    for (var i = 0; i<n; i++) {
        // check a more general constraint than assignment
        // namely that out[i] is binary
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] -1 ) === 0;

        lc1 += out[i] * e2;
        e2 = e2+e2;
    }
    // deferred constraint check of out
    // checks the value assignments of out, as lc1 is computed from out
    lc1 === in;
}
component main {public [in]}= Num2Bits(3);
```

> This templates returns a n-dimensional array with the value of `in` in binary. Line 7 uses the right shift `>>` and operator `&` to obtain at each iteration the `i` component of the array. Finally, line 12 adds the constraint `lc1 = in` to guarantee that the conversion is well done.

That is, the constraints for this template can be specified more succinctly than simply checking for assignment. The circomlib implementation checks that:
- `out[i]` is binary (this could be stated even more succinctly with the `binary` tag in circom 2.1.0) 
- `out`'s assignments are accumulated in var `lc1`, which is value-checked at template's end.

#### Example 3: further examples
```rust
template QuadraticIntermediate() {
    // Intermediate calculations
    signal input x;
    signal output y; // = x*x+x+1
    signal squareX;

    squareX <-- x * x; 
    y <== squareX + x + 1; // includes check that x*x == squareX
} 

// By comparison, this template DOES require an intermediate constraint
// to avoid enforcing non-linear constraints.
template CubicIntermediate() {
    signal input x;
    signal output y; // = x*x*x + x + 1
    signal sqX;

    // sqX <-- x * x; // leads to non-linear constraint in final line
    sqX <== x * x;
    y <== sqX * x + x + 1; 
}

template IsEven() {
    signal input bigNumber;
    signal output isEven;
    signal remainder;

    // assign the intermediate value without constraint:
    remainder <-- bigNumber % 2;
    // enforce the constraint we actually want to check:
    isEven <== 1 - remainder;
}
```

### Common mistakes in underconstraining circuits
I was originally going to close with a section on common oversights in underconstrained circuits, but other resources have already done this well. I direct the reader toward the [0xPARC ZK bug tracker](https://github.com/0xPARC/zk-bug-tracker) in particular, an index of zk bugs in discovered in the wild, and a list of common oversights in constraining circuits, and Erhant's [circom101 book](https://circom.erhant.me/), which provides further examples of optimized and constrained circuits.

## Further Reading 
The following resources may provide further direction in writing correctly constrained Circom. 

### Recommended short reading
- [0xPARC ZK bug tracker](https://github.com/0xPARC/zk-bug-tracker) - a list of bugs and exploits found in zk applications. The list of [common vulnerabilities](https://github.com/0xPARC/zk-bug-tracker?tab=readme-ov-file#common-vulnerabilities-1) is particularly worth reviewing.
- [Circom constraint generation docs](https://docs.circom.io/circom-language/constraint-generation/) - an introduction to how constraints are generated; overlaps with the *basics* section given above.
- [Circom Anonymous Component documentation](https://docs.circom.io/circom-language/anonymous-components-and-tuples) - Circom 2.1.0 introduced anonymous components. While not directly related to circuit constraints, anonymous components allow for significantly more concise and expressive syntax in declaring components, reducing risk of developer error (i.e. the developer may incur less brain damage from writing Circom, the author recommends this)

### Recommended longer reading
- [circom101 book by erhant, author of circomkit](https://circom.erhant.me/) - Erhant's book is good supplementary material for the circom documentation, and details the implementation of several optimized circom templates.
- [0xPARC: circom workshop series](https://learn.0xparc.org/materials/circom/learning-group-1/intro-zkp) - a series of videos on zero knowledge generally, and circom in particular

### Also reviewed in preparation for this post
To save the reader some time in exploring resources, these posts were reviewed in preparation for this post and are briefly summarized for completeness, but are not recommended reading.

- [dacian: exploiting under-constrained zk circuits](https://dacian.me/exploiting-under-constrained-zk-circuits) - a walkthrough of correctly constraining a circom template that a value is not prime. Examples provided for:
    - asserting inputs values are not equal to one
    - range checking for to prevent multiplication overflow
- [veridise blog: circom pairing](https://medium.com/veridise/circom-pairing-a-million-dollar-zk-bug-caught-early-c5624b278f25) - somewhat in the weeds audit by Veridise found a bug in the `circom-pairing` library. The bug involves somewhat in-the-weeds elliptic curve cryptography trivia; namely than the output of a custom comparator, `BigLessThan`, is unconstrained, allowing for inputs to `CoreVerifyPubkeyG1` to accept inputs larger than the curve prime `q`. I didn't take anything away from this post.
- [blockdev: tips for safe circom circuits](https://hackmd.io/@blockdev/Bk_-jRkXa) - a high level notes pass on circom circuits

## License

Licensed under the Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)

## Contributing

We welcome contributions to our open-source projects. If you want to contribute or follow along with contributor discussions, join our [main Telegram channel](https://t.me/pluto_xyz/1) to chat about Pluto's development.

Our contributor guidelines can be found in [CONTRIBUTING.md](./CONTRIBUTING.md). A good starting point is issues labelled 'bounty' in our repositories.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be licensed as above, without any additional terms or conditions.
