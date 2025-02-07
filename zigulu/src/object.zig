const std = @import("std");
const Allocator = std.mem.Allocator;
const VM = @import("vm.zig");
const HashMap = @import("HashMap.zig");

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
    hash: usize,

    const Self = @This();

    pub fn init(allocator: Allocator, chars: []const u8, string_intern_store: ?*HashMap) !*Self {
        const hash = hashString(chars);
        if (string_intern_store) |intern_store| {
            const intern = intern_store.findString(chars, hash);
            if (intern) |str| {
                return str;
            }
        }
        const self = try allocator.create(Self);
        const dup_str = try allocator.dupe(u8, chars);
        self.* = .{
            .allocator = allocator,
            .value = dup_str,
            .hash = hash,
        };
        if (string_intern_store) |intern_store| {
            try intern_store.put(self, .Nil);
        }
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.value);
        self.allocator.destroy(self);
    }

    pub fn concatenate(allocator: Allocator, intern_map: *HashMap, str1: []const u8, str2: []const u8) !*ObjString {
        const new_str = try std.fmt.allocPrint(allocator, "{s}{s}", .{ str1[1 .. str1.len - 1], str2[1 .. str2.len - 1] });
        defer allocator.free(new_str);
        return try ObjString.init(allocator, new_str, intern_map);
    }
};

pub fn copyString(allocator: Allocator, intern_map: *HashMap, chars: []const u8) !*ObjString {
    return try ObjString.init(allocator, chars, intern_map);
}

// FNV-1: https://www.isthe.com/chongo/tech/comp/fnv/
fn hashString(key: []const u8) usize {
    var hash: usize = 21666136261;
    for (0..key.len) |i| {
        hash ^= key[i];
        hash *%= 16777619;
    }
    return hash;
}
