const lib = @import("root.zig"); 
const std = @import("std"); 

const Element = lib.Element; 
const EMPTY = lib.EMPTY; 
const maybeThreeGetSize = lib.maybeThreeGetSize; 
const fourSize = lib.fourSize; 
const fourLength = lib.fourLength; 
const allocOne = lib.allocOne; 
const initSingle = lib.initSingle; 

const size_calc = @import("size_calc.zig"); 
const deepGetSize = size_calc.deepGetSize; 

const pop = lib.pop; 

pub fn fourSplit(left: *Element, right: *Element, mid: *usize, inner_idx: *usize, buffer: []Element, use_first: bool, origin: Element, index: usize, depth: usize) ![]Element {
    _ = use_first; // autofix
    if (depth == 0) {
        @memcpy(left.Four[0..index], origin.Four[0..index]); 
        left.Four[index] = 0; 
        @memcpy(right.Four[0..(3-index)], origin.Four[index+1..]); 
        right.Four[3-index] = 0; 
        mid.* = origin.Four[index]; 
        return buffer; 
    }
    var cum = index; 
    for (origin.Four, 0..) |f, idx| {
        if (f == 0) unreachable; 
        const s = maybeThreeGetSize(f, depth); 
        if (cum >= s) {
            cum -= s; 
        } else {
            @memcpy(left.Four[0..idx], origin.Four[0..idx]); 
            left.Four[idx] = 0; 
            @memcpy(right.Four[0..(3-idx)], origin.Four[idx+1..]); 
            right.Four[3-idx] = 0; 
            mid.* = origin.Four[idx]; 
            inner_idx.* = cum; 
            return buffer; 
        }
    }
    unreachable; 
}

pub fn split(left: *Element, right: *Element, mid: *usize, inner_idx: *usize, buffer: []Element, use_first: bool, origin: Element, index: usize, depth: usize) ![]Element {
    var remain = buffer; 
    if (origin.FingerTree.t == Element.EmptyT) {
        unreachable; 
    } else if (origin.FingerTree.t == Element.SingleT) {
        mid.* = origin.FingerTree.ptr; 
        inner_idx.* = index; 
        left.* = EMPTY; 
        right.* = EMPTY; 
    } else if (origin.FingerTree.t == Element.DeepT) {
        const deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
        const d_left: *Element = @ptrFromInt(deep.Deep.left); 
        const d_right: *Element = @ptrFromInt(deep.Deep.right); 
        const d_ft: *Element = @ptrFromInt(deep.Deep.finger_tree); 
        const d_left_size = fourSize(d_left.*, depth); 
        const d_inner_size = d_ft.FingerTree.size; 
        if (index < d_left_size) {
            var l_four: Element = undefined; 
            var r_four: Element = undefined; 
            remain = try fourSplit(&l_four, &r_four, mid, inner_idx, remain, use_first, d_left.*, index, depth);  
            remain = try fourToFingerTree(left, remain, use_first, l_four, depth); 
            var r_four0: *Element = &r_four; 
            if (r_four.Four[0] != 0) {
                remain = try allocOne(remain, use_first, &r_four0); 
                r_four0.* = r_four; 
            }
            remain = try maybeDeepFingerTreeButDigit0(right, remain, use_first, r_four0, d_ft, d_right, depth); 
        } else if (index < d_left_size + d_inner_size) {
            const r = index - d_left_size; 
            var this_mid: usize = undefined; 
            var inner_idx0: usize = undefined; 
            var inner_left: *Element = undefined; 
            var inner_right: *Element = undefined; 
            remain = try allocOne(remain, use_first, &inner_left); 
            remain = try allocOne(remain, use_first, &inner_right); 
            remain = try split(inner_left, inner_right, &this_mid, &inner_idx0, remain, use_first, d_ft.*, r, depth + 1); 
            const ip: *Element = @ptrFromInt(this_mid); 
            var xs: Element = undefined; 
            @memcpy(xs.Four[0..3], ip.Three.content[0..]); 
            xs.Four[3] = 0; 
            var l: Element = undefined; 
            var r0: Element = undefined; 
            remain = try fourSplit(&l, &r0, mid, inner_idx, remain, use_first, xs, inner_idx0, depth); 
            var new_l: *Element = &l; 
            var new_r = &r0; 
            if (l.Four[0] != 0) {
                remain = try allocOne(remain, use_first, &new_l); 
                new_l.* = l; 
            }
            if (r0.Four[0] != 0) {
                remain = try allocOne(remain, use_first, &new_r); 
                new_r.* = r0; 
            }
            remain = try maybeDeepFingerTreeButDigit0(left, remain, use_first, d_left, inner_left, new_l, depth); 
            remain = try maybeDeepFingerTreeButDigit0(right, remain, use_first, new_r, inner_right, d_right, depth); 
        } else {
            std.debug.assert(index < d_left_size + d_inner_size + fourSize(d_right.*, depth)); 
            const r = index - d_left_size - d_inner_size; 
            var l_four: Element = undefined; 
            var r_four: Element = undefined; 
            remain = try fourSplit(&l_four, &r_four, mid, inner_idx, remain, use_first, d_right.*, r, depth);  
            remain = try fourToFingerTree(right, remain, use_first, r_four, depth); 
            var l_four0: *Element = &l_four; 
            if (l_four.Four[0] != 0) {
                remain = try allocOne(remain, use_first, &l_four0); 
                l_four0.* = l_four; 
            }
            remain = try maybeDeepFingerTreeButDigit0(left, remain, use_first, d_left, d_ft, l_four0, depth); 
        }
    } 
    return remain; 
}

pub fn fourToFingerTree(e: *Element, buffer: []Element, use_first: bool, origin: Element, depth: usize) ![]Element {
    if (origin.Four[0] == 0) {
        e.* = EMPTY; 
        return buffer; 
    }
    const f_length = fourLength(origin); 
    if (f_length == 1) {
        initSingle(e, origin.Four[0], depth); 
        return buffer; 
    }
    var remain = buffer; 
    var left: *Element = undefined; 
    var right: *Element = undefined; 
    var emp: *Element = undefined; 
    var deep: *Element = undefined; 
    remain = try allocOne(remain, use_first, &deep); 
    remain = try allocOne(remain, use_first, &left); 
    remain = try allocOne(remain, use_first, &right); 
    remain = try allocOne(remain, use_first, &emp); 
    emp.* = EMPTY; 
    const mid = f_length / 2; 
    @memcpy(left.Four[0..mid], origin.Four[0..mid]); 
    std.mem.reverse(usize, left.Four[0..mid]); 
    left.Four[mid] = 0; 
    @memcpy(right.Four[0..(f_length - mid)], origin.Four[mid..f_length]); 
    right.Four[f_length - mid] = 0; 
    deep.Deep.left = @intFromPtr(left); 
    deep.Deep.finger_tree = @intFromPtr(emp); 
    deep.Deep.right = @intFromPtr(right); 
    e.FingerTree.t = Element.DeepT; 
    e.FingerTree.ptr = @intFromPtr(deep); 
    e.FingerTree.size = deepGetSize(deep.*, depth); 
    return remain; 
}

pub fn maybeDeepFingerTreeButDigit0(e: *Element, buffer: []Element, use_first: bool, left: *Element, inner: *Element, right: *Element, depth: usize) ![]Element {
    var remain = buffer; 
    var new_inner: *Element = undefined; 
    var d: *Element = undefined; 
    var new_left: *Element = undefined; 
    var new_right: *Element = undefined; 
    if (left.Four[0] == 0) {
        std.debug.assert(right.Four[0] != 0); 
        if (inner.FingerTree.t == Element.EmptyT) {
            if (right.Four[1] == 0) {
                initSingle(e, right.Four[0], depth); 
            } else {
                remain = try allocOne(remain, use_first, &d); 
                remain = try allocOne(remain, use_first, &new_left); 
                remain = try allocOne(remain, use_first, &new_right); 
                const rlen = fourLength(right.*); 
                @memcpy(new_right.Four[0..rlen-1], right.Four[1..rlen]); 
                new_right.Four[rlen] = 0; 
                new_left.Four[0] = right.Four[0];
                new_left.Four[1] = 0; 
                d.Deep.left = @intFromPtr(new_left); 
                d.Deep.right = @intFromPtr(new_right); 
                d.Deep.finger_tree = @intFromPtr(inner); 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(d); 
                e.FingerTree.size = deepGetSize(d.*, depth); 
            }
        } else {
            remain = try allocOne(remain, use_first, &new_inner); 
            remain = try allocOne(remain, use_first, &d); 
            remain = try allocOne(remain, use_first, &new_left); 
            var result: usize = undefined; 
            remain = try pop(new_inner, remain, use_first, inner.*, depth + 1, false, &result); 
            const p: *Element = @ptrFromInt(result); 
            const plen: usize = if (p.Three.content[2] == 0) 2 else 3; 
            @memcpy(new_left.Four[0..plen], p.Three.content[0..plen]); 
            std.mem.reverse(usize, new_left.Four[0..plen]); 
            new_left.Four[plen] = 0; 
            d.Deep.left = @intFromPtr(new_left); 
            d.Deep.finger_tree = @intFromPtr(new_inner); 
            d.Deep.right = @intFromPtr(right); 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.ptr = @intFromPtr(d); 
            e.FingerTree.size = deepGetSize(d.*, depth); 
        }
    } else if (right.Four[0] == 0) {
        if (inner.FingerTree.t == Element.EmptyT) {
            if (left.Four[1] == 0) {
                initSingle(e, left.Four[0], depth); 
            } else {
                remain = try allocOne(remain, use_first, &d); 
                remain = try allocOne(remain, use_first, &new_left); 
                remain = try allocOne(remain, use_first, &new_right); 
                const llen = fourLength(left.*); 
                @memcpy(new_left.Four[0..llen-1], left.Four[1..llen]); 
                new_right.Four[llen] = 0; 
                new_right.Four[0] = left.Four[0];
                new_right.Four[1] = 0; 
                d.Deep.left = @intFromPtr(new_left); 
                d.Deep.right = @intFromPtr(new_right); 
                d.Deep.finger_tree = @intFromPtr(inner); 
                e.FingerTree.t = Element.DeepT; 
                e.FingerTree.ptr = @intFromPtr(d); 
                e.FingerTree.size = deepGetSize(d.*, depth); 
            } 
        } else {
            remain = try allocOne(remain, use_first, &new_inner); 
            remain = try allocOne(remain, use_first, &d); 
            remain = try allocOne(remain, use_first, &new_right); 
            var result: usize = undefined; 
            remain = try pop(new_inner, remain, use_first, inner.*, depth + 1, true, &result); 
            const p: *Element = @ptrFromInt(result); 
            const plen: usize = if (p.Three.content[2] == 0) 2 else 3; 
            @memcpy(new_right.Four[0..plen], p.Three.content[0..plen]); 
            new_right.Four[plen] = 0; 
            d.Deep.left = @intFromPtr(left); 
            d.Deep.finger_tree = @intFromPtr(new_inner); 
            d.Deep.right = @intFromPtr(new_right); 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.ptr = @intFromPtr(d); 
            e.FingerTree.size = deepGetSize(d.*, depth); 
        }
    } else {
        remain = try allocOne(remain, use_first, &d); 
        d.Deep.left = @intFromPtr(left); 
        d.Deep.finger_tree = @intFromPtr(inner); 
        d.Deep.right = @intFromPtr(right); 
        e.FingerTree.ptr = @intFromPtr(d); 
        e.FingerTree.t = Element.DeepT; 
        e.FingerTree.size = deepGetSize(d.*, depth); 
    }
    return remain; 
}
