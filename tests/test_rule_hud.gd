extends TestCase


# A plus-shaped 5x5 core: a pixel with lit neighbours straight up, down, left and right, and the four
# diagonal neighbours dark, at arm length 2. Any such spot reads as a cross at 1x.
func _has_plus(image: Image) -> bool:
	for y in range(2, image.get_height() - 2):
		for x in range(2, image.get_width() - 2):
			var lit := func(px: int, py: int) -> bool: return image.get_pixel(px, py).a > 0.5
			if not lit.call(x, y):
				continue
			var arms: bool = lit.call(x, y - 1) and lit.call(x, y - 2) and lit.call(x, y + 1) and lit.call(x, y + 2) \
				and lit.call(x - 1, y) and lit.call(x - 2, y) and lit.call(x + 1, y) and lit.call(x + 2, y)
			var corners: bool = lit.call(x - 1, y - 1) or lit.call(x + 1, y - 1) or lit.call(x - 1, y + 1) or lit.call(x + 1, y + 1)
			if arms and not corners:
				return true
	return false


func test_every_rule_has_a_pictogram_without_a_cross() -> void:
	for rule in RoomRule.ALL:
		var image := RulePictogram.image(rule)
		assert_eq(image.get_width(), RulePictogram.SIZE, rule)
		assert_false(_has_plus(image), "%s draws a plus shape" % rule)


func test_the_cross_check_catches_a_plus() -> void:
	var image := Image.create(9, 9, false, Image.FORMAT_RGBA8)
	for i in 9:
		image.set_pixel(4, i, Color.WHITE)
		image.set_pixel(i, 4, Color.WHITE)
	assert_true(_has_plus(image))


func test_the_pulse_never_uses_the_warning_red_or_safe_mint() -> void:
	for color in [RuleIcon.PULSE_COLOR, RuleIcon.BROKEN_COLOR]:
		assert_false(color.is_equal_approx(Color("e4524f")))
		assert_false(color.is_equal_approx(Color("7fe0a0")))


func test_the_icon_sits_under_the_minimap_on_screen() -> void:
	var rect := Rect2(RuleIcon.AT, Vector2(RulePictogram.SIZE + 4, RulePictogram.SIZE + 4))
	assert_true(rect.position.y >= Hud.MAP_PANEL.end.y, "below the map panel")
	assert_true(rect.end.x <= 640.0 and rect.end.y <= 360.0)


func test_the_stamp_words_are_short_enough_to_read_in_a_second() -> void:
	for kind in [RuleStamp.KIND_VIOLATION, RuleStamp.KIND_GOOD, RuleStamp.KIND_LIFTED]:
		assert_true(RuleStamp.text_of(kind).length() <= 18, kind)


func test_the_rule_sounds_are_catalogued() -> void:
	for name in ["rule_whistle", "rule_stamp", "reel_flicker"]:
		assert_true(SoundBank.NAMES.has(name), name)
