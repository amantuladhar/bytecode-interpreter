const std = @import("std");
const Chunk = @import("Chunk.zig");
const Value = @import("ValueArr.zig").Value;

const MAX_STACK_SIZE = 256;

pub const Result = enum { Ok, CompileError, RuntimeError };

pub const VM = struct {
    const Self = @This();

    chunk: *Chunk,
    ip: [*]Chunk.ChunkValue,
    stack: [256]Value = undefined,
    stack_top: ?[*]Value,

    pub fn init(chunk: *Chunk) Self {
        const ip = chunk.code.ptr;
        return Self{
            .chunk = chunk,
            .ip = ip,
            .stack_top = null,
        };
    }

    pub fn deinit(self: *Self) void {
        self.ip = self.chunk.code.ptr;
        self.stack_top = null;
        self.stack = undefined;
    }

    pub fn interpret(self: *Self) void {
        while (true) {
            const inst = self.readByte().*;
            std.debug.print("{any}\n", .{inst});

            switch (inst) {
                .OpCode => |op_code| {
                    switch (op_code) {
                        .Constant => {
                            const constant = self.readConstant();
                            self.push(constant);
                        },
                        .Negate => {},
                        .Return => {},
                    }
                },
                .Constant => {
                    @breakpoint();
                    @panic("this is unrechable, opcode should have consumed this chunk");
                },
            }
        }
    }

    fn readByte(self: *Self) *Chunk.ChunkValue {
        const inst = &self.ip[0];
        self.ip += 1;
        return inst;
    }
    fn readConstant(self: *Self) Value {
        const offset = self.readByte().*;
        if (offset != .Constant) {
            @breakpoint();
            @panic("This should be a constant");
        }
        const constant = self.chunk.constants.values[offset.Constant];
        return constant;
    }

    fn push(self: *Self, value: Value) void {
        if (self.stack_top) |top| {
            top[0].* = value;
            return;
        } else {
            self.stack[0] = value;
            const x = &self.stack[0];
            self.stack_top = x;
        }
        const one: usize = 1;
        self.stack_top.? += one;
    }
};

test "test vm" {
    const testing = std.testing;
    const allocator = std.testing.allocator;

    var chunk = try Chunk.init(allocator);
    defer chunk.deinit();

    try chunk.writeConstant(1.2, 123);
    try chunk.write(.{ .OpCode = .Negate }, 123);
    try chunk.write(.{ .OpCode = .Return }, 123);

    var vm = VM.init(&chunk);
    vm.interpret();

    try testing.expect(true);
}
