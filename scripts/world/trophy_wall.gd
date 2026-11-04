class_name TrophyWall
extends Node2D

# Six frames along the lobby's top wall, one per floor boss in floor order. A beaten boss's memento
# hangs in its frame. An empty frame shows a faint "?" and the boss's short name, so what is left to
# beat is always in view. Placeholder shapes, drawn in code.

const FRAME_SIZE := Vector2(26, 22)
const FRAME_STEP := 32.0
const MAT_INSET := 3.0
const WOOD := Color("4a2f1c")
const WOOD_EDGE := Color("22150c")
const MAT := Color("d8cfb8")
const QUESTION := Color(0.3, 0.27, 0.22, 0.45)
const CAPTION := Color("ece9e0")
const CAPTION_SIZE := 7
const CAPTION_Y := 21.0
# Every second caption hangs lower, since a long name like "Mortimer" is as wide as a frame step and
# two empty frames side by side would run their names together.
const CAPTION_STAGGER := 10.0

var _hung := {}


func setup(data: ProgressData) -> void:
	_hung = {}
	for entry in Mementos.hung(data):
		_hung[entry["boss"]] = true
	queue_redraw()


# The middle of each frame, from left to right.
static func frame_center(index: int) -> Vector2:
	return Vector2((index - (Mementos.ALL.size() - 1) / 2.0) * FRAME_STEP, 0.0)


# How far below a frame's middle its caption's baseline sits.
static func caption_y(index: int) -> float:
	return CAPTION_Y + (CAPTION_STAGGER if index % 2 == 1 else 0.0)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in Mementos.ALL.size():
		var entry: Dictionary = Mementos.ALL[i]
		var at := frame_center(i)
		var frame := Rect2(at - FRAME_SIZE / 2.0, FRAME_SIZE)
		draw_rect(frame, WOOD)
		draw_rect(frame, WOOD_EDGE, false, 1.0)
		draw_rect(frame.grow(-MAT_INSET), MAT)
		if _hung.has(entry["boss"]):
			_draw_memento(entry["perk"], at)
		else:
			draw_string(font, at + Vector2(-3, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, QUESTION)
			var caption: String = entry["short_name"]
			var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x
			draw_string_outline(font, at + Vector2(-width / 2.0, caption_y(i)), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE, 2, Color.BLACK)
			draw_string(font, at + Vector2(-width / 2.0, caption_y(i)), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE, CAPTION)


func _draw_memento(perk: String, at: Vector2) -> void:
	match perk:
		Mementos.START_PENSION_PERK:
			# Name badge: a white card with a red stripe.
			draw_rect(Rect2(at + Vector2(-8, -5), Vector2(16, 10)), Color.WHITE)
			draw_rect(Rect2(at + Vector2(-8, -5), Vector2(16, 3)), Color("c8323a"))
			draw_rect(Rect2(at + Vector2(-8, -5), Vector2(16, 10)), Color("555555"), false, 1.0)
		Mementos.PROP_COINS_PERK:
			# Bent shovel: a grey blade on a bent brown handle.
			draw_polyline(PackedVector2Array([at + Vector2(-8, -6), at + Vector2(-1, -1), at + Vector2(2, 2)]), Color("7a5130"), 2.0)
			draw_colored_polygon(PackedVector2Array([at + Vector2(1, 1), at + Vector2(8, 3), at + Vector2(6, 7), at + Vector2(0, 6)]), Color("9a9aa4"))
		Mementos.FIRST_HEAL_PERK:
			# Bedpan: a pale oval with a handle.
			_draw_ellipse(at + Vector2(-1, 0), Vector2(7, 5), Color("eef0f2"))
			draw_rect(Rect2(at + Vector2(5, -1), Vector2(5, 2)), Color("eef0f2"))
			draw_arc(at + Vector2(-1, 0), 5.0, 0.0, TAU, 16, Color("a9adb3"), 1.0)
		Mementos.FIRE_PERK:
			# Coal shovel: a black blade on a straight handle.
			draw_line(at + Vector2(-8, -6), at + Vector2(0, 1), Color("7a5130"), 2.0)
			draw_colored_polygon(PackedVector2Array([at + Vector2(-1, 0), at + Vector2(7, 2), at + Vector2(5, 8), at + Vector2(-2, 6)]), Color("1a1a1e"))
		Mementos.BOSS_ROOM_PILL_PERK:
			# Top hat: a black crown and brim with a band.
			draw_rect(Rect2(at + Vector2(-5, -7), Vector2(10, 11)), Color("141216"))
			draw_rect(Rect2(at + Vector2(-9, 4), Vector2(18, 2)), Color("141216"))
			draw_rect(Rect2(at + Vector2(-5, 1), Vector2(10, 2)), Color("8c2a2a"))
		Mementos.TREASURE_CHOICE_PERK:
			# Empty sack: a red sack outline, tied at the top.
			draw_polyline(PackedVector2Array([at + Vector2(-2, -6), at + Vector2(-7, 1), at + Vector2(-5, 6), at + Vector2(5, 6), at + Vector2(7, 1), at + Vector2(2, -6)]), Color("c8323a"), 1.5)
			draw_line(at + Vector2(-3, -6), at + Vector2(3, -6), Color("c8323a"), 1.5)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
