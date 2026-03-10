---
layout: page
title: Assembly-Level Formal Verification of HQC
permalink: /hqc-verification/
---

[proposal](/assets/hqc-verification-proposal.pdf)

---

### Month 1 — Foundation and Specification
**Goal:** Understand the toolchain and state the theorems you intend to prove, before writing any assembly.

- Study s2n-bignum's HOL Light proofs for ML-KEM NTT routines — focus on how ring axioms are established, how assembly functional specs are stated, and how the secret-independence (`secret_independent`) property is expressed as a HOL theorem
- Read the HQC specification document in full; write out in mathematical notation the exact specification of GF(2)[x]/(xⁿ − 1) multiplication that your assembly must satisfy
- Survey PCLMULQDQ (x86_64) or PMULL (AArch64) instruction semantics and how they map to binary polynomial multiplication
- **Deliverable:** A plain-English + HOL Light pseudocode statement of the two top-level theorems you will prove (polynomial multiplication correctness + constant-time)

---

### Month 2 — Binary Polynomial Multiplication: Assembly and Functional Correctness
**Goal:** Working assembly and a correctness proof for HQC-128 polynomial multiplication.

- Implement optimized x86_64 dense–dense polynomial multiplication for HQC-128 (n = 17669) using PCLMULQDQ-based Karatsuba decomposition followed by XOR-based reduction mod xⁿ − 1
- Write the HOL Light functional correctness proof: the assembly output equals the unique element of GF(2)[x]/(xⁿ − 1) equal to the product of the two input polynomials
- Prove the supporting lemmas needed to establish the binary ring axioms in HOL Light (likely reusable across all three parameter sets)
- **Deliverable:** Verified polynomial multiplication for HQC-128 with proof script passing HOL Light

---

### Month 3 — Constant-Time Proof and Multi-Parameter Extension
**Goal:** Secret-independence proof, then extend to HQC-192 and HQC-256.

- Prove in HOL Light that the polynomial multiplication assembly is secret-independent: the execution trace (PC sequence and memory access pattern) is a function only of the public input lengths, not the polynomial coefficients
- Because the dense–dense algorithm has no data-dependent branches or addressing, this proof is largely structural — budget time for any surprises in the reduction step
- Parametrize the assembly and proofs over n; generate and verify implementations for HQC-192 (n = 35851) and HQC-256 (n = 57637)
- **Deliverable:** Fully verified, constant-time polynomial multiplication for all three parameter sets

---

### Month 4 — Reed-Muller Decoder: FWHT Assembly and Proofs
**Goal:** Formally verified Fast Walsh–Hadamard Transform for Reed-Muller decoding.

- Implement the FWHT on 128-element binary vectors in assembly (butterfly network analogous to an NTT, but over GF(2))
- Prove functional correctness by induction over butterfly stages: the output is the Hadamard transform of the input, and the argmax recovers the maximum-likelihood decoded message
- Prove constant-time: no data-dependent branches, including in the peak-finding step (use a branchless argmax implementation)
- **Deliverable:** Verified FWHT assembly — this directly and formally invalidates the attack model of published RM decoder side-channel exploits

---

### Month 5 — Integration, RS Decoder Scoping, and Second Architecture
**Goal:** Unified verified module; plant a flag on Reed-Solomon; optionally start AArch64 port.

- Integrate polynomial multiplication and FWHT proofs into a single HOL Light theory representing HQC decapsulation's dominant computational path
- Formalize in HOL Light a precise *specification* (not full proof) of the GF(2⁸) syndrome computation in the Reed-Solomon decoder — this is a publishable partial result and a foundation for follow-up work
- If time permits, begin porting the polynomial multiplication assembly and proofs to AArch64 (PMULL); the proof structure is identical, only the instruction semantics differ
- **Deliverable:** Integrated proof module + formal RS decoder spec; optionally, AArch64 polynomial multiplication proof

---

### Month 6 — Paper Writing and Submission
**Goal:** Submit to TCHES.

- Write the full paper: motivation (HQC standardization + attack history), technical background (s2n-bignum model, HQC arithmetic), main results (correctness + constant-time theorems), proof methodology, performance of the verified assembly, and future work (RS decoder, AArch64 port if not complete)
- Prepare the proof artifact repository (clean, documented HOL Light scripts) for public release alongside submission
- Target the TCHES quarterly submission window; IEEE S&P is a secondary target if the scope has expanded to include partial RS decoder results
- **Deliverable:** Submitted paper + open-source verified implementation

---

### Summary View

| Month | Focus | Key Deliverable |
|-------|-------|----------------|
| 1 | Study + specification | Theorem statements in HOL pseudocode |
| 2 | Polynomial mult. assembly + correctness | Verified HQC-128 multiplication |
| 3 | Constant-time proof + HQC-192/256 | All parameter sets, constant-time certified |
| 4 | Reed-Muller / FWHT | Verified FWHT, RM decoder proved constant-time |
| 5 | Integration + RS scoping | Unified module + RS decoder formal spec |
| 6 | Paper writing | TCHES submission |
