This tiny thing is a key logger for linux machines, but the program must be ran with root priveleges and the direct path to the event file must be provided as an argument.

Yes, super applicable and useful to all.

But, really this was just exploration into Zig comptime and what it could do.

You may notice that every one of the 100s of keys you could press are mapped in only ~70 LOC.

This is due to the power of Zig comptime and being able to generate a mapping from C macros before runtime even begins.