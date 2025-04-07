const std = @import("std");

pub const add = @import("add.zig");
pub const sub = @import("sub.zig");

comptime {
    std.testing.refAllDeclsRecursive(@This());
}
