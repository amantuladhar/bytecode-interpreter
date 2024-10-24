const std = @import("std");
const Chunk = @import("Chunk.zig");
const OpCode = @import("Chunk.zig").OpCode;
const debug = @import("debug.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() == .leak) {
            std.debug.panic("\n🛑🛑🛑 MEMORY LEAKED 🛑🛑🛑\n", .{});
        }
        std.debug.print("\n🟢🟢🟢 PROGRAM EXITED SUCCESSFULLY 🟢🟢🟢\n", .{});
    }

    var chunk = try Chunk.init(allocator);
    defer chunk.deinit();

    try chunk.writeConstant(1.2, 123);
    try chunk.write(.{ .OpCode = .Negate }, 123);
    try chunk.write(.{ .OpCode = .Return }, 123);

    std.debug.print("\n===== INTERPRETER =====\n", .{});
    

    debug.disassembleChunk(&chunk, "test chunk");
}
