class_name TerminalStrike
extends GroundStrike

# A GroundStrike with the departure hall's looks: a grey security tray dropping onto its spot, or a
# giant boarding stamp, the heaviest attack of the floor, whose mark is the clearest of all: a second
# ring outside the first and the stamp's shadow growing over the spot, then a red DEPARTED inked
# where it landed. Everything else, from landing to breaking props, is GroundStrike's.
const LOOK_TRAY := "tray"
const LOOK_STAMP := "stamp"
const STAMP_RING_GAP := 8.0
const TRAY := Color("9aa0a8")
const TRAY_EDGE := Color("3c4048")
const STAMP_SHADOW := Color(0.05, 0.03, 0.08)
const STAMP_HANDLE := Color("7a2f3a")
const INK := Color("c4161c")
const INK_TEXT := "DEPARTED"

var kind := LOOK_TRAY


# A strike with one of these looks, placed in the source's room as Enemy.strike_ground places one.
# Nothing lands on a wall or a hole.
static func strike(source: Enemy, at: Vector2, radius: float, warning: float, delay := 0.0, damage := -1, look_kind := LOOK_TRAY) -> TerminalStrike:
	if source.open_ground.is_valid() and not source.open_ground.call(at):
		return null
	var spot := TerminalStrike.new()
	spot.setup(source, radius, warning, delay, 0.0, damage)
	spot.kind = look_kind
	source.get_parent().add_child(spot)
	spot.global_position = at
	return spot


func _draw() -> void:
	super()
	if _delay > 0.0:
		return
	var r := radius()
	if _landed:
		if kind == LOOK_STAMP:
			var fade := clampf(_show_left / SHOW_TIME, 0.0, 1.0)
			draw_rect(Rect2(-r * 0.7, -r * 0.35, r * 1.4, r * 0.7), Color(INK, 0.8 * fade), false, 3.0)
			var font := ThemeDB.fallback_font
			var width := font.get_string_size(INK_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			draw_string(font, Vector2(-width / 2.0, 4.0), INK_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(INK, fade))
		return
	var filled := fill()
	if kind == LOOK_STAMP:
		draw_arc(Vector2.ZERO, r + STAMP_RING_GAP, 0.0, TAU, 32, COLOR, 2.0)
		var size := 0.3 + 0.7 * filled
		var alpha := 0.25 + 0.5 * filled
		draw_rect(Rect2(-r * 0.7 * size, -r * 0.45 * size, r * 1.4 * size, r * 0.9 * size), Color(STAMP_SHADOW, alpha))
		draw_rect(Rect2(-r * 0.15 * size, -r * 0.9 * size, r * 0.3 * size, r * 0.45 * size), Color(STAMP_HANDLE, alpha))
	else:
		var size := 0.4 + 0.6 * filled
		var tray := Rect2(-12.0 * size, -8.0 * size, 24.0 * size, 16.0 * size)
		draw_rect(tray, Color(TRAY, 0.35 + 0.5 * filled))
		draw_rect(tray, Color(TRAY_EDGE, 0.35 + 0.5 * filled), false, 1.0)
