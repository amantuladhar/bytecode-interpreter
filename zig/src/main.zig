const std = @import("std");
const Chunk = @import("Chunk.zig");
const OpCode = @import("OpCode.zig").OpCode;

const debug = @import("debug.zig");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const v = gpa.deinit();
        std.debug.print("\n\n======== LEAK STATUS: {any} ======== \n", .{v});
    }

    const allocator = gpa.allocator();
    var c = try Chunk.init(allocator);
    defer c.deinit();

    try c.writeConstant(.{ .Number = 1.2 });
    try c.writeConstant(.{ .Number = 42.42 });
    try c.writeOpCode(.Return);

    debug.disasssembleChunk(c, "Test chunk");
}
