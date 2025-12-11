// File: app.zk_rollup.nr
// SPDX-License-Identifier: MIT
// Minimal Aztec-style rollup step circuit.
//
// Proves:
//  - old note commitment opens to (old_value, old_blinding)
//  - new note commitment opens to (new_value, new_blinding)
//  - value conservation: old_value = new_value + fee

use dep::std::hash::pedersen;

struct Note {
    value: u64,
    blinding: Field,
}

/// Commitment scheme used for notes: Pedersen(value, blinding).
fn note_commitment(note: Note) -> Field {
    // Two-input Pedersen: [value, blinding].
    let inputs: [Field; 2] = [note.value as Field, note.blinding];
    pedersen(inputs)
}
/// Ensure the note's commitment matches a public commitment.
fn assert_note_matches_commitment(note: Note, expected_commitment: Field) {
    let computed = note_commitment(note);
    assert(computed == expected_commitment);
}

fn main(
    // public inputs
    /// Commitment for the input note being spent.
    public old_commitment: Field,
    /// Commitment for the output note being created.
    public new_commitment: Field,
    /// Public fee charged for this transfer.
    public fee: Value,


      // private witness for old note
    /// Secret value of the input note.
    old_value: Value,
    /// Secret blinding of the input note.
    old_blinding: Field,

    // private witness for new note
    /// Secret value of the output note.
    new_value: Value,
    /// Secret blinding of the output note.
    new_blinding: Field,


) {
    // Recompute commitments from the private witnesses
    let old_note = Note {
        value: old_value,
        blinding: old_blinding,
    };
    let new_note = Note {
        value: new_value,
        blinding: new_blinding,
    };
    // Value conservation: old_value = new_value + fee
    // No hidden value creation inside this rollup step.
    assert_value_conserved(old_value, new_value, fee);

    // Optional policy: disallow zero-fee transfers.
    assert(fee > 0);

       // Soundness constraints: witnesses must match public commitments
    assert_note_matches_commitment(old_note, old_commitment);
    assert_note_matches_commitment(new_note, new_commitment);


    // Value conservation: old_value = new_value + fee
    // No hidden value creation inside this rollup step.
    assert(old_value == new_value + fee);
    // Explicit check: cannot create value (old_value must be >= new_value).
    assert(old_value >= new_value);

     // Basic sanity checks
    assert(old_value > 0);
    assert(fee <= old_value);
    assert(new_value > 0);
}
