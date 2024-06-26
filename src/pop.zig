const std = @import("std");
const testing = std.testing;

const lib = @import("root.zig"); 

const Element = lib.Element; 
const EMPTY = lib.EMPTY; 
const initSingle = lib.initSingle; 

const fourLength = lib.fourLength; 
const fourSize = lib.fourSize; 
const deepGetSize = lib.deepGetSize; 
const maybeThreeGetSize = lib.maybeThreeGetSize; 
const threeSizeUpdateDirectly = lib.threeSizeUpdateDirectly; 

const allocOne = lib.allocOne; 

const pushlib = @import("push.zig"); 
const threeInnerPush = pushlib.threeInnerPush; 

pub fn pop(e: *Element, buffer: []Element, use_first: bool, origin: Element, depth: usize, right: bool, pop_rst: *usize) ![]Element {
    if (origin.FingerTree.t == Element.EmptyT) {
        unreachable; 
    }
    var remain: []Element = buffer; 
    if (origin.FingerTree.t == Element.SingleT) {
        pop_rst.* = origin.FingerTree.ptr; 
        e.* = EMPTY; 
        return remain; 
    } 
    std.debug.assert(origin.FingerTree.t == Element.DeepT); 
    const deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
    const rright: *Element = @ptrFromInt(if (right) deep.Deep.right else deep.Deep.left); 
    const left: *Element = @ptrFromInt(if (right) deep.Deep.left else deep.Deep.right); 
    const right_len = fourLength(rright.*); 
    if (right_len == 1) {
        const deep_fingertree: *Element = @ptrFromInt(deep.Deep.finger_tree); 
        if (deep_fingertree.FingerTree.t == Element.EmptyT) {
            const left_len = fourLength(left.*);
            if (left_len == 1) {
                pop_rst.* = rright.Four[0]; 
                initSingle(e, left.Four[0], depth); 
            } else {
                var new_left: *Element = undefined; 
                var new_right: *Element = undefined; 
                var new_deep: *Element = undefined; 
                remain = try allocOne(remain, use_first, &new_left); 
                remain = try allocOne(remain, use_first, &new_right); 
                remain = try allocOne(remain, use_first, &new_deep); 
                pop_rst.* = rright.Four[0]; 
                new_right.Four[0] = left.Four[0]; 
                new_right.Four[1] = 0; 
                @memcpy(new_left.Four[0..left_len - 1], left.Four[1..left_len]); 
                new_left.Four[left_len - 1] = 0; 
                new_deep.Deep.left = @intFromPtr(if (right) new_left else new_right ); 
                new_deep.Deep.right = @intFromPtr(if (!right) new_left else new_right ); 
                new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                e.FingerTree.size = origin.FingerTree.size - maybeThreeGetSize(rright.Four[0], depth); 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.t = Element.DeepT; 
            }
        } else {
            var new_deep_fingertree: *Element = undefined; 
            var new_rfour: *Element = undefined; 
            var new_deep: *Element = undefined; 
            remain = try allocOne(remain, use_first, &new_deep_fingertree); 
            remain = try allocOne(remain, use_first, &new_rfour); 
            remain = try allocOne(remain, use_first, &new_deep); 
            var rst: usize = undefined; 
            remain = try pop(new_deep_fingertree, remain, use_first, deep_fingertree.*, depth + 1, right, &rst); 
            pop_rst.* = rright.Four[0]; 
            const pop_three: *Element = @ptrFromInt(rst); 
            @memcpy(new_rfour.Four[0..3], pop_three.Three.content[0..]); 
            new_rfour.Four[3] = 0; 
            const new_rfour_len = fourLength(new_rfour.*); 
            new_deep.* = deep.*; 
            new_deep.Deep.finger_tree = @intFromPtr(new_deep_fingertree); 
            if (!right) {
                std.mem.reverse(usize, new_rfour.Four[0..new_rfour_len]);  
                new_deep.Deep.left = @intFromPtr(new_rfour); 
            } else {
                new_deep.Deep.right = @intFromPtr(new_rfour); 
            }
            e.FingerTree.size = origin.FingerTree.size - maybeThreeGetSize(rright.Four[0], depth); 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.t = Element.DeepT; 
        }
    } else {
        var new_rright: *Element = undefined; 
        var new_deep: *Element= undefined; 
        remain = try allocOne(remain, use_first, &new_rright); 
        remain = try allocOne(remain, use_first, &new_deep); 
        pop_rst.* = rright.Four[right_len - 1]; 
        new_rright.* = rright.*; 
        new_rright.Four[right_len - 1] = 0; 
        new_deep.* = deep.*; 
        (if (right) 
            new_deep.Deep.right 
        else 
            new_deep.Deep.left)
                = @intFromPtr(new_rright); 
        e.FingerTree.size = origin.FingerTree.size - maybeThreeGetSize(rright.Four[right_len - 1], depth); 
        e.FingerTree.ptr = @intFromPtr(new_deep); 
        e.FingerTree.t = Element.DeepT; 
    }
    return remain; 
}

pub fn innerPop(e: *Element, buffer: []Element, use_first: bool, origin: Element, index: usize, depth: usize, pop_rst: *usize, fail_check: *?usize) ![]Element {
    std.debug.assert(origin.FingerTree.t != Element.EmptyT); 
    var remain = buffer; 
    if (origin.FingerTree.t == Element.SingleT) {
        if (depth == 0) {
            pop_rst.* = origin.FingerTree.ptr; 
            e.* = EMPTY; 
        } else {
            var tmp: Element = undefined; 
            var fail: ?usize = undefined; 
            const three: *Element = @ptrFromInt(origin.FingerTree.ptr); 
            remain = try threeInnerPop(&tmp, remain, use_first, three.*, index, depth - 1, pop_rst, &fail); 
            if (fail) |f| {
                fail_check.* = f; 
                return remain; 
            } else {
                var tmp2: *Element = undefined; 
                remain = try allocOne(remain, use_first, &tmp2); 
                tmp2.* = tmp; 
                e.FingerTree.size = origin.FingerTree.size - 1; 
                e.FingerTree.ptr = @intFromPtr(tmp2); 
                e.FingerTree.t = Element.SingleT; 
            }
        }
    } else if (origin.FingerTree.t == Element.DeepT) {
        const deep: *Element = @ptrFromInt(origin.FingerTree.ptr); 
        const left: *Element = @ptrFromInt(deep.Deep.left); 
        const right: *Element = @ptrFromInt(deep.Deep.right); 
        const inner: *Element = @ptrFromInt(deep.Deep.finger_tree); 
        const l_size = fourSize(left.*, depth); 
        const inner_size = inner.FingerTree.size;  
        if (index < l_size) {
            var left0: Element = left.*; 
            std.mem.reverse(usize, left0.Four[0..fourLength(left0)]); 
            var four: Element = undefined; 
            var fail: ?usize = undefined; 
            remain = try fourInnerPop(&four, remain, use_first, left0, index, depth, pop_rst, &fail); 
            if (fail) |f| {
                if (inner.FingerTree.t == Element.EmptyT) {
                    const rlen = fourLength(right.*); 
                    if (f == 0) {
                        std.debug.assert(depth == 0); 
                        if (rlen == 1) {
                            e.FingerTree.ptr = right.Four[0]; 
                            // e.FingerTree.size = origin.FingerTree.size - 1; 
                            e.FingerTree.size = 1; 
                            e.FingerTree.t = Element.SingleT; 
                        } else {
                            var new_left: *Element = undefined; 
                            var new_right: *Element = undefined; 
                            var new_deep: *Element = undefined; 
                            remain = try allocOne(remain, use_first, &new_left); 
                            remain = try allocOne(remain, use_first, &new_right); 
                            remain = try allocOne(remain, use_first, &new_deep); 
                            @memcpy(new_right.Four[0..3], right.Four[1..4]);  
                            new_right.Four[3] = 0;  
                            new_left.Four[0] = right.Four[0]; 
                            new_left.Four[1] = 0;
                            new_deep.Deep.left = @intFromPtr(new_left); 
                            new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                            new_deep.Deep.left = @intFromPtr(new_right); 
                            e.FingerTree.t = Element.DeepT; 
                            e.FingerTree.ptr = @intFromPtr(new_deep); 
                            e.FingerTree.size = origin.FingerTree.size - 1; 
                        }
                    } else {
                        std.debug.assert(depth > 0); 
                        var new_left: *Element = undefined; 
                        var new_right: *Element = undefined; 
                        var new_deep: *Element = undefined; 
                        const r_first: *Element = @ptrFromInt(right.Four[0]); 
                        if (r_first.Three.content[2] == 0) {
                            var new_three: *Element = undefined; 
                            remain = try allocOne(remain, use_first, &new_three); 
                            if (rlen == 1) {
                                new_three.Three.content[0] = f; 
                                @memcpy(new_three.Three.content[1..3], r_first.Three.content[0..2]); 
                                threeSizeUpdateDirectly(new_three, depth - 1);     
                                e.FingerTree.ptr = @intFromPtr(new_three); 
                                e.FingerTree.size = origin.FingerTree.size - 1; 
                                e.FingerTree.t = Element.SingleT; 
                            } else {
                                remain = try allocOne(remain, use_first, &new_left); 
                                remain = try allocOne(remain, use_first, &new_right); 
                                remain = try allocOne(remain, use_first, &new_deep); 
                                new_three.Three.content[0] = f; 
                                @memcpy(new_three.Three.content[1..3], r_first.Three.content[0..2]); 
                                threeSizeUpdateDirectly(new_three, depth - 1); 
                                new_left.Four[0] = @intFromPtr(new_three); 
                                new_left.Four[1] = 0; 
                                @memcpy(new_right.Four[0..rlen - 1], right.Four[1..rlen]); 
                                new_right.Four[rlen-1] = 0; 
                                new_deep.Deep.left = @intFromPtr(new_left); 
                                new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                                new_deep.Deep.right = @intFromPtr(new_right); 
                                e.FingerTree.t = Element.DeepT; 
                                e.FingerTree.size = origin.FingerTree.size - 1; 
                                e.FingerTree.ptr = @intFromPtr(new_deep); 
                            }
                        } else {
                            var new_three0: *Element = undefined; 
                            var new_three1: *Element = undefined; 
                            remain = try allocOne(remain, use_first, &new_three0); 
                            remain = try allocOne(remain, use_first, &new_three1); 
                            remain = try allocOne(remain, use_first, &new_left); 
                            remain = try allocOne(remain, use_first, &new_right); 
                            remain = try allocOne(remain, use_first, &new_deep); 
                            new_three0.Three.content[0] = f; 
                            new_three0.Three.content[1] = r_first.Three.content[0]; 
                            new_three0.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(new_three0, depth); 
                            new_three1.Three.content[0] = r_first.Three.content[1]; 
                            new_three1.Three.content[1] = r_first.Three.content[2]; 
                            new_three1.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(new_three1, depth); 
                            new_left.Four[0] = @intFromPtr(new_three0); 
                            new_left.Four[1] = 0; 
                            new_right.Four[0] = @intFromPtr(new_three1); 
                            @memcpy(new_right.Four[1..4], right.Four[1..4]); 
                            new_deep.Deep.left = @intFromPtr(new_left); 
                            new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                            new_deep.Deep.right = @intFromPtr(new_right); 
                            e.FingerTree.ptr = @intFromPtr(new_deep); 
                            e.FingerTree.size = origin.FingerTree.size - 1; 
                            e.FingerTree.t = Element.DeepT; 
                        }
                    }
                    fail_check.* = null; 
                    return remain; 
                }
                var new_inner_ft: *Element = undefined; 
                var new_left: *Element = undefined; 
                var new_deep: *Element = undefined; 
                var p: usize = undefined; 
                remain = try allocOne(remain, use_first, &new_inner_ft); 
                remain = try allocOne(remain, use_first, &new_left); 
                remain = try allocOne(remain, use_first, &new_deep); 
                remain = try pop(new_inner_ft, remain, use_first, inner.*, depth + 1, false, &p); 
                const this_three: *Element = @ptrFromInt(p); 
                if (f == 0) {
                    std.debug.assert(depth == 0); 
                    if (this_three.Three.content[2] == 0) {
                        new_left.Four[0] = this_three.Three.content[1]; 
                        new_left.Four[1] = this_three.Three.content[0]; 
                        new_left.Four[2] = 0; 
                    } else {
                        new_left.Four[0] = this_three.Three.content[2]; 
                        new_left.Four[1] = this_three.Three.content[1]; 
                        new_left.Four[2] = this_three.Three.content[0]; 
                        new_left.Four[3] = 0; 
                    }
                    new_deep.Deep.left = @intFromPtr(new_left); 
                    new_deep.Deep.finger_tree = @intFromPtr(new_inner_ft); 
                    new_deep.Deep.right = deep.Deep.right; 
                    e.FingerTree.ptr = @intFromPtr(new_deep);
                    e.FingerTree.t = Element.DeepT; 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                    fail_check.* = null; 
                    return remain; 
                }
                const inner_three: *Element = @ptrFromInt(this_three.Three.content[0]); 
                if (inner_three.Three.content[2] == 0) {
                    var new_three0: *Element = undefined; 
                    remain = try allocOne(remain, use_first, &new_three0); 
                    @memcpy(new_three0.Three.content[1..3], inner_three.Three.content[0..2]);  
                    new_three0.Three.content[0] = f; 
                    threeSizeUpdateDirectly(new_three0, depth); 
                    @memcpy(new_left.Four[0..2], this_three.Three.content[1..]); 
                    new_left.Four[2] = @intFromPtr(new_three0); 
                    new_left.Four[3] = 0; 
                    new_deep.Deep.left = @intFromPtr(new_left); 
                    new_deep.Deep.finger_tree = @intFromPtr(new_inner_ft); 
                    new_deep.Deep.right = deep.Deep.right; 
                    e.FingerTree.t = Element.DeepT; 
                    e.FingerTree.ptr = @intFromPtr(new_deep); 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                } else {
                    var new_three0: *Element = undefined; 
                    var new_three1: *Element = undefined; 
                    remain = try allocOne(remain, use_first, &new_three0); 
                    remain = try allocOne(remain, use_first, &new_three1); 
                    new_three0.Three.content[0] = f; 
                    new_three0.Three.content[1] = inner_three.Three.content[0]; 
                    new_three0.Three.content[2] = 0; 
                    threeSizeUpdateDirectly(new_three0, depth - 1); 
                    new_three1.Three.content[0] = inner_three.Three.content[1]; 
                    new_three1.Three.content[1] = inner_three.Three.content[2]; 
                    new_three1.Three.content[2] = 0; 
                    threeSizeUpdateDirectly(new_three1, depth - 1); 
                    @memcpy(new_left.Four[0..2], this_three.Three.content[1..]); 
                    new_left.Four[2] = @intFromPtr(new_three1); 
                    new_left.Four[3] = @intFromPtr(new_three0); 
                    new_deep.Deep.left = @intFromPtr(new_left);
                    new_deep.Deep.finger_tree = @intFromPtr(new_inner_ft); 
                    new_deep.Deep.right = deep.Deep.right; 
                    e.FingerTree.t = Element.DeepT; 
                    e.FingerTree.ptr = @intFromPtr(new_deep); 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                }
            } else {
                std.mem.reverse(usize, four.Four[0..fourLength(four)]); 
                var new_four: *Element = undefined; 
                var new_deep: *Element = undefined; 
                remain = try allocOne(remain, use_first, &new_four); 
                remain = try allocOne(remain, use_first, &new_deep); 
                new_four.* = four; 
                new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                new_deep.Deep.left = @intFromPtr(new_four); 
                new_deep.Deep.right = deep.Deep.right; 
                e.FingerTree.t = Element.DeepT;
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.size = origin.FingerTree.size - 1;  
            }
        } else if (index < l_size + inner_size) {
            const r = index - l_size; 
            var inner0: Element = undefined; 
            var fail: ?usize = undefined; 
            var new_deep: *Element = undefined; 
            remain = try innerPop(&inner0, remain, use_first, inner.*, r, depth + 1, pop_rst, &fail); 
            if (fail) |f| {
                if (f == 0) {
                    unreachable; 
                }
                const llen = fourLength(left.*); 
                const rlen = fourLength(right.*); 
                if (llen == 4 and rlen == 4) {
                    var new_three: *Element = undefined; 
                    var new_single: *Element = undefined; 
                    var new_left: *Element = undefined; 
                    var new_right: *Element = undefined; 
                    remain = try allocOne(remain, use_first, &new_three); 
                    remain = try allocOne(remain, use_first, &new_single); 
                    remain = try allocOne(remain, use_first, &new_left); 
                    remain = try allocOne(remain, use_first, &new_right); 
                    remain = try allocOne(remain, use_first, &new_deep); 
                    new_three.Three.content[0] = left.Four[0]; 
                    new_three.Three.content[1] = f; 
                    new_three.Three.content[2] = right.Four[0]; 
                    threeSizeUpdateDirectly(new_three, depth); 
                    initSingle(new_single, @intFromPtr(new_three), depth); 
                    @memcpy(new_left.Four[0..3], left.Four[1..]); 
                    new_left.Four[3] = 0; 
                    @memcpy(new_right.Four[0..3], right.Four[1..]); 
                    new_right.Four[3] = 0; 
                    new_deep.Deep.left = @intFromPtr(new_left); 
                    new_deep.Deep.finger_tree = @intFromPtr(new_single); 
                    new_deep.Deep.right = @intFromPtr(new_right); 
                    e.FingerTree.ptr = @intFromPtr(new_deep); 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                    e.FingerTree.t = Element.DeepT; 
                } else if (llen < rlen) {
                    var new_left: *Element = undefined; 
                    var emp: *Element = undefined; 
                    remain = try allocOne(remain, use_first, &new_left); 
                    remain = try allocOne(remain, use_first, &emp); 
                    remain = try allocOne(remain, use_first, &new_deep); 
                    emp.* = EMPTY; 
                    @memcpy(new_left.Four[1..], left.Four[0..3]); 
                    new_left.Four[0] = f; 
                    new_deep.Deep.left = @intFromPtr(new_left); 
                    new_deep.Deep.finger_tree = @intFromPtr(emp); 
                    new_deep.Deep.right = deep.Deep.right; 
                    e.FingerTree.t = Element.DeepT; 
                    e.FingerTree.ptr = @intFromPtr(new_deep); 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                } else {
                    var new_left: *Element = undefined; 
                    var emp: *Element = undefined; 
                    remain = try allocOne(remain, use_first, &new_left); 
                    remain = try allocOne(remain, use_first, &emp); 
                    remain = try allocOne(remain, use_first, &new_deep); 
                    emp.* = EMPTY; 
                    @memcpy(new_left.Four[1..], right.Four[0..3]); 
                    new_left.Four[0] = f; 
                    new_deep.Deep.left = deep.Deep.left; 
                    new_deep.Deep.finger_tree = @intFromPtr(emp); 
                    new_deep.Deep.right = @intFromPtr(new_left); 
                    e.FingerTree.t = Element.DeepT; 
                    e.FingerTree.ptr = @intFromPtr(new_deep); 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                }
            } else {
                var inner1: *Element = undefined; 
                remain = try allocOne(remain, use_first, &inner1); 
                remain = try allocOne(remain, use_first, &new_deep); 
                inner1.* = inner0; 
                new_deep.Deep.left = deep.Deep.left; 
                new_deep.Deep.finger_tree = @intFromPtr(inner1); 
                new_deep.Deep.right = deep.Deep.right; 
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.size = origin.FingerTree.size - 1; 
                e.FingerTree.t = Element.DeepT; 
            }
        } else {
            const r = index - l_size - inner_size; 
            var right0: Element = undefined; 
            var fail: ?usize = undefined; 
            remain = try fourInnerPop(&right0, remain, use_first, right.*, r, depth, pop_rst, &fail); 
            if (fail) |f| {
                if (inner.FingerTree.t == Element.EmptyT) {
                    const llen = fourLength(left.*); 
                    if (f == 0) {
                        std.debug.assert(depth == 0); 
                        if (llen == 1) {
                            e.FingerTree.ptr = left.Four[0]; 
                            e.FingerTree.size = 1; 
                            e.FingerTree.t = Element.SingleT; 
                        } else {
                            var new_left: *Element = undefined; 
                            var new_right: *Element = undefined; 
                            var new_deep: *Element = undefined; 
                            remain = try allocOne(remain, use_first, &new_left); 
                            remain = try allocOne(remain, use_first, &new_right); 
                            remain = try allocOne(remain, use_first, &new_deep); 
                            @memcpy(new_left.Four[0..3], left.Four[1..4]);  
                            new_left.Four[3] = 0;  
                            new_right.Four[0] = left.Four[0]; 
                            new_right.Four[1] = 0;
                            new_deep.Deep.left = @intFromPtr(new_left); 
                            new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                            new_deep.Deep.left = @intFromPtr(new_right); 
                            e.FingerTree.t = Element.DeepT; 
                            e.FingerTree.ptr = @intFromPtr(new_deep); 
                            e.FingerTree.size = origin.FingerTree.size - 1; 
                        }
                    } else {
                        std.debug.assert(depth > 0); 
                        var new_left: *Element = undefined; 
                        var new_right: *Element = undefined; 
                        var new_deep: *Element = undefined; 
                        const l_first: *Element = @ptrFromInt(left.Four[0]); 
                        if (l_first.Three.content[2] == 0) {
                            var new_three: *Element = undefined; 
                            remain = try allocOne(remain, use_first, &new_three); 
                            if (llen == 1) {
                                @memcpy(new_three.Three.content[0..2], l_first.Three.content[0..2]); 
                                new_three.Three.content[2] = f; 
                                threeSizeUpdateDirectly(new_three, depth - 1);     
                                e.FingerTree.ptr = @intFromPtr(new_three); 
                                e.FingerTree.size = origin.FingerTree.size - 1; 
                                e.FingerTree.t = Element.SingleT; 
                            } else {
                                remain = try allocOne(remain, use_first, &new_left); 
                                remain = try allocOne(remain, use_first, &new_right); 
                                remain = try allocOne(remain, use_first, &new_deep); 
                                @memcpy(new_three.Three.content[0..2], l_first.Three.content[0..2]); 
                                new_three.Three.content[2] = f; 
                                threeSizeUpdateDirectly(new_three, depth - 1); 
                                new_right.Four[0] = @intFromPtr(new_three); 
                                new_left.Four[1] = 0; 
                                @memcpy(new_left.Four[0..llen - 1], left.Four[1..llen]); 
                                new_left.Four[llen-1] = 0; 
                                new_deep.Deep.left = @intFromPtr(new_left); 
                                new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                                new_deep.Deep.right = @intFromPtr(new_right); 
                                e.FingerTree.t = Element.DeepT; 
                                e.FingerTree.size = origin.FingerTree.size - 1; 
                                e.FingerTree.ptr = @intFromPtr(new_deep); 
                            }
                        } else {
                            var new_three0: *Element = undefined; 
                            var new_three1: *Element = undefined; 
                            remain = try allocOne(remain, use_first, &new_three0); 
                            remain = try allocOne(remain, use_first, &new_three1); 
                            remain = try allocOne(remain, use_first, &new_left); 
                            remain = try allocOne(remain, use_first, &new_right); 
                            remain = try allocOne(remain, use_first, &new_deep); 
                            new_three0.Three.content[0] = l_first.Three.content[0]; 
                            new_three0.Three.content[1] = l_first.Three.content[1]; 
                            new_three0.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(new_three0, depth); 
                            new_three1.Three.content[0] = l_first.Three.content[2]; 
                            new_three1.Three.content[1] = f; 
                            new_three1.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(new_three1, depth); 
                            new_right.Four[0] = @intFromPtr(new_three1); 
                            new_right.Four[1] = 0; 
                            new_left.Four[0] = @intFromPtr(new_three0); 
                            @memcpy(new_left.Four[1..4], right.Four[1..4]); 
                            new_deep.Deep.left = @intFromPtr(new_left); 
                            new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                            new_deep.Deep.right = @intFromPtr(new_right); 
                            e.FingerTree.ptr = @intFromPtr(new_deep); 
                            e.FingerTree.size = origin.FingerTree.size - 1; 
                            e.FingerTree.t = Element.DeepT; 
                        }
                    }
                    fail_check.* = null; 
                    return remain; 
                } 
                var new_inner_ft: *Element = undefined; 
                var new_right: *Element = undefined; 
                var new_deep: *Element = undefined; 
                var p: usize = undefined; 
                remain = try allocOne(remain, use_first, &new_inner_ft); 
                remain = try allocOne(remain, use_first, &new_right); 
                remain = try allocOne(remain, use_first, &new_deep); 
                remain = try pop(new_inner_ft, remain, use_first, inner.*, depth + 1, true, &p); 
                const this_three: *Element = @ptrFromInt(p); 
                if (f == 0) {
                    std.debug.assert(depth == 0); 
                    @memcpy(new_right.Four[0..3], this_three.Three.content[0..]); 
                    new_right.Four[3] = 0; 
                    new_deep.Deep.left = deep.Deep.left; 
                    new_deep.Deep.finger_tree = @intFromPtr(new_inner_ft); 
                    new_deep.Deep.right = @intFromPtr(new_right); 
                    e.FingerTree.ptr = @intFromPtr(new_deep);
                    e.FingerTree.t = Element.DeepT; 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                    fail_check.* = null; 
                    return remain; 
                }
                const three_len : usize = if (this_three.Three.content[2] == 0) 1 else 2; 
                const inner_three: *Element = @ptrFromInt(this_three.Three.content[three_len]); 
                if (inner_three.Three.content[2] == 0) {
                    var new_three0: *Element = undefined; 
                    remain = try allocOne(remain, use_first, &new_three0); 
                    @memcpy(new_three0.Three.content[0..2], inner_three.Three.content[0..2]);  
                    new_three0.Three.content[2] = f; 
                    threeSizeUpdateDirectly(new_three0, depth - 1); 
                    @memcpy(new_right.Four[0..three_len], this_three.Three.content[0..three_len]); 
                    new_right.Four[three_len] = @intFromPtr(new_three0); 
                    new_right.Four[three_len+1] = 0; 
                    new_deep.Deep.left = deep.Deep.left; 
                    new_deep.Deep.finger_tree = @intFromPtr(new_inner_ft); 
                    new_deep.Deep.right = @intFromPtr(new_right); 
                    e.FingerTree.t = Element.DeepT; 
                    e.FingerTree.ptr = @intFromPtr(new_deep); 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                } else {
                    var new_three0: *Element = undefined; 
                    var new_three1: *Element = undefined; 
                    remain = try allocOne(remain, use_first, &new_three0); 
                    remain = try allocOne(remain, use_first, &new_three1); 
                    new_three0.Three.content[0] = inner_three.Three.content[0]; 
                    new_three0.Three.content[1] = inner_three.Three.content[1]; 
                    new_three0.Three.content[2] = 0; 
                    threeSizeUpdateDirectly(new_three0, depth - 1); 
                    new_three1.Three.content[0] = inner_three.Three.content[2]; 
                    new_three1.Three.content[1] = f; 
                    new_three1.Three.content[2] = 0; 
                    threeSizeUpdateDirectly(new_three1, depth - 1); 
                    @memcpy(new_right.Four[0..three_len], this_three.Three.content[0..three_len]); 
                    new_right.Four[three_len] = @intFromPtr(new_three1); 
                    new_right.Four[three_len+1] = @intFromPtr(new_three0); 
                    if (three_len == 1) {
                        new_right.Four[3] = 0; 
                    }
                    new_deep.Deep.left = deep.Deep.left; 
                    new_deep.Deep.finger_tree = @intFromPtr(new_inner_ft); 
                    new_deep.Deep.right = @intFromPtr(new_right); 
                    e.FingerTree.t = Element.DeepT; 
                    e.FingerTree.ptr = @intFromPtr(new_deep); 
                    e.FingerTree.size = origin.FingerTree.size - 1; 
                }
            } else {
                var new_four: *Element = undefined; 
                var new_deep: *Element = undefined; 
                remain = try allocOne(remain, use_first, &new_four); 
                remain = try allocOne(remain, use_first, &new_deep); 
                new_four.* = right0; 
                new_deep.Deep.finger_tree = deep.Deep.finger_tree; 
                new_deep.Deep.left = deep.Deep.left; 
                new_deep.Deep.right = @intFromPtr(new_four); 
                e.FingerTree.t = Element.DeepT;
                e.FingerTree.ptr = @intFromPtr(new_deep); 
                e.FingerTree.size = origin.FingerTree.size - 1;  
            }
        }
    }
    fail_check.* = null; 
    return remain; 
}

pub fn threeInnerPop(e: *Element, buffer: []Element, use_first: bool, origin: Element, index: usize, depth: usize, pop_rst: *usize, fail_check: *?usize) ![]Element {
    std.debug.assert(index < origin.Three.size); 
    var remain = buffer; 
    if (depth == 0) {
        if (origin.Three.content[2] == 0) {
            if (index == 0) {
                pop_rst.* = origin.Three.content[0]; 
                fail_check.* = origin.Three.content[1]; 
                return remain; 
            } else if (index == 1) {
                pop_rst.* = origin.Three.content[1]; 
                fail_check.* = origin.Three.content[0]; 
                return remain; 
            }
        } else {
            pop_rst.* = origin.Three.content[index]; 
            @memcpy(e.Three.content[0..index], origin.Three.content[0..index]); 
            @memcpy(e.Three.content[index..2], origin.Three.content[index+1..]); 
            e.Three.content[2] = 0; 
            threeSizeUpdateDirectly(e, depth); 
        } 
    } else {
        var cum = index; 
        for (origin.Three.content, 0..) |c, the_idx| {
            if (c == 0) {
                unreachable; 
            }
            const p: *Element = @ptrFromInt(c); 
            if (cum >= p.Three.size) {
                cum -= p.Three.size; 
            } else {
                var buf: Element = undefined; 
                var fail: ?usize = undefined; 
                remain = try threeInnerPop(&buf, remain, use_first, p.*, cum, depth - 1, pop_rst, &fail); 
                if (fail) |f| {
                    std.debug.assert(f != 0); 
                    var new_three0: *Element = undefined; 
                    var new_three1: *Element = undefined; 
                    if (the_idx == 0) {
                        const nxt_three: *Element = @ptrFromInt(origin.Three.content[1]); 
                        remain = try allocOne(remain, use_first, &new_three0); 
                        if (nxt_three.Three.content[2] == 0) {
                            new_three0.Three.content[0] = f; 
                            new_three0.Three.content[1] = nxt_three.Three.content[0]; 
                            new_three0.Three.content[2] = nxt_three.Three.content[1]; 
                            threeSizeUpdateDirectly(new_three0, depth - 1); 
                            if (origin.Three.content[2] == 0) {
                                fail_check.* = @intFromPtr(new_three0); 
                                return remain; 
                            }
                            e.Three.content[0] = @intFromPtr(new_three0); 
                            e.Three.content[1] = origin.Three.content[2]; 
                            e.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(e, depth); 
                        } else {
                            remain = try allocOne(remain, use_first, &new_three1); 
                            new_three0.Three.content[0] = f; 
                            new_three0.Three.content[1] = nxt_three.Three.content[0]; 
                            new_three0.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(new_three0, depth - 1); 
                            new_three1.Three.content[0] = nxt_three.Three.content[1]; 
                            new_three1.Three.content[1] = nxt_three.Three.content[2]; 
                            new_three1.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(new_three1, depth - 1); 
                            e.Three.content[0] = @intFromPtr(new_three0); 
                            e.Three.content[1] = @intFromPtr(new_three1); 
                            e.Three.content[2] = origin.Three.content[2]; 
                            threeSizeUpdateDirectly(e, depth); 
                        }
                    } else {
                        const prev_three: *Element = @ptrFromInt(origin.Three.content[the_idx - 1]); 
                        remain = try allocOne(remain, use_first, &new_three0); 
                        if (prev_three.Three.content[2] == 0) {
                            new_three0.Three.content[0] = prev_three.Three.content[0]; 
                            new_three0.Three.content[1] = prev_three.Three.content[1]; 
                            new_three0.Three.content[2] = f; 
                            threeSizeUpdateDirectly(new_three0, depth - 1); 
                            if (origin.Three.content[2] == 0) {
                                fail_check.* = @intFromPtr(new_three0); 
                                return remain; 
                            }
                            @memcpy(e.Three.content[0..the_idx-1], origin.Three.content[0..the_idx-1]); 
                            e.Three.content[the_idx-1] = @intFromPtr(new_three0); 
                            @memcpy(e.Three.content[the_idx..2], origin.Three.content[the_idx+1..]); 
                            e.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(e, depth); 
                        } else {
                            remain = try allocOne(remain, use_first, &new_three1); 
                            new_three0.Three.content[0] = prev_three.Three.content[0]; 
                            new_three0.Three.content[1] = prev_three.Three.content[1]; 
                            new_three0.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(new_three0, depth - 1); 
                            new_three1.Three.content[0] = prev_three.Three.content[2]; 
                            new_three1.Three.content[1] = f; 
                            new_three1.Three.content[2] = 0; 
                            threeSizeUpdateDirectly(new_three1, depth - 1); 
                            if (the_idx == 1) {
                                e.Three.content[0] = @intFromPtr(new_three0); 
                                e.Three.content[1] = @intFromPtr(new_three1); 
                                e.Three.content[2] = origin.Three.content[2]; 
                            } else if (the_idx == 2) {
                                e.Three.content[0] = origin.Three.content[0]; 
                                e.Three.content[1] = @intFromPtr(new_three0); 
                                e.Three.content[2] = @intFromPtr(new_three1); 
                            } else {
                                unreachable; 
                            }
                            threeSizeUpdateDirectly(e, depth); 
                        }
                    }
                } else {
                    var new_three: *Element = undefined; 
                    remain = try allocOne(remain, use_first, &new_three); 
                    new_three.* = buf; 
                    e.* = origin; 
                    e.Three.content[the_idx] = @intFromPtr(new_three); 
                    threeSizeUpdateDirectly(e, depth); 
                }
                break; 
            }
        } 
    } 
    fail_check.* = null; 
    return remain; 
}

pub fn fourInnerPop(e: *Element, buffer: []Element, use_first: bool, origin: Element, index: usize, depth: usize, pop_rst: *usize, fail_check: *?usize) ![]Element {
    var remain = buffer; 
    if (depth == 0) {
        if (origin.Four[1] == 0) {
            std.debug.assert(index == 0); 
            pop_rst.* = origin.Four[0]; 
            fail_check.* = 0; 
        } else {
            const flen = fourLength(origin); 
            @memcpy(e.Four[0..index], origin.Four[0..index]); 
            @memcpy(e.Four[index..flen-1], origin.Four[index+1..flen]); 
            e.Four[flen] = 0; 
            pop_rst.* = origin.Four[index]; 
            fail_check.* = null; 
        }
        return remain; 
    } 
    var cum : usize = index; 
    var idx0: ?usize = null; 
    for (origin.Four, 0..) |f, t| {
        if (f == 0) break; 
        const c = maybeThreeGetSize(f, depth); 
        if (cum >= c) {
            cum -= c; 
        } else {
            idx0 = t; 
            break; 
        }
    }
    const idx = idx0.?; 
    var new_three: Element = undefined; 
    const origin_three: *Element = @ptrFromInt(origin.Four[idx]); 
    var fail: ?usize = undefined; 
    remain = try threeInnerPop(&new_three, remain, use_first, origin_three.*, cum, depth - 1, pop_rst, &fail); 
    if (fail == null) {
        var new_three0: *Element = undefined; 
        remain = try allocOne(remain, use_first, &new_three0); 
        new_three0.* = new_three; 
        @memcpy(e.Four, origin.Four); 
        e.Four[idx] = @intFromPtr(new_three0); 
        fail_check.* = null; 
        return remain; 
    }
    const f = fail.?; 
    if (origin.Four[1] == 0) {
        fail_check.* = f; 
        return remain; 
    } 
    var new_three0: *Element = undefined; 
    remain = try allocOne(remain, use_first, &new_three0); 
    if (idx == 3 or (origin.Four[idx+1] == 0)) {
        const lthree: *Element = @ptrFromInt(origin.Four[idx-1]); 
        var buf: ?*Element = undefined; 
        // ?????? incorrectly push method 
        remain = try threeInnerPush(new_three0, &buf, remain, use_first, lthree.*, 0, f, depth - 1); 
        @memcpy(e.Four[0..idx-1], origin.Four[0..idx-1]); 
        if (buf) |b| {
            e.Four[idx-1] = @intFromPtr(new_three0);
            e.Four[idx] = @intFromPtr(b); 
            @memcpy(e.Four[idx+1..], origin.Four[idx+1..]); 
        } else {
            e.Four[idx-1] = @intFromPtr(new_three0); 
            @memcpy(e.Four[idx..3], origin.Four[idx+1..]); 
            e.Four[3] = 0; 
        }
    } else {
        // push left with (idx+1)
        const rthree: *Element = @ptrFromInt(origin.Four[idx+1]); 
        var buf: ?*Element = undefined; 
        remain = try threeInnerPush(new_three0, &buf, remain, use_first, rthree.*, 0, f, depth - 1); 
        @memcpy(e.Four[0..idx], origin.Four[0..idx]); 
        if (buf) |b| {
            e.Four[idx] = @intFromPtr(new_three0);
            e.Four[idx+1] = @intFromPtr(b); 
            @memcpy(e.Four[idx+2..], origin.Four[idx+2..]); 
        } else {
            e.Four[idx] = @intFromPtr(new_three0); 
            @memcpy(e.Four[idx+1..3], origin.Four[idx+2..]); 
            e.Four[3] = 0; 
        }
    } 
    fail_check.* = null; 
    return remain; 
}
