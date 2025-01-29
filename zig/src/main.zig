const std = @import("std");
const Chunk = @import("Chunk.zig");
const VM = @import("VM.zig");
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

    var vm = VM.init();
    defer vm.deinit();

    var c = try Chunk.init(allocator);
    defer c.deinit();

    try c.writeConstant(.{ .Number = 10.2 }, 123);
    try c.writeConstant(.{ .Number = 9.8 }, 123);
    try c.writeOpCode(.Add, 123);
    try c.writeConstant(.{ .Number = 5 }, 123);
    try c.writeOpCode(.Divide, 123);
    try c.writeOpCode(.Negate, 123);
    try c.writeOpCode(.Return, 123);

    std.debug.print("\n========== Disassemble =======\n", .{});
    debug.disasssembleChunk(c, "Test chunk");

    std.debug.print("========== Interpret =======\n", .{});
    try vm.interpret(&c);
}
