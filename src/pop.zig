const std = @import("std");
const testing = std.testing;

const lib = @import("root.zig"); 

const Element = lib.Element; 
const EMPTY = lib.EMPTY; 
const fourLength = lib.fourLength; 
const initSingle = lib.initSingle; 

const allocOne = lib.allocOne; 

const deepGetSize = lib.deepGetSize; 

const maybeThreeGetSize = lib.maybeThreeGetSize; 

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
