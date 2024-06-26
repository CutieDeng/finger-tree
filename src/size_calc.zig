const std = @import("std"); 

const lib = @import("root.zig");

const Element = lib.Element;

pub fn maybeThreeGetSize(three: usize, depth: usize) usize {
    if (depth == 0) {
        return 1; 
    }
    // check the aligned (actually for debug the value here... )
    const three_ptr: *Element = @ptrFromInt(three); 
    return three_ptr.Three.size;
}

pub fn fourLength(four: Element) usize {
    return anyLengthSentinel(&four.Four);  
}

pub fn fourSize(four: Element, depth: usize) usize {
    var f_size: usize = 0; 
    for (four.Four) |f| {
        if (f == 0) break; 
        f_size += maybeThreeGetSize(f, depth); 
    }
    return f_size; 
}

pub fn anyLengthSentinel(any: []const usize) usize {
    var any_length: usize = 0; 
    for (any) |an| {
        if (an == 0) break; 
        any_length += 1; 
    }
    return any_length; 
}

pub fn threeSizeUpdateDirectly(e: *Element, depth: usize) void {
    var size : usize = 0; 
    for (e.Three.content) |c| {
        if (c == 0) break; 
        size += maybeThreeGetSize(c, depth); 
    }
    e.Three.size = size; 
}

pub fn deepGetSize(deep: Element, depth: usize) usize {
    const left: *Element = @ptrFromInt(deep.Deep.left); 
    const right: *Element = @ptrFromInt(deep.Deep.right); 
    const inner: *Element = @ptrFromInt(deep.Deep.finger_tree); 
    var s: usize = inner.FingerTree.size; 
    for (left.Four) |f| {
        if (f == 0) break; 
        s += maybeThreeGetSize(f, depth); 
    }
    for (right.Four) |f| {
        if (f == 0) break; 
        s += maybeThreeGetSize(f, depth); 
    }
    return s; 
}
