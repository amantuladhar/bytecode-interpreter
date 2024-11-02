const std = @import("std");
const Allocator = std.mem.Allocator;
const debug = @import("debug.zig");
const VM = @import("vm.zig");
const Chunk = @import("Chunk.zig");
const OpCode = Chunk.OpCode;
const Compiler = @import("Compiler.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() == .leak) {
            std.debug.panic("\n🛑🛑🛑 MEMORY LEAKED 🛑🛑🛑\n", .{});
        }
        std.debug.print("\n🟢🟢🟢 PROGRAM EXITED SUCCESSFULLY 🟢🟢🟢\n", .{});
    }
    const x = 10;
    _ = x;
    try repl(allocator);
}

fn repl(allocator: Allocator) !void {
    // const sout = std.io.getStdOut().writer();
    // try sout.print("> ", .{});

    // var line: [1024]u8 = undefined;
    // const read_count = try std.io.getStdIn().read(&line);
    // try sout.print("{s}", .{line[0..read_count]});

    const source = "5";

    var chunk = try Chunk.init(allocator);
    defer chunk.deinit();

    var compiler = try Compiler.init(allocator, source, &chunk);
    defer compiler.deinit();
    compiler.compile();
}
