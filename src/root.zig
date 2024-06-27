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

const modifylib = @import("modify.zig"); 
pub const modify = modifylib.modify; 

pub const debug = @import("debug.zig"); 

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

const splitlib = @import("split.zig"); 
pub const split = splitlib.split; 