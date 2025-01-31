const std = @import("std");
const Allocator = std.mem.Allocator;
const VM = @import("vm.zig");
const Chunk = @import("chunk.zig");
const ValueArr = @import("ValueArr.zig");
const object = @import("object.zig");
const Obj = object.Obj;
const ObjString = object.ObjString;
const disassembleInstruction = @import("debug.zig").disassembleInstruction;
const Value = ValueArr.Value;
const printValue = ValueArr.printValue;
const equalValue = ValueArr.equalValue;
const isFalsy = ValueArr.isFalsy;

const MAX_STACK_SIZE = 256;

pub const InterpretResult = enum { Ok, CompileError, RuntimeError };

const Self = @This();

chunk: *Chunk,
ip: usize,
stack: [MAX_STACK_SIZE]Value = undefined,
stack_top: usize,
objects: ?*Obj = null,

pub fn init(chunk: *Chunk) Self {
    return Self{
        .chunk = chunk,
        .ip = 0,
        .stack_top = 0,
    };
}

pub fn deinit(self: *Self) void {
    self.ip = 0;
    self.stack = undefined;
    self.stack_top = 0;
    var next_obj = self.objects;
    while (next_obj) |obj| {
        const next = obj.next;
        obj.deinit();
        next_obj = next;
    }
}

pub fn interpret(self: *Self, allocator: Allocator, vm: *VM) !InterpretResult {
    while (true) {
        const show_stacktrace = true;
        if (show_stacktrace) {
            std.debug.print("        ", .{});
            for (self.stack[0..self.stack_top]) |slot| {
                std.debug.print("[", .{});
                printValue(slot);
                std.debug.print("]", .{});
            }
            std.debug.print("\n", .{});
            _ = disassembleInstruction(@ptrCast(self.chunk), self.ip);
        }

        const inst = self.readByte().*;
        if (inst != .OpCode) {
            @breakpoint();
            @panic("this is unrechable, opcode should have consumed this chunk");
        }
        switch (inst.OpCode) {
            .Constant => {
                const constant = self.readConstant();
                self.push(constant);
            },
            .Add, .Subtract, .Multiply, .Divide => {
                const bv = self.pop();
                const av = self.pop();
                if (inst.OpCode == .Add and av == .Obj and av.Obj.*.value == .String) {
                    const b = bv.Obj.*.value.String;
                    const a = av.Obj.*.value.String;
                    const join_str = ObjString.concatenate(allocator, a.value, b.value) catch unreachable;
                    const obj = object.Obj.init(allocator, vm, .{ .String = join_str }) catch unreachable;
                    self.push(.{ .Obj = obj });
                } else {
                    const b = bv.Number;
                    const a = av.Number;
                    const result = switch (inst.OpCode) {
                        .Add => a + b,
                        .Subtract => a - b,
                        .Multiply => a * b,
                        .Divide => a / b,
                        // unreachable so random value to return float
                        else => 0.0,
                    };
                    self.push(.{ .Number = result });
                }
            },
            .Negate => {
                self.push(.{ .Number = -(self.pop().Number) });
            },
            .Return => {
                printValue(self.pop());
                std.debug.print("\n", .{});
                return .Ok;
            },
            .Nil => {
                self.push(.Nil);
            },
            .True => self.push(.{ .Bool = true }),
            .False => self.push(.{ .Bool = false }),
            .Equal => {
                const b = self.pop();
                const a = self.pop();
                self.push(.{ .Bool = equalValue(a, b) });
            },
            .Not => {
                self.push(.{ .Bool = isFalsy(self.pop()) });
            },
            .Greater, .Less => {},
        }
    }
}

fn readByte(self: *Self) *Chunk.ChunkValue {
    const inst = &self.chunk.code[self.ip];
    self.ip += 1;
    return inst;
}
fn readConstant(self: *Self) Value {
    const offset = self.readByte().*;
    if (offset != .Constant) {
        @breakpoint();
        @panic("This should be a constant");
    }
    const constant = self.chunk.constants.values[offset.Constant];
    return constant;
}

fn push(self: *Self, value: Value) void {
    self.stack[self.stack_top] = value;
    self.stack_top += 1;
}

fn pop(self: *Self) Value {
    self.stack_top -= 1;
    const inst = self.stack[self.stack_top];
    return inst;
}

test "test vm" {
    const testing = std.testing;
    const allocator = std.testing.allocator;
    std.debug.print("\n", .{});

    var chunk = try Chunk.init(allocator);
    defer chunk.deinit();

    try chunk.writeConstant(1.2, 123);
    try chunk.writeConstant(2.3, 123);
    try chunk.write(.{ .OpCode = .Add }, 123);

    try chunk.writeConstant(2.3, 123);
    try chunk.write(.{ .OpCode = .Subtract }, 123);

    try chunk.writeConstant(1.2, 123);
    try chunk.write(.{ .OpCode = .Divide }, 123);

    try chunk.writeConstant(10, 123);
    try chunk.write(.{ .OpCode = .Multiply }, 123);

    try chunk.write(.{ .OpCode = .Negate }, 123);
    try chunk.write(.{ .OpCode = .Return }, 123);

    var vm = init(&chunk);
    _ = vm.interpret();

    try testing.expect(true);
}
