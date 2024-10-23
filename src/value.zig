const std = @import("std");
const memory = @import("memory.zig");
const Allocator = std.mem.Allocator;

pub const Value = f64;

pub const ValueArray = struct {
    const Self = @This();

    capacity: usize,
    count: usize,
    data: ?[]Value,
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
        _ = try memory.freeArray(Value, self.allocator, self.data, self.capacity);
        self.capacity = 0;
        self.count = 0;
        self.data = null;
    }

    pub fn write(self: *Self, item: Value) !void {
        if (self.count >= self.capacity) {
            const old_capacity = self.capacity;
            self.capacity = memory.growCapacity(old_capacity);
            self.data = try memory.growArray(Value, self.allocator, self.data, old_capacity, self.capacity);
        }
        self.data.?[self.count] = item;
        self.count += 1;
    }
};

pub fn printValue(value: Value) void {
    std.debug.print("{d}", .{value});
}
