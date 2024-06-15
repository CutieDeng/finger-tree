const std = @import("std");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

pub const Element = extern union {
    Four: [4]usize,  
    FingerTree: extern struct {
        t: usize, 
        ptr: usize, 
        size: usize, 
    }, 
    Deep: extern struct {
        left: usize, 
        right: usize, 
        finger_tree: usize, 
    }, 
    Three: extern struct {
        content: [3]usize, 
        size: usize, 
    }, 
    pub const EmptyT : usize = 0; 
    pub const SingleT : usize = 1; 
    pub const DeepT : usize = 2;  
}; 

pub fn empty(e: *Element) void {
    e.* = Element {
        .FingerTree = .{ 
            .t = 0, 
            .ptr = 0, 
            .size = 0, 
        }
    }; 
}

pub fn single(e: *Element, value: usize, depth: usize) void {
    e.* = Element {
        .FingerTree = .{ 
            .t = 1, 
            .ptr = value, 
            .size = maybeThreeCalcSize(value, depth), 
        }
    }; 
}

pub fn merge(e: *Element, buffer: []Element, use_first: bool, left: Element, right: Element, depth: usize) ![]Element {
    // Handle empty situation 
    if (left.FingerTree.t == Element.EmptyT) {
        e.* = right;  
        return buffer; 
    }
    if (right.FingerTree.t == Element.EmptyT) {
        e.* = left; 
        return buffer;
    }
    if (left.FingerTree.t == Element.SingleT) {
        return push(e, buffer, use_first, right, left.FingerTree.ptr, depth, false); 
    } 
    if (right.FingerTree.t == Element.SingleT) {
        return push(e, buffer, use_first, left, right.FingerTree.ptr, depth, true); 
    }
    const ldeep : *Element = @ptrFromInt(left.FingerTree.ptr); 
    const rdeep : *Element = @ptrFromInt(right.FingerTree.ptr); 
    const lrfour : *Element = @ptrFromInt(ldeep.Deep.right); 
    const rlfour : *Element = @ptrFromInt(rdeep.Deep.left); 
    const lrfourlen = fourLength(lrfour); 
    const rlfourlen = fourLength(rlfour); 
    const len = lrfourlen + rlfourlen; 
    var remain = buffer; 
    std.debug.assert(len >= 2 and len <= 8); 
    const left_deep_fingertree: *Element = @ptrFromInt(ldeep.Deep.finger_tree); 
    const right_deep_fingertree : *Element = @ptrFromInt(rdeep.Deep.finger_tree); 
    switch (len) {
        2, 3 => {
            var new: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new); 
            var idx: usize = 0; 
            for (0..lrfourlen) |li| {
                new.Three.content[idx] = lrfour.Four[li]; 
                idx += 1; 
            }
            for (0..rlfourlen) |ri| {
                new.Three.content[idx] = rlfour.Four[ri]; 
                idx += 1; 
            }
            if (idx == 2) {
                new.Three.content[idx] = 0; 
            }
            threeFlushSize(new, depth); 
            var left2: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &left2); 
            remain = try push(left2, remain, use_first, left_deep_fingertree.*, @intFromPtr(new), depth + 1, true); 
            var new_deep_fingertree: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_deep_fingertree); 
            remain = try merge(new_deep_fingertree, remain, use_first, left2.*, right_deep_fingertree.*, depth + 1); 
            var new_deep: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_deep); 
            new_deep.Deep.finger_tree = @intFromPtr(new_deep_fingertree); 
            new_deep.Deep.left = ldeep.Deep.left; 
            new_deep.Deep.right = rdeep.Deep.right; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.size = deepFlushSize(new_deep, depth); 
        }, 
        4, 5, 6 => {
            var new: [2]*Element = undefined; 
            remain = try allocSingle(remain, use_first, &new[0]); 
            remain = try allocSingle(remain, use_first, &new[1]); 
            var idx: usize = 0; 
            const first_len: usize = if (len == 4) 2 else 3; 
            var now: usize = 0; 
            for (0..lrfourlen) |li| {
                new[now].Three.content[idx] = lrfour.Four[li];  
                idx += 1; 
                if (idx == first_len) {
                    if (first_len == 2) {
                        new[now].Three.content[idx] = 0; 
                    }
                    idx = 0; 
                    now += 1; 
                }
            }
            for (0..rlfourlen) |ri| {
                new[now].Three.content[idx] = rlfour.Four[ri]; 
                idx += 1; 
                if (idx == first_len) {
                    if (first_len == 2) {
                        new[now].Three.content[idx] = 0; 
                    }
                    idx = 0; 
                    now += 1; 
                }
            }
            if (idx == 2) {
                new[now].Three.content[idx] = 0; 
            }
            threeFlushSize(new[0], depth); 
            threeFlushSize(new[1], depth); 
            var left_deep_finger: [2]*Element = undefined; 
            remain = try allocSingle(remain, use_first, &left_deep_finger[0]); 
            remain = try allocSingle(remain, use_first, &left_deep_finger[1]); 
            remain = try push(left_deep_finger[0], remain, use_first, left_deep_fingertree.*, @intFromPtr(new[0]), depth + 1, true); 
            remain = try push(left_deep_finger[1], remain, use_first, left_deep_finger[0].*, @intFromPtr(new[1]), depth + 1, true); 
            var new_deep_fingertree: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_deep_fingertree); 
            remain = try merge(new_deep_fingertree, remain, use_first, left_deep_finger[1].*, right_deep_fingertree.*, depth + 1); 
            var new_deep: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_deep); 
            new_deep.Deep.finger_tree = @intFromPtr(new_deep); 
            new_deep.Deep.left = ldeep.Deep.left; 
            new_deep.Deep.right = rdeep.Deep.right; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.size = deepFlushSize(new_deep, depth); 
        }, 
        7, 8 => {
            var new: [3]*Element = undefined;  
            remain = try allocSingle(remain, use_first, &new[0]); 
            remain = try allocSingle(remain, use_first, &new[1]); 
            remain = try allocSingle(remain, use_first, &new[2]); 

            var idx: usize = 0; 
            const limits = [_] usize { 2, if (len == 8) 3 else 2, 3 }; 
            var now: usize = 0; 
            for (0..lrfourlen) |li| {
                new[now].Three.content[idx] = lrfour.Four[li];  
                idx += 1; 
                if (idx == limits[now]) {
                    if (idx == 2) {
                        new[now].Three.content[idx] = 0; 
                    }
                    idx = 0; 
                    now += 1; 
                }
            }
            for (0..rlfourlen) |ri| {
                new[now].Three.content[idx] = rlfour.Four[ri]; 
                idx += 1; 
                if (idx == limits[now]) {
                    if (idx == 2) {
                        new[now].Three.content[idx] = 0; 
                    }
                    idx = 0; 
                    now += 1; 
                }
            }
            if (idx == 2) {
                new[now].Three.content[idx] = 0; 
            }
            threeFlushSize(new[0], depth); 
            threeFlushSize(new[1], depth); 
            threeFlushSize(new[2], depth); 
            var left_deep_finger: [3]*Element = undefined; 
            remain = try allocSingle(remain, use_first, &left_deep_finger[0]); 
            remain = try allocSingle(remain, use_first, &left_deep_finger[1]); 
            remain = try allocSingle(remain, use_first, &left_deep_finger[2]); 
            remain = try push(left_deep_finger[0], remain, use_first, left_deep_fingertree.*, @intFromPtr(new[0]), depth + 1, true); 
            remain = try push(left_deep_finger[1], remain, use_first, left_deep_finger[0].*, @intFromPtr(new[0]), depth + 1, true); 
            remain = try push(left_deep_finger[2], remain, use_first, left_deep_finger[1].*, @intFromPtr(new[0]), depth + 1, true); 
            var new_deep: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_deep); 
            new_deep.Deep.finger_tree = @intFromPtr(left_deep_finger[2]); 
            new_deep.Deep.left = ldeep.Deep.left; 
            new_deep.Deep.right = rdeep.Deep.right; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.size = deepFlushSize(new_deep, depth); 
        }, 
        else => unreachable, 
    }
    return remain; 
}

pub const Error = error { BufferNotEnough }; 

pub fn createDeep(e: *Element, buffer: []Element, use_first: bool) ![]Element {
    var remain = buffer; 
    var deep: *Element = undefined; 
    remain = try allocSingle(remain, use_first, &deep); 
    var left2: [2]*Element = undefined; 
    for (&left2) |*l| {
        remain = try allocSingle(remain, use_first, l); 
    }
    var emptyE: *Element = undefined; 
    remain = try allocSingle(remain, use_first, &emptyE); 
    empty(emptyE); 
    deep.Deep.left = @intFromPtr(left2[0]); 
    deep.Deep.right = @intFromPtr(left2[1]); 
    deep.Deep.finger_tree = @intFromPtr(emptyE); 
    e.* = Element { 
        .FingerTree = .{ .t = Element.DeepT, .ptr = @intFromPtr(deep), .size = undefined }
    }; 
    return remain; 
}

pub fn allocSingle(buffer: []Element, use_first: bool, rst: **Element) ![]Element {
    if (buffer.len < 1) {
        return error.BufferNotEnough; 
    }
    var remain = buffer; 
    if (use_first) {
        rst.* = &remain[0]; 
        remain = remain[1..];  
    } else {
        rst.* = &remain[remain.len - 1]; 
        remain.len -= 1; 
    }
    return remain; 
}

pub fn maybeThreeCalcSize(value: usize, depth: usize) usize {
    if (depth == 0) {
        return 1; 
    }
    const vptr : *Element = @ptrFromInt(value); 
    return vptr.Three.size; 
}

pub fn fourLength(value: *Element) usize {
    var l: usize = 0; 
    for (value.Four) |f| {
        if (f == 0) {
            break; 
        }
        l += 1; 
    }
    std.debug.assert(l > 0 and l <= 4); 
    return l; 
}

pub fn deepFlushSize(deep: *Element, depth: usize) usize {
    const left: *Element = @ptrFromInt(deep.Deep.left); 
    const right: *Element = @ptrFromInt(deep.Deep.right); 
    const inner: *Element = @ptrFromInt(deep.Deep.finger_tree); 
    var s: usize = inner.FingerTree.size; 
    for (left.Four) |f| {
        if (f == 0) {
            break; 
        }
        s += maybeThreeCalcSize(f, depth); 
    }
    for (right.Four) |f| {
        if (f == 0) {
            break; 
        }
        s += maybeThreeCalcSize(f, depth); 
    }
    return s; 
}

pub fn threeFlushSize(e: *Element, depth: usize) void {
    var size : usize = 0; 
    for (e.Three.content) |c| {
        if (c == 0) {
            break; 
        }
        size += maybeThreeCalcSize(c, depth); 
    }
    e.Three.size = size; 
}

pub fn get(e: Element, idx: usize, depth: usize) usize {
    if (e.FingerTree.t == Element.EmptyT) {
        unreachable; 
    }
    if (e.FingerTree.t == Element.SingleT) {
        if (depth == 0) {
            if (idx == 0) {
                return e.FingerTree.ptr; 
            } else {
                unreachable; 
            }
        } else {
            return threeGet(@ptrFromInt(e.FingerTree.ptr), idx, depth); 
        }
    }
    if (e.FingerTree.t == Element.DeepT) {
        const d : *Element = @ptrFromInt(e.FingerTree.ptr); 
        const l : *Element = @ptrFromInt(d.Deep.left); 
        var rem = idx; 
        const cnt = fourLength(l); 
        for (0..cnt) |c| {
            const cnt_c = maybeThreeCalcSize(l.Four[cnt - c - 1], depth); 
            if (rem >= cnt_c) {
                rem -= cnt_c; 
            } else {
                if (depth == 0) {
                    return l.Four[cnt - c - 1]; 
                } else {
                    return threeGet(@ptrFromInt(l.Four[cnt - c - 1]), rem, depth); 
                }
            }
        }
        const inner: *Element = @ptrFromInt(d.Deep.finger_tree); 
        if (rem < inner.FingerTree.size) {
            return get(inner.*, rem, depth + 1); 
        }
        rem -= inner.FingerTree.size; 
        const r : *Element = @ptrFromInt(d.Deep.right); 
        const rcnt = fourLength(r); 
        for (0..rcnt) |c| {
            const cnt_c = maybeThreeCalcSize(r.Four[c], depth); 
            if (rem >= cnt_c) {
                rem -= cnt_c; 
            } else {
                if (depth == 0) {
                    return r.Four[c]; 
                } else {
                    return threeGet(@ptrFromInt(r.Four[c]), rem, depth); 
                }
            }
        }
    }
    unreachable; 
}

pub fn threeGet(e: *Element, idx: usize, depth: usize) usize {
    var rem = idx; 
    for (e.Three.content) |c| {
        if (c == 0) {
            unreachable; 
        }
        const cs = maybeThreeCalcSize(c, depth - 1); 
        if (rem >= cs) {
            rem -= cs; 
        } else {
            if (depth == 1) {
                std.debug.assert(rem == 0); 
                return c; 
            }
            return threeGet(@ptrFromInt(c), rem, depth - 1); 
        }
    }
    unreachable; 
}

pub fn push(e: *Element, buffer: []Element, use_first: bool, origin: Element, value: usize, depth: usize, right: bool) ![]Element {
    if (origin.FingerTree.t == Element.EmptyT) {
        single(e, value, depth); 
        return buffer; 
    }
    var remain = buffer; 
    if (origin.FingerTree.t == Element.SingleT) {
        remain = try createDeep(e, remain, use_first); 
        const innerDeep: *Element = @ptrFromInt(e.FingerTree.ptr); 
        const left: *Element = @ptrFromInt(innerDeep.Deep.left); 
        const rright: *Element = @ptrFromInt(innerDeep.Deep.right); 
        if (right) {
            left.Four[0] = origin.FingerTree.ptr; 
            rright.Four[0] = value; 
        } else {
            left.Four[0] = value; 
            rright.Four[0] = origin.FingerTree.ptr; 
        }
        left.Four[1] = 0; 
        rright.Four[1] = 0; 
        e.FingerTree.size = origin.FingerTree.size + maybeThreeCalcSize(value, depth); 
        return remain; 
    }
    std.debug.assert(origin.FingerTree.t == Element.DeepT); 
    // check right ~ 
    const deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
    const right_ptr: *Element = @ptrFromInt(if (right) deep.Deep.right else deep.Deep.left); 
    const len_of_right = fourLength(right_ptr); 
    // just adjust it 
    if (len_of_right < 4) {
        var new_right: *Element = undefined; 
        var new_deep: *Element = undefined; 
        remain = try allocSingle(remain, use_first, &new_right);  
        remain = try allocSingle(remain, use_first, &new_deep);  
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
        e.* = origin; 
        e.FingerTree.ptr = @intFromPtr(new_deep); 
        e.FingerTree.size = origin.FingerTree.size + maybeThreeCalcSize(value, depth); 
    } else {
        var new_three: *Element = undefined; 
        var new_single: *Element = undefined; 
        var new_right: *Element = undefined; 
        var new_deep: *Element = undefined; 
        remain = try allocSingle(remain, use_first, &new_three); 
        remain = try allocSingle(remain, use_first, &new_single); 
        remain = try allocSingle(remain, use_first, &new_right); 
        remain = try allocSingle(remain, use_first, &new_deep); 
        @memcpy(&new_three.Three.content, right_ptr.Four[0..3]); 
        if (!right) {
            std.mem.swap(usize, &new_three.Three.content[0], &new_three.Three.content[2]); 
        }
        threeFlushSize(new_three, depth); 
        right_ptr.Four[0] = right_ptr.Four[3]; 
        right_ptr.Four[1] = value; 
        right_ptr.Four[2] = 0; 
        single(new_single, @intFromPtr(new_three), depth + 1); 
        new_deep.* = deep.*; 
        new_deep.Deep.finger_tree = @intFromPtr(new_single); 
        (if (right) 
            new_deep.Deep.right
        else 
            new_deep.Deep.left) 
                = @intFromPtr(new_right); 
        e.* = origin; 
        e.FingerTree.ptr = @intFromPtr(new_deep);
        e.FingerTree.size = origin.FingerTree.size + maybeThreeCalcSize(value, depth); 
    }
    return remain; 
}

test {
    _ = Element; 
    _ = empty; 
    var buffer: [10]Element = undefined; 
    var e: Element = undefined; 
    empty(&e); 
    single(&e, 1, 0); 
    std.log.warn("size: {}", .{ e.FingerTree.size }); 
    std.log.warn("first: {}", .{ get(e, 0, 0) }); 
    single(&e, 1, 0); 
    var remain = try push(&buffer[0], buffer[1..], true, e, 15, 0, false); 
    std.log.warn("size: {}", .{ buffer[0].FingerTree.size }); 
    std.log.warn("first: {}", .{ get(buffer[0], 0, 0) }); 
    const remain1 = &remain[0]; 
    const remain2_ = try push(remain1, remain[1..], true, buffer[0], 4, 0, false); 
    std.log.warn("size: {}", .{ remain1.FingerTree.size }); 
    std.log.warn("first: {}", .{ get(remain1.*, 0, 0) }); 
    std.log.warn("remain len: {}", .{ remain2_.len }); 
}

test {
    var buffer: [20] Element = undefined; 
    var empty0: Element = undefined; 
    empty(&empty0); 
    const one: *Element = &buffer[0]; 
    var remain: []Element = buffer[1..]; 
    remain = try push(one, remain, true, empty0, 24, 0, true); 
    const two: *Element = &remain[0]; 
    remain = try push(two, remain[1..], true, empty0, 9, 0, true); 
    const m: *Element = &remain[0]; 
    remain = try merge(m, remain[1..], true, two.*, one.*, 0); 
    std.log.warn("one: {}", .{ get(one.*, 0, 0) }); 
    std.log.warn("two: {}", .{ get(two.*, 0, 0)}); 
    std.log.warn("m[0]: {}", .{ get(m.*, 0, 0) }); 
    std.log.warn("m[1]: {}", .{ get(m.*, 1, 0) }); 
    const mdup: *Element = &remain[0]; 
    remain = try merge(mdup, remain[1..], true, m.*, m.*, 0); 
    for (0..4) |i| {
        std.log.warn("get md[{}]: {}", .{ i, get(mdup.*, i, 0) }); 
    }
}