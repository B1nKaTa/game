extends TestCase


func _palette() -> PackedColorArray:
	return PackedColorArray([Color.BLACK, Color.WHITE, Color.RED])


func test_output_has_the_requested_size() -> void:
	var source := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	var result := PixelCleanup.process(source, 32, 48, _palette())
	assert_eq(result.get_width(), 32)
	assert_eq(result.get_height(), 48)


func test_colors_snap_to_the_palette() -> void:
	var source := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	source.fill(Color(0.9, 0.1, 0.1, 1.0))
	var result := PixelCleanup.process(source, 2, 2, _palette())
	assert_eq(result.get_pixel(0, 0), Color.RED)


func test_soft_edges_become_transparent_or_solid() -> void:
	var source := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	source.set_pixel(0, 0, Color(1, 1, 1, 0.2))
	source.set_pixel(1, 0, Color(1, 1, 1, 0.8))
	var result := PixelCleanup.process(source, 2, 1, _palette())
	assert_near(result.get_pixel(0, 0).a, 0.0)
	assert_near(result.get_pixel(1, 0).a, 1.0)


func test_parse_palette_ignores_comments_and_blanks() -> void:
	var colors := PixelCleanup.parse_palette("# shadows\n\n17131c\nffd24a\n")
	assert_eq(colors.size(), 2)
	assert_eq(colors[0], Color.html("17131c"))


func test_shipped_palette_is_usable() -> void:
	var colors := PixelCleanup.parse_palette(FileAccess.get_file_as_string("res://art/palette.txt"))
	assert_true(colors.size() >= 16)
