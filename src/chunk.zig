const std = @import("std");
const Allocator = std.mem.Allocator;
const memory = @import("memory.zig");

pub const OpCode = enum { OpReturn, Test1, Test2 };

pub const Chunk = struct {
    const Self = @This();
    const CodeType = OpCode;

    code: ?[]CodeType,
    capacity: usize,
    count: usize,
    allocator: Allocator,


    pub fn init(allocator: Allocator) Self {
        const self = Self{
            .allocator = allocator,
            .capacity = 0,
            .count = 0,
            .code = null,
        };
        return self;
    }
    pub fn free(self: *Self) void {
        _ = try memory.freeArray(CodeType, self.allocator, self.code, self.capacity);
        self.capacity = 0;
        self.count = 0;
        self.code = null;
    }
    pub fn write(self: *Self, byte: CodeType) !void {
        if (self.count >= self.capacity) {
            const old_capacity = self.capacity;
            self.capacity = memory.growCapacity(old_capacity);
            self.code = try memory.growArray(CodeType, self.allocator, self.code, old_capacity, self.capacity);
        }
        self.code.?[self.count] = byte;
        self.count += 1;
    }
};

test "chunk" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var chunk = Chunk.init(allocator);
    defer chunk.free();
    try chunk.write(OpCode.OpReturn);
    try chunk.write(OpCode.OpReturn);
    try chunk.write(OpCode.OpReturn);
    try chunk.write(OpCode.OpReturn);
    try chunk.write(OpCode.OpReturn);
}
