const std = @import("std"); 

const lib = @import("root.zig"); 

const Element = lib.Element; 

const push = lib.push;
const push2 = lib.push2; 
const push3 = lib.push3; 

const threeSizeUpdateDirectly = lib.threeSizeUpdateDirectly; 

const allocOne = lib.allocOne; 

const fourLength = lib.fourLength; 

const size_calc = @import("size_calc.zig"); 
const deepGetSize = size_calc.deepGetSize; 

pub fn merge(e: *Element, buffer: []Element, use_first: bool, left: Element, right: Element, depth: usize) ![]Element {
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
    const lrfourlen = fourLength(lrfour.*); 
    const rlfourlen = fourLength(rlfour.*); 
    const len = lrfourlen + rlfourlen; 
    var remain = buffer; 
    var base: [9]usize = undefined; 
    std.debug.assert(len >= 2 and len <= 8); 
    @memcpy(base[0..lrfourlen], lrfour.Four[0..lrfourlen]); 
    @memcpy(base[lrfourlen..][0..rlfourlen], rlfour.Four[0..rlfourlen]); 
    base[len] = 0;
    const left_deep_fingertree: *Element = @ptrFromInt(ldeep.Deep.finger_tree); 
    const right_deep_fingertree : *Element = @ptrFromInt(rdeep.Deep.finger_tree); 
    var new: [3]*Element = undefined; 
    switch (len) {
        2, 3 => {
            remain = try allocOne(remain, use_first, &new[0]); 
            @memcpy(new[0].Three.content[0..3], base[0..3]); 
            threeSizeUpdateDirectly(new[0], depth); 
            var left2: *Element = undefined; 
            var new_deep_fingertree: *Element = undefined; 
            var new_deep: *Element = undefined; 
            remain = try allocOne(remain, use_first, &left2); 
            remain = try allocOne(remain, use_first, &new_deep_fingertree); 
            remain = try allocOne(remain, use_first, &new_deep); 
            remain = try push(left2, remain, use_first, left_deep_fingertree.*, @intFromPtr(new[0]), depth + 1, true); 
            remain = try merge(new_deep_fingertree, remain, use_first, left2.*, right_deep_fingertree.*, depth + 1); 
            new_deep.Deep.finger_tree = @intFromPtr(new_deep_fingertree); 
            new_deep.Deep.left = ldeep.Deep.left; 
            new_deep.Deep.right = rdeep.Deep.right; 
            e.FingerTree.size = deepGetSize(new_deep.*, depth); 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.t = Element.DeepT; 
        }, 
        4, 5, 6 => {
            remain = try allocOne(remain, use_first, &new[0]); 
            remain = try allocOne(remain, use_first, &new[1]); 
            const first_len: usize = if (len == 4) 2 else 3; 
            new[0].Three.content[2] = 0; 
            @memcpy(new[0].Three.content[0..first_len], base[0..first_len]); 
            @memcpy(new[1].Three.content[0..3], base[first_len..][0..3]); 
            threeSizeUpdateDirectly(new[0], depth); 
            threeSizeUpdateDirectly(new[1], depth); 
            var left_deep_finger: *Element = undefined; 
            var new_deep_fingertree: *Element = undefined; 
            var new_deep: *Element = undefined; 
            remain = try allocOne(remain, use_first, &left_deep_finger); 
            remain = try allocOne(remain, use_first, &new_deep_fingertree); 
            remain = try allocOne(remain, use_first, &new_deep); 
            remain = try push2(left_deep_finger, remain, use_first, left_deep_fingertree.*, @intFromPtr(new[0]), @intFromPtr(new[1]), depth + 1, true); 
            remain = try merge(new_deep_fingertree, remain, use_first, left_deep_finger.*, right_deep_fingertree.*, depth + 1); 
            new_deep.Deep.finger_tree = @intFromPtr(new_deep); 
            new_deep.Deep.left = ldeep.Deep.left; 
            new_deep.Deep.right = rdeep.Deep.right; 
            e.FingerTree.size = left.FingerTree.size + right.FingerTree.size; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.t = Element.DeepT; 
        }, 
        7, 8 => {
            remain = try allocOne(remain, use_first, &new[0]); 
            remain = try allocOne(remain, use_first, &new[1]); 
            remain = try allocOne(remain, use_first, &new[2]); 
            @memcpy(new[0].Three.content[0..2], base[0..2]); 
            new[0].Three.content[2] = 0; 
            @memcpy(new[1].Three.content[0..3], base[2..][0..3]); 
            @memcpy(new[2].Three.content[0..3], base[5..][0..3]); 
            threeSizeUpdateDirectly(new[0], depth); 
            threeSizeUpdateDirectly(new[1], depth); 
            threeSizeUpdateDirectly(new[2], depth); 
            var left_deep_finger: *Element = undefined; 
            var new_deep: *Element = undefined; 
            remain = try allocOne(remain, use_first, &left_deep_finger); 
            remain = try allocOne(remain, use_first, &new_deep); 
            remain = try push3(left_deep_finger, remain, use_first, left_deep_fingertree.*, @intFromPtr(new[0]), 
                @intFromPtr(new[1]), @intFromPtr(new[2]), depth + 1, true); 
            new_deep.Deep.finger_tree = @intFromPtr(left_deep_finger); 
            new_deep.Deep.left = ldeep.Deep.left; 
            new_deep.Deep.right = rdeep.Deep.right; 
            e.FingerTree.size = left.FingerTree.size + right.FingerTree.size; 
            e.FingerTree.ptr = @intFromPtr(new_deep); 
            e.FingerTree.t = Element.DeepT; 
        }, 
        else => unreachable, 
    }
    return remain; 
}