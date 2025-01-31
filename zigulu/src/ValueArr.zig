const std = @import("std");
const Obj = @import("object.zig").Obj;
const ObjectValue = @import("object.zig").ObjValue;
const Allocator = std.mem.Allocator;

pub const Value = union(enum) {
    Number: f64,
    Bool: bool,
    Obj: *Obj,
    Nil,
};

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
    switch (value) {
        .Number => std.debug.print("{d}", .{value.Number}),
        .Nil => std.debug.print("nil", .{}),
        .Bool => std.debug.print("{}", .{value.Bool}),
        .Obj => switch (value.Obj.value) {
            .String => std.debug.print("{s}", .{value.Obj.value.String.value}),
        },
    }
}

pub fn equalValue(v1: Value, v2: Value) bool {
    if (@as(std.meta.Tag(Value), v1) != @as(std.meta.Tag(Value), v2)) {
        return false;
    }
    return switch (v1) {
        .Number => v1.Number == v2.Number,
        .Nil => true,
        .Bool => v1.Bool == v2.Bool,
        .Obj => {
            if (@as(std.meta.Tag(ObjectValue), v1.Obj.value) != @as(std.meta.Tag(ObjectValue), v2.Obj.value)) {
                return false;
            }
            return switch (v1.Obj.value) {
                .String => std.mem.eql(u8, v1.Obj.value.String.value, v2.Obj.value.String.value),
            };
        },
    };
}
pub fn isFalsy(v: Value) bool {
    return switch (v) {
        .Number => v.Number == 0,
        .Nil => true,
        .Bool => v.Bool == false,
        else =>false,
    };
}
