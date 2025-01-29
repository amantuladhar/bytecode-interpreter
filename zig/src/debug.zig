const std = @import("std");
const Chunk = @import("Chunk.zig");
const Value = @import("ValueArr.zig").Value;
const printValue = @import("ValueArr.zig").printValue;
const print = std.debug.print;

pub fn disasssembleChunk(chunk: Chunk, name: []const u8) void {
    print(" == {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}
pub fn disassembleInstruction(chunk: Chunk, offset: usize) usize {
    print(" {d:0>4} ", .{offset});

    if (offset > 0 and chunk.lines[offset] == chunk.lines[offset - 1]) {
        print("   | ", .{});
    } else {
        print("{d:0>4} ", .{chunk.lines[offset]});
    }

    const instruction = chunk.instructions[offset];
    if (instruction == .Constant) {
        @panic("Constant should be consumed by previous OpCode");
    }

    return switch (instruction.OpCode) {
        .Constant => return constantInstruction("OP_CONSTANT", chunk, offset),
        .Add => return simpleInstruction("OP_ADD", offset),
        .Subtract => return simpleInstruction("OP_Subtract", offset),
        .Multiply => return simpleInstruction("OP_MULTIPLY", offset),
        .Divide => return simpleInstruction("OP_DIVIDE", offset),
        .Negate => return simpleInstruction("OP_NEGATE", offset),
        .Return => return simpleInstruction("OP_RETURN", offset),
    };
}

fn constantInstruction(name: []const u8, chunk: Chunk, offset: usize) usize {
    const c = chunk.instructions[offset + 1];
    if (c != .Constant) {
        @panic(".Constant OpCode must be followed by a constant instruction.");
    }

    print("{s:<16} {d:0>4} '", .{ name, c.Constant });
    printValue(chunk.constants.values[c.Constant]);
    print("'\n", .{});
    return offset + 2;
}

fn simpleInstruction(name: []const u8, offset: usize) usize {
    print("{s}\n", .{name});
    return offset + 1;
}
