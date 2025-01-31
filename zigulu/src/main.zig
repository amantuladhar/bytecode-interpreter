const std = @import("std");
const debug = @import("debug.zig");
const VM = @import("vm.zig");
const Chunk = @import("chunk.zig");
const Compiler = @import("Compiler.zig");
const Allocator = std.mem.Allocator;
const OpCode = Chunk.OpCode;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try repl(allocator);
}

fn repl(allocator: Allocator) !void {
    const sout = std.io.getStdOut().writer();
    try sout.print("> ", .{});

    var line: [1024]u8 = undefined;
    const read_count = try std.io.getStdIn().read(&line);
    try sout.print("{s}", .{line[0..read_count]});

    var chunk = try Chunk.init(allocator);
    defer chunk.deinit();

    var vm = VM.init(&chunk);
    defer vm.deinit();

    var compiler = try Compiler.init(allocator, &vm, line[0..read_count], &chunk);
    defer compiler.deinit();
    compiler.compile();

    std.debug.print("\n ========= Interpret =========\n", .{});
    _ = try vm.interpret(allocator, &vm);

    std.debug.print("\n ========= Chunk =========\n", .{});
    _ = debug.disassembleChunk(@ptrCast(&chunk), "repl");
}
