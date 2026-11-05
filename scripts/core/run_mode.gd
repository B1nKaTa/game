class_name RunMode
extends RefCounted

# Whether this is a test or probe run, started with --script or its short form -s. Such runs never
# touch the real save, settings, slots or sounds, so every autoload guard asks here.


static func is_script_run() -> bool:
	return is_script_args(OS.get_cmdline_args())


static func is_script_args(args: PackedStringArray) -> bool:
	return args.has("--script") or args.has("-s")
