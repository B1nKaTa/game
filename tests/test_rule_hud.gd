extends TestCase


# Only ink counts as lit: the pictogram's INK or SLASH colour, never its face, rim or transparent corners.
func _is_ink(image: Image, x: int, y: int, with_slash := true) -> bool:
	var c := image.get_pixel(x, y)
	if c.a < 0.5:
		return false
	for ink: Color in ([RulePictogram.INK, RulePictogram.SLASH] if with_slash else [RulePictogram.INK]):
		if absf(c.r - ink.r) < 0.03 and absf(c.g - ink.g) < 0.03 and absf(c.b - ink.b) < 0.03:
			return true
	return false


# A plus-shaped 5x5 core: an ink pixel with ink neighbours straight up, down, left and right, and the four
# diagonal neighbours not ink, at arm length 2. Any such spot reads as a cross at 1x.
func _has_plus(image: Image) -> bool:
	for y in range(2, image.get_height() - 2):
		for x in range(2, image.get_width() - 2):
			var lit := func(px: int, py: int) -> bool: return _is_ink(image, px, py)
			if not lit.call(x, y):
				continue
			var arms: bool = lit.call(x, y - 1) and lit.call(x, y - 2) and lit.call(x, y + 1) and lit.call(x, y + 2) \
				and lit.call(x - 1, y) and lit.call(x - 2, y) and lit.call(x + 1, y) and lit.call(x + 2, y)
			var corners: bool = lit.call(x - 1, y - 1) or lit.call(x + 1, y - 1) or lit.call(x - 1, y + 1) or lit.call(x + 1, y + 1)
			if arms and not corners:
				return true
	return false


# A vertical ink run of 5 or more that a level ink run crosses, reaching 2 or more pixels to both sides at
# one row: a shoulder bar or a T-bar that reads as a cross.
func _has_crossbar(image: Image) -> bool:
	for x in image.get_width():
		var run := 0
		for y in image.get_height() + 1:
			if y < image.get_height() and _is_ink(image, x, y, false):
				run += 1
				continue
			if run >= 5:
				for row in range(y - run, y):
					var left := 0
					while x - left - 1 >= 0 and _is_ink(image, x - left - 1, row, false):
						left += 1
					var right := 0
					while x + right + 1 < image.get_width() and _is_ink(image, x + right + 1, row, false):
						right += 1
					# A bar is thin (2 rows or fewer) where it leaves the line; the edge of a solid block is deeper.
					if left >= 2 and right >= 2 and _depth(image, x - 2, row) <= 2 and _depth(image, x + 2, row) <= 2:
						return true
			run = 0
	return false


# How many ink pixels stack vertically through (x, y).
func _depth(image: Image, x: int, y: int) -> int:
	var count := 1
	var up := y - 1
	while up >= 0 and _is_ink(image, x, up, false):
		count += 1
		up -= 1
	var down := y + 1
	while down < image.get_height() and _is_ink(image, x, down, false):
		count += 1
		down += 1
	return count


func _disc_with_ink_plus() -> Image:
	var image := Image.create(RulePictogram.SIZE, RulePictogram.SIZE, false, Image.FORMAT_RGBA8)
	image.fill(RulePictogram.FACE)
	for i in range(4, 20):
		image.set_pixel(12, i, RulePictogram.INK)
		image.set_pixel(i, 12, RulePictogram.INK)
	return image


func test_every_rule_has_a_pictogram_without_a_cross() -> void:
	for rule in RoomRule.ALL:
		var image := RulePictogram.image(rule)
		assert_eq(image.get_width(), RulePictogram.SIZE, rule)
		assert_false(_has_plus(image), "%s draws a plus shape" % rule)
		assert_false(_has_crossbar(image), "%s has a bar across a vertical line" % rule)
		var inked := 0
		for y in image.get_height():
			for x in image.get_width():
				if _is_ink(image, x, y):
					inked += 1
		assert_true(inked > 10, "%s has ink to check" % rule)


func test_every_pictogram_is_slashed() -> void:
	for rule in RoomRule.ALL:
		var image := RulePictogram.image(rule)
		for i in range(6, 18):
			assert_eq(image.get_pixel(i, i), RulePictogram.SLASH, "%s slash at %d" % [rule, i])


func test_the_cross_check_catches_an_ink_plus_on_the_face() -> void:
	var image := _disc_with_ink_plus()
	assert_true(_has_plus(image))
	assert_true(_has_crossbar(image))
	image.fill(RulePictogram.FACE)
	assert_false(_has_plus(image))


func test_a_stamp_in_the_announcement_still_shows_the_icon() -> void:
	var stamp := RuleStamp.new()
	var done: Array = []
	stamp.announce_done.connect(func(rule: String) -> void: done.append(rule))
	stamp.announce(RoomRule.NO_HORSEPLAY)
	stamp._process(0.3)
	assert_eq(done.size(), 0)
	stamp.stamp(RuleStamp.KIND_VIOLATION)
	assert_eq(done, [RoomRule.NO_HORSEPLAY])
	stamp._process(2.0)
	assert_eq(done.size(), 1, "announce_done fires once")
	stamp.free()


func test_the_cross_check_catches_a_plus() -> void:
	var image := Image.create(9, 9, false, Image.FORMAT_RGBA8)
	for i in 9:
		image.set_pixel(4, i, RulePictogram.INK)
		image.set_pixel(i, 4, RulePictogram.INK)
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


# The first real-window shot ran "LEAVE CANES AT RECEPTION" well past both sides of the card. Every sign
# fits the card, in one line or two.
func test_every_sign_fits_its_card() -> void:
	var font := HudStyle.font()
	for rule in RoomRule.ALL:
		var lines := RuleStamp.sign_lines(RoomRule.sign_text(rule), font, RuleStamp.SIGN_SIZE, RuleStamp.SIGN_ROOM)
		assert_true(lines.size() >= 1 and lines.size() <= 2, "%s in %d lines" % [rule, lines.size()])
		assert_eq(" ".join(lines), RoomRule.sign_text(rule), "no word lost")
		for line in lines:
			var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, RuleStamp.SIGN_SIZE).x
			assert_true(width <= RuleStamp.SIGN_ROOM, "%s: '%s' is %.0f px in %.0f" % [rule, line, width, RuleStamp.SIGN_ROOM])
	assert_true(RuleStamp.SIGN_ROOM < RuleStamp.CARD.x, "inside the card")
