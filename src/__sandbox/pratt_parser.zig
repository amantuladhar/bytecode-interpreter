// // scanner.zig
// const std = @import("std");
//
// pub const Token = enum {
//     Identifier,
//     Number,
//     Plus,
//     Minus,
//     Multiply,
//     Divide,
//     LeftParen,
//     RightParen,
//     Eof,
// };
//
// pub const Scanner = struct {
//     source: []const u8,
//     pos: usize = 0,
//
//     pub fn next(self: *Scanner) Token {
//         // Implement lexer logic here
//     }
// };
//
// // parser.zig
// const std = @import("std");
// const Scanner = @import("scanner.zig").Scanner;
// const Token = @import("scanner.zig").Token;
//
// pub const Expr = union(enum) {
//     Literal: f64,
//     Binary: struct { op: Token, left: *Expr, right: *Expr },
// };
//
// pub const Parser = struct {
//     scanner: *Scanner,
//     allocator: std.mem.Allocator,
//
//     pub fn parse(self: *Parser) ?*Expr {
//         return self.expression(0);
//     }
//
//     fn expression(self: *Parser, precedence: u8) ?*Expr {
//         var left = self.primary() orelse return null;
//
//         while (true) {
//             const op = self.scanner.next();
//             if (!self.isInfixOperator(op)) {
//                 self.scanner.pos -= 1;
//                 return left;
//             }
//
//             const rightPrecedence = self.getInfixPrecedence(op);
//             if (rightPrecedence < precedence) {
//                 self.scanner.pos -= 1;
//                 return left;
//             }
//
//             const right = self.expression(rightPrecedence) orelse return null;
//             left = self.allocator.create(Expr) catch return null;
//             left.* = Expr{ .Binary = .{ .op = op, .left = left, .right = right } };
//         }
//     }
//
//     // Other parser helper functions...
// };
//
// // compiler.zig
// const std = @import("std");
// const Expr = @import("parser.zig").Expr;
// const Token = @import("scanner.zig").Token;
//
// pub const Instruction = enum {
//     PushLiteral,
//     Add,
//     Subtract,
//     Multiply,
//     Divide,
// };
//
// pub const Compiler = struct {
//     allocator: std.mem.Allocator,
//     instructions: std.ArrayList(Instruction),
//
//     pub fn compile(self: *Compiler, expr: *Expr) !void {
//         switch (expr.*) {
//             .Literal => |literal| try self.instructions.append(.PushLiteral),
//             .Binary => |binary| {
//                 try self.compile(binary.left);
//                 try self.compile(binary.right);
//                 switch (binary.op) {
//                     .Plus => try self.instructions.append(.Add),
//                     .Minus => try self.instructions.append(.Subtract),
//                     .Multiply => try self.instructions.append(.Multiply),
//                     .Divide => try self.instructions.append(.Divide),
//                     else => {},
//                 }
//             },
//         }
//     }
// };
//
// // vm.zig
// const std = @import("std");
// const Instruction = @import("compiler.zig").Instruction;
//
// pub const VirtualMachine = struct {
//     stack: [100]f64 = [_]f64{0} ** 100,
//     sp: usize = 0,
//     instructions: []Instruction,
//     pc: usize = 0,
//
//     pub fn init(instructions: []Instruction) VirtualMachine {
//         return .{ .instructions = instructions };
//     }
//
//     pub fn run(self: *VirtualMachine) f64 {
//         while (self.pc < self.instructions.len) : (self.pc += 1) {
//             switch (self.instructions[self.pc]) {
//                 .PushLiteral => self.push(self.instructions[self.pc + 1]),
//                 .Add => {
//                     const right = self.pop();
//                     const left = self.pop();
//                     self.push(left + right);
//                 },
//                 .Subtract => {
//                     const right = self.pop();
//                     const left = self.pop();
//                     self.push(left - right);
//                 },
//                 .Multiply => {
//                     const right = self.pop();
//                     const left = self.pop();
//                     self.push(left * right);
//                 },
//                 .Divide => {
//                     const right = self.pop();
//                     const left = self.pop();
//                     self.push(left / right);
//                 },
//             }
//         }
//         return self.pop();
//     }
//
//     fn push(self: *VirtualMachine, value: f64) void {
//         self.stack[self.sp] = value;
//         self.sp += 1;
//     }
//
//     fn pop(self: *VirtualMachine) f64 {
//         self.sp -= 1;
//         return self.stack[self.sp];
//     }
// };
//
// // main.zig
// const std = @import("std");
// const Scanner = @import("scanner.zig").Scanner;
// const Parser = @import("parser.zig").Parser;
// const Compiler = @import("compiler.zig").Compiler;
// const VirtualMachine = @import("vm.zig").VirtualMachine;
//
// pub fn main() !void {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//
//     const allocator = arena.allocator();
//
//     var scanner = Scanner{ .source = "1 + 2 * 3" };
//     var parser = Parser{ .scanner = &scanner, .allocator = allocator };
//     var compiler = Compiler{ .allocator = allocator, .instructions = std.ArrayList(Compiler.Instruction).init(allocator) };
//     defer compiler.instructions.deinit();
//
//     const expr = parser.parse() orelse return;
//     try compiler.compile(expr);
//
//     var vm = VirtualMachine.init(compiler.instructions.items);
//     const result = vm.run();
//     std.debug.print("Result: {d}\n", .{result});
// }