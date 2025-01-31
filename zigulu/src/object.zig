const std = @import("std");
const Allocator = std.mem.Allocator;
const VM = @import("vm.zig");

pub const Obj = struct {
    value: ObjValue,
    next: ?*Obj = null,
    allocator: Allocator,

    pub fn init(allocator: Allocator, vm: *VM, value: ObjValue) !*Obj {
        const self = try allocator.create(Obj);
        self.* = .{
            .value = value,
            .allocator = allocator,
        };
        self.next = vm.objects;
        vm.objects = self;
        return self;
    }

    pub fn deinit(self: *Obj) void {
        switch (self.value) {
            .String => self.value.String.deinit(),
        }
        self.allocator.destroy(self);
    }
};

pub const ObjValue = union(enum) {
    String: *ObjString,
};

pub const ObjString = struct {
    allocator: Allocator,
    value: []const u8,

    const Self = @This();

    pub fn init(allocator: Allocator, chars: []const u8) !*Self {
        const self = try allocator.create(Self);
        const dup_str = try allocator.dupe(u8, chars);
        self.* = .{
            .allocator = allocator,
            .value = dup_str,
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.value);
        self.allocator.destroy(self);
    }

    pub fn concatenate(allocator: Allocator, str1: []const u8, str2: []const u8) !*ObjString {
        const new_str = try std.fmt.allocPrint(allocator, "{s}{s}", .{ str1[1 .. str1.len - 1], str2[1 .. str2.len - 1] });
        defer allocator.free(new_str);
        return try ObjString.init(allocator, new_str);
    }
};

pub fn copyString(allocator: Allocator, chars: []const u8) !*ObjString {
    return try ObjString.init(allocator, chars);
}
