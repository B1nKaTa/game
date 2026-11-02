extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4:
		print("Usage: -- <input.png> <output.png> <width> <height>")
		quit(2)
		return
	var source := Image.load_from_file(args[0])
	if source == null or source.is_empty():
		print("Could not read " + args[0])
		quit(1)
		return
	var palette := PixelCleanup.parse_palette(FileAccess.get_file_as_string("res://art/palette.txt"))
	var result := PixelCleanup.process(source, args[2].to_int(), args[3].to_int(), palette)
	if result.save_png(args[1]) != OK:
		print("Could not write " + args[1])
		quit(1)
		return
	print("Wrote " + args[1])
	quit(0)
