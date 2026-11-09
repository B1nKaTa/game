class_name AuditFlash
extends Node2D

# The word AUDIT stamped over the door the Auditor walks in by: the rule stamp's red, tilted, with a
# dark rim, for about a second. It stands on the door, unless that would put it under the HUD's top
# rows on screen (a north door), where it shows just below the door instead.

const LIFE := 1.0
const FADE := 0.3
const WORD := "AUDIT"
const SIZE := 16
const TILT := -8.0
const INK := Color("c43d2f")
const RIM := Color(0.1, 0.06, 0.06)
# Over the bodies and warnings, as shots fly.
const Z := 56

var _left := LIFE


func _ready() -> void:
	z_index = Z


# Where the word's middle goes, from the door, given the door's height on screen and the camera's zoom:
# on the door, or a cell below it when the word's top would reach into the HUD band.
static func word_offset(door_screen_y: float, zoom: float) -> Vector2:
	var on_door := Vector2(0.0, -4.0)
	if door_screen_y + (on_door.y - SIZE) * zoom < Hud.BAND_BOTTOM:
		return Vector2(0.0, RoomBackdrop.TILE)
	return on_door


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := tr(WORD)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	var screen := get_global_transform_with_canvas()
	var middle := word_offset(screen.origin.y, screen.get_scale().y)
	var alpha := clampf(_left / FADE, 0.0, 1.0)
	draw_set_transform(middle, deg_to_rad(TILT))
	var box := Rect2(-width / 2.0 - 4.0, -SIZE * 0.75, width + 8.0, SIZE + 2.0)
	draw_rect(box.grow(1.0), Color(RIM, alpha), false, 3.0)
	draw_rect(box, Color(INK, alpha), false, 1.5)
	var at := Vector2(-width / 2.0, SIZE * 0.35)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 3, Color(RIM, alpha))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(INK, alpha))
	draw_set_transform(Vector2.ZERO)
