# directed-rounding

(zig) software emulation of all CPU rounding modes for a RTNE platform

## Purpose

On many platforms (WASM, embedded, ...), either the hardware doesn't provide access to rounding mode swaps, or the VM doesn't expose that functionality to the end user. Certain applications (like RandomX hashing) absolutely require bit-for-bit identical floating point results, however, necessitating some solution like the current library.

## Status

All rounding-dependent operations necessary for RandomX are implemented (add, sub, mul, div, sqrt). Addition and subtraction work for all native Zig float types, but mul, div, and sqrt internally use floats of twice the bit-width of their inputs, meaning they only work for f16, f32, and f64 (and, on most platforms, the f64 implementation will use a slow, soft float implementation under the hood, incurring a ~5x slowdown).

I plan to leave this project alone for a few days or weeks while I clean-room a RandomX implementation. The underlying ideas in this code are proven on paper, and I exhaustively tested some version of each of these algorithms across all f16 inputs (and randomly tested against tens of billions of f32 and f64 inputs), but the current iteration may very well have bugs. I don't plan to work on this repository till my RandomX implementation is complete -- either finding that this repo is flawless, or using that particular more battle-tested repo to guide the bug fixes here.
