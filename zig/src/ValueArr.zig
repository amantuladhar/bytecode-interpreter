const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Value = union(enum) { Number: f32 };

len: usize,
capacity: usize,
values: []Value,
allocator: Allocator,

const Self = @This();

pub fn init(allocator: Allocator) !Self {
    return .{
        .len = 0,
        .capacity = 8,
        .values = try allocator.alloc(Value, 8),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.values);
    self.len = 0;
    self.capacity = 0;
}

pub fn write(self: *Self, value: Value) !void {
    if (self.capacity < self.len + 1) {
        const old_cap = self.capacity;
        self.capacity = if (old_cap < 8) 8 else old_cap * 2;
        self.values = try self.allocator.realloc(self.values, self.capacity);
    }
    self.values[self.len] = value;
    self.len += 1;
}
