const std = @import("std");

pub const add = @import("add.zig");
pub const sub = @import("sub.zig");
pub const sqrt = @import("sqrt.zig");

comptime {
    std.testing.refAllDeclsRecursive(@This());
}
