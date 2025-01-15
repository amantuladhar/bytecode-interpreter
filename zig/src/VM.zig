const std = @import("std");
const Chunk = @import("Chunk.zig");
const Instruction = @import("Chunk.zig").Instruction;
const Value = @import("ValueArr.zig").Value;
const printValue = @import("ValueArr.zig").printValue;
const disassembleInstruction = @import("debug.zig").disassembleInstruction;

const Allocator = std.mem.Allocator;

pub const VMError = error{
    Compile,
    Runtime,
};

const STACK_MAX = 256;

chunk: ?*Chunk,
ip_index: usize,
stack: [STACK_MAX]Value,
stack_top: usize,

const Self = @This();

pub fn init() Self {
    return .{
        .chunk = null,
        .ip_index = 0,
        .stack = undefined,
        .stack_top = 0,
    };
}

pub fn deinit(self: *Self) void {
    self.chunk = null;
    self.ip_index = 0;
    self.stack = undefined;
    self.stack_top = 0;
}

pub fn interpret(self: *Self, chunk: *Chunk) VMError!void {
    self.chunk = chunk;
    self.ip_index = 0;
    return try self.run();
}

fn run(self: *Self) VMError!void {
    std.debug.assert(self.chunk != null);

    while (true) {
        const show_stacktrace = true;
        if (show_stacktrace) {
            std.debug.print("        ", .{});
            for (self.stack[0..self.stack_top]) |slot| {
                std.debug.print("[", .{});
                printValue(slot);
                std.debug.print("]", .{});
            }
            std.debug.print("\n", .{});
            _ = disassembleInstruction(self.chunk.?.*, self.ip_index);
        }

        const instruction = self.readBytes();
        if (instruction != .OpCode) {
            @panic("This must be OpCode instruction");
        }
        switch (instruction.OpCode) {
            .Constant => {
                const c = self.readConstant();
                self.push(c);
            },
            .Negate => {
                const v = self.pop();
                if (v != .Number) {
                    return VMError.Runtime;
                }
                self.push(.{ .Number = -(v.Number) });
            },
            .Return => {
                printValue(self.pop());
                std.debug.print("\n", .{});
                return;
            },
        }
    }
}

pub fn push(self: *Self, value: Value) void {
    self.stack[self.stack_top] = value;
    self.stack_top += 1;
}

pub fn pop(self: *Self) Value {
    self.stack_top -|= 1;
    return self.stack[self.stack_top];
}

fn readConstant(self: *Self) Value {
    const constant = self.readBytes();
    if (constant != .Constant) {
        @panic("Instruction after .Constant should be index to find constant");
    }
    return self.chunk.?.constants.values[constant.Constant];
}

fn readBytes(self: *Self) Instruction {
    const idx = self.ip_index;
    self.ip_index += 1;
    return self.chunk.?.instructions[idx];
}

fn resetStack(self: *Self) void {
    self.stack_top = 0;
}
