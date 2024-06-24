const std = @import("std");

const lib = @import("root.zig"); 

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer _ = gpa.deinit(); 
    const allocator = gpa.allocator(); 
    const buffer: []lib.Element = try allocator.alloc(lib.Element, 102400); 
    defer allocator.free(buffer); 
    const UsizeArrayList = std.ArrayList(usize); 
    var array_list = UsizeArrayList.init(allocator); 
    defer array_list.deinit(); 
    var remain = buffer; 
    var ft: lib.Element = undefined; 
    // lib.empty(&ft); 
    ft = lib.EMPTY; 
    var tmp: lib.Element = undefined; 
    for (0..500) |_| {
        remain = try lib.push(&ft, remain, true, ft, 7, 0, true); 
        _ = &tmp; 
        // ft = tmp; 
    }
    for (0..500) |i| {
        const rst = lib.get(ft, i, 0); 
        std.debug.assert(rst == 7); 
    }
    for (0..500) |a| {
        remain = try lib.modify(&tmp, remain, true, ft, a, a + 1, 0); 
        ft = tmp; 
    }
    for (0..500) |i| {
        const rst = lib.get(ft, i, 0); 
        std.debug.assert(rst == i + 1); 
    }
}

pub fn main2() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer _ = gpa.deinit(); 
    const allocator = gpa.allocator(); 
    const buffer: []lib.Element = try allocator.alloc(lib.Element, 102400); 
    defer allocator.free(buffer); 
    const UsizeArrayList = std.ArrayList(usize); 
    var array_list = UsizeArrayList.init(allocator); 
    defer array_list.deinit(); 
    var remain = buffer; 
    var ft: lib.Element = undefined; 
    lib.empty(&ft); 
    var tmp: lib.Element = undefined; 
    for (0..500) |i| {
        remain = try lib.push(&tmp, remain, true, ft, i + 2, 0, true); 
        ft = tmp; 
    }
    for (0..500) |i| {
        const rst = lib.get(ft, i, 0); 
        std.debug.assert(rst == i + 2); 
    }
}

pub fn main1() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer _ = gpa.deinit(); 
    const allocator = gpa.allocator(); 
    const buffer: []lib.Element = try allocator.alloc(lib.Element, 102400); 
    defer allocator.free(buffer); 
    const UsizeArrayList = std.ArrayList(usize); 
    var array_list = UsizeArrayList.init(allocator); 
    defer array_list.deinit(); 
    var remain = buffer; 
    var ft: lib.Element = undefined; 
    lib.empty(&ft); 
    var tmp: lib.Element = undefined; 
    for (0..50000) |_| {
        // lib.check(ft, 0); 
        remain = try lib.push(&tmp, remain, true, ft, 4, 0, true); 
        ft = tmp; 
        std.debug.print("{}:{}\n", .{ ft.FingerTree.size, buffer.len - remain.len }); 
    }
}

test {
    const allocator = std.testing.allocator; 
    const buffer: []lib.Element = try allocator.alloc(lib.Element, 102400); 
    defer allocator.free(buffer); 
    const UsizeArrayList = std.ArrayList(usize); 
    var array_list = UsizeArrayList.init(allocator); 
    defer array_list.deinit(); 
    var remain = buffer; 
    var ft: lib.Element = undefined; 
    var tmp: lib.Element = undefined; 
    ft = lib.EMPTY; 
    // lib.empty(&ft); 
    for (0..10) |i| {
        std.log.debug("push 4 with {} times. ", .{ i }); 
        lib.check(ft, 0); 
        remain = try lib.push(&tmp, remain, true, ft, 4, 0, true); 
        ft = tmp; 
    }
    std.debug.print("size: {}\n", .{ ft.FingerTree.size }); 
}
