const std = @import("std");

const Allocator = std.mem.Allocator;

pub const OpCode = enum {
    Constant,
    Return,
};
