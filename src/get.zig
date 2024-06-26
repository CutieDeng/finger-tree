const std = @import("std"); 

const lib = @import("root.zig"); 

const Element = lib.Element; 

const maybeThreeGetSize = lib.maybeThreeGetSize; 

const fourLength = lib.fourLength; 

pub fn get(e: Element, idx: usize, depth: usize) usize {
    std.debug.assert(e.FingerTree.t != Element.EmptyT); 
    if (e.FingerTree.t == Element.SingleT) {
        const three: *Element = @ptrFromInt(e.FingerTree.ptr); 
        if (depth == 0) {
            if (idx == 0) {
                return e.FingerTree.ptr; 
            } else {
                unreachable; 
            }
        } else {
            return threeGet(three.*, idx, depth); 
        }
    }
    if (e.FingerTree.t == Element.DeepT) {
        const d : *Element = @ptrFromInt(e.FingerTree.ptr); 
        const l : *Element = @ptrFromInt(d.Deep.left); 
        var rem = idx; 
        for (l.Four) |lf| {
            if (lf == 0) break; 
            const lfc = maybeThreeGetSize(lf, depth); 
            if (rem >= lfc) {
                rem -= lfc; 
            } else {
                if (depth == 0) {
                    return lf; 
                } else {
                    const th: *Element = @ptrFromInt(lf); 
                    return threeGet(th.*, rem, depth - 1); 
                }
            }
        }
        const inner: *Element = @ptrFromInt(d.Deep.finger_tree); 
        if (rem < inner.FingerTree.size) {
            return get(inner.*, rem, depth + 1); 
        }
        rem -= inner.FingerTree.size; 
        const r : *Element = @ptrFromInt(d.Deep.right); 
        for (r.Four) |rf| {
            const rfc = maybeThreeGetSize(rf, depth); 
            if (rem >= rfc) {
                rem -= rfc; 
            } else {
                if (depth == 0) {
                    return rf; 
                } else {
                    const th: *Element = @ptrFromInt(rf); 
                    return threeGet(th.*, rem, depth - 1); 
                }
            }
        }
    }
    unreachable; 
}

pub fn threeGet(e: Element, idx: usize, depth: usize) usize {
    var rem = idx; 
    for (e.Three.content) |c| {
        if (c == 0) {
            break; 
        }
        const cs = maybeThreeGetSize(c, depth); 
        if (rem >= cs) {
            rem -= cs; 
        } else {
            if (depth == 0) {
                std.debug.assert(rem == 0); 
                return c; 
            }
            const next_three: *Element = @ptrFromInt(c); 
            return threeGet(next_three.*, rem, depth - 1); 
        }
    }
    unreachable; 
}
