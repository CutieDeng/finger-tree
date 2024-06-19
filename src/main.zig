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
    lib.empty(&ft); 
    var tmp: lib.Element = undefined; 
    for (0..20) |i| {
        std.log.debug("push 4 with {} times. ", .{ i }); 
        lib.check(ft, 0); 
        remain = try lib.push(&tmp, remain, true, ft, 4, 0, true); 
        ft = tmp; 
        std.log.debug("now size: {}", .{ ft.FingerTree.size }); 
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
    lib.empty(&ft); 
    for (0..10) |i| {
        std.log.debug("push 4 with {} times. ", .{ i }); 
        lib.check(ft, 0); 
        remain = try lib.push(&tmp, remain, true, ft, 4, 0, true); 
        ft = tmp; 
    }
    std.debug.print("size: {}\n", .{ ft.FingerTree.size }); 
}
