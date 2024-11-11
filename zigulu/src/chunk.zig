const std = @import("std");
const Allocator = std.mem.Allocator;
const ValueArr = @import("ValueArr.zig");

pub const OpCode = enum {
    Constant,
    Nil,
    True,
    False,
    Add,
    Subtract,
    Multiply,
    Divide,
    Not,
    Negate,
    Equal,
    Greater,
    Less,
    Return,
};

pub const ChunkValue = union(enum) {
    OpCode: OpCode,
    /// Offset to find constant on contants array
    Constant: usize,
};

const Self = @This();

code: []ChunkValue,
lines: []usize,
constants: ValueArr,
capacity: usize,
len: usize,
allocator: Allocator,

pub fn init(allocator: Allocator) !Self {
    const initial_cap = 8;
    return Self{
        .allocator = allocator,
        .capacity = initial_cap,
        .len = 0,
        .code = try allocator.alloc(ChunkValue, initial_cap),
        .lines = try allocator.alloc(usize, initial_cap),
        .constants = try ValueArr.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.constants.deinit();
    self.len = 0;
    self.capacity = 0;
    self.allocator.free(self.code);
    self.allocator.free(self.lines);
}

pub fn write(self: *Self, chunk: ChunkValue, line: usize) !void {
    if (self.len >= self.capacity) {
        self.capacity = self.capacity * 2;
        self.code = try self.allocator.realloc(self.code, self.capacity);
        self.lines = try self.allocator.realloc(self.lines, self.capacity);
    }
    self.code[self.len] = chunk;
    self.lines[self.len] = line;
    self.len += 1;
}

pub fn writeConstant(self: *Self, constant: ValueArr.Value, line: u16) !void {
    const offset = try self.addConstant(constant);
    try self.write(.{ .OpCode = .Constant }, line);
    try self.write(.{ .Constant = offset }, line);
}

pub fn addConstant(self: *Self, value: ValueArr.Value) !usize {
    try self.constants.write(value);
    return self.constants.len - 1;
}
