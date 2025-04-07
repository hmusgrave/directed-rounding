# directed-rounding

(zig) software emulation of all CPU rounding modes for a RTNE platform

## Purpose

On many platforms (WASM, embedded, ...), either the hardware doesn't provide access to rounding mode swaps, or the VM doesn't expose that functionality to the end user. Certain applications (like RandomX hashing) absolutely require bit-for-bit identical floating point results, however, necessitating some solution like the current library.

## Status

I just started. Addition, subtraction, and square roots are flawless for all native Zig float types. I plan to implement the remaining operations required for RandomX within a few days or weeks.
