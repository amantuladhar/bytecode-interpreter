const std = @import("std");
const memory = @import("memory.zig");
const Allocator = std.mem.Allocator;

pub fn DynArray(comptime T: type) type {
    return struct {
        const Self = @This();

        capacity: usize,
        count: usize,
        data: ?[]T,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .allocator = allocator,
                .capacity = 0,
                .count = 0,
                .data = null,
            };
        }
        pub fn free(self: *Self) void {
            _ = try memory.freeArray(T, self.allocator, self.data, self.capacity);
            self.capacity = 0;
            self.count = 0;
            self.data = null;
        }

        pub fn write(self: *Self, item: T) !void {
            if (self.count >= self.capacity) {
                const old_capacity = self.capacity;
                self.capacity = memory.growCapacity(old_capacity);
                self.data = try memory.growArray(T, self.allocator, self.data, old_capacity, self.capacity);
            }
            self.data.?[self.count] = item;
            self.count += 1;
        }
    };
}

test "Dyn Array" {
    const testing = std.testing;
    const allocator = testing.allocator;
    const OpCode = @import("chunk.zig").OpCode;

    var chunk = DynArray(OpCode).init(allocator);
    defer chunk.free();
    try chunk.write(OpCode.OpReturn);
    try chunk.write(OpCode.Test1);
}
