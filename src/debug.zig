const std = @import("std");
const Chunk = @import("chunk.zig").Chunk;
const value = @import("value.zig");

pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    std.debug.print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.count) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: *Chunk, offset: usize) usize {
    std.debug.print("{d:0>4} ", .{offset});

    if (offset > 0 and chunk.lines.?[offset] == chunk.lines.?[offset - 1]) {
        std.debug.print("    | ", .{});
    } else {
        std.debug.print("{d:>5} ", .{chunk.lines.?[offset]});
    }

    const instruction = chunk.code.?[offset];
    switch (instruction) {
        .opCode => |opCode| {
            switch (opCode) {
                .OpReturn => {
                    return simpleInstruction("OP_RETURN", offset);
                },
                .OpConstant => {
                    return constantInstruction("OP_CONSTANT", chunk, offset);
                },
                // else => {
                //     std.debug.print("Unknown opcode {any}\n", .{instruction});
                //     return offset + 1;
                // },
            }
        },
        else => {
            unreachable;
            // std.debug.print("Unknown opcode {any}\n", .{instruction});
            // return offset + 1;
        },
    }
}

fn simpleInstruction(name: []const u8, offset: usize) usize {
    std.debug.print("{s:<16}\n", .{name});
    return offset + 1;
}

fn constantInstruction(name: []const u8, chunk: *Chunk, offset: usize) usize {
    const constant = switch (chunk.code.?[offset + 1]) {
        .usize => |v| v,
        .opCode => @panic("constantInstruction must have contant"),
    };
    std.debug.print("{s:<16} {d:<4} '", .{ name, constant });

    value.printValue(chunk.constants.data.?[constant]);
    std.debug.print("'\n", .{});
    return offset + 2;
}
