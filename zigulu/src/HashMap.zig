const std = @import("std");
const Allocator = std.mem.Allocator;
const object = @import("object.zig");
const ObjString = object.ObjString;
const ValueArr = @import("ValueArr.zig");
const Value = ValueArr.Value;
const HashMap = @import("HashMap.zig");

count: usize,
capacity: usize,
entries: []Entry,
allocator: Allocator,

const MAX_LOAD = 0.70;

const Entry = struct {
    key: ?*ObjString = null,
    value: ?Value = null,
    is_dead_entry: bool = false,
};

const Self = @This();

pub fn init(allocator: Allocator) Self {
    var self: Self = .{
        .count = 0,
        .capacity = 0,
        .allocator = allocator,
        .entries = allocator.alloc(Entry, 0) catch unreachable,
    };
    self.adjustCapacity(8) catch unreachable;
    return self;
}

pub fn deinit(s: *Self) void {
    for (s.entries) |entry| {
        if (entry.key) |key| {
            // these are owned by 'vm.strings' as this is contrived example for HashMap
            key.deinit();
        }
    }
    s.allocator.free(s.entries);
    s.count = 0;
    s.capacity = 0;
}

pub fn put(s: *Self, key: *ObjString, value: Value) !void {
    const load_factor: f32 = MAX_LOAD;

    const load_cap: usize = @intFromFloat(@as(f32, @floatFromInt(s.capacity)) * load_factor);
    if (s.capacity == 0 or s.count + 1 > load_cap) {
        const new_cap = s.capacity * 2;
        try s.adjustCapacity(if (new_cap < 8) 8 else new_cap);
    }
    const entry = findEntry(s.entries, key, s.capacity);
    if (entry.key == null and !entry.is_dead_entry) {
        s.count += 1;
    }
    entry.key = key;
    entry.value = value;
}

pub fn get(s: *Self, key: *ObjString) ?Value {
    const entry = findEntry(s.entries, key, s.capacity);
    return entry.value;
}

pub fn remove(s: *Self, key: *ObjString) void {
    const entry = findEntry(s.entries, key, s.capacity);
    if (entry.key != null) {
        // vm.strings owns the string
        const k = entry.key.?;
        k.deinit();
        entry.key = null;

        const v = entry.value.?;
        if (v == .Obj) {
            v.Obj.deinit();
        }
        entry.value = null;
        entry.is_dead_entry = true;
        s.count -= 1;
    }
}

fn findEntry(entries: []Entry, key: *ObjString, capacity: usize) *Entry {
    var index: usize = key.hash % capacity;
    var counter: usize = 0;
    var first_dead_entry: ?*Entry = null;
    while (true) {
        counter += 1;
        if (counter > capacity) {
            @panic("What goes around, goes around, goes around, goes around, comes back aroud... yeah!!");
        }
        const entry = &entries[index];

        if (entry.key) |entry_key| {
            if (entry_key.hash == key.hash and
                entry_key.value.len == key.value.len and
                entry_key == key)
                //std.mem.eql(u8, entry_key.value, key.value))
            {
                return entry;
            }
            if (first_dead_entry != null) {
                return first_dead_entry.?;
            }
        } else {
            if (!entry.is_dead_entry) {
                return entry;
            }
            if (first_dead_entry == null) {
                first_dead_entry = entry;
            }
        }
        index += index;
        index %= capacity;
    }
    return null;
}

pub fn findString(s: *const Self, chars: []const u8, hash: usize) ?*ObjString {
    if (chars.len <= 0) {
        return null;
    }
    var index: usize = hash % s.capacity;
    var counter: usize = 0;

    while (true) {
        defer counter += 1;
        if (counter > s.capacity) {
            @panic("findString:: loop loop loop");
        }
        const entry: *Entry = &s.entries[index];
        if (entry.key) |key| {
            if (key.value.len == chars.len and
                key.hash == hash and
                std.mem.eql(u8, key.value, chars))
            {
                return key;
            }
        } else {
            if (!entry.is_dead_entry) {
                return null;
            }
        }
        index += 1;
        index %= s.capacity;
    }
}

fn adjustCapacity(s: *Self, new_cap: usize) !void {
    const entries = try s.allocator.alloc(Entry, new_cap);
    for (0..entries.len) |i| {
        entries[i].key = null;
        entries[i].value = null;
        entries[i].is_dead_entry = false;
    }

    s.count = 0;
    const old_capacity = s.capacity;
    for (0..old_capacity) |i| {
        const entry: *Entry = &s.entries[i];
        if (entry.key == null) {
            continue;
        }
        const dest = findEntry(entries, entry.key.?, new_cap);
        dest.key = entry.key;
        dest.value = entry.value;
        dest.is_dead_entry = false;
        s.count += 1;
    }
    // INVESTIGATE: realloc is removing old data - maybe I am halucinating
    const old_entry = s.entries;
    s.allocator.free(old_entry);
    s.entries = entries;
    s.capacity = new_cap;
}

test "HashMap" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // var strings = init(allocator);
    // defer strings.deinit();

    var map = init(allocator);
    defer map.deinit();
    const key1 = try ObjString.init(allocator, "one", &map);
    const key2 = try ObjString.init(allocator, "two", &map);
    const three = try ObjString.init(allocator, "three", &map);
    const four = try ObjString.init(allocator, "four", &map);
    const five = try ObjString.init(allocator, "five", &map);
    const six = try ObjString.init(allocator, "six", &map);
    const seven = try ObjString.init(allocator, "seven", &map);

    try map.put(key1, .{ .Number = 1 });
    try map.put(key2, .{ .Number = 2 });
    try map.put(key2, .{ .Number = 2 });
    try map.put(key2, .{ .Number = 2 });
    try map.put(three, .{ .Number = 3 });
    try map.put(four, .{ .Number = 4 });

    // testPrettyPrint(&map.entries);
    try map.put(five, .{ .Number = 5 });
    try map.put(six, .{ .Number = 6 });
    try map.put(seven, .{ .Number = 7 });

    try testing.expectEqual(map.count, 7);

    // testPrettyPrint(&map.entries);
    const value_one = map.get(key1);
    const value_two = map.get(key2);
    const value_three = map.get(three);

    try testing.expectEqual(value_one.?.Number, 1);
    try testing.expectEqual(value_two.?.Number, 2);
    try testing.expectEqual(value_three.?.Number, 3);

    map.remove(key1);
    try testing.expectEqual(map.count, 6);

    const kk1 = try ObjString.init(allocator, "one", null);
    defer kk1.deinit();
    const value_one_ = map.get(kk1);
    std.debug.print("{any}\n", .{value_one_});
    try testing.expect(value_one_ == null);

    // testPrettyPrint(&map.entries);
}

fn testPrettyPrint(entries: *const []Entry) void {
    std.debug.print("\n-----------------\n", .{});
    for (entries.*, 0..) |entry, i| {
        var xx: [1024]u8 = undefined;
        const key = if (entry.key) |k| k.value else null;
        const value = switch (entry.value orelse .Nil) {
            .Number => std.fmt.bufPrint(&xx, "{d}", .{entry.value.?.Number}) catch unreachable,
            .Bool => std.fmt.bufPrint(&xx, "{any}", .{entry.value.?.Bool}) catch unreachable,
            .Obj => switch (entry.value.?.Obj.*.value) {
                .String => entry.value.?.Obj.*.value.String.value,
            },
            .Nil => "nil",
        };
        const is_dead_entry = entry.is_dead_entry;
        std.debug.print("{d}.key={s},value={s},,{any},,\n", .{ i, if (key == null) "NULL" else key.?, value, is_dead_entry });
    }
    std.debug.print("\n-----------------\n", .{});
}
