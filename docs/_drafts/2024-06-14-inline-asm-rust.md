```rust
fn get_cycles() -> u64 {
    let value: u64;

    unsafe {
        core::arch::asm!(
            "isb",
            "mov {0}, 42",  // this works
            // "mrs {0}, PMCCNTR_EL0",
            out(reg) value,
        );
    }

    return value;
}


fn main() {
    let val1 = get_cycles();
    let val2 = get_cycles();

    println!("{} cycles elapsed", val2 - val1);
}
```