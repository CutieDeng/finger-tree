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

const pushlib = @import("push.zig"); 

pub const push = pushlib.push; 
pub const push2 = pushlib.push2; 
pub const push3 = pushlib.push3; 
pub const innerPush = pushlib.innerPush; 

const threeInnerPush = pushlib.threeInnerPush; 

const init = @import("init.zig");
pub const EMPTY = init.EMPTY; 
pub const single = initSingle; 
pub const initSingle = init.initSingle;

const alloc = @import("alloc.zig"); 
pub const allocSingle = alloc.allocOne; 
pub const allocOne = alloc.allocOne; 

const size_calc = @import("size_calc.zig"); 
pub const maybeThreeGetSize = size_calc.maybeThreeGetSize; 
pub const threeFlushSize = size_calc.threeSizeUpdateDirectly; 
pub const threeSizeUpdateDirectly  = size_calc.threeSizeUpdateDirectly; 
pub const fourLength = size_calc.fourLength; 
pub const fourSize = size_calc.fourSize; 
const deepGetSize = size_calc.deepGetSize; 

const poplib = @import("pop.zig"); 
pub const pop = poplib.pop; 
pub const innerPop = poplib.innerPop; 

const getlib = @import("get.zig"); 
pub const get = getlib.get; 

pub const Error = error { BufferNotEnough }; 

const mergelib = @import("merge.zig"); 
pub const merge = mergelib.merge; 

pub fn modify(e: *Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    std.debug.assert(idx < origin.FingerTree.size); 
    var remain = buffer; 
    if (origin.FingerTree.t == Element.SingleT) {
        if (depth == 0) {
            e.FingerTree.ptr = value; 
            e.FingerTree.size = 1; 
            e.FingerTree.t = Element.SingleT; 
        } else {
            var new: *Element = undefined; 
            const three: *Element = @ptrFromInt(origin.FingerTree.ptr); 
            remain = try allocSingle(remain, use_first, &new); 
            remain = try threeModify(new, remain, use_first, three.*, idx, value, depth - 1); 
            e.FingerTree.ptr = @intFromPtr(new); 
            e.FingerTree.size = origin.FingerTree.size; 
            e.FingerTree.t = Element.SingleT; 
        }
    } else {
        std.debug.assert(origin.FingerTree.t == Element.DeepT); 
        const deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
        const left: *Element = @ptrFromInt(deep.Deep.left); 
        const right: *Element = @ptrFromInt(deep.Deep.right); 
        const left_size = fourSize(left.*, depth); 
        const right_size = fourSize(right.*, depth); 
        const innerft: *Element = @ptrFromInt(deep.Deep.finger_tree); 
        const inner_size = innerft.FingerTree.size; 
        var new_deep: *Element = undefined; 
        if (idx < left_size) {
            // ...... 
            var new_four: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_four); 
            remain = try allocSingle(remain, use_first, &new_deep); 
            var fourr: Element = left.*; 
            const fourr_len = fourLength(fourr); 
            std.mem.reverse(usize, fourr.Four[0..fourr_len]); 
            remain = try fourModify(new_four, remain, use_first, fourr, idx, value, depth); 
            std.mem.reverse(usize, new_four.Four[0..fourr_len]); 
            new_deep.Deep.left = @intFromPtr(new_four); 
            new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
            new_deep.Deep.right = deep.Deep.right; 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.size = origin.FingerTree.size; 
        } else if (idx < left_size + inner_size) {
            const r = idx - left_size; 
            var new_ft: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_ft); 
            remain = try allocSingle(remain, use_first, &new_deep); 
            remain = try modify(new_ft, remain, use_first, innerft.*, r, value, depth + 1); 
            new_deep.Deep.left = deep.Deep.left; 
            new_deep.Deep.right = deep.Deep.right; 
            new_deep.Deep.finger_tree = @intFromPtr(new_ft); 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.size = origin.FingerTree.size; 
        } else {
            std.debug.assert(idx < left_size + inner_size + right_size); 
            const r = idx - left_size - inner_size; 
            var new_four: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &new_four); 
            remain = try allocSingle(remain, use_first, &new_deep); 
            remain = try fourModify(new_four, remain, use_first, right.*, r, value, depth); 
            new_deep.Deep.left = deep.Deep.left; 
            new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
            new_deep.Deep.right = @intFromPtr(new_four); 
            e.FingerTree.t = Element.DeepT; 
            e.FingerTree.size = origin.FingerTree.size; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
        }
    }
    return remain; 
}

pub fn fourModify(e: *Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    const len = fourLength(origin); 
    var cumul = idx; 
    var v: usize = undefined; 
    for (0..len) |l| {
        const l0 = origin.Four[l]; 
        const lc = maybeThreeGetSize(l0, depth); 
        if (cumul >= lc) {
            cumul -= lc; 
        } else {
            v = l; 
            break; 
        }
    }
    e.Four = origin.Four; 
    if (depth == 0) {
        e.Four[v] = value; 
        return buffer; 
    } else {
        var remain = buffer; 
        var new_three: *Element = undefined; 
        const now_three: *Element = @ptrFromInt(e.Four[v]); 
        remain = try allocSingle(remain, use_first, &new_three); 
        remain = try threeModify(new_three, remain, use_first, now_three.*, cumul, value, depth - 1); 
        e.Four[v] = @intFromPtr(new_three); 
        return remain; 
    }
}

pub fn threeModify(e: *Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    std.debug.assert(idx < origin.Three.size); 
    if (depth == 0) {
        e.* = origin; 
        e.Three.content[idx] = value; 
        return buffer; 
    } else {
        var remain = buffer; 
        var cum = idx; 
        for (origin.Three.content, 0..) |c, modi_idx| {
            if (c == 0) {
                unreachable; 
            }
            if (false and c % 8 != 0) {
                std.log.warn("c {x}, in idx {}, value {}, depth {}", .{ c, idx, value, depth }); 
            }
            const p: *Element = @ptrFromInt(c); 
            const s = maybeThreeGetSize(c, depth); 
            if (cum >= s) {
                cum -= s; 
            } else { 
                var new_three: *Element = undefined; 
                remain = try allocSingle(remain, use_first, &new_three); 
                remain = try threeModify(new_three, remain, use_first, p.*, cum, value, depth - 1); 
                e.* = origin; 
                e.Three.content[modi_idx] = @intFromPtr(new_three); 
                break; 
            }
        }
        return remain; 
    }
}

test {
    std.log.warn("similar test", .{}); 
    var buffer: [10]Element = undefined; 
    var e: Element = EMPTY; 
    var remain: []Element = buffer[0..];
    remain = try push(&e, remain, true, e, 1, 0, true); 
    remain = try push(&e, remain, true, e, 1, 0, true); 
    remain = try push(&e, remain, true, e, 1, 0, true); 
    std.log.warn("similar test end", .{}); 
}

test {
    std.log.warn("similar test3", .{}); 
    var buffer: [10]Element = undefined; 
    var e: Element = EMPTY; 
    var remain: []Element = buffer[0..];
    var tmp: Element = undefined; 
    remain = try push(&tmp, remain, true, e, 1, 0, true); 
    e = tmp; 
    remain = try push(&tmp, remain, true, e, 1, 0, true); 
    e = tmp; 
    remain = try push(&tmp, remain, true, e, 1, 0, true); 
    e = tmp; 
    std.log.warn("similar test3 end", .{}); 
}

test {
    std.log.warn("similar test2", .{}); 
    var buffer: [10]Element = undefined; 
    const a0 = &buffer[0]; 
    var remain: []Element = buffer[1..];
    a0.* = EMPTY; 
    const b0 = &remain[0]; 
    remain = try push(b0, remain[1..], true, a0.*, 1, 0, true); 
    const c0 = &remain[0]; 
    remain = try push(c0, remain[1..], true, b0.*, 1, 0, true); 
    const d0 = &remain[0]; 
    remain = try push(d0, remain[1..], true, c0.*, 1, 0, true); 
    std.log.warn("d0 size: {}", .{ d0.FingerTree.size }); 
    std.log.warn("similar test2 end", .{}); 
}

test {
    var buffer: [10]Element = undefined; 
    var e: Element = EMPTY; 
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
    const empty0: Element = EMPTY; 
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

test {
    var buffer: [40]Element = undefined; 
    var remain: []Element = buffer[0..]; 
    const emp: *Element = &remain[0]; 
    emp.* = EMPTY; 
    const one: *Element = &remain[1]; 
    remain = try innerPush(one, remain[2..], true, emp.*, 0, 10, 0); 
    const two: *Element = &remain[0]; 
    remain = try innerPush(two, remain[1..], true, one.*, 1, 11, 0); 
    std.log.warn("one size: {}; two size: {}; ", .{ one.FingerTree.size, two.FingerTree.size }); 
    std.log.warn("two[0]: {}, two[1]: {}", .{ get(two.*, 0, 0), get(two.*, 1, 0) }); 
    std.log.warn("Just cost {} elems memory, for two elements tree. ", .{ 40 - remain.len }); 
}

test {
    var buf: [30] Element = undefined; 
    var remain: []Element = &buf; 
    const emp = &remain[0]; 
    const one = &remain[1]; 
    emp.* = EMPTY; 
    remain = try push(one, remain[2..], true, emp.*, 1, 0, true); 
    const two = &remain[0]; 
    remain = try push(two, remain[1..], true, one.*, 3, 0, true); 
    const fiv = &remain[0]; 
    remain = try push(fiv, remain[1..], true, two.*, 5, 0, true); 
    const sev = &remain[0]; 
    var rst: usize = undefined; 
    var fail: ?usize = undefined; 
    remain = try innerPop(sev, remain[1..], true, fiv.*, 1, 0, &rst, &fail); 
    std.debug.assert(fail == null); 
    std.log.warn("Remove successful, rst: {x}, but expect {}", .{ rst, 3 }); 
    std.debug.assert(rst == 3); 
}

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
            break; 
        }
    }
    return buffer; 
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
    remain = try allocSingle(remain, use_first, &deep); 
    remain = try allocSingle(remain, use_first, &left); 
    remain = try allocSingle(remain, use_first, &right); 
    remain = try allocSingle(remain, use_first, &emp); 
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
    e.FingerTree.size = deepGetSize(deep, depth); 
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
                single(e, right.Four[0], depth); 
            } else {
                remain = try allocSingle(remain, use_first, &d); 
                remain = try allocSingle(remain, use_first, &new_left); 
                remain = try allocSingle(remain, use_first, &new_right); 
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
                e.FingerTree.size = deepGetSize(d, depth); 
            }
        } else {
            remain = try allocSingle(remain, use_first, &new_inner); 
            remain = try allocSingle(remain, use_first, &d); 
            remain = try allocSingle(remain, use_first, &new_left); 
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
            e.FingerTree.size = deepGetSize(d, depth); 
        }
    } else if (right.Four[0] == 0) {
        if (inner.FingerTree.t == Element.EmptyT) {
            if (left.Four[1] == 0) {
                single(e, left.Four[0], depth); 
            } else {
                remain = try allocSingle(remain, use_first, &d); 
                remain = try allocSingle(remain, use_first, &new_left); 
                remain = try allocSingle(remain, use_first, &new_right); 
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
                e.FingerTree.size = deepGetSize(d, depth); 
            } 
        } else {
            remain = try allocSingle(remain, use_first, &new_inner); 
            remain = try allocSingle(remain, use_first, &d); 
            remain = try allocSingle(remain, use_first, &new_right); 
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
            e.FingerTree.size = deepGetSize(d, depth); 
        }
    } else {
        remain = try allocSingle(remain, use_first, &d); 
        d.Deep.left = @intFromPtr(left); 
        d.Deep.finger_tree = @intFromPtr(inner); 
        d.Deep.right = @intFromPtr(right); 
        e.FingerTree.ptr = @intFromPtr(d); 
        e.FingerTree.t = Element.DeepT; 
        e.FingerTree.size = deepGetSize(d, depth); 
    }
    return remain; 
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
        const d_left_size = fourSize(d_left, depth); 
        const d_inner_size = d_ft.FingerTree.size; 
        if (index < d_left_size) {
            var l_four: Element = undefined; 
            var r_four: Element = undefined; 
            remain = try fourSplit(&l_four, &r_four, mid, inner_idx, remain, use_first, d_left.*, index, depth);  
            remain = try fourToFingerTree(left, remain, use_first, l_four, depth); 
            var r_four0: *Element = &r_four; 
            if (r_four.Four[0] != 0) {
                remain = try allocSingle(remain, use_first, &r_four0); 
                r_four0.* = r_four; 
            }
            remain = try maybeDeepFingerTreeButDigit0(right, remain, use_first, r_four0, d_ft, d_right, depth); 
        } else if (index < d_left_size + d_inner_size) {
            const r = index - d_left_size; 
            var this_mid: usize = undefined; 
            var inner_idx0: usize = undefined; 
            var inner_left: *Element = undefined; 
            var inner_right: *Element = undefined; 
            remain = try allocSingle(remain, use_first, &inner_left); 
            remain = try allocSingle(remain, use_first, &inner_right); 
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
                remain = try allocSingle(remain, use_first, &new_l); 
                new_l.* = l; 
            }
            if (r0.Four[0] != 0) {
                remain = try allocSingle(remain, use_first, &new_r); 
                new_r.* = r0; 
            }
            remain = try maybeDeepFingerTreeButDigit0(left, remain, use_first, d_left, inner_left, new_l, depth); 
            remain = try maybeDeepFingerTreeButDigit0(right, remain, use_first, new_r, inner_right, d_right, depth); 
        } else {
            std.debug.assert(index < d_left_size + d_inner_size + fourSize(d_right, depth)); 
            const r = index - d_left_size - d_inner_size; 
            var l_four: Element = undefined; 
            var r_four: Element = undefined; 
            remain = try fourSplit(&l_four, &r_four, mid, inner_idx, remain, use_first, d_right.*, r, depth);  
            remain = try fourToFingerTree(right, remain, use_first, r_four, depth); 
            var l_four0: *Element = &l_four; 
            if (l_four.Four[0] != 0) {
                remain = try allocSingle(remain, use_first, &l_four0); 
                l_four0.* = l_four; 
            }
            remain = try maybeDeepFingerTreeButDigit0(left, remain, use_first, d_left, d_ft, l_four0, depth); 
        }
    } 
    return remain; 
}

test {
    const buf_base: []Element = try std.testing.allocator.alloc(Element, 100);
    defer std.testing.allocator.free(buf_base); 
    var buf: []Element = buf_base; 
    single(&buf[0], 10, 0); 
    single(&buf[1], 11, 0); 
    var rst: usize = undefined; 
    var inner: usize = undefined; 
    buf = try split(&buf[2], &buf[3], &rst, &inner, buf[4..], true, buf[0], 0, 0); 
    std.log.warn("split rst: {}, inner: {x}, lsize: {}, rsize: {}", .{ rst, inner, buf_base[2].FingerTree.size, buf_base[3].FingerTree.size }); 
    const m1 = &buf[0]; 
    buf = try merge(m1, buf[1..], true, buf_base[0], buf_base[1], 0); 
    const m2 = &buf[0]; 
    buf = try merge(m2, buf[1..], true, m1.*, m1.*, 0); 
    std.log.warn("size of m2: {}", .{ m2.FingerTree.size }); 
    const buf1 = buf[0..2]; 
    buf = try split(&buf[0], &buf[1], &rst, &inner, buf[2..], true, m2.*, 3, 0); 
    std.log.warn("rst: {}, inner: {}", .{ rst, inner }); 
    std.log.warn("l size: {}, r size: {}", .{ buf1[0].FingerTree.size, buf1[1].FingerTree.size }); 
    std.log.warn("l[0]: {}; l[1]: {}; l[2]: {}", .{ get(buf1[0], 0, 0), get(buf1[0], 1, 0), get(buf1[0], 2, 0) }); 
}
