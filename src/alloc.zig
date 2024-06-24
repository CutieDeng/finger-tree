const lib = @import("root.zig"); 
const Element = lib.Element; 

pub fn allocOne(buffer: []Element, use_first: bool, rst: **Element) lib.Error![]Element {
    if (buffer.len < 1) {
        return error.BufferNotEnough; 
    }
    var remain = buffer; 
    if (use_first) {
        rst.* = &remain[0]; 
        remain = remain[1..];  
    } else {
        rst.* = &remain[remain.len - 1]; 
        remain.len -= 1; 
    }
    return remain; 
}
