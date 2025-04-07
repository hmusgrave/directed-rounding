const std = @import("std");
const round_mode = @import("round_mode.zig");

fn MulF(F: type) type {
    // every multiplication (:F) * (:F) can be exactly
    // represented in a result type of size 2F, at least
    // for the IEEE-754 definitions of f16, f32, f64, f128
    return @Type(.{ .Float = .{ .bits = 2 * @bitSizeOf(F) } });
}

pub fn mul(F: type, a: F, b: F, comptime mode: round_mode.RoundMode) F {
    return switch (mode) {
        .Up => mul_up(F, a, b),
        .Down => mul_down(F, a, b),
        .Even => mul_nearest(F, a, b),
        .Trunc => mul_trunc(F, a, b),
    };
}

fn mul_nearest(F: type, a: F, b: F) F {
    @setFloatMode(.strict);
    return a * b;
}

fn mul_trunc(F: type, a: F, b: F) F {
    @setFloatMode(.strict);

    const guess: MulF(F) = @floatCast(a * b);
    if (std.math.isNan(guess))
        return a * b;

    if (std.math.isNegativeInf(guess) and std.math.isFinite(a) and std.math.isFinite(b))
        return -std.math.floatMax(F);

    if (std.math.isPositiveInf(guess) and std.math.isFinite(a) and std.math.isFinite(b))
        return std.math.floatMax(F);

    if (std.math.isInf(guess))
        return a * b;

    const target = @as(MulF(F), @floatCast(a)) * @as(MulF(F), @floatCast(b));

    // Everything in sight is exactly representable at
    // this precision level, meaning:
    //  - err < 0 => guess too low
    //  - err = 0 => guess just right
    //  - err > 0 => guess too high
    const err = guess - target;

    // Note:
    //  - a * b < 0 => round_up
    //  - a * b > 0 => round_down
    //  - a * b = 0:
    //      - The multiplication is exact at this precision
    //        level, so one of the source arguments must have
    //        been zero.
    if (a * b < 0) {
        if (err < 0)
            return std.math.nextAfter(F, guess, std.math.inf(F));
        return a * b;
    }

    if (a * b > 0) {
        if (err > 0)
            return std.math.nextAfter(F, guess, -std.math.inf(F));
        return a * b;
    }

    std.debug.assert(a == 0 or b == 0);
    return a * b;
}

fn mul_up(F: type, a: F, b: F) F {
    @setFloatMode(.strict);

    const guess: MulF(F) = @floatCast(a * b);
    if (std.math.isNan(guess))
        return a * b;

    if (std.math.isNegativeInf(guess) and std.math.isFinite(a) and std.math.isFinite(b))
        return -std.math.floatMax(F);

    if (std.math.isInf(guess))
        return a * b;

    const target = @as(MulF(F), @floatCast(a)) * @as(MulF(F), @floatCast(b));

    // Everything in sight is exactly representable at
    // this precision level, meaning:
    //  - err < 0 => guess too low
    //  - err = 0 => guess just right
    //  - err > 0 => guess too high
    const err = guess - target;

    if (err < 0)
        return std.math.nextAfter(F, guess, std.math.inf(F));

    return guess;
}

fn mul_down(F: type, a: F, b: F) F {
    @setFloatMode(.strict);

    const guess: MulF(F) = @floatCast(a * b);
    if (std.math.isNan(guess))
        return a * b;

    if (std.math.isPositiveInf(guess) and std.math.isFinite(a) and std.math.isFinite(b))
        return std.math.floatMax(F);

    if (std.math.isInf(guess))
        return a * b;

    const target = @as(MulF(F), @floatCast(a)) * @as(MulF(F), @floatCast(b));

    // Everything in sight is exactly representable at
    // this precision level, meaning:
    //  - err < 0 => guess too low
    //  - err = 0 => guess just right
    //  - err > 0 => guess too high
    const err = guess - target;

    if (err > 0)
        return std.math.nextAfter(F, guess, -std.math.inf(F));

    return guess;
}
