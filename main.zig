const std = @import("std");

pub fn main(init: std.process.Init) !void {
    std.debug.print("hello world", .{});
}
