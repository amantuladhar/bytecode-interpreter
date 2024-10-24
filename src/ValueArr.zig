const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Value = f64;

const Self = @This();

values: []Value,
capacity: usize,
len: usize,
allocator: Allocator,

pub fn init(allocator: Allocator) !Self {
    const initial_cap = 8;
    return Self{
        .allocator = allocator,
        .capacity = initial_cap,
        .len = 0,
        .values = try allocator.alloc(Value, initial_cap),
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.values);
    self.len = 0;
    self.capacity = 0;
}

pub fn write(self: *Self, value: Value) !void {
    if (self.len >= self.capacity) {
        self.capacity = self.capacity * 2;
        self.values = try self.allocator.realloc(self.values, self.capacity);
    }
    self.values[self.len] = value;
    self.len += 1;
}

pub fn printValue(value: Value) void {
    std.debug.print("{d}", .{value});
}
