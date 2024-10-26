const std = @import("std");
const Allocator = std.mem.Allocator;
const Chunk = @import("Chunk.zig");
const OpCode = @import("Chunk.zig").OpCode;
const debug = @import("debug.zig");
const VM = @import("vm.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() == .leak) {
            std.debug.panic("\n🛑🛑🛑 MEMORY LEAKED 🛑🛑🛑\n", .{});
        }
        std.debug.print("\n🟢🟢🟢 PROGRAM EXITED SUCCESSFULLY 🟢🟢🟢\n", .{});
    }
    try repl(allocator);
}

fn repl(allocator: Allocator) !void {
    _ = allocator;
    const sout = std.io.getStdOut().writer();
    try sout.print("> ", .{});

    var line: [1024]u8 = undefined;
    const read_count = try std.io.getStdIn().read(&line);
    try sout.print("{s}", .{line[0..read_count]});
}
