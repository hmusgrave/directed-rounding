const std = @import("std");
const round_mode = @import("round_mode.zig");

fn MulF(F: type) type {
    // every multiplication (:F) * (:F) can be exactly
    // represented in a result type of size 2F, at least
    // for the IEEE-754 definitions of f16, f32, f64, f128
    return @Type(.{ .Float = .{ .bits = 2 * @bitSizeOf(F) } });
}

pub fn div(F: type, a: F, b: F, comptime mode: round_mode.RoundMode) F {
    return switch (mode) {
        .Up => div_up(F, a, b),
        .Down => div_down(F, a, b),
        .Even => div_nearest(F, a, b),
        .Trunc => div_trunc(F, a, b),
    };
}

fn div_trunc(F: type, a: F, b: F) F {
    @setFloatMode(.strict);

    // TODO: This implementation is a bit lazy, and
    // the compiler isn't likely to skip unnecessary
    // computations because of the complexity of this
    // call graph. We should probably optimize it
    // a bit.

    const guess = a / b;
    if (std.math.isNan(guess))
        return guess;

    if (guess > 0)
        return div_down(F, a, b);

    if (guess < 0)
        return div_up(F, a, b);

    std.debug.assert(guess == 0);

    if (a == 0)
        return div_up(F, a, b);

    const sign = std.math.sign(a) * std.math.sign(b);
    if (sign < 0)
        return -0.0;

    return 0.0;
}

fn div_nearest(F: type, a: F, b: F) F {
    @setFloatMode(.strict);
    return a / b;
}

fn div_down(F: type, a: F, b: F) F {
    @setFloatMode(.strict);

    const guess: MulF(F) = @floatCast(a / b);
    if (std.math.isNan(guess) or b == 0)
        return a / b;

    if (std.math.isPositiveInf(guess) and std.math.isFinite(a))
        return std.math.floatMax(F);

    if (std.math.isInf(guess))
        return a / b;

    // Everything in sight is exactly representable at this
    // precision level, but things are more complicated than
    // with sqrt or multiplication. The err being negative
    // means guess * b is too low, but whether that means
    // the guess is too low or too high depends on the signs
    // of everything involved.
    //   err < 0
    //     b < 0
    //       guess too big
    //     b > 0
    //       guess too small
    //   err > 0
    //     b < 0
    //       guess too small
    //     b > 0
    //       guess too big
    const target: MulF(F) = @floatCast(a);
    const err = @mulAdd(MulF(F), guess, @as(MulF(F), @floatCast(b)), -target);

    if ((err < 0 and b < 0) or (err > 0 and b > 0))
        return std.math.nextAfter(F, a / b, -std.math.inf(F));

    return a / b;
}

fn div_up(F: type, a: F, b: F) F {
    @setFloatMode(.strict);

    const guess: MulF(F) = @floatCast(a / b);
    if (std.math.isNan(guess) or b == 0)
        return a / b;

    if (std.math.isNegativeInf(guess) and std.math.isFinite(a))
        return -std.math.floatMax(F);

    if (std.math.isInf(guess))
        return a / b;

    // Everything in sight is exactly representable at this
    // precision level, but things are more complicated than
    // with sqrt or multiplication. The err being negative
    // means guess * b is too low, but whether that means
    // the guess is too low or too high depends on the signs
    // of everything involved.
    //   err < 0
    //     b < 0
    //       guess too big
    //     b > 0
    //       guess too small
    //   err > 0
    //     b < 0
    //       guess too small
    //     b > 0
    //       guess too big
    const target: MulF(F) = @floatCast(a);
    const err = @mulAdd(MulF(F), guess, @as(MulF(F), @floatCast(b)), -target);

    if ((err < 0 and b > 0) or (err > 0 and b < 0))
        return std.math.nextAfter(F, a / b, std.math.inf(F));

    return a / b;
}
