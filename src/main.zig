const std = @import("std");
const Allocator = std.mem.Allocator; 

const lib = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    if (true) {
        // return justPush12Elements(gpa.allocator()); 
    }
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
    for (0..500) |v| {
        remain = try lib.push(&ft, remain, true, ft, v + 2, 0, true);
    }
    for (0..500) |i| {
        const rst = lib.get(ft, i, 0);
        if (rst != i + 2) {
            std.log.err("rst: {}; i: {}", .{ rst, i });
        } else {
        //     std.log.debug("rst: {}; i: {}", .{ rst, i }); 
        }
    }
}

test "push 12 elements" {
    try justPush12Elements(std.testing.allocator); 
}

fn justPush12Elements(allocator: Allocator) !void {
    const buffer = try allocator.alloc(lib.Element, 1024);  
    defer allocator.free(buffer); 
    var ft: lib.Element = lib.EMPTY; 
    var remain: []lib.Element = buffer; 
    for (0..12) |i| {
        remain = try lib.push(&ft, remain, true, ft, i + 1, 0, true); 
        for (0..i+1) |inner| {
            const v = lib.get(ft, inner, 0); 
            if (v != inner + 1) {
                std.log.err("round [{}], [{}] = {} but expect {}", 
                    .{ i, inner, v, inner + 1 }); 
                const d: *lib.Element = @ptrFromInt(ft.FingerTree.ptr); 
                const l: *lib.Element = @ptrFromInt(d.Deep.left); 
                const r: *lib.Element = @ptrFromInt(d.Deep.right); 
                std.log.err("|left : {any}", .{ l.Four }); 
                std.log.err("|right: {any}", .{ r.Four }); 
            }
        }
    }
}

pub fn main3() !void {
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
    for (0..500) |_| {
        remain = try lib.push(&ft, remain, true, ft, 7, 0, true);
    }
    for (0..500) |i| {
        const rst = lib.get(ft, i, 0);
        std.debug.assert(rst == 7);
    }
    for (0..500) |a| {
        remain = try lib.modify(&ft, remain, true, ft, a, a + 1, 0);
    }
    // lib.debug.check(ft, 0);
    for (0..500) |i| {
        const rst = lib.get(ft, i, 0);
        if (rst != i + 1) {
            std.log.err("rst: {}; i: {}", .{ rst, i });
        } else {
            // std.log.debug("rst: {}; i: {}", .{ rst, i });
        }
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
        std.log.debug("push 4 with {} times. ", .{i});
        lib.debug.check(ft, 0);
        remain = try lib.push(&tmp, remain, true, ft, 4, 0, true);
        ft = tmp;
    }
    std.debug.print("size: {}\n", .{ft.FingerTree.size});
}
