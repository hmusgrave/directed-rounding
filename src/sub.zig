const std = @import("std");

const add = @import("add.zig");
const round_mode = @import("round_mode.zig");

pub fn sub(F: type, a: F, b: F, comptime mode: round_mode.RoundMode) F {
    return add.add(F, a, -b, mode);
}

test "sub same as add negated" {
    // Runs correctly, but slows down tests substantially.
    if (true)
        return error.SkipZigTest;

    inline for (@typeInfo(round_mode.RoundMode).Enum.fields) |mode_field| {
        const scope = round_mode.RoundScope.init(@enumFromInt(mode_field.value));
        defer scope.deinit();

        for (0..(1 << 32)) |i| {
            const x: u16 = @truncate(i >> 16);
            const y: u16 = @truncate(i & 0xFFFF);

            const a: f16 = @bitCast(x);
            const b: f16 = @bitCast(y);

            // Using volatile to thwart compiler optimizations
            const u: *const volatile f16 = &a;
            const v: *const volatile f16 = &b;

            const c: f16 = -v.*;

            // Can't just check equality because of:
            //  - NaN
            //  - Inf
            //  - Negative Zero
            const res1: u16 = @bitCast(u.* + c);
            const res2: u16 = @bitCast(u.* - v.*);

            try std.testing.expectEqual(res1, res2);
        }
    }
}
