const std = @import("std");
const testing = std.testing;

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

pub fn pop(e: *Element, buffer: []Element, use_first: bool, origin: Element, depth: usize, right: bool, pop_rst: *usize) ![]Element {
    if (origin.FingerTree.t == Element.EmptyT) {
        unreachable; 
    }
    if (origin.FingerTree.t == Element.SingleT) {
        empty(e); 
        pop_rst.* = origin.FingerTree.ptr; 
        return buffer; 
    }
    var remain: []Element = buffer; 
    std.debug.assert(origin.FingerTree.t == Element.DeepT); 
    const deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
    const rright: *Element = @ptrFromInt(if (right) deep.Deep.right else deep.Deep.left); 
    const right_len = fourLength(rright); 
    if (right_len == 1) {
        const deep_fingertree: *Element = @ptrFromInt(deep.Deep.finger_tree); 
        // pop it to handle this problem ~ 
        if (deep_fingertree.FingerTree.t == Element.EmptyT) {
            // .. ignore it, and handle with left branch 
            const left: *Element = @ptrFromInt(if (right) deep.Deep.left else deep.Deep.right); 
            const left_len = fourLength(left);
            if (left_len == 1) {
                single(e, left.Four[0], depth); 
                pop_rst.* = rright.Four[0]; 
            } else {
                var new_left: *Element = undefined; 
                var new_right: *Element = undefined; 
                var new_deep: *Element = undefined; 
                remain = try allocSingle(remain, use_first, &new_left); 
                remain = try allocSingle(remain, use_first, &new_right); 
                remain = try allocSingle(remain, use_first, &new_deep); 
                pop_rst.* = rright.Four[0]; 
                new_right.Four[0] = left.Four[0]; 
                new_right.Four[1] = 0; 
                @memcpy(new_left.Four[0..left_len - 1], left.Four[1..left_len]); 
                new_left.Four[left_len - 1] = 0; 
                new_deep.Deep.left = @intFromPtr(if (right) new_left else new_right ); 
                new_deep.Deep.right = @intFromPtr(if (!right) new_left else new_right ); 
                new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.size = deepGetSize(new_deep, depth); 
            }
        } else {
            var new_deep_fingertree: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_deep_fingertree); 
            // pop it 
            var rst: usize = undefined; 
            remain = try pop(new_deep_fingertree, remain, use_first, deep_fingertree.*, depth + 1, right, &rst); 
            var new_rfour: *Element = undefined; 
            var new_deep: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_rfour); 
            remain = try allocSingle(remain, use_first, &new_deep); 
            pop_rst.* = rright.Four[0]; 
            // handle it with new four ~ 
            var new_rfour_idx: usize = 0; 
            const pop_three: *Element = @ptrFromInt(rst); 
            for (pop_three.Three.content) |c| {
                if (c == 0) {
                    break; 
                }
                new_rfour.Four[new_rfour_idx] = c; 
                new_rfour_idx += 1; 
            }
            new_rfour.Four[new_rfour_idx] = 0; 
            new_deep.* = deep.*; 
            new_deep.Deep.finger_tree = @intFromPtr(new_deep_fingertree); 
            (if (right) 
                new_deep.Deep.right 
            else 
                new_deep.Deep.left)
                    = @intFromPtr(new_rfour); 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.size = deepGetSize(new_deep, depth); 
        }
    } else {
        // just remove it directly 
        var new_rright: *Element = undefined; 
        var new_deep: *Element= undefined; 
        remain = try allocSingle(remain, use_first, &new_rright); 
        remain = try allocSingle(remain, use_first, &new_deep); 
        pop_rst.* = rright.Four[right_len - 1]; 
        new_rright.* = rright.*; 
        new_rright.Four[right_len - 1] = 0; 
        new_deep.* = deep.*; 
        (if (right) 
            new_deep.Deep.right 
        else 
            new_deep.Deep.left)
                = @intFromPtr(new_rright); 
        e.FingerTree.ptr = @intFromPtr(new_deep); 
        e.FingerTree.t = Element.DeepT; 
        e.FingerTree.size = deepGetSize(new_deep, depth); 
    }
    return remain; 
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
                new.Three.content[idx] = rlfour.Four[rlfourlen - 1 - ri]; 
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
            e.FingerTree.size = deepGetSize(new_deep, depth); 
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
                new[now].Three.content[idx] = rlfour.Four[rlfourlen - 1 - ri]; 
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
            e.FingerTree.size = deepGetSize(new_deep, depth); 
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
                new[now].Three.content[idx] = rlfour.Four[rlfourlen - 1 - ri]; 
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
            e.FingerTree.size = deepGetSize(new_deep, depth); 
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

pub fn deepGetSize(deep: *Element, depth: usize) usize {
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

pub fn innerPush(e: *Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    var remain = buffer; 
    if (origin.FingerTree.t == Element.EmptyT) {
        // idx = 0 ! 
        std.debug.assert(idx == 0);
        std.debug.assert(depth == 0);
        e.FingerTree.ptr = value; 
        e.FingerTree.size = 1; 
        e.FingerTree.t = Element.SingleT; 
    } else if (origin.FingerTree.t == Element.SingleT) {
        // handle it with ~ 
        if (depth == 0) {
            // according to the idx ~ 
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
            remain = try allocSingle(remain, use_first, &inner_three2); 
            var inner_three_back: ?*Element = undefined; 
            remain = try threeInnerPush(inner_three2, &inner_three_back, remain, use_first, inner_three.*, idx, value, depth); 
            if (inner_three_back) |three3| {
                var four0: *Element = undefined; 
                var four1: *Element = undefined; 
                var emp: *Element = undefined; 
                var d: *Element = undefined; 
                remain = try allocSingle(remain, use_first, &four0); 
                remain = try allocSingle(remain, use_first, &four1); 
                remain = try allocSingle(remain, use_first, &emp); 
                remain = try allocSingle(remain, use_first, &d); 
                empty(emp); 
                four0.Four[0] = @intFromPtr(inner_three); 
                four0.Four[1] = 0; 
                four1.Four[0] = @intFromPtr(three3); 
                four1.Four[1] = 0; 
                d.Deep.finger_tree = @intFromPtr(emp); 
                d.Deep.left = @intFromPtr(four0); 
                d.Deep.right = @intFromPtr(four1); 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.size = inner_three.Three.size + 1; 
                e.FingerTree.ptr = @intFromPtr(d); 
            } else {
                e.FingerTree.t = Element.SingleT; 
                e.FingerTree.ptr = @intFromPtr(inner_three2); 
                e.FingerTree.size = threeFlushSize(inner_three2, depth); 
            }
        }
    } else {
        std.debug.assert(origin.FingerTree.t == Element.DeepT); 
        const origin_d: *Element = @ptrFromInt(origin.FingerTree.ptr); 
        const left: *Element = @ptrFromInt(origin_d.Deep.left); 
        const right: *Element = @ptrFromInt(origin_d.Deep.right); 
        const inner_ft: *Element = @ptrFromInt(origin_d.Deep.finger_tree); 
        const l_len = fourLength(left); 
        _ = l_len; // autofix
        const r_len = fourLength(right); 
        const l_size = fourSize(left, depth); 
        const r_size = fourSize(right, depth); 
        const inner_size = inner_ft.FingerTree.size; 
        _ = r_size; // autofix
        _ = r_len; // autofix
        if (inner_ft.FingerTree.t != Element.EmptyT or (inner_ft.FingerTree.t == Element.EmptyT and depth == 0)) {
            if (idx >= l_size and idx <= l_size + inner_size) {
                var new_inner_ft: *Element = undefined; 
                remain = try allocSingle(remain, use_first, &new_inner_ft); 
                return innerPush(new_inner_ft, remain, use_first, inner_ft.*, idx - l_size, value, depth + 1); 
            } 
        }
        if (idx <= l_size) {
            var left_tmp: Element = left.Four; 
            std.mem.reverse(usize, &left_tmp.Four); 
            var rst: [5]usize = undefined; 
            remain = try deepFourPush(&rst, remain, use_first, left_tmp, idx, value, depth); 
            const rst_len = fiveLength(rst); 
            var new_four: *Element = undefined; 
            var new_deep: *Element = undefined;  
            remain = try allocSingle(remain, use_first, &new_four); 
            remain = try allocSingle(remain, use_first, &new_deep); 
            if (rst_len <= 4) {
                @memset(new_four.Four[0..rst_len], rst[0..rst_len]); 
                std.mem.reverse(usize, new_four.Four[0..rst_len]); 
                new_deep.* = origin_d.*; 
                new_deep.Deep.left = @intFromPtr(new_four); 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.size = origin.FingerTree.size + 1; 
            } else {
                var new_three: *Element = undefined; 
                var new_finger: *Element = undefined; 
                remain = try allocSingle(remain, use_first, &new_three); 
                remain = try allocSingle(remain, use_first, &new_finger); 
                new_three.Three.content[0] = rst[2]; 
                new_three.Three.content[1] = rst[3]; 
                new_three.Three.content[2] = rst[4]; 
                threeFlushSize(new_three, depth);
                remain = try push(new_finger, remain, use_first, inner_ft.*, @intFromPtr(new_three), depth, false); 
                new_four.Four[0] = rst[1]; 
                new_four.Four[1] = rst[0]; 
                new_four.Four[2] = 0; 
                new_deep.Deep.left = @intFromPtr(new_four); 
                new_deep.Deep.finger_tree = @intFromPtr(new_finger); 
                new_deep.Deep.right = origin_d.Deep.right; 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.size = origin.FingerTree.size + 1; 
            }
        } else if (idx >= l_size + inner_size) {
            var rst: [5]usize = undefined; 
            remain = try deepFourPush(&rst, remain, use_first, right.*, idx, value, depth); 
            const rst_len = fiveLength(rst); 
            var new_four: *Element = undefined; 
            var new_deep: *Element = undefined;  
            remain = try allocSingle(remain, use_first, &new_four); 
            remain = try allocSingle(remain, use_first, &new_deep); 
            if (rst_len <= 4) {
                @memset(new_four.Four[0..rst_len], rst[0..rst_len]); 
                new_deep.* = origin_d.*; 
                new_deep.Deep.right = @intFromPtr(new_four); 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.size = origin.FingerTree.size + 1; 
            } else {
                var new_three: *Element = undefined; 
                var new_finger: *Element = undefined; 
                remain = try allocSingle(remain, use_first, &new_three); 
                remain = try allocSingle(remain, use_first, &new_finger); 
                new_three.Three.content[0] = rst[0]; 
                new_three.Three.content[1] = rst[1]; 
                new_three.Three.content[2] = rst[2]; 
                threeFlushSize(new_three, depth);
                remain = try push(new_finger, remain, use_first, inner_ft.*, @intFromPtr(new_three), depth, true); 
                new_four.Four[0] = rst[3]; 
                new_four.Four[1] = rst[4]; 
                new_four.Four[2] = 0; 
                new_deep.Deep.right = @intFromPtr(new_four); 
                new_deep.Deep.finger_tree = @intFromPtr(new_finger); 
                new_deep.Deep.left = origin_d.Deep.left; 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.size = origin.FingerTree.size + 1; 
            }
        } else {
            unreachable; 
        }
    }
    return remain; 
}

pub fn fiveLength(fiv: [5]usize) usize {
    var cnt: usize = 0;
    for (fiv) |v| {
        if (v == 0) {
            break; 
        }
        cnt += 1; 
    }
    return cnt; 
}

pub fn deepFourPush(rst: *[5]usize, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    var cumulative: usize = idx; 
    var quantile: ?usize = null; 
    for (origin.Four, 0..) |f, idx0| {
        if (f == 0) {
            break;  
        }
        const f_sum = maybeThreeCalcSize(f, depth); 
        if (cumulative > f_sum) {
            cumulative -= f_sum; 
        } else {
            quantile = idx0; 
            break; 
        }
    }
    const quantile0 = quantile.?; 
    if (depth == 0) {
        var cumul: usize = 0; 
        for (0..quantile0+1) |q| {
            rst.*[cumul] = origin.Four[q]; 
            cumul += 1; 
        }
        rst.*[cumul] = value; 
        cumul += 1; 
        for (origin.Four[quantile0+1..]) |q| {
            if (q == 0) {
                break; 
            }
            rst.*[cumul] = q; 
            cumul += 1; 
        }
        if (cumul < 5) {
            rst.*[cumul] = 0; 
        }
        return buffer; 
    }
    const origin0: *Element = @intFromPtr(origin.Four[quantile0]); 
    var e: *Element = undefined; 
    var e2: ?*Element = undefined; 
    var remain = buffer; 
    remain = try allocSingle(remain, use_first, &e); 
    remain = try threeInnerPush(e, &e2, remain, use_first, origin0.*, cumulative, value, depth - 1); 
    var cumul: usize = 0; 
    for (0..quantile0) |q| {
        rst.*[cumul] = origin.Four[q]; 
        cumul += 1; 
    }
    rst.*[cumul] = @intFromPtr(e); 
    cumul += 1; 
    if (e2) |e2r| {
        rst.*[cumul] = @intFromPtr(e2r); 
        cumul += 1; 
    }
    for (origin.Four[quantile0+1..]) |q| {
        if (q == 0) {
            break; 
        }
        rst.*[cumul] = q; 
        cumul += 1; 
    }
    if (cumul < 5) {
        rst.*[cumul] = 0; 
    }
    return remain; 
}

pub fn fourSize(e: *Element, depth: usize) usize {
    var cnt: usize = 0; 
    for (e.Four) |f| {
        if (f == 0) {
            break; 
        } 
        cnt += maybeThreeCalcSize(f, depth); 
    }
    return cnt; 
}

pub fn threeInnerPush(e: *Element, e2: *?*Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    std.debug.assert(idx < origin.Three.size); 
    var remain: []Element = buffer; 
    if (depth == 0) {
        if (origin.Three.size == 2) {
            std.debug.assert(origin.Three.content[2] == 0); 
            defer e2.* = null; 
            e.Three.content = origin.Three.content; 
            e.Three.size = 3; 
            @memcpy(e.Three.content[0..idx], origin.Three.content[0..idx]); 
            e.Three.content[idx] = value; 
            @memcpy(e.Three.content[(idx+1)..3], origin.Three.content[idx..2]); 
            e.Three.size = 3; 
        } else if (origin.Three.size == 3) {
            var new_three2: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_three2); 
            defer e2.* = new_three2; 
            var four: [4]usize = undefined; 
            var four_idx: usize = 0; 
            for (0..4) |v| {
                if (v == idx) {
                    four[four_idx] = value; 
                    four_idx += 1; 
                }
                if (v != 3) {
                    four[four_idx] = origin.Three.content[v]; 
                    four_idx += 1; 
                }
            }
            std.debug.assert(four_idx == 4); 
            e.Three.content[0] = four[0]; 
            e.Three.content[1] = four[1]; 
            e.Three.content[2] = 0; 
            e.Three.size = 2; 
            new_three2.Three.content[0] = four[2]; 
            new_three2.Three.content[1] = four[3]; 
            new_three2.Three.content[2] = 0; 
            new_three2.Three.size = 2; 
        }
        unreachable; 
    }
    var inner_idx: ?usize = null; 
    var else_cnt: usize = idx; 
    for (0..origin.Three.content.len) |i| {
        if (origin.Three.content[i] == 0) {
            break; 
        }
        const c = maybeThreeCalcSize(origin.Three.content[i], depth); 
        if (else_cnt < c) {
            inner_idx = i;  
            break; 
        } else {
            else_cnt -= c; 
        }
    }
    const idx2: usize = inner_idx.?; 
    var buf: ?*Element = undefined; 
    var e3: *Element = undefined; 
    remain = try allocSingle(remain, use_first, &e3); 
    const inner_three: *Element = @ptrFromInt(origin.Three.content[idx2]); 
    remain = try threeInnerPush(e3, &buf, remain, use_first, inner_three.*, else_cnt, value, depth - 1); 
    if (buf) |b| {
        _ = b; // autofix
        if (origin.Three.content[2] == 0) {
            // Node 2 pattern 
            defer e2.* = null; 
            e.Three.content = origin.Three.content; 
            @memcpy(e.Three.content[0..idx2], origin.Three.content[0..idx2]); 
            e.Three.content[idx2] = value; 
            @memcpy(e.Three.content[(idx2+1)..3], origin.Three.content[idx2..2]); 
            e.Three.size += 1; 
        } else {
            var newly : *Element = undefined; 
            remain = try allocSingle(remain, use_first, &newly); 
            defer e2.* = newly; 
            var base: [4]usize = undefined; 
            var base_idx: usize = 0; 
            for (0..4) |v| {
                if (v == idx2 + 1) {
                    base[base_idx] = value; 
                    base_idx += 1; 
                }
                if (v != 3) {
                    if (v != idx2) {
                        base[base_idx] = origin.Three.content[v]; 
                    } else {
                        base[base_idx] = e3; 
                    }
                    base_idx += 1; 
                }
            }
            std.debug.assert(base_idx == 4); 
            e.Three.content[0] = base[0]; 
            e.Three.content[1] = base[1]; 
            e.Three.content[2] = 0;  
            newly.Three.content[0] = base[2]; 
            newly.Three.content[1] = base[3]; 
            newly.Three.content[2] = 0;  
            threeFlushSize(e, depth); 
            threeFlushSize(newly, depth); 
        }
    } else {
        defer e2.* = null; 
        e.* = origin; 
        e.Three.content[idx2] = @intFromPtr(e3); 
        // handle here 
        e.Three.size += 1; 
        if (false) {
            threeFlushSize(e, depth); 
        }
    }
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

test {
    var buffer: [30] Element = undefined; 
    var remain: []Element = buffer[0..]; 
    const s32: *Element = &remain[0]; 
    single(s32, 32, 0); 
    const emp: *Element = &remain[1]; 
    var value: usize = undefined; 
    remain = try pop(emp, remain[2..], true, s32.*, 0, true, &value); 
    std.log.warn("emp: {}", .{ value }); 
    std.log.warn("rst emp t: {}", .{ emp.FingerTree.t }); 
    var last_ele: *Element = s32; 
    for (3..7) |i| {
        const nowout: *Element = &remain[0]; 
        remain = try push(nowout, remain[1..], true, last_ele.*, i, 0, true); 
        last_ele = nowout; 
    }
    const si = last_ele.FingerTree.size; 
    std.log.warn("cnt: {}", .{ si }); 
    var right: bool = false; 
    while (true) {
        if (last_ele.FingerTree.t == Element.EmptyT) {
            break; 
        } 
        var val: usize = undefined;  
        const nowout: *Element = &remain[0]; 
        remain = try pop(nowout, remain[1..], true, last_ele.*, 0, right, &val); 
        std.log.warn("pop (right={}), as {}", .{ right, val }); 
        last_ele = nowout; 
        right = !right; 
    }
}