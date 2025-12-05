# noir-zk-soundness-rollup

Minimal Noir circuit that models a single confidential transfer step, inspired by web3 zk rollups and privacy projects such as Aztec, Zama, and soundness-focused proof systems.

The circuit proves that a transfer between two confidential notes is value preserving and consistent with publicly known commitments, without revealing the underlying balances.

Repository contains exactly two files:

1. app.zk_rollup.nr – Noir circuit with the rollup transfer proof
2. README.md – this documentation file

---

## Concept

High-level idea:

- We model a simple rollup-like state transition in Noir.
- Each balance is represented as a private note:
  - value (u64 amount)
  - blinding (Field randomness)
- A Pedersen commitment is used to bind the note contents to a public on-chain commitment, similar to how Aztec constructs commitments for notes.
- The circuit takes:
  - Public inputs:
    - old_commitment
    - new_commitment
    - fee
  - Private inputs:
    - old_value, old_blinding
    - new_value, new_blinding
- It enforces:
  - The private notes open to the provided public commitments.
  - Value conservation: old_value = new_value + fee.
  - Simple sanity constraints on amounts.

This pattern mirrors many web3 zk designs:

- Aztec-style rollups use commitments to hide individual balances while ensuring soundness via proofs.
- Zama-style FHE systems can feed encrypted results into circuits that are then proven correct.
- Soundness is preserved because no valid proof exists if any value is created from nothing.

---

## Features

The Noir circuit in app.zk_rollup.nr provides:

- A Note struct describing a confidential note with a value and blinding.
- A note_commitment function:
  - Builds a Pedersen hash commitment to (value, blinding).
- A main function that:
  - Recomputes commitments for old and new notes.
  - Checks that:
    - computed_old_commitment equals the public old_commitment.
    - computed_new_commitment equals the public new_commitment.
  - Enforces conservation of value via:
    - old_value = new_value + fee.
  - Ensures basic sanity on values:
    - old_value and new_value must be positive.
    - fee cannot exceed old_value.

This is intentionally minimal, focusing on the soundness core that zk and FHE stacks build upon.

---

## Repository structure

- app.zk_rollup.nr
  - Contains the Noir circuit, including the Note struct, commitment function, and main proof entry.
  - Uses dep::std::hash::pedersen to model a Pedersen hash commitment.
  - Designed as a single circuit file that can be dropped into a Noir project.

- README.md
  - The file you are reading, describing installation, usage, and conceptual background.

---

## Prerequisites

Before using this repository, you should have:

- Noir toolchain and Nargo installed from the official Noir documentation.
- A Rust toolchain if required by your Noir installer.
- A basic understanding of:
  - Zero-knowledge circuits.
  - Commitments and blindings.
  - How Aztec-style rollups or Zama-style cryptographic runtimes typically use proofs for soundness.

Assumptions:

- You are comfortable with command-line tools.
- You can create and manage Noir projects using Nargo.

---

## Installation

1. Create the project directory

- Choose a folder name, for example:
  - noir-zk-soundness-rollup

2. Create a new Noir package

- Use Nargo to scaffold a new Noir project inside this folder.
- You will obtain a standard Nargo project structure with a src directory and a Nargo.toml file.

3. Add the circuit file

- Inside the src directory, create a new file:
  - app.zk_rollup.nr
- Copy the contents of app.zk_rollup.nr from this repository into that file.

4. Connect the circuit to Nargo

You have two simple options:

- Option A: Make app.zk_rollup.nr the main circuit file:
  - Either rename app.zk_rollup.nr to main.nr, or
  - Update your Nargo.toml so that the package entry point points at app.zk_rollup.nr instead of the default file.

- Option B: Import app.zk_rollup.nr into your existing main.nr:
  - Keep your existing main.nr.
  - Use Noir module imports to call the circuit from app.zk_rollup.nr.
  - This is useful if you are integrating the circuit into a larger zk project.

5. Ensure standard library access

- The circuit expects the standard hash functions (Pedersen) to be available via dependency configuration in Nargo.toml.
- If your Noir version uses a different import path for Pedersen, adjust the use statement accordingly while preserving the structure of the circuit.

---

## Building the circuit

To build the Noir project:

1. Navigate to the project root (the folder containing Nargo.toml).
2. Run the Nargo build command for your Noir version.
3. Confirm that:
   - The project compiles successfully.
   - The compiler recognizes the app.zk_rollup.nr file and the main function as the circuit entry.

If you see issues related to imports or standard library paths:

- Check the spelling of dep::std::hash::pedersen.
- Check that your Nargo.toml lists the correct Noir version and dependencies.

---

## Proving and verifying

Once the circuit builds successfully, you can use Nargo to:

1. Generate a proof

- Prepare a witness file or Nargo input file containing the required data:
  - Public inputs:
    - old_commitment
    - new_commitment
    - fee
  - Private inputs:
    - old_value
    - old_blinding
    - new_value
    - new_blinding
- Run the command to prove the circuit with those inputs.
- Nargo will produce a proof artifact.

2. Verify a proof

- Use the Nargo verify command with the proof and public inputs.
- Verification should succeed if:
  - Commitments match the supplied witnesses.
  - The conservation equation old_value = new_value + fee holds.
  - Sanity constraints on the values are met.

3. Inspect outputs

- The circuit does not produce complex outputs; its main job is to assert constraints.
- A successful verification implies:
  - The rollup step is sound with respect to the model encoded in the circuit.
  - No value has been secretly created or destroyed.

---

## Integration with web3 and rollups

This Noir circuit is designed to be a building block for larger web3 systems:

- Aztec-style rollups:
  - Use commitments to hide per-user balances.
  - Rely on circuits similar to this one for proving soundness of transfers and updates.
  - May maintain full private note data off chain, while on chain stores only commitments and proofs.

- Zama-style FHE stacks:
  - Can process encrypted balances off chain.
  - Feed the resulting state into a Noir circuit to prove that encrypted computations and decrypted transitions are consistent.

- General soundness frameworks:
  - The key property enforced here is that the sum of outputs plus fees equals the sum of inputs.
  - This is the core of value soundness for many L2, rollup, and private payment designs.

Typical integration steps:

- Your L2 or rollup maintains:
  - A list of commitments representing user notes.
  - A mapping from public commitments to their underlying encrypted or private state.
- When a user wants to transfer value or withdraw:
  - Off chain, you construct a witness with:
    - old_value, old_blinding, new_value, new_blinding, fee.
  - You compute the corresponding commitments and feed them to the circuit.
  - After generating a proof, you submit:
    - The public inputs (commitments and fee).
    - The proof.
  - On chain, a verifier contract checks the proof and updates commitments if verification passes.

---

## Expected result

After setting up and running this repository in a Noir project, you should be able to:

- Compile the circuit without errors.
- Provide sample inputs and generate a proof that:
  - Shows the old note commitment and new note commitment correspond to the provided witnesses.
  - Demonstrates that the value relationship old_value = new_value + fee holds.
- Verify that:
  - Any attempt to violate value conservation results in a failing proof.
  - Any mismatched commitment or incorrect blinding also leads to verification failure.

Conceptually, the expected outcome is:

- A small, self-contained Noir circuit that can serve as a soundness kernel for confidential transfers.
- A starting point you can extend to full rollup state updates, multi-note joins and splits, or more advanced Aztec and Zama style workflows.

---

## Notes and limitations

- The circuit is intentionally simplified:
  - It uses a single input note and a single output note plus a fee.
  - Real protocols often use multiple inputs and outputs, nullifiers, and Merkle tree checks.
- Privacy:
  - Only the commitments and fee are public.
  - The circuit assumes old_value, new_value, and blindings are private witnesses.
  - Additional constraints may be needed to achieve strong privacy guarantees in a real deployment.
- Security:
  - This repository does not include:
    - On-chain verifier implementations.
    - Key management or wallet integration.
    - Full rollup or bridging logic.
- Version compatibility:
  - Noir is evolving; syntax and library paths may change.
  - If compilation fails, adapt the imports and main signature to match your Noir version while preserving the circuit structure.

---

## Future extensions

To extend this repository into a more complete web3 protocol component, you can:

- Add support for:
  - Multiple input and output notes.
  - Nullifier checks to prevent double spending.
  - Merkle path membership proofs for notes in a commitment tree.
- Integrate with:
  - A smart contract or L1 verifier that checks Noir proofs on chain.
  - A rollup operator that aggregates many such transitions into a batch proof.
- Combine with FHE or advanced cryptography by:
  - Using Zama-style encrypted computation to update balances off chain.
  - Feeding the results back into Noir circuits for public verification of correctness.
- Extend the README with:
  - Concrete Nargo command examples tailored to your tooling version.
  - Example input files for running local proofs and verifications.

This repository is meant to be a compact, easy-to-read starting point for experimenting with Noir, web3 rollups, and soundness guarantees inspired by Aztec, Zama, and general zk ecosystems.

