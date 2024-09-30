<h1 align="center">
  A succinct reference to correctly constraining circuits
</h1>

<div align="center">
  <a href="https://github.com/pluto/circom-correctly-constrained/graphs/contributors">
    <img src="https://img.shields.io/github/contributors/pluto/circom-correctly-constrained?style=flat-square&logo=github&logoColor=8b949e&labelColor=282f3b&color=32c955" alt="Contributors" />
  </a>
  <a href="https://github.com/pluto/circom-correctly-constrained/actions/workflows/test.yaml">
    <img src="https://img.shields.io/badge/tests-passing-32c955?style=flat-square&logo=github-actions&logoColor=8b949e&labelColor=282f3b" alt="Tests" />
  </a>
  <a href="https://github.com/pluto/circom-correctly-constrained/actions/workflows/lint.yaml">
    <img src="https://img.shields.io/badge/lint-passing-32c955?style=flat-square&logo=github-actions&logoColor=8b949e&labelColor=282f3b" alt="Lint" />
  </a>
</div>

## Overview
This repo is a reference on correctly testing and constraining circom circuits, with example workflows and reference patterns.

### Tools and resources considered

#### tools
- [circomkit circom testing suite](https://github.com/erhant/circomkit)
    - [examples](https://github.com/erhant/circomkit-examples)
- [circomspect static analyzer and linter for circom](https://github.com/trailofbits/circomspect)
    - [ToB blog: it pays to be circomspect](https://blog.trailofbits.com/2022/09/15/it-pays-to-be-circomspect/)
    - [ToB blog: circomspect has more passes](https://blog.trailofbits.com/2023/03/21/circomspect-static-analyzer-circom-more-passes/)
- [zksecurity circomscribe - demo playground, visualize constraints ](https://www.circomscribe.dev/)
    - [blog post about circomscribe](https://www.zksecurity.xyz/blog/posts/circomscribe/)
- [Picus QED uniqueness property underconstraint checker](https://github.com/Veridise/Picus)
- [circom-mutator](https://github.com/aviggiano/circom-mutator) - test whether mutations of correct circuit actually fail by fuzzing

#### more reading about underconstrained circuits
- [circom constraining docs](https://docs.circom.io/circom-language/constraint-generation/)
- [circom docs: --inspect option](https://docs.circom.io/circom-language/code-quality/inspect/)
- [veridise blog: circom pairing](https://medium.com/veridise/circom-pairing-a-million-dollar-zk-bug-caught-early-c5624b278f25)
- [dacian: exploiting under-constrained zk circuits](https://dacian.me/exploiting-under-constrained-zk-circuits)
- [blockdev: tips for safe circom circuits](https://hackmd.io/@blockdev/Bk_-jRkXa)
- [circom101 book by erhant, author of circomkit](https://github.com/erhant/circom101/tree/main)
- [0xparc: circom workshop series](https://learn.0xparc.org/materials/circom/learning-group-1/intro-zkp)
- [paper by veridise on underconstrained circuits](https://eprint.iacr.org/2023/512.pdf)

## State of the Tools 

### [circomspect static analyzer and linter for circom](https://github.com/trailofbits/circomspect)
`circomspect` is a static analyzer and linter for Circom.
- install: `cargo install circomspect`
- run: `circomspect $CIRCUIT_PATH`
    - e.g.: `circomspect circuits/multiplier.circom`. `circomspect` will flag underconstrained templates, but will not flag the overconstrained circuit.

More about circomspect by Trail of Bits. These blog posts briefly describe the tool and a few of the passes performed by `circomspect`. They are summaries of the `circomspect` in context, but not important for using the tool.
- [ToB blog: it pays to be circomspect](https://blog.trailofbits.com/2022/09/15/it-pays-to-be-circomspect/)
- [ToB blog: circomspect has more passes](https://blog.trailofbits.com/2023/03/21/circomspect-static-analyzer-circom-more-passes/)

It would be good if there were CI to run circomspect, but that does not currently seem to be available.

## License

Licensed under the Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)

## Contributing

We welcome contributions to our open-source projects. If you want to contribute or follow along with contributor discussions, join our [main Telegram channel](https://t.me/pluto_xyz/1) to chat about Pluto's development.

Our contributor guidelines can be found in [CONTRIBUTING.md](./CONTRIBUTING.md). A good starting point is issues labelled 'bounty' in our repositories.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be licensed as above, without any additional terms or conditions.
