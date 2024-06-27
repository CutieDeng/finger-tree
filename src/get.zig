const std = @import("std");

const lib = @import("root.zig");

const Element = lib.Element;

const maybeThreeGetSize = lib.maybeThreeGetSize;

const fourLength = lib.fourLength;

pub fn get(e: Element, idx: usize, depth: usize) usize {
    std.debug.assert(idx < e.FingerTree.size);
    std.debug.assert(e.FingerTree.t != Element.EmptyT);
    if (e.FingerTree.t == Element.SingleT) {
        if (depth == 0) {
            return e.FingerTree.ptr;
        } else {
            const three: *Element = @ptrFromInt(e.FingerTree.ptr);
            return threeGet(three.*, idx, depth - 1);
        }
    }
    if (e.FingerTree.t == Element.DeepT) {
        const d: *Element = @ptrFromInt(e.FingerTree.ptr);
        const l: *Element = @ptrFromInt(d.Deep.left);
        var rem = idx;
        var idx0: ?usize = null;
        const llen = fourLength(l.*);
        var four: Element = l.*;
        std.mem.reverse(usize, four.Four[0..llen]);
        for (four.Four, 0..) |lf, i| {
            if (lf == 0) break;
            const lfc = maybeThreeGetSize(lf, depth);
            if (rem >= lfc) {
                rem -= lfc;
            } else {
                idx0 = i;
                break; 
            }
        }
        if (idx0) |idx1| {
            if (depth == 0) {
                return four.Four[idx1];
            } else {
                const th: *Element = @ptrFromInt(four.Four[idx1]);
                return threeGet(th.*, rem, depth - 1);
            }
        }
        const inner: *Element = @ptrFromInt(d.Deep.finger_tree);
        if (rem < inner.FingerTree.size) {
            return get(inner.*, rem, depth + 1);
        }
        rem -= inner.FingerTree.size;
        const r: *Element = @ptrFromInt(d.Deep.right);
        var idx2: ?usize = null;
        for (r.Four, 0..) |rf, i| {
            if (rf == 0) break;
            const rfc = maybeThreeGetSize(rf, depth);
            if (rem >= rfc) {
                rem -= rfc;
            } else {
                idx2 = i;
                break; 
            }
        }
        const idx3 = idx2.?;
        if (depth == 0) {
            return r.Four[idx3];
        } else {
            const th: *Element = @ptrFromInt(r.Four[idx3]);
            return threeGet(th.*, rem, depth - 1);
        }
    }
    unreachable;
}

pub fn fourGet(e: Element, idx: usize, depth: usize) usize {
    var idx0: ?usize = null; 
    if (depth == 0) {
        return e.Four[idx]; 
    }
    var cum = idx; 
    for (e.Four, 0..) |ef, i| {
        if (ef == 0) break; 
        const efc = maybeThreeGetSize(ef, depth); 
        if (cum >= efc) {
            cum -= efc; 
        } else {
            idx0 = i; 
            break; 
        }
    }
    const idx1 = idx0.?; 
    const p: *Element = @ptrFromInt(e.Four[idx1]); 
    return threeGet(p.*, cum, depth - 1); 
}

pub fn threeGet(e: Element, idx: usize, depth: usize) usize {
    var rem = idx;
    var idx0: ?usize = null;
    if (depth == 0) {
        return e.Three.content[idx];
    }
    for (e.Three.content, 0..) |c, i| {
        if (c == 0) break;
        const cs = maybeThreeGetSize(c, depth);
        if (rem >= cs) {
            rem -= cs;
        } else {
            idx0 = i;
            break; 
        }
    }
    const idx1 = idx0.?;
    const next_three: *Element = @ptrFromInt(e.Three.content[idx1]);
    return threeGet(next_three.*, rem, depth - 1);
}
