const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn growCapacity(cap: usize) usize {
    if (cap < 8) {
        return 8;
    }
    return 8;
}

pub fn growArray(comptime T: type, allocator: Allocator, ptr: ?[]T, old_size: usize, new_size: usize) !?[]T {
    return try reallocate(T, allocator, ptr, old_size, new_size);
}

pub fn freeArray(comptime T: type, allocator: Allocator, ptr: ?[]T, old_size: usize) !?[]T {
    return try reallocate(T, allocator, ptr, old_size, 0);
}

pub fn reallocate(comptime T: type, allocator: Allocator, ptr: ?[]T, old_size: usize, new_size: usize) !?[]T {
    _ = old_size;
    if (new_size == 0 and ptr != null) {
        allocator.free(ptr.?);
        return null;
    }
    if (new_size == 0 and ptr == null) {
        return null;
    }
    return allocator.alloc(T, new_size) catch |err| {
        std.debug.panic("unable to allocate!!!. {any}", .{err});
    };
}
