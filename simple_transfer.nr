// simple_transfer.nr

// Import standard Pedersen hash for commitments
use dep::std::hash::pedersen;

// A confidential note type
struct Note {
    value: u64,
    blinding: Field,
}

// Computes a Pedersen commitment to (value, blinding)
fn note_commitment(note: Note) -> Field {
    // Pack the u64 into four u16s for hashing
    let limbs = [
        (note.value & 0xFFFF) as u16,
        ((note.value >> 16) & 0xFFFF) as u16,
        ((note.value >> 32) & 0xFFFF) as u16,
        ((note.value >> 48) & 0xFFFF) as u16,
    ];
    pedersen::hash_many([limbs[0], limbs[1], limbs[2], limbs[3], note.blinding])
}

fn main(
    // Public inputs
    old_commitment: Field,
    new_commitment: Field,
    fee: u64,

    // Private witnesses
    old_value: u64,
    old_blinding: Field,
    new_value: u64,
    new_blinding: Field,
) {
    // 1) Recompute commitments
    let old_note = Note { value: old_value, blinding: old_blinding };
    let new_note = Note { value: new_value, blinding: new_blinding };

    assert(note_commitment(old_note) == old_commitment);
    assert(note_commitment(new_note) == new_commitment);

    // 2) Soundness: no value created or destroyed
    //    old_value = new_value + fee
    assert(old_value == new_value + fee);

    // 3) Simple range checks (sanity)
    //    Ensure values are within a reasonable range
    assert(old_value <= 1_000_000_000);
    assert(new_value <= 1_000_000_000);
    assert(fee <= old_value);
}
