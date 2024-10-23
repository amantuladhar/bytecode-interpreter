const std = @import("std");
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const debug = @import("debug.zig");

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() == .leak) {
            std.debug.panic("\n🛑🛑🛑 MEMORY LEAKED 🛑🛑🛑\n", .{});
        }
        std.debug.print("\n🟢🟢🟢 PROGRAM EXITED SUCCESSFULLY 🟢🟢🟢\n", .{});
    }

    var chunk = Chunk.init(allocator);
    defer chunk.free();

    var constant_offset = try chunk.addConstant(1.2);
    try chunk.write(.{ .opCode = .OpConstant }, 123);
    try chunk.write(.{ .usize = constant_offset }, 123);

    constant_offset = try chunk.addConstant(1000.1);
    try chunk.write(.{ .opCode = .OpConstant }, 123);
    try chunk.write(.{ .usize = constant_offset }, 123);

    try chunk.write(.{ .opCode = OpCode.OpReturn }, 123);

    debug.disassembleChunk(&chunk, "test chunk");
}
