const std = @import("std"); 

const lib = @import("root.zig"); 

const Element = lib.Element; 

const maybeThreeGetSize = lib.maybeThreeGetSize; 

pub fn threeCheck(e: Element, depth: usize) void {
    var cum: usize = 0; 
    for (e.Three.content) |f| {
        if (f == 0) break; 
        cum += maybeThreeGetSize(f, depth); 
    }
    if (cum == e.Three.size) {
        std.log.debug("check depth {} node", .{ depth }); 
    } else {
        std.log.warn("check depth {} node, but ft.size = {}; but actaul size = {}", .{ depth, e.Three.size, cum }); 
    }
}

pub fn check(e: Element, depth: usize) void {
    if (e.FingerTree.t == Element.EmptyT) {
        if (e.FingerTree.size != 0) {
            std.log.warn("check depth {} tree, empty but size = {}", .{ depth, e.FingerTree.size });
        } else {
            std.log.debug("check depth {} tree: empty", .{ depth }); 
        }
        return ; 
    }
    if (e.FingerTree.t == Element.SingleT) {
        const s = maybeThreeGetSize(e.FingerTree.ptr, depth); 
        if (s == e.FingerTree.size) {
            std.log.debug("check depth {} tree: single", .{ depth }); 
        } else {
            std.log.warn("check depth {} tree: single, expect size (from node) {}, but get {} in ft self", .{ depth, s, e.FingerTree.size }); 
        }
        if (depth != 0) {
            const p : *Element = @ptrFromInt(e.FingerTree.ptr); 
            threeCheck(p.*, depth - 1); 
        }
        return ; 
    }
    std.debug.assert(e.FingerTree.t == Element.DeepT); 
    const d: *Element = @ptrFromInt(e.FingerTree.ptr); 
    const inner: *Element = @ptrFromInt(d.Deep.finger_tree); 
    if (depth != 0) {
        std.log.debug("check depth {} tree: deep start", .{ depth }); 
        defer std.log.debug("check depth {} tree: deep end", .{ depth }); 
        const l: *Element = @ptrFromInt(d.Deep.left); 
        const r: *Element = @ptrFromInt(d.Deep.right); 
        for (l.Four) |f| {
            if (f == 0) break; 
            const the_three: *Element = @ptrFromInt(f); 
            threeCheck(the_three.*, depth - 1); 
        } 
        check(inner.*, depth + 1); 
        for (r.Four) |f| {
            if (f == 0) break; 
            const the_three: *Element = @ptrFromInt(f); 
            threeCheck(the_three.*, depth - 1); 
        } 
    } else {
        check(inner.*, depth + 1);     
    }
}