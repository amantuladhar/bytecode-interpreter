const std = @import("std");
const Allocator = std.mem.Allocator;

const OpCode = @import("chunk.zig").OpCode;
const Chunk = @import("chunk.zig").Chunk;
const ChunkValue = @import("chunk.zig").ChunkValue;

pub const Vm = struct {
    const Self = @This();

    chunk: *Chunk,
    ip: *OpCode,

    pub fn init(chunk: *Chunk) Self {
        return Self{
            .chunk = chunk,
            .ip = chunk,
        };
    }

    pub fn free(self: *Self) void {
        if (self.chunk) |chunk| {
            self.allocator.free(chunk);
        }
    }

    pub fn interpret(self: *Self) InterpretResult {
        self.ip = &self.chunk.?.code.?[0];
        return self.run();
    }

    fn run(self: *Self) InterpretResult {
        _ = self;
        while (true) {}
    }
    fn readBytes(self: *Self) *OpCode {
        const instruction = self.ip.?.opCode;
        self.ip += 1;
        return instruction;
    }
};

pub const InterpretResult = enum {
    Ok,
    CompileError,
    RuntimeError,
};
