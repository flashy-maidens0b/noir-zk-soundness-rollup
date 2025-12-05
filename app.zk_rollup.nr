// File: app.zk_rollup.nr

use dep::std::hash::pedersen;

/// Minimal Noir circuit modelling a confidential transfer step
/// for an Aztec-style rollup. It proves:
///  - The old note commitment opens to (old_value, old_blinding)
///  - The new note commitment opens to (new_value, new_blinding)
///  - Value is conserved: old_value = new_value + fee
/// Real zk / FHE systems like Aztec, Zama, and other soundness-focused
/// frameworks can build on top of this style of constraint system.

struct Note {
    value: u64,
    blinding: Field,
}

fn note_commitment(note: Note) -> Field {
    let inputs: [Field; 2] = [note.value as Field, note.blinding];
    pedersen(inputs)
}
// -----------------------------------------------------------------------------
// Circuit entrypoint
// -----------------------------------------------------------------------------

fn main(
    // public inputs
    public old_commitment: Field,
    public new_commitment: Field,
    public fee: u64,

    // private witness for old note
    old_value: u64,
    old_blinding: Field,

    // private witness for new note
    new_value: u64,
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

    let computed_old_commitment = note_commitment(old_note);
    let computed_new_commitment = note_commitment(new_note);

    // Soundness constraints: witnesses must match public commitments
    assert(computed_old_commitment == old_commitment);
    assert(computed_new_commitment == new_commitment);

    // Value conservation: old_value = new_value + fee
    // No hidden value creation inside this rollup step.
    assert(old_value == new_value + fee);

    // Basic sanity checks
    assert(old_value > 0);
    assert(new_value > 0);
    assert(fee <= old_value);
}
