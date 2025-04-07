const std = @import("std");
const round_mode = @import("round_mode.zig");

fn MulF(F: type) type {
    // every multiplication (:F) * (:F) can be exactly
    // represented in a result type of size 2F, at least
    // for the IEEE-754 definitions of f16, f32, f64, f128
    return @Type(.{ .Float = .{ .bits = 2 * @bitSizeOf(F) } });
}

pub fn sqrt(F: type, a: F, comptime mode: round_mode.RoundMode) F {
    return switch (mode) {
        .Up => sqrt_up(F, a),
        .Down => sqrt_down(F, a),
        .Even => sqrt_nearest(F, a),
        .Trunc => sqrt_trunc(F, a),
    };
}

fn sqrt_nearest(F: type, a: F) F {
    @setFloatMode(.strict);
    return @sqrt(a);
}

const sqrt_trunc = sqrt_down;

fn sqrt_down(F: type, a: F) F {
    @setFloatMode(.strict);

    const guess: MulF(F) = @floatCast(@sqrt(a));
    if (std.math.isNan(guess) or std.math.isInf(guess))
        return guess;

    const target: MulF(F) = @floatCast(a);

    // Everything in sight is exactly representable at
    // this precision level, meaning:
    //  - err < 0 => guess too low
    //  - err = 0 => guess just right
    //  - err > 0 => guess too high
    const err = @mulAdd(MulF(F), guess, guess, -target);

    if (err > 0)
        return std.math.nextAfter(F, guess, -std.math.inf(F));

    return guess;
}

fn sqrt_up(F: type, a: F) F {
    @setFloatMode(.strict);

    const guess: MulF(F) = @floatCast(@sqrt(a));
    if (std.math.isNan(guess) or std.math.isInf(guess))
        return guess;

    const target: MulF(F) = @floatCast(a);

    // Everything in sight is exactly representable at
    // this precision level, meaning:
    //  - err < 0 => guess too low
    //  - err = 0 => guess just right
    //  - err > 0 => guess too high
    const err = @mulAdd(MulF(F), guess, guess, -target);

    if (err < 0)
        return std.math.nextAfter(F, guess, std.math.inf(F));

    return guess;
}
