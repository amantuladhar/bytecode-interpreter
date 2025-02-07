const std = @import("std");
const Scanner = @import("Scanner.zig");
const Chunk = @import("chunk.zig");
const Token = @import("Token.zig");
const ValueArr = @import("ValueArr.zig");
const object = @import("object.zig");
const VM = @import("vm.zig");
const Value = ValueArr.Value;
const ChunkValue = Chunk.ChunkValue;
const TokenType = Token.TokenType;
const OpCode = Chunk.OpCode;

const Self = @This();

source: []const u8,
allocator: std.mem.Allocator,
scanner: *Scanner,
parser: Parser,
chunk: *Chunk,
vm: *VM,

pub fn init(
    allocator: std.mem.Allocator,
    vm: *VM,
    source: []const u8,
    chunk: *Chunk,
) !Self {
    var scanner = try allocator.create(Scanner);
    scanner.* = Scanner.init(source);
    return .{
        .allocator = allocator,
        .vm = vm,
        .source = source,
        .scanner = scanner,
        .chunk = chunk,
        .parser = .{
            .scanner = scanner,
            .current = scanner.scanToken(),
        },
    };
}

pub fn deinit(s: *Self) void {
    s.allocator.destroy(s.scanner);
}

pub fn compile(s: *Self) void {
    // s.advance();
    s.expression();
    s.consume(.Eof, "Expect end of expression");
    s.endCompiler();
}

fn consume(s: *Self, token: TokenType, msg: []const u8) void {
    if (s.parser.current.type == token) {
        s.advance();
        return;
    }
    s.errorAt(&s.parser.current, msg);
}

fn endCompiler(s: *Self) void {
    s.emitReturn();
}

fn expression(s: *Self) void {
    s.parsePrecedence(.Equality);
}

fn parsePrecedence(s: *Self, rbp: Precedence) void {
    s.advance();
    const rule_index = @intFromEnum(s.parser.previous.?.type);
    const parse_rule = RULES[rule_index];
    if (parse_rule.prefix) |prefix_fn| {
        prefix_fn(s);
    } else {
        s.errorAt(&s.parser.previous.?, "expect expression");
        return;
    }
    while (@intFromEnum(rbp) <= @intFromEnum(RULES[@intFromEnum(s.parser.current.type)].precedence)) {
        s.advance();
        const rule = RULES[@intFromEnum(s.parser.previous.?.type)];
        rule.infix.?(s);
    }
}

const ParseFn = *const fn (s: *Self) void;

const ParseRule = struct {
    prefix: ?ParseFn = null,
    infix: ?ParseFn = null,
    precedence: Precedence = .None,
};

const precedence_fields = @typeInfo(TokenType).Enum.fields;
const RULES: [precedence_fields.len]ParseRule = blk: {
    var rules: [precedence_fields.len]ParseRule = undefined;
    for (precedence_fields) |token| {
        const token_type: TokenType = @enumFromInt(token.value);
        rules[token.value] = switch (token_type) {
            .LeftParen => .{ .prefix = grouping },
            .Minus => .{ .prefix = unary, .infix = binary, .precedence = .Term },
            .Plus => .{ .infix = binary, .precedence = .Term },
            .Slash, .Star => .{ .infix = binary, .precedence = .Factor },
            .Bang => .{ .prefix = unary },
            .BangEqual, .EqualEqual => .{ .infix = binary, .precedence = .Equality },
            .Greater, .GreaterEqual => .{ .infix = binary, .precedence = .Comparision },
            .Number => .{ .prefix = number },
            .False, .True, .Nil => .{ .prefix = literal },
            .String => .{ .prefix = string },
            .RightParen => .{},
            .LeftBrace => .{},
            .RightBrace => .{},
            .Comma => .{},
            .Dot => .{},
            .Semicolon => .{},
            .Equal => .{},
            .Less => .{},
            .LessEqual => .{},
            .Ident => .{},
            .And => .{},
            .Class => .{},
            .Else => .{},
            .For => .{},
            .Fun => .{},
            .If => .{},
            .Or => .{},
            .Print => .{},
            .Super => .{},
            .Return => .{},
            .This => .{},
            .Var => .{},
            .While => .{},
            .Error => .{},
            .Eof => .{},
        };
    }
    break :blk rules;
};

fn createRule() [std.meta.fields(Precedence).len]ParseRule {}

fn grouping(s: *Self) void {
    s.expression();
    s.consume(.RightParen, "Expect ')' after expression");
}

fn unary(s: *Self) void {
    const token_type = s.parser.previous.?.type;
    s.expression();
    switch (token_type) {
        .Bang => s.emitOpCode(.Not),
        .Minus => s.emitOpCode(.Negate),
        else => {},
    }
}

fn binary(s: *Self) void {
    const token_type = s.parser.previous.?.type;
    const rule = RULES[@intFromEnum(token_type)];
    s.parsePrecedence(@enumFromInt(@intFromEnum(rule.precedence) + 1));
    switch (token_type) {
        .BangEqual => s.emitOpCodes(.Equal, .Not),
        .EqualEqual => s.emitOpCode(.Equal),
        .Greater => s.emitOpCode(.Greater),
        .GreaterEqual => s.emitOpCodes(.Less, .Not),
        .Less => s.emitOpCode(.Less),
        .LessEqual => s.emitOpCodes(.Greater, .Not),
        .Plus => s.emitOpCode(.Add),
        .Minus => s.emitOpCode(.Subtract),
        .Star => s.emitOpCode(.Multiply),
        .Slash => s.emitOpCode(.Divide),
        else => unreachable,
    }
}

fn number(s: *Self) void {
    const n = std.fmt.parseFloat(f32, s.parser.previous.?.text) catch unreachable;
    s.emitConstant(.{ .Number = n });
}

fn literal(s: *Self) void {
    switch (s.parser.previous.?.type) {
        .False => s.emitByte(.{ .OpCode = .False }),
        .True => s.emitByte(.{ .OpCode = .True }),
        .Nil => s.emitByte(.{ .OpCode = .Nil }),
        else => unreachable,
    }
}

fn string(s: *Self) void {
    const str = object.copyString(s.allocator, &s.vm.strings, s.parser.previous.?.text) catch unreachable;
    const obj = object.Obj.init(s.allocator, s.vm, .{ .String = str }) catch unreachable;
    const v: Value = .{ .Obj = obj };
    s.emitConstant(v);
}

fn emitConstant(s: *Self, v: Value) void {
    s.emitBytes(.{ .OpCode = .Constant }, s.makeConstant(v));
}

fn makeConstant(s: *Self, v: Value) ChunkValue {
    const c = s.chunk.addConstant(v) catch unreachable;
    return .{ .Constant = c };
}

fn emitOpCode(s: *Self, op_code: OpCode) void {
    s.emitByte(.{ .OpCode = op_code });
}

fn emitByte(s: *Self, chunk: ChunkValue) void {
    s.chunk.write(chunk, s.parser.previous.?.line) catch unreachable;
}

fn emitOpCodes(s: *Self, op_code1: OpCode, op_code2: OpCode) void {
    s.emitByte(.{ .OpCode = op_code1 });
    s.emitByte(.{ .OpCode = op_code2 });
}

fn emitBytes(s: *Self, chunk1: ChunkValue, chunk2: ChunkValue) void {
    s.emitByte(chunk1);
    s.emitByte(chunk2);
}

fn emitReturn(s: *Self) void {
    s.emitByte(.{ .OpCode = .Return });
}

// Higher the number higher the priority
pub const Precedence = enum(u8) {
    None,
    Assignment,
    Or,
    And,
    Equality,
    Comparision,
    Term,
    Factor,
    Unary,
    Call,
    Primary,
};

fn advance(s: *Self) void {
    s.parser.previous = s.parser.current;
    while (true) {
        s.parser.current = s.scanner.scanToken();
        if (s.parser.current.type != .Error) break;
        s.errorAt(&s.parser.current, "");
    }
}

fn errorAt(s: *Self, token: *const Token, msg: []const u8) void {
    if (s.parser.panicMode) return;
    s.parser.panicMode = true;
    std.debug.print("[line {d}] Error", .{token.line});
    switch (token.type) {
        .Error => {},
        .Eof => std.debug.print(" at end", .{}),
        else => std.debug.print(" at '{s}'", .{token.text}),
    }
    std.debug.print(" : {s}\n", .{msg});
    s.parser.hadError = true;
}

const Parser = struct {
    scanner: *Scanner,
    current: Token,
    previous: ?Token = null,
    hadError: bool = false,
    panicMode: bool = false,
};

test "compile expressions" {
    const allocator = std.testing.allocator;
    const TestInstruction = struct { chunk: ChunkValue, constant: ?Value = null };
    const TestCase = struct { source: []const u8, expected: []const TestInstruction };

    const test_cases = [_]TestCase{
        // Single number
        .{
            .source = "5",
            .expected = &[_]TestInstruction{
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 0 }, .constant = .{ .Number = 5 } },
                .{ .chunk = .{ .OpCode = .Return } },
            },
        },
        // Binary expression
        .{
            .source = "5 + 10",
            .expected = &[_]TestInstruction{
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 0 }, .constant = .{ .Number = 5 } },
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 1 }, .constant = .{ .Number = 10 } },
                .{ .chunk = .{ .OpCode = .Add } },
                .{ .chunk = .{ .OpCode = .Return } },
            },
        },
        // Chained binary
        .{
            .source = "5 + 10 * 15 / 20",
            .expected = &[_]TestInstruction{
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 0 }, .constant = .{ .Number = 5 } },
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 1 }, .constant = .{ .Number = 10 } },
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 2 }, .constant = .{ .Number = 15 } },
                .{ .chunk = .{ .OpCode = .Multiply } },
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 3 }, .constant = .{ .Number = 20 } },
                .{ .chunk = .{ .OpCode = .Divide } },
                .{ .chunk = .{ .OpCode = .Add } },
                .{ .chunk = .{ .OpCode = .Return } },
            },
        },
        // equality
        .{
            .source = "10 == 10",
            .expected = &[_]TestInstruction{
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 0 }, .constant = .{ .Number = 10 } },
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 1 }, .constant = .{ .Number = 10 } },
                .{ .chunk = .{ .OpCode = .Equal } },
                .{ .chunk = .{ .OpCode = .Return } },
            },
        },
        // boolean
        .{
            .source = "true",
            .expected = &[_]TestInstruction{
                .{ .chunk = .{ .OpCode = .True } },
                .{ .chunk = .{ .OpCode = .Return } },
            },
        },
        // long comparision
        .{
            .source = "!(5 - 4 > 3 * 2 == !nil)",
            .expected = &[_]TestInstruction{
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 0 }, .constant = .{ .Number = 5 } },
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 1 }, .constant = .{ .Number = 4 } },
                .{ .chunk = .{ .OpCode = .Subtract } },
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 2 }, .constant = .{ .Number = 3 } },
                .{ .chunk = .{ .OpCode = .Constant } },
                .{ .chunk = .{ .Constant = 3 }, .constant = .{ .Number = 2 } },
                .{ .chunk = .{ .OpCode = .Multiply } },
                .{ .chunk = .{ .OpCode = .Greater } },
                .{ .chunk = .{ .OpCode = .Nil } },
                .{ .chunk = .{ .OpCode = .Not } },
                .{ .chunk = .{ .OpCode = .Equal } },
                .{ .chunk = .{ .OpCode = .Not } },
                .{ .chunk = .{ .OpCode = .Return } },
            },
        },
        .{
            .source = "false == true",
            .expected = &[_]TestInstruction{
                .{ .chunk = .{ .OpCode = .False } },
                .{ .chunk = .{ .OpCode = .True } },
                .{ .chunk = .{ .OpCode = .Equal } },
                .{ .chunk = .{ .OpCode = .Return } },
            },
        },
    };

    for (test_cases) |case| {
        const source = case.source;
        const expected = case.expected;

        var chunk = try Chunk.init(allocator);
        defer chunk.deinit();
        var vm = VM.init(allocator, &chunk);
        defer vm.deinit();

        var compiler = try init(allocator, &vm, source, &chunk);
        defer compiler.deinit();
        compiler.compile();

        // for (chunk.code[0..chunk.len]) |c| {
        //     std.debug.print("{any}\n", .{c});
        // }

        try std.testing.expectEqual(expected.len, chunk.len);
        for (expected, chunk.code[0..chunk.len]) |exp, actual| {
            try std.testing.expectEqual(exp.chunk, actual);
            if (exp.constant) |constant| {
                try std.testing.expectEqual(chunk.constants.values[exp.chunk.Constant], constant);
            }
        }
    }
}
