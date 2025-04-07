const std = @import("std");
const round_mode = @import("round_mode.zig");

pub fn add(F: type, a: F, b: F, comptime mode: round_mode.RoundMode) F {
    return switch (mode) {
        .Up => add_up(F, a, b),
        .Down => add_down(F, a, b),
        .Even => add_nearest(F, a, b),
        .Trunc => add_trunc(F, a, b),
    };
}

fn add_nearest(F: type, a: F, b: F) F {
    // only currently supported rounding mode from the compiler (<= 0.14)
    return a + b;
}

fn add_trunc(F: type, a: F, b: F) F {
    // t > 0: round down
    // t < 0: round up
    // t == 0
    //   - only happens (even for floats) if a == -b (i.e., no rounding)
    //   - negative zero behavior experimentally confirmed to
    //     be the same as RoundMode.Up

    @setFloatMode(.strict);

    const t = a + b;

    if (t >= 0 and (t - a < b or t - b < a))
        return std.math.nextAfter(F, t, std.math.inf(F));

    if (t < 0) {
        const x_minus_x = t == 0 and a != 0;
        const includes_neg_zero = t == 0 and (std.math.isNegativeZero(a) or std.math.isNegativeZero(b));
        if (x_minus_x or includes_neg_zero)
            return -0.0;

        if (t - a > b or t - b > a)
            return std.math.nextAfter(F, t, -std.math.inf(F));
    }

    return t;
}

fn add_up(F: type, a: F, b: F) F {
    // With a bit of tedium, it's easy to confirm results
    // involving NaN and Inf all work correctly (using
    // properties like `inf - inf -> NaN` and
    // `NaN < anything == False`), even for edge cases
    // like adding two finite results and achieving
    // something infinite. The only "incorrect" result
    // is if you might want to add data some specific
    // way to a signaling NaN created in this routine.
    //
    // Interestingly, subnormals work correctly using
    // the same analysis as the normal floating point
    // range.
    //
    // In the normal range, there are a few cases. Some
    // observations:
    //   - If the result was rounded correctly, then
    //     (using real math, not floats), we know
    //     t >= a + b, which forces the floating point
    //     check before nextAfter to fail.
    //   - If the result was rounded incorrectly, then
    //     (using real math, not floats) we know
    //     t < a + b, which trivially shows all of:
    //       t - a <= b
    //       t - b <= a
    //     using floating point math. Our job is to prove
    //     that at least one of those inequalities is not
    //     strict.
    //   - If at least one of a or b is positive, with
    //     some work, one proof strategy relies on the
    //     fact that floating point resolution increases
    //     toward zero. You can use the existence of incorrect
    //     rounding to create a non-zero delta you'd like
    //     to propagate in a chain of inequalities, and
    //     the increasing resolution near zero to confirm
    //     that it does actually propagate.
    //   - If both a and b are negative, life is harder.
    //     Observe the subdivisions of floats from zero
    //     outward:
    //       | | | | |   |   |   |   |       |       | ...
    //       |       |               |
    //
    //     As the exponent increases, floats get further and
    //     further apart (you have many more available floats
    //     in a range because of nontrivially sized mantissas,
    //     but that's irrelevant to the picture).
    //
    //     Note that the coarser subdivisions overlap with
    //     the conceptually finer subdivisions, should that
    //     granularity happen to continue extending outward.
    //
    //     Since t < a,b < 0, this means that t has a
    //     (potentially not strictly) coarser granularity than
    //     both a and b.
    //
    //     When everything is in the same frequency band, the
    //     result is trivially true (we're simply describing
    //     integer math without rounding, so t being improperly
    //     rounded implies both of the subsequent inequalities
    //     don't hold). For the purpose of this proof, there are
    //     two meaningfully distinct frequency bands:
    //       - The coarser band (containing t)
    //       - The finer band (containing a and b) -- note that
    //         a and b might lie on different bands, but you can
    //         consider them as lying on the same finer band for
    //         this analysis
    //
    //     Let k be the finer gap and mk be the coarser gap
    //     (with k >= 1 and m >= 2). Suppose k is as large as
    //     possible such that both a and b can be represented
    //     as xk and yk (respectively, everything scale by an
    //     irrelevant power of 2, so that the proof can much
    //     more easily work in integer math).
    //
    //     With those assumptions and a fair bit of arithmetic,
    //     t being incorrectly rounded implies that both x and y
    //     are even, contradicting k being as large as possible.

    @setFloatMode(.strict);

    const t = a + b;

    if (t - a < b or t - b < a)
        return std.math.nextAfter(F, t, std.math.inf(F));

    return t;
}

fn add_down(F: type, a: F, b: F) F {
    // See the proof in `add_up`, and also note
    // that the following equality holds [0]
    //   add_down(F, a, b) == -add_up(F, -a, -b)
    //
    // EXCEPT for the handling of negative zero,
    // which we special case.
    //
    // [0] Please don't nit-pick NaN, inf, the
    //     IEEE definition of equality, .... Take
    //     that description as some sort of "super
    //     equal" -- bit-for-bit equality.
    @setFloatMode(.strict);

    const t = a + b;

    const x_minus_x = t == 0 and a != 0;
    const includes_neg_zero = t == 0 and (std.math.isNegativeZero(a) or std.math.isNegativeZero(b));
    if (x_minus_x or includes_neg_zero)
        return -0.0;

    if (t - a > b or t - b > a)
        return std.math.nextAfter(F, t, -std.math.inf(F));

    return t;
}

test "investigate negative zero addition behavior" {
    @setFloatMode(.strict);

    var x: f16 = -0.0;
    var y: f16 = 0.0;

    // prevent round-to-nearest-even constant folding
    const a: *volatile f16 = &x;
    const b: *volatile f16 = &y;

    inline for (@typeInfo(round_mode.RoundMode).Enum.fields) |mode_field| {
        const mode: round_mode.RoundMode = @enumFromInt(mode_field.value);
        const scope = round_mode.RoundScope.init(mode);
        defer scope.deinit();

        const condition = switch (mode) {
            .Down => std.math.isNegativeZero(a.* + b.*),
            else => std.math.isPositiveZero(a.* + b.*),
        };

        std.testing.expect(condition) catch |err| {
            std.debug.print("Mode failure: {s}\n", .{@tagName(mode)});
            return err;
        };
    }
}

test "negative zero sanity check" {
    @setFloatMode(.strict);

    const x: f16 = -0.0;
    const y: f16 = 0.0;

    const a: u16 = @bitCast(x);
    const b: u16 = @bitCast(y);

    try std.testing.expect(a != b);
}
