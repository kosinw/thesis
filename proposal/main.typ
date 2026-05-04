#import "@preview/springer-spaniel:0.1.0"
#import "@preview/theorion:0.4.1": *
#import "@preview/commute:0.3.0": node, arr, commutative-diagram

#show: show-theorion

#show: springer-spaniel.template(
  title: [Verifying Side-Channel Security for Out-of-Order Machines],
  authors: (
    (
      name: "Kosi Nwabueze",
      institute: "Department of Electrical Engineering and Computer Science",
      address: "Massachusetts Institute of Technology",
      email: "kosinw@mit.edu"
    ),
  ),
  abstract: [
    In this proposed thesis, I aim to work towards an at-scale, machine-checked security proof, formalized in the Rocq proof assistant, for a realistic, synthesizable out-of-order processor.
    This security proof shows that the reference processor only leaks information as if it were a sequentially executing machine that leaks branch targets, addresses of loads and stores, and operands of variable-latency instructions.
    In particular, this proposed thesis will constitute one component of that larger proof---focusing on establishing necessary correctness and security results for the register-renaming logic in the processor's frontend.
  ],
)

#pagebreak()

#show outline.entry.where(level: 2): set block(above: 1.4em)
#show outline.entry.where(level: 1): set block(above: 2em)
#outline()

#pagebreak()

= Introduction

Modern processors employ a litany of sophisticated microarchitectural optimizations for increased performance.
Before the Meltdown @lipp2018 and Spectre @kocher2019 attacks in 2018, computer architectures emphasized ensuring that new optimizations preserved correctness rather than security.
However, these attacks have shown that even seemingly correct microarchitectures are still insecure.
Secret information can still leak through timing side-channels.
Since then, security researchers have focused on developing defenses against speculative-execution attacks.
However, how do we ensure that the defenses themselves correctly ensure processor security?

Using the tools of formal verification, we can state what it means for a processor to be secure according to leakage-based semantics.
While the formulation of these security properties is understood in the literature, producing an at-scale machine-checked proof for a synthesizable processor is not quite clear.
Producing components of this mechanized proof and the necessary invariants for such a result is the goal of this proposed thesis.
In particular, we present a case study in this direction by establishing both correctness and security results for the register-renaming logic.

== Constant-Time Programming

Side-channel attacks exploit the fact that executions of a program are not a black box: attackers may still observe branch targets, memory accesses, and operands of variable-latency instructions.
Attacker observable events are called _leakage events_. During execution, a program accumulates these leakage events into a _leakage trace_.
In order to write "safe" programs that avoid leaking secret data, cryptographers have adopted a design principle called _constant-time_ programming.
We say a program is _(cryptographic) constant-time_ if its leakage trace is independent of secret data.

#definition(title: [Hyperproperty constant time])[
  A program $p$ is _constant-time_ with respect to the security projection $sans("pub")$ if for any two initial configurations $sigma_1, sigma_2$ such that $(sigma_1)_sans("pub") approx.eq (sigma_2)_sans("pub")$, the leakage trace of $(p, sigma_1)$ is indistinguishable from the leakage trace of $(p, sigma_2)$.
] <hyperproperty>

A security projection $sans("pub")$ distinguishes which parts of the program configuration are public from which parts are secret.
Another equivalent, yet more convenient definition of _constant time_ is the formulation as a single-copy property @conoly2025.


#definition(title: [Single-copy constant time])[
  A program $p$ is _constant time_ with respect to the security projection $sans("pub")$ if there exists a function $f_sans("predict")$ such that for every initial configuration $sigma$, the leakage trace of $(p, sigma)$ is $f_sans("predict")(sigma_sans("pub"))$.
] <single-copy>

@hyperproperty formulates _constant time_ as a hyperproperty of the program, meaning that proofs reason about multiple executions of the program simultaneously,
while @single-copy formulates _constant time_ as a single-copy property, meaning that proofs reason about a single execution of the program.
We prefer the single-copy formulation, as it is generally more elegant to reason about when compared to the hyperproperty formulation.


== Out-of-Order Execution
Out-of-order execution dynamically reorders instructions to eliminate dataflow dependencies and overall improve instruction throughput.
However, the combination of instruction reordering and speculative execution may introduce side-channel leakage of potentially secret data that a sequential machine would not leak.
For example, a load-store queue may receive transient loads during misspeculated execution, potentially leaking secret data accesses to attackers according to our threat model.

In my proposed thesis, I will study a reference processor with two different secure speculation defenses.
First, we will consider a defense that prohibits the reorder buffer from issuing loads and branches if there are unresolved younger branches.
This defense greatly reduces cycles-per-instruction (CPI) performance; however, a proof of security for this defense would be easier than more sophisticated defenses.
As a future extension, we will consider adapting the proof to a processor that uses a variant of speculative taint tracking as a defense @yu2019.

= Related Work

== Hardware-Software Contracts
_Guarnieri et al._ @guarnieri2021 introduces the concept of hardware-software contracts for secure speculation.
Contracts formalize hardware defenses for secure speculation by specifying what _information is leaked_ and _which paths are explored_ as allowed by the defense.
The paper investigates a model of an out-of-order processor with speculative taint tracking (STT) and concludes that the defense satisfies a contract that leaks branch targets, addresses of loads and stores, and operands of variable-latency instructions.
The defense also leaks values of load instructions on non-speculative paths.
Although we do not use the exact formulation of hardware-software contracts in our work, our approach is closely related to the ideas presented in the paper.
The strongest limitation of this work is that it only considers abstract models of processors, rather than any concrete design that could be synthesized from a hardware-description language.

== Kami
Kami @choi2017 is a library for hardware circuit specification and verification formalized in the Rocq proof assistant.
It is a domain-specific language, roughly based on Bluespec SystemVerilog, for specifying hardware circuits and verifying their correctness via modular reasoning and refinement arguments.
Kami is a deeply embedded hardware-description language, meaning that it is a language for describing hardware circuits that is itself implemented in the Rocq proof assistant.
In the original paper introducing Kami, the authors present a case study in which they verify the functional correctness for a multicore system.
Using the Kami language, the authors constructed the overall circuit by composing together smaller modules.
Furthermore, they can independently reason about the correctness of each module and later use algebraic laws regarding refinement to compose together the total correctness proof.
Further work @duxovni2018 explores expanding beyond functional correctness proofs into security proofs using Kami.
Although my work does not directly use Kami, many of the ideas around semantics and proof techniques are closely related.

// TOOD: citations
// - Securing Cryptographic Software via Typed Assembly Language (CCS '25)
// - Specification and Verification of Strong Timing Isolation of Hardware Enclaves (CCS '24)
// - Smooth, Integrated Proofs of Cryptographic Constant Time for Nondeterministic Programs and Compilers (PLDI '25)

= Proposed Work
For my thesis work, I propose writing a machine-checked proof ensuring security for the register-renaming logic in a custom out-of-order processor design.
Using an embedded hardware description language, I will first design the processor itself in Rocq.
Then, I will verify the correctness of the processor's frontend, which includes the register-renaming logic.
My results will serve as an important step towards a complete security proof over the entire processor.

== Encoding Hardware Circuits
So far, most of the verification work has been completed using a shallow embedding based on _guarded state monads_.
Reasoning about programs defined in a shallow embedding requires less bureaucracy when compared to performing similar reasoning using a deep embedding.
Shallow embeddings are more desirable for exploring proof ideas.
Using _state monads_, we can encode imperative-style computations directly as Gallina programs.
Like all monads, the state monad ($sans("State")$) has two fundamental operations: "return" and "bind".

#set math.equation(numbering: none)
$
sans("ret") quad &:: quad forall alpha . med alpha -> sans("State") med alpha \
sans("ret") quad &:= quad lambda x . med lambda s . med chevron.l s, x chevron.r \
sans("bind") quad &:: quad forall alpha . med forall beta . med sans("State") med alpha -> (alpha -> sans("State") med beta) -> sans("State") med beta \
sans("bind") quad &:= quad lambda m . med lambda f . med lambda s . med sans("let") (s', x) := m med s sans("in") f med x med s'
$

Computations defined using state monads take a state and return a new state and a value. The "return" operation lifts a value into the state monad, while the "bind" operation composes two computations together. The state monad also features the operations "get", "put", and "modify" that correspond to reading, writing, and modifying the state, respectively.

$
sans("get") quad &:: quad forall sigma. sans("State") med sigma \
sans("get") quad &:= quad lambda s . med chevron.l s, s chevron.r \
sans("put") quad &:: quad forall sigma. sigma -> sans("State") med sans("unit") \
sans("put") quad &:= quad lambda s . med chevron.l s, t chevron.r \
sans("modify") quad &:: quad forall sigma. (sigma -> sigma) -> sans("State") med sans("unit") \
sans("modify") quad &:= quad lambda f . med lambda s . med chevron.l t t, f med s chevron.r \
$

Furthermore, we define a _guarded state monad_ ($sans("Action")$) as a state monad that permits failure.
These monads are guarded in the Bluespec sense, meaning that if some condition is not satisfied, the computation will fail.
We redefine the state monad to instead return an inductive type that represents either _success_ ($sans("Success")$), returning a value and a new state; or _failure_ ($sans("Failure")$), representing a failed computation.
We introduce the new operators "abort" and "guard" that allow a computation to express failure.

$
sans("abort") quad &:: quad forall alpha . med sans("Action") med alpha \
sans("abort") quad &:= quad lambda s . med sans("Failure") \
sans("guard") quad &:: quad forall sigma . med (sigma -> bb(B)) -> forall alpha . med sans("Action") med alpha -> sans("Action") med alpha \
sans("guard") quad &:= quad lambda p . med lambda m . med lambda s . med sans("if") (p med s) sans("then") m med s sans("else") sans("abort") med s \
$

Combined with the notation facility built into the Rocq proof assistant, we can define an embedded language for imperative-style computations together with the guarded state monad.

== Security

In a similar manner to how we defined _constant time_ for programs, we can also define _constant time_ for hardware circuits. First, we give a mathematical description of what a hardware circuit is.

#definition(title: [Hardware circuits])[
  A hardware circuit $cal(C)$ is a 3-tuple $(S, S_0, M)$ where $S$ is a set of states,
  $S_0 in S$ is the reset state of the circuit, and $M$ is a list of methods that the circuit can execute.
]

We treat hardware circuits as transition systems that "step" whenever a method is executed.
A method execution may not necessarily correspond to a hardware clock-cycle transformation but instead represent sub-cycle behaviors.
Similar to Bluespec semantics, we consider the method execution to be atomic and non-interleaving; however, they may and should be synthesized as parallel operations.
Each method may also choose to extend the leakage trace of the circuit internally as part of its execution.
However, unlike Bluespec semantics, we allow multiple reads and writes to the same register across multiple method executions.
In practice, interleaved register reads and writes would be synthesized using an _ephemeral history register_ @rosenband2004.
Akin to @single-copy for software programs, we define _constant time_ for hardware circuits as a single-copy property.

#definition(title: [Hardware constant time])[
  A hardware circuit $cal(C) = (S, S_0, M)$ is _constant-time_ with respect to a security function $f_sans("pub")$ if there exists a function $f_sans("predict")$ such that for any history of executed methods $cal(H)$, the leakage trace starting from state $S_0$ is $(f_sans("predict") compose f_sans("pub"))(cal(H))$.
]

Similar to the security projection for programs, we define a security function $f_sans("pub")$ that distinguishes which parts of the method-execution history are public and which parts are secret. In other words, each method has some public and some private inputs, and $f_sans("pub")$ extracts only the public parts of all the inputs.

Given some circuit $cal(C)$, we construct a proof of hardware constant time by following a simulation argument.

#definition(title: [Simulation with respect to $f$])[
  A binary relation $R subset.eq S times S'$ is a simulation w.r.t a security function $f_sans("pub")$ for hardware circuits $cal(C) = (S, S_0, M)$ and $cal(C') = (S', S_0', M')$ if for all states $s_1 in S$ and $s'_1 in S'$, $s_1 med R med s'_1$ and $s_1$ steps to $s_2$ using method $m$ with inputs $I$, then there exists some $s'_2$ (with zero or more methods) such that $s_2$ steps to $s'_2$ only knowing $f_sans("pub")(I)$.
]

We show that there exists another circuit $cal(C')$ and some binary relation $R$ such that for every "step" that $cal(C)$ takes, there exists some "step" that $cal(C')$ can take without knowledge of secret method inputs such that the relation $R$ is preserved. We combine this simulation argument paired with an argument that states of $cal(C)$ and $cal(C')$ that are related by $R$ have the same leakage trace to give the following theorem.

#theorem(title: [Hardware constant time by simulation])[
  A hardware circuit $cal(C)$ is constant time with respect to a security function $f_sans("pub")$ if there exists a hardware circuit $cal(C')$ and a binary relation $R subset.eq S times S'$ such that $R$ is a simulation with respect to $f_sans("pub")$ for $cal(C)$ and $cal(C')$ and for all states $s in S$ and $s' in S'$, $s med R med s'$ implies the leakage trace of $s$ is the same as the leakage trace of $s'$.
]

#proof[
  Construct $f_sans("predict")$ by iteratively feeding each method from the input method history $cal(H')$ through circuit $cal(C')$.
  Since we know that $R$ is a simulation, then it is preserved after feeding all of $cal(H')$ through $cal(C')$.
  Then, by the fact that the relation implies the leakage traces are the same, we know that our constructed $f_sans("predict")$ must give the same leakage trace as just running $cal(H)$ through $cal(C)$.
]

== Case Study: Multiplier
Our first case study for our verification techniques will be a 32-bit integer multiplier circuit.
The multiplier is a sequential circuit that computes products via shift-and-add.
The multiplier has methods with the following signatures:
$
  sans("enq") &:: sans("Bit") med 32 * sans("Bit") med 32 -> sans("Action") med sans("unit") \
  sans("tick") &:: sans("unit") -> sans("Action") med sans("unit") \
  sans("deq") &:: sans("unit") -> sans("Action") med (sans("Bit") med 32) \
$

$sans("enq")$ enqueues two 32-bit words onto the multiplier (unless it is busy).
$sans("tick")$ is a method that advances the multiplier's state by one stage (for 32 stages).
$sans("deq")$ dequeues the product from the multiplier once the result is finished (otherwise it aborts).
This multiplier has a peculiar behavior when the first input to $sans("enq")$ is 0.
The multiplier will "short-circuit," meaning the product will be 0 after only one call to $sans("tick")$.

The leakage model for this multiplier is simple: whenever the product is dequeued, the leakage trace records that the multiplier has produced a product (but not the actual value of the product itself).

The multiplier circuit serves as a good litmus test for our verification techniques.
It is a simple circuit that is easy to reason about and has a clear leakage model.
It also has a peculiar behavior that is easy to reason about and that we can use to test our verification techniques.
Another insight is that whether or not this multiplier is constant-time depends on which particular $f_sans("pub")$ we choose.
Changing $f_sans("pub")$ corresponds to the capabilities of the attacker in our threat model.
A more permissive $f_sans("pub")$ (i.e. more method inputs are public) corresponds to a more capable attacker.

We will use the least permissive $f_sans("pub")$ for this circuit that is still hardware constant-time.
$f_sans("pub")$ hides both operands to $sans("enq")$ but keeps whether the first input is zero.
For proofs of this style, the central insight behind the proof relies on choosing a good simulation relation $R$.
In this case we choose the other circuit $cal(C')$ to have state that tracks the stage of the multiplier (either waiting, busy, or full) and state that tracks a countdown until the current computation is complete.
The relation $R$ just relates the stages of $cal(C)$ and $cal(C')$ and relates the countdowns.
The proof that this relation is a simulation follows quite briefly in Rocq with proof automation.

== Case Study: Pipelined Processor
The second case study will be a 4-stage pipelined processor based on the RV32I instruction set architecture.
The circuit has the following methods with the following signatures:
$
  sans("tick") &:: sans("unit") -> sans("Action") med sans("unit") \
  sans("toImem") &:: sans("unit") -> sans("Action") med sans("IMemoryRequest") \
  sans("fromImem") &:: sans("IMemoryResponse") -> sans("Action") med sans("unit") \
  sans("toDmem") &:: sans("unit") -> sans("Action") med sans("DMemoryRequest") \
  sans("fromDmem") &:: sans("DMemoryResponse") -> sans("Action") med sans("unit")
$

The methods above besides $sans("tick")$ serve as an interface between the processor and the memory system.
The "to" methods are requests from the processor to the memory system, while the "from" methods are responses from the memory system to the processor.
$sans("tick")$ is a method that advances each of the processor's pipeline stages forward by one stage (for 4 stages) if possible.

The leakage model for this processor works as follows: (1) whenever the processor requests a data-memory access, the leakage trace records the address of the memory access.
(2) Whenever the processor executes a variable-latency multiply instruction, the leakage trace records the first operand of the multiply instruction.
(3) Whenever the processor resolves a branch, the leakage trace records the branch target.

The $f_sans("pub")$ for this processor partitions the data memory into two regions: a private region and a public region.
Addresses for the public region have the uppermost bit set to 0, while addresses for the private region have the uppermost bit set to 1.
Only the values of the private region are removed from method inputs.

The simulation relation for the processor is much more sophisticated than the multiplier and relies on reasoning about invariants between different pipeline stages with an alternate 4-stage pipelined processor that does not receive any data-memory responses from the secret region.

== Goal: Register Renaming
The next steps for this thesis will be to verify the correctness and security of the register-renaming logic.
The details surrounding the design, leakage model, the particular security function, and the simulation relation for the register-renaming logic are still being worked out at this point.

#pagebreak()

== Proposed Timeline

#table(
  columns: (0.9fr, 2.1fr),
  align: (left, left),
  inset: 6pt,
  stroke: 0.5pt + gray,
  strong[Month],
  strong[Deliverables],
    [Dec 2025],
    [
      Review the computer architecture of out-of-order processors and design a cycle-accurate model of a reference processor in Rust.
      Clean up existing artifacts from the multiplier and pipelined processor case studies.
    ],
    [Jan 2026],
    [
      Begin learning Elvis's hardware description language and implement the out-of-order processor in Rocq using this language.
    ],
    [Feb 2026],
    [
      Begin working on the proof for the out-of-order processor.
    ],
    [Mar 2026],
    [
      Continue working on the proof for the out-of-order processor.
    ],
    [Apr 2026],
    [
      Continue working on the proof for the out-of-order processor.
      Finish the proof to the point where we can present correctness and security theorems for just the renaming logic as standalone results.
      Start working on the final thesis report.
    ],
    [May 2026],
    [
      Work on the final thesis report.
    ],
)

#pagebreak()

#bibliography(style: "ieee", "refs.bib")