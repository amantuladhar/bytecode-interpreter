const std = @import("std");
const OpCode = @import("OpCode.zig").OpCode;
const ValueArr = @import("ValueArr.zig");

const Value = ValueArr.Value;
const Allocator = std.mem.Allocator;

pub const Instruction = union(enum) {
    OpCode: OpCode,
    /// holds offset to find constant value from constants array
    Constant: usize,
};

len: usize,
capacity: usize,
instructions: []Instruction,
constants: ValueArr,
lines: []u16,
allocator: Allocator,

const Self = @This();

pub fn init(allocator: Allocator) !Self {
    return .{
        .len = 0,
        .capacity = 8,
        .instructions = try allocator.alloc(Instruction, 8),
        .constants = try ValueArr.init(allocator),
        .lines = try allocator.alloc(u16, 8),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.constants.deinit();
    self.allocator.free(self.instructions);
    self.allocator.free(self.lines);
    self.len = 0;
    self.capacity = 0;
}

pub fn writeOpCode(self: *Self, code: OpCode, line: u16) !void {
    try self.write(.{ .OpCode = code }, line);
}

pub fn writeConstant(self: *Self, constant: Value, line: u16) !void {
    const c_offset = try self.addConstant(constant);
    try self.writeOpCode(.Constant, line);
    try self.write(.{ .Constant = c_offset }, line);
}

fn addConstant(self: *Self, constant: Value) !usize {
    try self.constants.write(constant);
    return self.constants.len - 1;
}

fn write(self: *Self, instruction: Instruction, line: u16) !void {
    if (self.capacity < self.len + 1) {
        const old_cap = self.capacity;
        self.capacity = if (old_cap < 8) 8 else old_cap * 2;
        self.instructions = try self.allocator.realloc(self.instructions, self.capacity);
        self.lines = try self.allocator.realloc(self.lines, self.capacity);
    }
    self.instructions[self.len] = instruction;
    self.lines[self.len] = line;
    self.len += 1;
}

test "chunk test" {
    const testing = std.testing;
    const allocator = std.testing.allocator;

    var chunk = try Self.init(allocator);
    defer chunk.deinit();

    try chunk.writeOpCode(.Return, 123);
    try chunk.writeConstant(.{ .Number = 1.1 }, 123);
    try chunk.writeConstant(.{ .Number = 2.2 }, 123);

    try testing.expectEqual(5, chunk.len);
    try testing.expectEqual(8, chunk.capacity);
    try testing.expectEqual(8, chunk.instructions.len);
}
