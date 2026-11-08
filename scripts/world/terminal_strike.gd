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
# The falling security tray's picture (art/props/security_tray.png, 24x18), drawn 1:1 and coming clear
# as the mark fills; the drawing stays for when it is missing.
const TRAY_ART := "security_tray"
# The stamp itself (art/props/rubber_stamp.png), coming down over its shadow in the warning's last part;
# the shadow and the ink stay drawn.
const STAMP_ART := "rubber_stamp"
const STAMP_SHOWS := 0.5
const STAMP_DROP := 40.0
const STAMP_SHADOW := Color(0.05, 0.03, 0.08)
const STAMP_HANDLE := Color("7a2f3a")
const INK := Color("c4161c")
const INK_TEXT := "DEPARTED"
# The ink stays this long after the stamp lands, fading over its last INK_FADE, so it can be read.
# A landing's dust alone lasts GroundStrike.SHOW_TIME, far too short for a word.
const INK_TIME := 1.0
const INK_FADE := 0.4

var kind := LOOK_TRAY
var _ink_left := INK_TIME


# How long a strike of this look stays drawn after it lands.
static func shown_after_landing(look_kind: String) -> float:
	return INK_TIME if look_kind == LOOK_STAMP else SHOW_TIME


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


# A landed stamp keeps its ink a while: its dust plays out as any landing's does, then the word stays.
func _process(delta: float) -> void:
	if _landed and kind == LOOK_STAMP:
		queue_redraw()
		_show_left = maxf(_show_left - delta, 0.0)
		if ink_fades(delta):
			queue_free()
		return
	super(delta)


# Counts the ink down. Returns true once it has gone.
func ink_fades(delta: float) -> bool:
	_ink_left -= delta
	return _ink_left <= 0.0


func _draw() -> void:
	super()
	if _delay > 0.0:
		return
	var r := radius()
	if _landed:
		if kind == LOOK_STAMP:
			var fade := clampf(_ink_left / INK_FADE, 0.0, 1.0)
			draw_rect(Rect2(-r * 0.7, -r * 0.35, r * 1.4, r * 0.7), Color(INK, 0.8 * fade), false, 3.0)
			var font := ThemeDB.fallback_font
			var width := font.get_string_size(INK_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			draw_string(font, Vector2(-width / 2.0, 4.0), INK_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(INK, fade))
		return
	var filled := fill()
	if kind == LOOK_STAMP:
		# The stamp's outer red ring only with Attack warnings on (AttackWarnings); the stamp's shadow
		# and the stamp coming down always show.
		if AttackWarnings.drawn_by(_source):
			draw_arc(Vector2.ZERO, r + STAMP_RING_GAP, 0.0, TAU, 32, COLOR, 2.0)
		var size := 0.3 + 0.7 * filled
		var alpha := 0.25 + 0.5 * filled
		draw_rect(Rect2(-r * 0.7 * size, -r * 0.45 * size, r * 1.4 * size, r * 0.9 * size), Color(STAMP_SHADOW, alpha))
		var stamp := PropArt.texture(STAMP_ART) if filled > STAMP_SHOWS else null
		if stamp != null:
			var lower := (filled - STAMP_SHOWS) / (1.0 - STAMP_SHOWS)
			draw_texture(stamp, PropArt.centred(stamp, Vector2(0.0, -STAMP_DROP * (1.0 - lower))), Color(1, 1, 1, lower))
		else:
			draw_rect(Rect2(-r * 0.15 * size, -r * 0.9 * size, r * 0.3 * size, r * 0.45 * size), Color(STAMP_HANDLE, alpha))
	else:
		var art := PropArt.texture(TRAY_ART)
		if art != null:
			draw_texture(art, PropArt.centred(art), Color(1, 1, 1, 0.35 + 0.65 * filled))
			return
		var size := 0.4 + 0.6 * filled
		var tray := Rect2(-12.0 * size, -8.0 * size, 24.0 * size, 16.0 * size)
		draw_rect(tray, Color(TRAY, 0.35 + 0.5 * filled))
		draw_rect(tray, Color(TRAY_EDGE, 0.35 + 0.5 * filled), false, 1.0)
