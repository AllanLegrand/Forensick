const std = @import("std");

pub const print_stat = @import("stat.zig").print_stat;
pub const Colors = @import("colors.zig").Colors;

pub fn print_help(stdout: *std.io.Writer, filename: []const u8) void {
	_ = stdout;
	_ = filename;
	return;
}

