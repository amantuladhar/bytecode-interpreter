const std = @import("std");
const Token = @import("Token.zig");
const TokenType = Token.TokenType;

const Self = @This();
source: []const u8,
start: usize,
current: usize,
line: usize,

pub fn init(source: []const u8) Self {
    return .{
        .source = source,
        .start = 0,
        .current = 0,
        .line = 1,
    };
}

pub fn scanToken(s: *Self) Token {
    s.skipIgnoredChars();
    s.start = s.current;

    if (s.isAtEnd()) {
        return s.makeToken(.Eof);
    }

    const c = s.consume();
    if (isAlpha(c)) {
        return s.identifier();
    }
    if (isDigit(c)) {
        return s.number();
    }

    return switch (c) {
        '(' => s.makeToken(.LeftParen),
        ')' => s.makeToken(.RightParen),
        '{' => s.makeToken(.LeftBrace),
        '}' => s.makeToken(.RightBrace),
        ';' => s.makeToken(.Semicolon),
        ',' => s.makeToken(.Comma),
        '.' => s.makeToken(.Dot),
        '-' => s.makeToken(.Minus),
        '+' => s.makeToken(.Plus),
        '/' => s.makeToken(.Slash),
        '*' => s.makeToken(.Star),
        '!' => bang: {
            if (s.match(1, "=", true)) {
                break :bang s.makeToken(.BangEqual);
            }
            break :bang s.makeToken(.Bang);
        },
        '=' => eql: {
            if (s.match(1, "=", true)) {
                break :eql s.makeToken(.EqualEqual);
            }
            break :eql s.makeToken(.Equal);
        },
        '<' => less: {
            if (s.match(1, "=", true)) {
                break :less s.makeToken(.LessEqual);
            }
            break :less s.makeToken(.Less);
        },
        '>' => gt: {
            if (s.match(1, "=", true)) {
                break :gt s.makeToken(.GreaterEqual);
            }
            break :gt s.makeToken(.Greater);
        },
        '"' => s.string(),
        else => return s.errorToken("Unexpected character"),
    };
}

pub fn number(s: *Self) Token {
    while (!s.isAtEnd() and isDigit(s.peek(0))) {
        _ = s.consume();
    }
    if (!s.isAtEnd() and s.peek(0) == '.' and isDigit(s.peek(1))) {
        _ = s.consume();
        while (!s.isAtEnd() and isDigit(s.peek(0))) {
            _ = s.consume();
        }
    }
    return s.makeToken(.Number);
}

pub fn identifier(s: *Self) Token {
    while (!s.isAtEnd() and (isAlpha(s.peek(0)) or isDigit(s.peek(0)))) {
        _ = s.consume();
    }
    return s.makeToken(s.identType());
}

pub fn identType(s: *Self) TokenType {
    const cur_token = s.source[s.start..s.current];
    if (std.mem.eql(u8, cur_token, "and")) {
        return .And;
    }
    if (std.mem.eql(u8, cur_token, "class")) {
        return .Class;
    }
    if (std.mem.eql(u8, cur_token, "else")) {
        return .Else;
    }
    if (std.mem.eql(u8, cur_token, "false")) {
        return .False;
    }
    if (std.mem.eql(u8, cur_token, "for")) {
        return .For;
    }
    if (std.mem.eql(u8, cur_token, "fun")) {
        return .Fun;
    }
    if (std.mem.eql(u8, cur_token, "if")) {
        return .If;
    }
    if (std.mem.eql(u8, cur_token, "nil")) {
        return .Nil;
    }
    if (std.mem.eql(u8, cur_token, "or")) {
        return .Or;
    }
    if (std.mem.eql(u8, cur_token, "print")) {
        return .Print;
    }
    if (std.mem.eql(u8, cur_token, "return")) {
        return .Return;
    }
    if (std.mem.eql(u8, cur_token, "super")) {
        return .Super;
    }
    if (std.mem.eql(u8, cur_token, "this")) {
        return .This;
    }
    if (std.mem.eql(u8, cur_token, "true")) {
        return .True;
    }
    if (std.mem.eql(u8, cur_token, "var")) {
        return .Var;
    }
    if (std.mem.eql(u8, cur_token, "while")) {
        return .While;
    }
    return .Ident;
}

pub fn string(s: *Self) Token {
    while (s.peek(0) != '"' and !s.isAtEnd()) {
        _ = s.consume();
        if (s.peek(0) == '\n') {
            s.line += 1;
        }
    }
    if (s.isAtEnd()) {
        return s.errorToken("Unterminated String");
    }
    _ = s.consume(); // consume closing "
    return s.makeToken(.String);
}

pub fn match(s: *Self, c_len: u8, str: []const u8, consume_token: bool) bool {
    const rem = s.source[s.start + c_len .. s.start + c_len + str.len];
    const result = std.mem.eql(u8, rem, str);
    if (result and consume_token) {
        s.current += str.len;
    }
    return result;
}

pub fn makeToken(s: *const Self, token_type: TokenType) Token {
    return Token{
        .line = s.line,
        .type = token_type,
        .text = s.source[s.start..s.current],
    };
}

pub fn errorToken(s: *const Self, message: []const u8) Token {
    return Token{
        .line = s.line,
        .type = .Error,
        .text = message,
    };
}

pub fn skipIgnoredChars(s: *Self) void {
    while (true) {
        switch (s.peek(0)) {
            ' ', '\r', '\t', '\n' => {
                const c = s.consume();
                if (c == '\n') {
                    s.line += 1;
                }
            },
            '/' => {
                if (s.peek(1) == '/') {
                    while (s.peek(0) != '\n' and !s.isAtEnd()) {
                        _ = s.consume();
                    }
                }
            },
            else => return,
        }
    }
}

pub fn isAtEnd(s: *const Self) bool {
    return s.current >= s.source.len;
}

pub fn peek(s: *const Self, offset: usize) u8 {
    if (s.isAtEnd()) {
        return 0;
    }
    return s.source[s.current + offset];
}

pub fn consume(s: *Self) u8 {
    const cur = s.source[s.current];
    s.current += 1;
    return cur;
}

pub fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}

pub fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

test "two char token" {
    const testing = std.testing;
    var scanner = Self.init("a == b");

    var t: Token = scanner.scanToken();
    try testing.expectEqual(t.line, 1);
    try testing.expectEqualSlices(u8, t.text, "a");
    try testing.expectEqual(t.type, .Ident);

    t = scanner.scanToken();
    try testing.expectEqual(t.line, 1);
    try testing.expectEqualSlices(u8, "==", t.text);
    try testing.expectEqual(t.type, .EqualEqual);

    t = scanner.scanToken();
    try testing.expectEqual(t.line, 1);
    try testing.expectEqualSlices(u8, "b", t.text);
    try testing.expectEqual(t.type, .Ident);
}

test "basic" {
    const testing = std.testing;
    var scanner = Self.init("1 + 1");

    var t: Token = scanner.scanToken();
    try testing.expectEqual(t.line, 1);
    try testing.expectEqualSlices(u8, t.text, "1");
    try testing.expectEqual(t.type, .Number);

    t = scanner.scanToken();
    try testing.expectEqual(t.line, 1);
    try testing.expectEqualSlices(u8, t.text, "+");
    try testing.expectEqual(t.type, .Plus);

    t = scanner.scanToken();
    try testing.expectEqual(t.line, 1);
    try testing.expectEqualSlices(u8, t.text, "1");
    try testing.expectEqual(t.type, .Number);
}

test "keywords" {
    const testing = std.testing;

    var scanner = Self.init("and or if else for while true false var class return this fun nil print super");

    const TestData = std.meta.Tuple(&.{ TokenType, []const u8 });
    const token_types = [_]TestData{
        .{ .And, "and" },       .{ .Or, "or" },
        .{ .If, "if" },         .{ .Else, "else" },
        .{ .For, "for" },       .{ .While, "while" },
        .{ .True, "true" },     .{ .False, "false" },
        .{ .Var, "var" },       .{ .Class, "class" },
        .{ .Return, "return" }, .{ .This, "this" },
        .{ .Fun, "fun" },       .{ .Nil, "nil" },
        .{ .Print, "print" },   .{ .Super, "super" },
    };

    for (token_types) |t_type| {
        const t: Token = scanner.scanToken();
        try testing.expectEqual(t.line, 1);
        try testing.expectEqual(t.type, t_type.@"0");
        try testing.expectEqualSlices(u8, t.text, t_type.@"1");
    }
}

test "advanced" {
    const testing = std.testing;
    const source: []const u8 =
        \\ var a = 1;
        \\ var b = 2;
        \\ var c = a == b;
        \\ if (c) {
        \\   print "inside if";
        \\ } else {
        \\   print "inside else";
        \\}
        \\ while(true) {}
        \\ // test
        \\ fun(){}
    ;

    const TestData = std.meta.Tuple(&.{ usize, TokenType, []const u8 });
    const token_types = [_]TestData{
        .{ 1, .Var, "var" },
        .{ 1, .Ident, "a" },
        .{ 1, .Equal, "=" },
        .{ 1, .Number, "1" },
        .{ 1, .Semicolon, ";" },

        .{ 2, .Var, "var" },
        .{ 2, .Ident, "b" },
        .{ 2, .Equal, "=" },
        .{ 2, .Number, "2" },
        .{ 2, .Semicolon, ";" },

        .{ 3, .Var, "var" },
        .{ 3, .Ident, "c" },
        .{ 3, .Equal, "=" },
        .{ 3, .Ident, "a" },
        .{ 3, .EqualEqual, "==" },
        .{ 3, .Ident, "b" },
        .{ 3, .Semicolon, ";" },

        .{ 4, .If, "if" },
        .{ 4, .LeftParen, "(" },
        .{ 4, .Ident, "c" },
        .{ 4, .RightParen, ")" },
        .{ 4, .LeftBrace, "{" },

        .{ 5, .Print, "print" },
        .{ 5, .String, "\"inside if\"" },
        .{ 5, .Semicolon, ";" },

        .{ 6, .RightBrace, "}" },
        .{ 6, .Else, "else" },
        .{ 6, .LeftBrace, "{" },

        .{ 7, .Print, "print" },
        .{ 7, .String, "\"inside else\"" },
        .{ 7, .Semicolon, ";" },

        .{ 8, .RightBrace, "}" },

        .{ 9, .While, "while" },
        .{ 9, .LeftParen, "(" },
        .{ 9, .True, "true" },
        .{ 9, .RightParen, ")" },
        .{ 9, .LeftBrace, "{" },
        .{ 9, .RightBrace, "}" },

        // 10 is comment

        .{ 11, .Fun, "fun" },
        .{ 11, .LeftParen, "(" },
        .{ 11, .RightParen, ")" },
        .{ 11, .LeftBrace, "{" },
        .{ 11, .RightBrace, "}" },
    };

    var scanner = Self.init(source);

    for (token_types) |t_type| {
        const t: Token = scanner.scanToken();
        try testing.expectEqual(t_type.@"0", t.line);
        try testing.expectEqualSlices(u8, t_type.@"2", t.text);
        try testing.expectEqual(t_type.@"1", t.type);
    }
}
