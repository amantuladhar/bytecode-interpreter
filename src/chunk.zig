const std = @import("std");
const memory = @import("memory.zig");
const Value = @import("value.zig").Value;
const ValueArray = @import("value.zig").ValueArray;

const Allocator = std.mem.Allocator;

pub const OpCode = enum {
    OpConstant,
    OpReturn,
};

pub const ChunkValue = union(enum) {
    opCode: OpCode,
    usize: usize,
};

pub const Chunk = struct {
    const Self = @This();
    const CodeType = ChunkValue;

    code: []CodeType,
    constants: ValueArray,
    // TODO: Update to use RLE so we don't store same data multiple times
    // This is reduce the memory we need
    // Also, RLE might be bit constly, but will get called only when exception occur,
    // So it doesn't affect runtime performance on critical areas
    lines: []usize,
    capacity: usize,
    count: usize,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        const self = Self{
            .allocator = allocator,
            .capacity = 0,
            .count = 0,
            .code = memory.growArray(CodeType, allocator, null, 0, 8),
            .constants = ValueArray.init(allocator),
            .line = memory.growArray(usize, allocator, null, 0, 8),
        };
        return self;
    }

    pub fn free(self: *Self) void {
        self.constants.free();
        _ = try memory.freeArray(CodeType, self.allocator, self.code, self.capacity);
        _ = try memory.freeArray(usize, self.allocator, self.lines, self.capacity);
        self.capacity = 0;
        self.count = 0;
        self.code = null;
    }

    pub fn write(self: *Self, byte: CodeType, line: usize) !void {
        if (self.count >= self.capacity) {
            const old_capacity = self.capacity;
            self.capacity = memory.growCapacity(old_capacity);
            self.code = try memory.growArray(
                CodeType,
                self.allocator,
                self.code,
                old_capacity,
                self.capacity,
            );
            self.lines = try memory.growArray(
                usize,
                self.allocator,
                self.lines,
                old_capacity,
                self.capacity,
            );
        }
        self.code[self.count] = byte;
        self.lines[self.count] = line;
        self.count += 1;
    }

    pub fn addConstant(self: *Self, byte: Value) !usize {
        try self.constants.write(byte);
        return self.constants.count - 1;
    }
};
