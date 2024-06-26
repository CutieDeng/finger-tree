const std = @import("std");

const lib = @import("root.zig");

const Element = lib.Element;
const allocOne = lib.allocOne;

const fourSize = lib.fourSize;
const fourLength = lib.fourLength;
const maybeThreeGetSize = lib.maybeThreeGetSize;

pub fn modify(e: *Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    std.log.debug("modify idx({}) in ft({})", .{ idx, origin.FingerTree.size });
    std.debug.assert(idx < origin.FingerTree.size);
    var remain = buffer;
    if (origin.FingerTree.t == Element.SingleT) {
        if (depth == 0) {
            e.FingerTree.size = 1;
            e.FingerTree.ptr = value;
            e.FingerTree.t = Element.SingleT;
        } else {
            var new: *Element = undefined;
            const three: *Element = @ptrFromInt(origin.FingerTree.ptr);
            remain = try allocOne(remain, use_first, &new);
            remain = try threeModify(new, remain, use_first, three.*, idx, value, depth - 1);
            e.FingerTree.size = origin.FingerTree.size;
            e.FingerTree.ptr = @intFromPtr(new);
            e.FingerTree.t = Element.SingleT;
        }
        return remain;
    }
    std.debug.assert(origin.FingerTree.t == Element.DeepT);
    const deep: *Element = @ptrFromInt(origin.FingerTree.ptr);
    const left: *Element = @ptrFromInt(deep.Deep.left);
    const right: *Element = @ptrFromInt(deep.Deep.right);
    const left_size = fourSize(left.*, depth);
    const innerft: *Element = @ptrFromInt(deep.Deep.finger_tree);
    const inner_size = innerft.FingerTree.size;
    var new_deep: *Element = undefined;
    remain = try allocOne(remain, use_first, &new_deep);
    if (idx < left_size) {
        std.log.debug("left modify idx({}) in lfour ({})", .{ idx, left_size });
        var new_four: *Element = undefined;
        remain = try allocOne(remain, use_first, &new_four);
        var fourr: Element = left.*;
        const fourr_len = fourLength(fourr);
        std.mem.reverse(usize, fourr.Four[0..fourr_len]);
        remain = try fourModify(new_four, remain, use_first, fourr, idx, value, depth);
        std.mem.reverse(usize, new_four.Four[0..fourr_len]);
        new_deep.Deep.left = @intFromPtr(new_four);
        new_deep.Deep.finger_tree = deep.Deep.finger_tree;
        new_deep.Deep.right = deep.Deep.right;
        e.FingerTree.size = origin.FingerTree.size;
        e.FingerTree.ptr = @intFromPtr(new_deep);
        e.FingerTree.t = Element.DeepT;
        return remain;
    }
    if (idx < left_size + inner_size) {
        const r = idx - left_size;
        var new_ft: *Element = undefined;
        remain = try allocOne(remain, use_first, &new_ft);
        remain = try modify(new_ft, remain, use_first, innerft.*, r, value, depth + 1);
        new_deep.Deep.left = deep.Deep.left;
        new_deep.Deep.right = deep.Deep.right;
        new_deep.Deep.finger_tree = @intFromPtr(new_ft);
        e.FingerTree.size = origin.FingerTree.size;
        e.FingerTree.ptr = @intFromPtr(new_deep);
        e.FingerTree.t = Element.DeepT;
        return remain;
    }
    const r = idx - left_size - inner_size;
    std.log.debug("right modify idx({}) in rfour ({})", .{ r, fourSize(right.*, depth) });
    var new_four: *Element = undefined;
    remain = try allocOne(remain, use_first, &new_four);
    remain = try fourModify(new_four, remain, use_first, right.*, r, value, depth);
    new_deep.Deep.left = deep.Deep.left;
    new_deep.Deep.finger_tree = deep.Deep.finger_tree;
    new_deep.Deep.right = @intFromPtr(new_four);
    e.FingerTree.size = origin.FingerTree.size;
    e.FingerTree.ptr = @intFromPtr(new_deep);
    e.FingerTree.t = Element.DeepT;
    return remain;
}

pub fn threeModify(e: *Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    std.log.debug("three modify ({}) in ({})", .{ idx, origin.Three.size });
    std.debug.assert(idx < origin.Three.size);
    if (depth == 0) {
        e.Three = origin.Three;
        e.Three.content[idx] = value;
        std.log.debug("change {any} -> {any} (actually)", .{ origin.Three.content, e.Three.content });
        return buffer;
    }
    var remain = buffer;
    var cum = idx;
    var idx0: ?usize = null;
    for (origin.Three.content, 0..) |c, modi_idx| {
        if (c == 0) break;
        const s = maybeThreeGetSize(c, depth);
        if (cum >= s) {
            cum -= s;
        } else {
            idx0 = modi_idx;
            break;
        }
    }
    const p: *Element = @ptrFromInt(origin.Three.content[idx0.?]);
    var new_three: *Element = undefined;
    remain = try allocOne(remain, use_first, &new_three);
    remain = try threeModify(new_three, remain, use_first, p.*, cum, value, depth - 1);
    e.* = origin;
    e.Three.content[idx0.?] = @intFromPtr(new_three);
    return remain;
}

pub fn fourModify(e: *Element, buffer: []Element, use_first: bool, origin: Element, idx: usize, value: usize, depth: usize) ![]Element {
    std.debug.assert(idx < fourSize(origin, depth));
    if (depth == 0) {
        e.Four = origin.Four;
        e.Four[idx] = value;
        return buffer;
    }
    var cumul = idx;
    var idx0: ?usize = null;
    for (origin.Four, 0..) |f, i| {
        if (f == 0) break;
        const lc = maybeThreeGetSize(f, depth);
        if (cumul >= lc) {
            std.log.debug("four modify, skip node {x}({})", .{ f, lc });
            cumul -= lc;
        } else {
            idx0 = i;
        }
    }
    const v = idx0.?;
    var remain = buffer;
    var new_three: *Element = undefined;
    const now_three: *Element = @ptrFromInt(origin.Four[v]);
    remain = try allocOne(remain, use_first, &new_three);
    remain = try threeModify(new_three, remain, use_first, now_three.*, cumul, value, depth - 1);
    e.Four = origin.Four;
    e.Four[v] = @intFromPtr(new_three);
    return remain;
}
