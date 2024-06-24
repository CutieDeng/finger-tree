const lib = @import("root.zig"); 

const Element = lib.Element; 

pub const EMPTY: Element = .{ .FingerTree = .{ .t = Element.EmptyT, .ptr = 0, .size = 0 } }; 

const maybeThreeGetSize= lib.maybeThreeGetSize; 

pub fn initSingle(e: *Element, value: usize, depth: usize) void {
    e.* = Element {
        .FingerTree = .{ 
            .t = Element.SingleT, 
            .ptr = value, 
            .size = maybeThreeGetSize(value, depth), 
        }
    }; 
}

