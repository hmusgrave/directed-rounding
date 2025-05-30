const std = @import("std");

pub const add = @import("add.zig");
pub const sub = @import("sub.zig");
pub const sqrt = @import("sqrt.zig");
pub const mul = @import("mul.zig");
pub const div = @import("div.zig");

comptime {
    std.testing.refAllDeclsRecursive(@This());
}
