const lib = @import("root.zig"); 
const std = @import("std"); 

const Element = lib.Element; 

const init = @import("init.zig"); 
const alloc = @import("alloc.zig"); 
const size_calc = @import("size_calc.zig"); 

const EMPTY = init.EMPTY; 
const allocOne = alloc.allocOne; 
const maybeThreeGetSize = size_calc.maybeThreeGetSize; 
const fourLength = size_calc.fourLength; 
const initSingle = init.initSingle; 
const threeSizeUpdateDirectly = size_calc.threeSizeUpdateDirectly; 

pub fn push(e: *Element, buffer: []Element, use_first: bool, origin: Element, value: usize, depth: usize, right: bool) ![]Element {
    std.debug.assert(value != 0);
    if (origin.FingerTree.t == Element.EmptyT) {
        initSingle(e, value, depth); 
        return buffer; 
    }
    var remain = buffer; 
    if (origin.FingerTree.t == Element.SingleT) {
        var inner_deep: *Element = undefined; 
        var emp: *Element = undefined; 
        var left: *Element = undefined; 
        var rright: *Element = undefined; 
        remain = try allocOne(remain, use_first, &inner_deep); 
        remain = try allocOne(remain, use_first, &left); 
        remain = try allocOne(remain, use_first, &emp); 
        remain = try allocOne(remain, use_first, &rright); 
        emp.* = EMPTY; 
        if (right) {
            left.Four[0] = origin.FingerTree.ptr; 
            rright.Four[0] = value; 
        } else {
            left.Four[0] = value; 
            rright.Four[0] = origin.FingerTree.ptr; 
        }
        left.Four[1] = 0; 
        rright.Four[1] = 0; 
        inner_deep.Deep.left = @intFromPtr(left); 
        inner_deep.Deep.finger_tree = @intFromPtr(emp); 
        inner_deep.Deep.right = @intFromPtr(rright); 
        e.FingerTree.size = origin.FingerTree.size + maybeThreeGetSize(value, depth); 
        e.FingerTree.t = Element.DeepT; 
        e.FingerTree.ptr = @intFromPtr(inner_deep); 
        return remain; 
    }
    std.debug.assert(origin.FingerTree.t == Element.DeepT); 
    const deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
    const inner: *Element = @ptrFromInt(deep.Deep.finger_tree); 
    const right_ptr: *Element = @ptrFromInt(if (right) deep.Deep.right else deep.Deep.left); 
    const len_of_right = fourLength(right_ptr.*); 
    if (len_of_right < 4) {
        var new_right: *Element = undefined; 
        var new_deep: *Element = undefined; 
        remain = try allocOne(remain, use_first, &new_right);  
        remain = try allocOne(remain, use_first, &new_deep);  
        new_right.* = right_ptr.*; 
        new_right.Four[len_of_right] = value; 
        if (len_of_right + 1 < 4) {
            new_right.Four[len_of_right + 1] = 0; 
        }
        new_deep.* = deep.*; 
        (if (right) 
            new_deep.Deep.right
        else 
            new_deep.Deep.left) 
                = @intFromPtr(new_right); 
        e.FingerTree.t = Element.DeepT; 
        e.FingerTree.ptr = @intFromPtr(new_deep); 
        e.FingerTree.size = origin.FingerTree.size + maybeThreeGetSize(value, depth); 
    } else {
        var new_three: *Element = undefined; 
        var new_inner: *Element = undefined; 
        var new_right: *Element = undefined; 
        var new_deep: *Element = undefined; 
        remain = try allocOne(remain, use_first, &new_three); 
        remain = try allocOne(remain, use_first, &new_inner); 
        remain = try allocOne(remain, use_first, &new_right); 
        remain = try allocOne(remain, use_first, &new_deep); 
        @memcpy(&new_three.Three.content, right_ptr.Four[0..3]); 
        if (!right) {
            std.mem.swap(usize, &new_three.Three.content[0], &new_three.Three.content[2]); 
        }
        threeSizeUpdateDirectly(new_three, depth); 
        new_right.Four[0] = right_ptr.Four[3]; 
        new_right.Four[1] = value; 
        new_right.Four[2] = 0; 
        remain = try push(new_inner, remain, use_first, inner.*, @intFromPtr(new_three), depth + 1, right); 
        new_deep.Deep = deep.Deep; 
        new_deep.Deep.finger_tree = @intFromPtr(new_inner); 
        (if (right) 
            new_deep.Deep.right
        else 
            new_deep.Deep.left) 
                = @intFromPtr(new_right); 
        e.FingerTree.t = Element.DeepT; 
        e.FingerTree.ptr = @intFromPtr(new_deep);
        e.FingerTree.size = origin.FingerTree.size + maybeThreeGetSize(value, depth); 
    }
    return remain; 
}

pub fn push2(e: *Element, buffer: []Element, use_first: bool, origin: Element, value0: usize, value1: usize, depth: usize, right: bool) ![]Element {
    std.debug.assert(value0 != 0); 
    std.debug.assert(value1 != 0); 
    var remain = buffer; 
    var inner_deep: *Element = undefined; 
    var emp: *Element = undefined; 
    var left: *Element = undefined; 
    var rright: *Element = undefined; 
    if (origin.FingerTree.t == Element.EmptyT) {
        remain = try allocOne(remain, use_first, &inner_deep); 
        remain = try allocOne(remain, use_first, &left); 
        remain = try allocOne(remain, use_first, &emp); 
        remain = try allocOne(remain, use_first, &rright); 
        if (right) {
            left.Four[0] = value0; 
            rright.Four[0] = value1; 
        } else {
            left.Four[0] = value1; 
            rright.Four[0] = value0; 
        }
        left.Four[1] = 0; 
        rright.Four[1] = 0; 
        emp.* = EMPTY; 
        inner_deep.Deep.finger_tree = @intFromPtr(emp); 
        inner_deep.Deep.left = @intFromPtr(left); 
        inner_deep.Deep.right = @intFromPtr(rright); 
        e.FingerTree.size = maybeThreeGetSize(value0, depth) + maybeThreeGetSize(value1, depth); 
        e.FingerTree.ptr = @intFromPtr(inner_deep); 
        e.FingerTree.t = Element.DeepT; 
        return remain; 
    }
    if (origin.FingerTree.t == Element.SingleT) {
        remain = try allocOne(remain, use_first, &inner_deep); 
        remain = try allocOne(remain, use_first, &left); 
        remain = try allocOne(remain, use_first, &emp); 
        remain = try allocOne(remain, use_first, &rright); 
        if (right) {
            left.Four[0] = origin.FingerTree.ptr; 
            left.Four[1] = 0; 
            rright.Four[0] = value0; 
            rright.Four[1] = value1; 
            rright.Four[2] = 0; 
        } else {
            left.Four[0] = value0; 
            left.Four[1] = value1; 
            left.Four[2] = 0; 
            rright.Four[0] = origin.FingerTree.ptr; 
            rright.Four[1] = 0; 
        }
        emp.* = EMPTY; 
        inner_deep.Deep.finger_tree = @intFromPtr(emp); 
        inner_deep.Deep.left = @intFromPtr(left); 
        inner_deep.Deep.right = @intFromPtr(rright); 
        e.FingerTree.size = origin.FingerTree.size + maybeThreeGetSize(value0, depth) + maybeThreeGetSize(value1, depth); 
        e.FingerTree.ptr = @intFromPtr(inner_deep); 
        e.FingerTree.t = Element.DeepT; 
        return remain; 
    }
    std.debug.assert(origin.FingerTree.t == Element.DeepT); 
    const deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
    const old_rright: *Element = @ptrFromInt(if (right) deep.Deep.right else deep.Deep.left); 
    const old_left: *Element = @ptrFromInt(if (right) deep.Deep.left else deep.Deep.right);  
    _ = old_left; // autofix
    const old_inner: *Element = @ptrFromInt(deep.Deep.finger_tree); 
    const rright_len = fourLength(old_rright.*); 
    remain = try allocOne(remain, use_first, &inner_deep); 
    remain = try allocOne(remain, use_first, &rright); 
    if (rright_len <= 2) {
        @memcpy(rright.Four[0..rright_len], old_rright.Four[0..rright_len]); 
        rright.Four[rright_len] = value0; 
        rright.Four[rright_len + 1] = value0; 
        if (rright_len == 1) {
            rright.Four[rright_len + 2] = 0; 
        }
        inner_deep.Deep = deep.Deep; 
        (if (right) inner_deep.Deep.right else inner_deep.Deep.left) = @intFromPtr(rright); 
        e.FingerTree.size = origin.FingerTree.size + maybeThreeGetSize(value0, depth) + maybeThreeGetSize(value1, depth); 
        e.FingerTree.ptr = @intFromPtr(inner_deep); 
        e.FingerTree.t = Element.DeepT; 
    } else { 
        var new_three: *Element = undefined; 
        var new_inner: *Element = undefined; 
        remain = try allocOne(remain, use_first, &new_inner); 
        remain = try allocOne(remain, use_first, &new_three); 
        @memcpy(new_three.Three.content[0..], old_rright.Four[0..3]); 
        if (!right) {
            std.mem.reverse(usize, new_three.Three.content[0..3]); 
        }
        remain = try push(new_inner, remain, use_first, old_inner.*, @intFromPtr(new_three), depth + 1, right); 
        if (rright_len == 3) {
            rright.Four[0] = value0; 
            rright.Four[1] = value1; 
            rright.Four[2] = 0; 
        } else {
            rright.Four[0] = old_rright.Four[3]; 
            rright.Four[1] = value0; 
            rright.Four[2] = value1; 
            rright.Four[3] = 0; 
        }
        inner_deep.Deep = deep.Deep; 
        inner_deep.Deep.finger_tree = @intFromPtr(new_inner); 
        (if (right) inner_deep.Deep.right else inner_deep.Deep.left) = @intFromPtr(rright); 
        e.FingerTree.size = origin.FingerTree.size + maybeThreeGetSize(value0, depth) + maybeThreeGetSize(value1, depth); 
        e.FingerTree.ptr = @intFromPtr(inner_deep); 
        e.FingerTree.t = Element.DeepT; 
    }
    return remain; 
}

pub fn push3(e: *Element, buffer: []Element, use_first: bool, origin: Element, value0: usize, value1: usize, value2: usize, depth: usize, right: bool) ![]Element {
    std.debug.assert(value0 != 0); 
    std.debug.assert(value1 != 0); 
    std.debug.assert(value2 != 0); 
    var remain = buffer;
    var new_deep: *Element = undefined; 
    var new_left: *Element = undefined; 
    var new_right: *Element = undefined; 
    var new_inner: *Element = undefined; 
    const size_added = 
        maybeThreeGetSize(value0, depth) + maybeThreeGetSize(value1, depth) + maybeThreeGetSize(value2, depth); 
    if (origin.FingerTree.t != Element.DeepT) {
        remain = try allocOne(remain, use_first, &new_deep); 
        remain = try allocOne(remain, use_first, &new_left); 
        remain = try allocOne(remain, use_first, &new_inner); 
        remain = try allocOne(remain, use_first, &new_right); 
    }
    if (origin.FingerTree.t == Element.EmptyT or origin.FingerTree.t == Element.SingleT) {
        new_inner.* = EMPTY; 
        new_left.Four[0] = value0; 
        if (false) {
            if (origin.FingerTree.t == Element.SingleT) {
                new_left.Four[1] = origin.FingerTree.ptr; 
                new_left.Four[2] = 0; 
            } else {
                new_left.Four[1] = 0; 
            }
        } else {
            new_left.Four[1] = origin.FingerTree.ptr; 
            new_left.Four[2] = 0; 
        }
        new_right.Four[0] = value1; 
        new_right.Four[1] = value2; 
        new_right.Four[2] = 0; 
        if (!right) {
            std.mem.swap(*Element, &new_left, &new_right);  
        } 
        new_deep.Deep.finger_tree = @intFromPtr(new_inner); 
        new_deep.Deep.left = @intFromPtr(new_left); 
        new_deep.Deep.right = @intFromPtr(new_right); 
    } else if (origin.FingerTree.t == Element.DeepT) {
        var new_three: *Element = undefined; 
        remain = try allocOne(remain, use_first, &new_three); 
        remain = try allocOne(remain, use_first, &new_deep); 
        remain = try allocOne(remain, use_first, &new_right); 
        remain = try allocOne(remain, use_first, &new_inner); 
        const old_deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
        const old_right: *Element = @ptrFromInt(if (right) old_deep.Deep.right else old_deep.Deep.left ); 
        const old_right_len = fourLength(old_right.*); 
        const old_inner: *Element = @ptrFromInt(old_deep.Deep.finger_tree); 
        var tmp_buffer: [8]usize = undefined; 
        @memcpy(tmp_buffer[0..old_right_len], old_right.Four[0..old_right_len]); 
        tmp_buffer[old_right_len] = value0; 
        tmp_buffer[old_right_len + 1] = value1; 
        tmp_buffer[old_right_len + 2] = value2; 
        tmp_buffer[old_right_len + 3] = 0; 
        @memcpy(new_three.Three.content[0..3], tmp_buffer[0..3]); 
        if (!right) {
            std.mem.reverse(usize, new_three.Three.content[0..3]); 
        }
        threeSizeUpdateDirectly(new_three, depth); 
        remain = try push(new_inner, remain, use_first, old_inner.*, @intFromPtr(new_three), depth + 1, right); 
        @memcpy(new_right.Four[0..old_right_len], tmp_buffer[3..3+old_right_len]); 
        if (old_right_len < 4) {
            new_right.Four[old_right_len] = 0; 
        }
        new_deep.Deep = old_deep.Deep; 
        (if (right) new_deep.Deep.right else new_deep.Deep.left) = @intFromPtr(new_right); 
        new_deep.Deep.finger_tree = @intFromPtr(new_inner); 
    } else {
        unreachable; 
    }
    e.FingerTree.size = size_added + origin.FingerTree.size; 
    e.FingerTree.t = Element.DeepT; 
    e.FingerTree.ptr = @intFromPtr(new_deep); 
    return remain; 
}

test {
    const base_buffer = try std.testing.allocator.alloc(Element, 1024);     
    defer std.testing.allocator.free(base_buffer); 
    var remain: []Element = base_buffer; 
    var now: Element = EMPTY; 
    remain = try push3(&now, remain, true, now, 1, 2, 3, 0, true); 
    remain = try push3(&now, remain, true, now, 4, 5, 6, 0, true); 
    remain = try push3(&now, remain, true, now, 7, 8, 9, 0, true); 
    // ... expect 9 size 
    if (now.FingerTree.size != 9) {
        std.log.err("insert 1..10 in EMPTY, and expect size 9, but actual size: {}", .{ now.FingerTree.size }); 
    }
}

test {
    const base_buffer = try std.testing.allocator.alloc(Element, 1024);     
    defer std.testing.allocator.free(base_buffer); 
    var remain: []Element = base_buffer; 
    var now: Element = EMPTY; 
    remain = try push2(&now, remain, true, now, 1, 2, 0, true); 
    remain = try push2(&now, remain, true, now, 4, 5, 0, true); 
    remain = try push2(&now, remain, true, now, 7, 8, 0, true); 
    if (now.FingerTree.size != 6) {
        std.log.err("insert 1, 2, 4, 5, 7, 8 in EMPTY, and expect size 6, but actual size: {}", .{ now.FingerTree.size }); 
    }
}

test {
    const base_buffer = try std.testing.allocator.alloc(Element, 1024);     
    defer std.testing.allocator.free(base_buffer); 
    var remain: []Element = base_buffer; 
    var now: Element = EMPTY; 
    remain = try push(&now, remain, true, now, 1, 0, true); 
    remain = try push(&now, remain, true, now, 4, 0, true); 
    remain = try push(&now, remain, true, now, 7, 0, true); 
    if (now.FingerTree.size != 3) {
        std.log.err("insert 1, 4, 7 in EMPTY, and expect size 6, but actual size: {}", .{ now.FingerTree.size }); 
    }
}
