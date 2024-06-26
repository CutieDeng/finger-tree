const lib = @import("root.zig"); 
const std = @import("std"); 

const Element = lib.Element; 

const EMPTY = lib.EMPTY; 
const allocOne = lib.allocOne; 
const maybeThreeGetSize = lib.maybeThreeGetSize; 
const fourLength = lib.fourLength; 
const initSingle = lib.initSingle; 

const threeSizeUpdateDirectly = lib.threeSizeUpdateDirectly; 
const fourSize = lib.fourSize; 

const fiveLength = lib.fiveLength; 

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

pub fn threeInnerPush(e: *Element, e2: *?*Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    std.debug.assert(idx <= origin.Three.size); 
    var remain: []Element = buffer; 
    if (depth == 0) {
        if (origin.Three.size == 2) {
            std.debug.assert(origin.Three.content[2] == 0); 
            e2.* = null; 
            @memcpy(e.Three.content[0..idx], origin.Three.content[0..idx]); 
            e.Three.content[idx] = value; 
            @memcpy(e.Three.content[(idx+1)..3], origin.Three.content[idx..2]); 
            e.Three.size = 3; 
        } else if (origin.Three.size == 3) {
            var new_three2: *Element = undefined; 
            remain = try allocOne(remain, use_first, &new_three2); 
            e2.* = new_three2; 
            var four: [4]usize = undefined; 
            @memcpy(four[0..idx], origin.Three[0..idx]); 
            four[idx] = value; 
            @memcpy(four[(idx+1) .. 4], origin.Three[idx..3]); 
            e.Three.content[0] = four[0]; 
            e.Three.content[1] = four[1]; 
            e.Three.content[2] = 0; 
            e.Three.size = 2; 
            new_three2.Three.content[0] = four[2]; 
            new_three2.Three.content[1] = four[3]; 
            new_three2.Three.content[2] = 0; 
            new_three2.Three.size = 2; 
        }
        return remain; 
    }
    var inner_idx: ?usize = null; 
    var else_cnt: usize = idx; 
    for (0..origin.Three.content.len) |i| {
        if (origin.Three.content[i] == 0) {
            unreachable; 
        }
        const c = maybeThreeGetSize(origin.Three.content[i], depth); 
        if (else_cnt <= c) {
            inner_idx = i;  
            break; 
        } else {
            else_cnt -= c; 
        }
    }
    const idx2: usize = inner_idx.?; 
    var buf: ?*Element = undefined; 
    var e3: *Element = undefined; 
    remain = try allocOne(remain, use_first, &e3); 
    const inner_three: *Element = @ptrFromInt(origin.Three.content[idx2]); 
    remain = try threeInnerPush(e3, &buf, remain, use_first, inner_three.*, else_cnt, value, depth - 1); 
    if (buf) |b| { 
        if (origin.Three.content[2] == 0) { 
            e2.* = null; 
            e.Three.content[idx2] = @intFromPtr(e3); 
            e.Three.content[idx2+1] = @intFromPtr(b); 
            if (idx2 == 0) {
                e.Three.content[2] = origin.Three.content[1]; 
            } else {
                std.debug.assert(idx2 == 1); 
                e.Three.content[0] = origin.Three.content[0]; 
            }
            e.Three.size = origin.Three.size + 1; 
        } else {
            var newly : *Element = undefined; 
            remain = try allocOne(remain, use_first, &newly); 
            e2.* = newly; 
            var base: [4]usize = undefined; 
            @memcpy(base[0..idx2], origin.Three.content[0..idx2]); 
            base[idx2] = @intFromPtr(e3); 
            base[idx2] = @intFromPtr(b); 
            @memcpy(base[idx2+2..], origin.Three.content[idx2+1..]); 
            e.Three.content[0] = base[0]; 
            e.Three.content[1] = base[1]; 
            e.Three.content[2] = 0;  
            newly.Three.content[0] = base[2]; 
            newly.Three.content[1] = base[3]; 
            newly.Three.content[2] = 0;  
            threeSizeUpdateDirectly(e, depth); 
            threeSizeUpdateDirectly(newly, depth); 
        }
    } else {
        e2.* = null; 
        e.* = origin; 
        e.Three.content[idx2] = @intFromPtr(e3); 
        e.Three.size += 1; 
    }
    return remain; 
}

pub fn innerPush(e: *Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    std.debug.assert(idx <= origin.FingerTree.size); 
    var remain = buffer; 
    if (origin.FingerTree.t == Element.EmptyT) {
        std.debug.assert(idx == 0);
        std.debug.assert(depth == 0);
        initSingle(e, value, 0); 
    } else if (origin.FingerTree.t == Element.SingleT) {
        if (depth == 0) {
            if (idx == 0) {
                return push(e, remain, use_first, origin, value, depth, false); 
            } else if (idx == 1) {
                return push(e, remain, use_first, origin, value, depth, true); 
            } else {
                unreachable; 
            }
        } else {
            const inner_three: *Element = @ptrFromInt(origin.FingerTree.ptr); 
            var inner_three2: *Element = undefined; 
            var inner_three_back: ?*Element = undefined; 
            remain = try allocOne(remain, use_first, &inner_three2); 
            remain = try threeInnerPush(inner_three2, &inner_three_back, remain, use_first, inner_three.*, idx, value, depth); 
            if (inner_three_back) |three3| {
                var four0: *Element = undefined; 
                var four1: *Element = undefined; 
                var emp: *Element = undefined; 
                var d: *Element = undefined; 
                remain = try allocOne(remain, use_first, &four0); 
                remain = try allocOne(remain, use_first, &four1); 
                remain = try allocOne(remain, use_first, &emp); 
                remain = try allocOne(remain, use_first, &d); 
                emp.* = EMPTY; 
                four0.Four[0] = @intFromPtr(inner_three); 
                four0.Four[1] = 0; 
                four1.Four[0] = @intFromPtr(three3); 
                four1.Four[1] = 0; 
                d.Deep.finger_tree = @intFromPtr(emp); 
                d.Deep.left = @intFromPtr(four0); 
                d.Deep.right = @intFromPtr(four1); 
                e.FingerTree.size = inner_three.Three.size + 1; 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(d); 
            } else {
                e.FingerTree.size = origin.FingerTree.size + 1; 
                e.FingerTree.t = Element.SingleT; 
                e.FingerTree.ptr = @intFromPtr(inner_three2); 
                std.debug.assert(e.FingerTree.size == inner_three2.Three.size); 
            }
        }
    } else {
        std.debug.assert(origin.FingerTree.t == Element.DeepT); 
        const origin_d: *Element = @ptrFromInt(origin.FingerTree.ptr); 
        const left: *Element = @ptrFromInt(origin_d.Deep.left); 
        const right: *Element = @ptrFromInt(origin_d.Deep.right); 
        const inner_ft: *Element = @ptrFromInt(origin_d.Deep.finger_tree); 
        const l_size = fourSize(left.*, depth); 
        const inner_size = inner_ft.FingerTree.size; 
        if (inner_ft.FingerTree.t != Element.EmptyT and idx >= l_size and idx <= l_size + inner_size) {
            var new_inner: *Element = undefined; 
            var new_deep: *Element = undefined;  
            remain = try allocOne(remain, use_first, &new_inner); 
            remain = try allocOne(remain, use_first, &new_deep); 
            remain = try innerPush(new_inner, remain, use_first, inner_ft.*, idx - l_size, value, depth + 1); 
            new_deep.* = origin_d.*; 
            new_deep.Deep.finger_tree = @intFromPtr(new_inner); 
            e.FingerTree.size = origin.FingerTree.size + 1; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.t = Element.DeepT; 
            return remain; 
        }
        if (idx <= l_size) {
            var left4: Element = left.*; 
            const left4_len = fourLength(left4);   
            var new_four: *Element = undefined; 
            var new_deep: *Element = undefined;  
            var rst: [5]usize = undefined; 
            remain = try allocOne(remain, use_first, &new_four); 
            remain = try allocOne(remain, use_first, &new_deep); 
            std.mem.reverse(usize, left4.Four[0..left4_len]); 
            remain = try deepFourPush(&rst, remain, use_first, left4, idx, value, depth); 
            const rst_len = fiveLength(rst); 
            std.mem.reverse(usize, rst[0..rst_len]); 
            if (rst_len <= 4) {
                @memcpy(new_four.Four[0..rst_len], rst[0..rst_len]); 
                if (rst_len < 4) {
                    new_four.Four[rst_len] = 0; 
                }
                new_deep.* = origin_d.*; 
                new_deep.Deep.left = @intFromPtr(new_four); 
                e.FingerTree.size = origin.FingerTree.size + 1; 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
            } else {
                var new_three: *Element = undefined; 
                var new_finger: *Element = undefined; 
                remain = try allocOne(remain, use_first, &new_three); 
                remain = try allocOne(remain, use_first, &new_finger); 
                @memcpy(new_three.Three.content[0..], rst[0..3]); 
                std.mem.reverse(usize, new_three.Three.content[0..]); 
                threeSizeUpdateDirectly(new_three, depth);
                remain = try push(new_finger, remain, use_first, inner_ft.*, @intFromPtr(new_three), depth + 1, false); 
                @memcpy(new_four.Four[0..2], rst[3..5]); 
                new_four.Four[2] = 0; 
                new_deep.Deep.left = @intFromPtr(new_four); 
                new_deep.Deep.finger_tree = @intFromPtr(new_finger); 
                new_deep.Deep.right = origin_d.Deep.right; 
                e.FingerTree.size = origin.FingerTree.size + 1; 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
            }
        } else if (idx >= l_size + inner_size) {
            var rst: [5]usize = undefined; 
            remain = try deepFourPush(&rst, remain, use_first, right.*, idx, value, depth); 
            const rst_len = fiveLength(rst); 
            var new_four: *Element = undefined; 
            var new_deep: *Element = undefined;  
            remain = try allocOne(remain, use_first, &new_four); 
            remain = try allocOne(remain, use_first, &new_deep); 
            if (rst_len <= 4) {
                @memcpy(new_four.Four[0..4], rst[0..4]); 
                new_deep.* = origin_d.*; 
                new_deep.Deep.right = @intFromPtr(new_four); 
                e.FingerTree.size = origin.FingerTree.size + 1; 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
            } else {
                var new_three: *Element = undefined; 
                var new_finger: *Element = undefined; 
                remain = try allocOne(remain, use_first, &new_three); 
                remain = try allocOne(remain, use_first, &new_finger); 
                @memcpy(new_three.Three.content[0..3], rst[0..3]); 
                threeSizeUpdateDirectly(new_three, depth);
                remain = try push(new_finger, remain, use_first, inner_ft.*, @intFromPtr(new_three), depth + 1, true); 
                @memcpy(new_four.Four[0..2], rst[3..5]); 
                new_four.Four[2] = 0; 
                new_deep.Deep.left = origin_d.Deep.left; 
                new_deep.Deep.finger_tree = @intFromPtr(new_finger); 
                new_deep.Deep.right = @intFromPtr(new_four); 
                e.FingerTree.size = origin.FingerTree.size + 1; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.t = Element.DeepT; 
            }
        } else {
            unreachable; 
        }
    }
    return remain; 
}

pub fn deepFourPush(rst: *[5]usize, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    var cumulative: usize = idx; 
    var quantile: ?usize = null; 
    if (depth == 0) {
        @memcpy(rst[0..idx], origin.Four[0..idx]); 
        rst[idx] = value; 
        @memcpy(rst[idx+1..], origin.Four[idx..]); 
        return buffer; 
    }
    for (origin.Four, 0..) |f, idx0| {
        if (f == 0) {
            unreachable; 
        }
        const f_sum = maybeThreeGetSize(f, depth); 
        if (cumulative > f_sum) {
            cumulative -= f_sum; 
        } else {
            quantile = idx0; 
            break; 
        }
    }
    const quantile0 = quantile.?; 
    const origin0: *Element = @ptrFromInt(origin.Four[quantile0]); 
    var e: *Element = undefined; 
    var e2: ?*Element = undefined; 
    var remain = buffer; 
    remain = try allocOne(remain, use_first, &e); 
    remain = try threeInnerPush(e, &e2, remain, use_first, origin0.*, cumulative, value, depth - 1); 
    @memcpy(rst[0..quantile0], origin0.Four[0..quantile0]); 
    rst[quantile0] = @intFromPtr(e); 
    if (e2) |e2r| {
        rst[quantile0+1] = @intFromPtr(e2r); 
        @memcpy(rst[quantile0+2..], origin0.Four[quantile0+1..]); 
    } else {
        @memcpy(rst[quantile0+1..4], origin0.Four[quantile0+1..]); 
        rst[4] = 0; 
    }
    return remain; 
}

pub fn threePush(e: *Element, e2: *?*Element, buffer: []Element, use_first: bool, origin: Element, value: usize, depth: usize, right: bool) ![]Element {
    const full = origin.Three.content[2] != 0; 
    var buf: [4]usize = undefined; 
    var remain = buffer; 
    if (full) {
        var back: *Element = undefined; 
        remain = try allocOne(remain, use_first, &back); 
        if (right) {
            @memcpy(buf[0..3], origin.Three.content[0..]);  
            buf[3] = value; 
        } else {
            @memcpy(buf[1..4], origin.Three.content[0..]);  
            buf[0] = value; 
        }
        @memcpy(e.Three.content[0..2], buf[0..2]); 
        e.Three.content[2] = 0; 
        threeSizeUpdateDirectly(e, depth); 
        @memcpy(back.Three.content[0..2], buf[2..4]); 
        back.Three.content[2] = 0; 
        threeSizeUpdateDirectly(back, depth); 
        e2.* = back; 
    } else {
        if (right) {
            @memcpy(buf[0..2], origin.Three.content[0..2]); 
            buf[2] = value; 
        } else {
            @memcpy(buf[1..3], origin.Three.content[0..2]); 
            buf[0] = value; 
        }
        @memcpy(e.Three.content[0..3], buf[0..3]); 
        threeSizeUpdateDirectly(e, depth); 
        e2.* = null; 
    }
    return remain; 
}