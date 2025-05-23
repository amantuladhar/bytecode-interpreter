const std = @import("std");
const print = std.debug.print;
const Chunk = @import("Chunk.zig");
const printValue = @import("ValueArr.zig").printValue;

pub fn disassembleChunk(chunk: *const Chunk, name: []const u8) void {
    print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}
pub fn disassembleInstruction(chunk: *const Chunk, offset: usize) usize {
    print("{d:0>4}", .{offset});
    if (offset > 0 and chunk.lines[offset] == chunk.lines[offset - 1]) {
        print("{s:>4}| ", .{""});
    } else {
        print("{d:5} ", .{chunk.lines[offset]});
    }
    const inst = chunk.code[offset];
    switch (inst) {
        .OpCode => |code| {
            switch (code) {
                .Return => return simpleInstruction("Return", offset),
                .Negate => return simpleInstruction("Negate", offset),
                .Add => return simpleInstruction("Add", offset),
                .Subtract => return simpleInstruction("Subtract", offset),
                .Multiply => return simpleInstruction("Multiply", offset),
                .Divide => return simpleInstruction("Divide", offset),
                .Nil => return simpleInstruction("Nil", offset),
                .True => return simpleInstruction("True", offset),
                .False => return simpleInstruction("False", offset),
                .Not => return simpleInstruction("Not", offset),
                .Equal => return simpleInstruction("Equal", offset),
                .Greater => return simpleInstruction("Greater", offset),
                .Less => return simpleInstruction("Less", offset),
                .Constant => return complexInstruction("Constant", chunk, offset),
            }
        },
        .Constant => {
            @panic("contant should be handled by OpCode");
        },
    }
}

fn simpleInstruction(name: []const u8, offset: usize) usize {
    print("{s}\n", .{name});
    return offset + 1;
}

fn complexInstruction(name: []const u8, chunk: *const Chunk, offset: usize) usize {
    const offset_chunk_value = chunk.code[offset + 1];
    if (offset_chunk_value != .Constant) {
        @breakpoint();
        @panic("constant must be followed by constant value");
    }
    const constant_offset = offset_chunk_value.Constant;
    print("{s:<16} {d:>4} '", .{ name, constant_offset });
    printValue(chunk.constants.values[constant_offset]);
    print("'\n", .{});
    return offset + 2;
}
