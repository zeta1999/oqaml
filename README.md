# OQaml

OQaml is a reference implementation of the Quantum Abstract Machine (QAM) outlined in _R. Smith, M. J. Curtis and W. J. Zeng, "A Practical Quantum Instruction Set Architecture," (2016)_, [arXiv:1608.03355 [quant-ph]](https://arxiv.org/abs/1608.03355). The purpose of OQaml is to demonstrate the conceptual similarities between a classical state machine and a Quantum state machine. It highlights the facts in which functional programming lends itself ideally to the operations on a quantum state as it enforces deliberate actions to force side-effects, i.e. interactions with the environment.

OQaml currently support ProtoQuil (a subset of the full Quil instruction language) which includes one- and two-qubit gate instructions as well as a full state measurement.

## Getting started
### Setting up the environment
To hit the ground running to interact with OQaml you need to set up your OCaml environment as described in a short [OQaml setup guide](./readmes/oqaml_setup.md). The best way to interact with OQaml is the use of [utop](https://opam.ocaml.org/blog/about-utop/). A more general guide how to set up a good OCaml environment can be found in the [RealWorldOCaml instructions](https://github.com/realworldocaml/book/wiki/Installation-Instructions).

OQaml actively uses [Owl](https://github.com/ryanrhymes/owl) and JaneStreet's [Core_extended](https://ocaml.janestreet.com/ocaml-core/111.21.00/doc/core_extended/). Both of which can be easily install using [Opam](https://opam.ocaml.org/). Note, however, that some functionality of OQaml requires the latest changes to the development branch of Owl, which is not yet available on Opam.

### Installing OQaml

If you have already have a working OCaml environment you can install OQaml by cloning this repository and run.

```bash
make oasis
make install
```
from the repository root. This will install OQaml into your OCaml environment.

### Interacting with the Ocaml QVM
If all functionality is installed then interactions with the OQaml QVM are best done using utop running

```bash
utop
```

This drops you into a OCaml REPL and you can start loading modules and interact with the QVM.

```ocaml
utop[0]> #require "oqaml";;
utop[1]> #require "owl";;
utop[2]> module V = Owl.Dense.Vector.C;;
module V = Owl.Dense.Vector.C
utop[3]> module Q = Oqaml;;
module Q = Oqaml
utop[4]> let tqvm = Q.init_qvm 3;;
val tqvm : Q.qvm = {Q.num_qubits = 3; wf =
        C0
R0 (1, 0i)
R1 (0, 0i)
R2 (0, 0i)
R3 (0, 0i)
R4 (0, 0i)
R5 (0, 0i)
R6 (0, 0i)
R7 (0, 0i)

;
reg = [|0; 0; 0;|]}
utop[5]> let is = Q.INSTRUCTIONSET([Q.Y 2; Q.CNOT (0,1); Q.X 0]);;
val is : Q.instruction_set = Q.INSTRUCTIONSET [Q.Y 2; Q.CNOT (0, 1); Q.X 0]
utop[6]> Q.apply_instructions is tqvm;;
- : Q.qvm = {Q.num_qubits = 3; wf =
        C0
R0 (0, 0i)
R1 (0, 0i)
R2 (0, 0i)
R3 (0, 0i)
R4 (0, 0i)
R5 (0, 0i)
R6 (0, 0i)
R7 (0, 1i)

;
reg = [|0; 0; 0;|]}
```

Note that the instructions in the set `is` are executed from right to left in the way quantum-mechanical notation acts on an intial state.

## Building the docs
To build the API docs you can run

```bash
make oasis
make docs
```

This will create a subfolder containing an HTML project that exposes all public APIs of OQaml.

## Development and Testing
The test infrastructure uses [Alcotest](https://github.com/mirage/alcotest). To run the tests you can execute

```bash
opam install alcotest
make oasis-test
```


## How to cite OQaml

If you use the reference-qvm please cite the repository as follows:

bibTex:
```tex
@misc{oqaml2017.0.0.1,
  author = {Rigetti Computing},
  title = {OQaml},
  year = {2017},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/rigetticomputing},
  commit = {the commit you used}
}
```

and the paper outlining the mathematical specification of the quantum-abstract-machine:

bibTeX:
```tex
@misc{1608.03355,
  title={A Practical Quantum Instruction Set Architecture},
  author={Smith, Robert S and Curtis, Michael J and Zeng, William J},
  journal={arXiv preprint arXiv:1608.03355},
  year={2016}
}
```