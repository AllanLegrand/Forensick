const std = @import("std");
const Forensick = @import("Forensick");
const Colors = Forensick.Colors;
const bufPrint = std.fmt.bufPrint;

const args_req = 2;

const args_enum = enum {
	stat,
	name,
	help,
	unknown,
};

const args_strings = std.StaticStringMap(args_enum).initComptime(.{
	.{ "-s", .stat },
	.{ "--state", .stat },
	.{ "-n", .name },
	.{ "--name", .name },
	.{ "-h", .help },
	.{ "--help", .help },
});

pub fn main() !void {
	const allocator = std.heap.page_allocator;

	const args = try std.process.argsAlloc(allocator);
	defer std.process.argsFree(allocator, args);

	var stdout_buffer: [1024]u8 = undefined;
	var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
	const stdout = &stdout_writer.interface;

	if (args.len < args_req) {
		Forensick.print_help(stdout, args[0]);
		return error.ExpectedArgument;
	}

	const input_filename = args[1];

	const file = try std.fs.cwd().openFile(
		input_filename,
		.{},
	);

	defer file.close();

	var i: usize = args_req;
	while (i < args.len) : (i += 1) {
		const arg = args_strings.get(args[i]) orelse .unknown;
		switch (arg) {
			.stat => {
				const stat = try file.stat();

				try Forensick.print_stat(stat, stdout);
			},
			.help => {
				Forensick.print_help(stdout, args[0]);
			},
			.name => {
				try stdout.print("{s}Name:{s} {s}{s}{s}\n"
					, .{ Colors.GOLD_BOLD, Colors.RESET, Colors.GOLD, input_filename, Colors.GOLD });
			},
			.unknown => {
				try stdout.print("{s}: {s}: unknown parameter\n\n", .{ args[0], args[i] });
				try stdout.flush();
				return;
			},
		}
	}

	try stdout.flush();
}
