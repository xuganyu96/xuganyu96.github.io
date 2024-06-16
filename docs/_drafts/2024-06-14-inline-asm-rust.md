I want to measure the performance of some Rust code using CPU cycles. According to [ARM's instruction](https://developer.arm.com/documentation/ddi0595/2021-06/AArch64-Registers/PMCCNTR-EL0--Performance-Monitors-Cycle-Count-Register), the system register `PMCCNTR_EL0` holds the value of the CPU cycles.

Rust has the capability of inline assembly just like C. The example first uses the `isb` instruction to flush the CPU pipeline so that all prior instructions finish executing before the instruction after `isb` is fetched, decoded, or executed. Then the `mrs` moves the value in some system register into the variable `val`.

```rust
fn get_cycles() -> u64 {
    let value: u64;

    unsafe {
        core::arch::asm!(
            "isb",
            "mrs {0}, PMCCNTR_EL0",
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

For some unknown reason, I get "illegal hardware instruction" in Apple M1.