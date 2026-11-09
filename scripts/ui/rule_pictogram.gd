class_name RulePictogram
extends RefCounted

# Each rule's sign, drawn in code so it stays sharp at 1x. The crossing-out is one diagonal slash in a
# circle, never a cross shape (tests/test_rule_hud.gd checks for a plus).

const SIZE := 24
const RIM := Color("2b2622")
const FACE := Color("ece9e0")
const INK := Color("3a332c")
const SLASH := Color("b8642f")


static func image(rule: String) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SIZE / 2.0 - 0.5, SIZE / 2.0 - 0.5)
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x, y).distance_to(c)
			if d <= 11.5:
				img.set_pixel(x, y, RIM if d > 10.0 else FACE)
	match rule:
		RoomRule.NO_CANE:
			# A walking cane: an upright shaft with a curved crook, which bends over one side only.
			_rect(img, Rect2i(11, 9, 2, 10), INK)
			for p in [Vector2i(11, 8), Vector2i(12, 7), Vector2i(13, 6), Vector2i(14, 6), Vector2i(15, 7), Vector2i(15, 8)]:
				_rect(img, Rect2i(p.x, p.y, 2, 1) if p.y == 6 else Rect2i(p.x, p.y, 1, 1), INK)
		RoomRule.NO_HORSEPLAY:
			_star_jump(img)
		RoomRule.TEETH_IN:
			_rect(img, Rect2i(7, 9, 10, 3), INK)
			_rect(img, Rect2i(7, 13, 10, 3), INK)
			for x in [8, 10, 12, 14]:
				img.set_pixel(x, 11, FACE)
				img.set_pixel(x + 1, 13, FACE)
		RoomRule.NO_EXPLOSIVES:
			# A thermos flask: a tall body with a pale band and a wider cup-cap, and no handle (a cup has one).
			_rect(img, Rect2i(8, 5, 8, 4), INK)
			_rect(img, Rect2i(9, 9, 6, 11), INK)
			_rect(img, Rect2i(9, 12, 6, 1), FACE)
			_rect(img, Rect2i(9, 16, 6, 1), FACE)
		RoomRule.NO_FOOD:
			_rect(img, Rect2i(8, 9, 7, 8), INK)
			_rect(img, Rect2i(15, 11, 2, 1), INK)
			_rect(img, Rect2i(16, 11, 1, 4), INK)
			_rect(img, Rect2i(15, 14, 2, 1), INK)
		RoomRule.EXHIBITS:
			# A vase on a plinth: flared lip, thin neck, round belly.
			_rect(img, Rect2i(10, 6, 5, 1), INK)
			_rect(img, Rect2i(11, 7, 3, 4), INK)
			for y in range(10, 19):
				for x in range(7, 18):
					if Vector2(x, y).distance_to(Vector2(12, 14.5)) <= 4.3:
						img.set_pixel(x, y, INK)
			img.set_pixel(10, 13, FACE)
			_rect(img, Rect2i(8, 19, 9, 1), INK)
		RoomRule.NO_LOITERING:
			_figure(img, Vector2i(9, 5), false)
			_ring(img, Vector2i(16, 11), 3, INK)
			_line(img, Vector2i(16, 11), Vector2i(17, 9), INK)
			return img
	_slash(img)
	return img


static func texture(rule: String) -> ImageTexture:
	return ImageTexture.create_from_image(image(rule))


# Top-left to bottom-right, two pixels thick: a diagonal never makes a plus.
static func _slash(img: Image) -> void:
	for i in range(5, 19):
		img.set_pixel(i, i, SLASH)
		img.set_pixel(i + 1, i, SLASH)


# A star jump: arms up in a V and legs flung apart, all diagonals, so it never draws a plus.
static func _star_jump(img: Image) -> void:
	_rect(img, Rect2i(11, 4, 3, 3), INK)
	_rect(img, Rect2i(12, 7, 1, 6), INK)
	_line(img, Vector2i(12, 8), Vector2i(7, 4), INK)
	_line(img, Vector2i(12, 8), Vector2i(17, 4), INK)
	_line(img, Vector2i(12, 13), Vector2i(9, 19), INK)
	_line(img, Vector2i(12, 13), Vector2i(15, 19), INK)


# A figure: head, body, and legs apart (jumping) or together (standing). Arms go out diagonally.
static func _figure(img: Image, head: Vector2i, jumping: bool) -> void:
	_rect(img, Rect2i(head.x - 1, head.y, 3, 3), INK)
	_rect(img, Rect2i(head.x, head.y + 3, 1, 6), INK)
	_line(img, head + Vector2i(0, 4), head + Vector2i(-3, 2 if jumping else 7), INK)
	_line(img, head + Vector2i(0, 4), head + Vector2i(3, 2 if jumping else 7), INK)
	_line(img, head + Vector2i(0, 9), head + Vector2i(-3, 13), INK)
	_line(img, head + Vector2i(0, 9), head + Vector2i(3, 13), INK)


static func _rect(img: Image, r: Rect2i, color: Color) -> void:
	img.fill_rect(r, color)


static func _line(img: Image, a: Vector2i, b: Vector2i, color: Color) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(steps, 1))
		img.set_pixel(roundi(p.x), roundi(p.y), color)


static func _ring(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius - 1, radius + 2):
		for x in range(-radius - 1, radius + 2):
			var d := Vector2(x, y).length()
			if absf(d - radius) < 0.6:
				img.set_pixel(center.x + x, center.y + y, color)
