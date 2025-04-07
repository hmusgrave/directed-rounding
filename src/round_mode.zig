extern fn fenv_get_round() c_int;
extern fn fenv_set_round(mode: c_int) void;

pub const RoundMode = enum(c_int) {
    Even = 0,
    Down = 0x400,
    Up = 0x800,
    Trunc = 0xC00,
};

pub const RoundScope = struct {
    prev_mode: RoundMode,

    pub fn init(mode: RoundMode) @This() {
        const prev: c_int = fenv_get_round();

        if (!@typeInfo(RoundMode).Enum.is_exhaustive)
            @compileError("WTF");
        fenv_set_round(@intFromEnum(mode));

        // Safe cast if your C toolchain isn't fucked
        return @This(){ .prev_mode = @enumFromInt(prev) };
    }

    pub fn deinit(self: @This()) void {
        fenv_set_round(@intFromEnum(self.prev_mode));
    }
};
