const std = @import("std");
const Colors = @import("colors.zig").Colors;

const bufPrint = std.fmt.bufPrint;

const months = [_][]const u8{ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };

fn strftime(ts_ns: i128) ![25]u8 {
	const seconds = @divTrunc(ts_ns, 1_000_000_000);

	var days = @divTrunc(seconds, 86400);
	const seconds_in_day = @mod(seconds, 86400);

	days += 719468;

	const era = @divTrunc(days, 146097);
	const doe = days - era * 146097;
	const yoe = @divTrunc((doe - @divTrunc(doe, 1460) + @divTrunc(doe, 36524) - @divTrunc(doe, 146096)), 365);
	var year: usize = @intCast(yoe + era * 400);
	const doy = doe - (365 * yoe + @divTrunc(yoe, 4) - @divTrunc(yoe, 100));
	const mp = @divTrunc(5 * doy + 2, 153);
	const day: usize = @intCast(doy - @divTrunc(153 * mp + 2, 5) + 1);
	const month: usize = @intCast(if (mp < 10) mp + 3 else mp - 9);
	year += @intFromBool(month <= 2);

	const hour: usize = @intCast(@divTrunc(seconds_in_day, 3600));
	const minute: usize = @intCast(@divTrunc(@mod(seconds_in_day, 3600), 60));
	const second: usize = @intCast(@mod(seconds_in_day, 60));

	var b: [25]u8 = undefined;
	const slice = try bufPrint(&b, "{s} {d: >2} {d: >2}:{d: >2}:{d: >2} {d: >4}", .{
		months[month - 1], day, hour, minute, second, year,
	});

	if (slice.len > b.len) unreachable;

	return b;
}

fn fmt_perm(perm: u16, kind: std.fs.File.Kind) ![120]u8 {
	const perm_str_size = comptime Colors.RESET.len * 10 + Colors.GREEN.len * 3 + Colors.YELLOW.len * 3 + Colors.RED.len * 3 + Colors.BLUE.len + 10;

	var perm_str: [perm_str_size]u8 = undefined;

	const perms = [_]struct { mask: u16, ch: u8, color: []const u8 }{
		.{ .mask = 0o400, .ch = 'r', .color = Colors.GREEN },
		.{ .mask = 0o200, .ch = 'w', .color = Colors.YELLOW },
		.{ .mask = 0o100, .ch = 'x', .color = Colors.RED },
		.{ .mask = 0o040, .ch = 'r', .color = Colors.GREEN },
		.{ .mask = 0o020, .ch = 'w', .color = Colors.YELLOW },
		.{ .mask = 0o010, .ch = 'x', .color = Colors.RED },
		.{ .mask = 0o004, .ch = 'r', .color = Colors.GREEN },
		.{ .mask = 0o002, .ch = 'w', .color = Colors.YELLOW },
		.{ .mask = 0o001, .ch = 'x', .color = Colors.RED },
	};

	var pos: usize = 0;

	const kind_char: u8 = switch (kind) {
		.directory => 'd',
		.sym_link => 'l',
		.block_device => 'b',
		.character_device => 'c',
		.named_pipe => 'p',
		.unix_domain_socket => 's',
		else => '-',
	};
	pos += (try bufPrint(perm_str[pos..], "{s}{c}{s}", .{ Colors.BLUE, kind_char, Colors.RESET })).len;

	for (perms) |p| {
		const c: u8 = if (perm & p.mask != 0) p.ch else '-';
		pos += (try bufPrint(perm_str[pos..], "{s}{c}{s}", .{ p.color, c, Colors.RESET })).len;
	}

	return perm_str;
}

pub fn print_stat(stat: std.fs.File.Stat, stdout: *std.Io.Writer) !void {
	const ctime_str = try strftime(stat.ctime);
	const mtime_str = try strftime(stat.mtime);
	const atime_str = try strftime(stat.atime);

	const perm = stat.mode & 0o777;
	const perm_str: [120]u8 = try fmt_perm(perm, stat.kind);

	try stdout.print(
					\\{s}Size:{s} {s}{B}{s}
					\\{s}Inode:{s} {s}{d}{s}
					\\{s}Mode:{s} {s} {s}{o}{s}
					\\{s}Kind:{s} {s}{s}{s}
					\\
					, .{
						Colors.GREEN_BOLD, Colors.RESET, Colors.GREEN, stat.size, Colors.RESET,
						Colors.RED_BOLD, Colors.RESET, Colors.RED, stat.inode, Colors.RESET,
						Colors.BLUE_BOLD, Colors.RESET, perm_str, Colors.BLUE, perm, Colors.RESET,
						Colors.ORANGE_BOLD, Colors.RESET, Colors.ORANGE, @tagName(stat.kind), Colors.RESET, });

	try stdout.print(
					\\{s}Change:{s} {s}{s}{s}
					\\{s}Modify:{s} {s}{s}{s}
					\\{s}Access:{s} {s}{s}{s}
					\\
					, .{
						Colors.DARKGREEN_BOLD, Colors.RESET, Colors.DARKGREEN, ctime_str, Colors.RESET,
						Colors.DARKGREEN_BOLD, Colors.RESET, Colors.DARKGREEN, mtime_str, Colors.RESET,
						Colors.DARKGREEN_BOLD, Colors.RESET, Colors.DARKGREEN, atime_str, Colors.RESET, });



}
