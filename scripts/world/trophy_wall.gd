class_name TrophyWall
extends Node2D

# Ten framed portraits along the lobby's top wall, one per floor boss in floor order, each in dark wood
# with a brass bevel (trophy_frame). A beaten boss's portrait hangs in colour, cut from his own sprite
# (art/props/waiting_room/trophy_<boss id>.png, built by tools/art/waiting_props.py); one still to beat
# shows only his dark silhouette. Every frame has a small brass name plate under it, every second one
# a plate lower so long names never meet, and the endings count is set on a larger brass plaque below.
# With no portrait the memento is drawn in code in its frame as before, and with no brass the words
# stand alone. Ten frames this narrow fit the eight wall cells between the north door and the next
# lantern (test_mementos).

const FRAME_SIZE := Vector2(22, 22)
const FRAME_ART := "trophy_frame"
const FRAME_STEP := 25.0
const MAT_INSET := 3.0
const PORTRAIT_SIZE := 16.0
# A boss not yet beaten: his portrait's shape in near black on the frame's dark backing.
const SILHOUETTE := Color(0.07, 0.06, 0.08)
const WOOD := Color("4a2f1c")
const WOOD_EDGE := Color("22150c")
const MAT := Color("d8cfb8")
const QUESTION := Color(0.3, 0.27, 0.22, 0.45)
const CAPTION := Color("ece9e0")
# Brass name plates (brass_plate: 3 px caps and one middle column stretched) and the endings plaque
# (brass_plaque: 4 px caps), with engraved dark words.
const PLATE_ART := "brass_plate"
const PLATE_CAP := 3
const PLAQUE_ART := "brass_plaque"
const PLAQUE_CAP := 4
const ENGRAVED := Color("2e1c0c")
const PLATE_PAD := 4.0
const CAPTION_SIZE := 7
# A caption's baseline under its frame's middle, and the plate's top this far over the baseline.
const CAPTION_Y := 21.0
const PLATE_ABOVE_BASELINE := 7.0
# Every second caption hangs a whole caption lower, since a name like "Commodore" is wider than a
# frame step and two plates side by side would run together.
const CAPTION_STAGGER := 13.0
# The endings count (EndingRules), on its plaque under the plates.
const ENDINGS_Y := 51.0
const PLAQUE_ABOVE_BASELINE := 9.0
const ENDINGS_COLOR := Color("ffd24a")
const ENDINGS_SIZE := 8

var _hung := {}
var _endings_line := ""


func setup(data: ProgressData) -> void:
	_hung = {}
	for entry in Mementos.hung(data):
		_hung[entry["boss"]] = true
	_endings_line = EndingRules.found_line(data)
	queue_redraw()


func endings_line() -> String:
	return _endings_line


# The middle of each frame, from left to right.
static func frame_center(index: int) -> Vector2:
	return Vector2((index - (Mementos.ALL.size() - 1) / 2.0) * FRAME_STEP, 0.0)


# How far below a frame's middle its caption's baseline sits.
static func caption_y(index: int) -> float:
	return CAPTION_Y + (CAPTION_STAGGER if index % 2 == 1 else 0.0)


static func portrait_art(boss: String) -> String:
	return "trophy_" + boss


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if not _endings_line.is_empty():
		_draw_label(_endings_line, Vector2(0, ENDINGS_Y), ENDINGS_SIZE, PLAQUE_ART, PLAQUE_CAP, PLAQUE_ABOVE_BASELINE, ENDINGS_COLOR)
	var frame_art := PropArt.texture(FRAME_ART)
	for i in Mementos.ALL.size():
		var entry: Dictionary = Mementos.ALL[i]
		var at := frame_center(i)
		var frame := Rect2(at - FRAME_SIZE / 2.0, FRAME_SIZE)
		if frame_art != null:
			PropArt.draw(self, frame_art, at)
		else:
			draw_rect(frame, WOOD)
			draw_rect(frame, WOOD_EDGE, false, 1.0)
			draw_rect(frame.grow(-MAT_INSET), MAT)
		var beaten := _hung.has(entry["boss"])
		var face := PropArt.texture(portrait_art(entry["boss"]))
		if face != null:
			PropArt.draw(self, face, at, Color.WHITE if beaten else SILHOUETTE)
		elif beaten:
			_draw_memento(entry["perk"], at)
		else:
			draw_string(font, at + Vector2(-3, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, QUESTION)
		_draw_label(entry["short_name"], at + Vector2(0, caption_y(i)), CAPTION_SIZE, PLATE_ART, PLATE_CAP, PLATE_ABOVE_BASELINE, CAPTION)


# Words centred on `baseline`, engraved on a brass plate stretched to fit them, or outlined alone when
# the plate's picture is missing.
func _draw_label(words: String, baseline: Vector2, size: int, plate_id: String, cap: int, above: float, bare_color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var spot := Vector2(-width / 2.0, 0.0) + baseline
	var plate := PropArt.texture(plate_id)
	if plate == null:
		draw_string_outline(font, spot, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color.BLACK)
		draw_string(font, spot, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, bare_color)
		return
	var plate_width := ceilf(width + PLATE_PAD * 2.0)
	var top_left := Vector2(floorf(baseline.x - plate_width / 2.0), baseline.y - above)
	draw_plate(self, plate, cap, Rect2(top_left, Vector2(plate_width, plate.get_height())))
	draw_string(font, spot, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ENGRAVED)


# A three-part picture stretched across `box`: its caps as drawn and its one middle column repeated.
static func draw_plate(canvas: CanvasItem, plate: Texture2D, cap: int, box: Rect2) -> void:
	var h := float(plate.get_height())
	var middle := maxf(box.size.x - cap * 2.0, 0.0)
	canvas.draw_texture_rect_region(plate, Rect2(box.position, Vector2(cap, h)), Rect2(0, 0, cap, h))
	canvas.draw_texture_rect_region(plate, Rect2(box.position + Vector2(cap, 0), Vector2(middle, h)), Rect2(cap, 0, 1, h))
	canvas.draw_texture_rect_region(plate, Rect2(box.position + Vector2(cap + middle, 0), Vector2(cap, h)), Rect2(cap + 1, 0, cap, h))


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
			# Last reel: a silver film reel with four holes round a hub, a strip of film trailing off it.
			var reel := Color("b8bcc6")
			draw_circle(at + Vector2(-1, -1), 6.5, reel)
			draw_arc(at + Vector2(-1, -1), 6.5, 0.0, TAU, 16, Color("555a66"), 1.0)
			for hole: Vector2 in [Vector2(-1, -4.5), Vector2(-1, 2.5), Vector2(-4.5, -1), Vector2(2.5, -1)]:
				draw_circle(at + hole, 1.4, Color("2a2a30"))
			draw_circle(at + Vector2(-1, -1), 1.2, Color("555a66"))
			draw_line(at + Vector2(4, 4), at + Vector2(9, 7), Color("3a2a1a"), 2.0)
		Mementos.SLIDE_PERK:
			# Ship's anchor: a ring, a shank with a stock across it, and two curved arms.
			var iron := Color("2e3440")
			draw_arc(at + Vector2(0, -6), 1.8, 0.0, TAU, 10, iron, 1.0)
			draw_line(at + Vector2(0, -4), at + Vector2(0, 6), iron, 2.0)
			draw_line(at + Vector2(-4, -3), at + Vector2(4, -3), iron, 1.5)
			draw_arc(at + Vector2(0, 1), 5.5, 0.2, PI - 0.2, 10, iron, 1.5)
			draw_colored_polygon(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(-7, 3), at + Vector2(-4, 3)]), iron)
			draw_colored_polygon(PackedVector2Array([at + Vector2(6, 0), at + Vector2(7, 3), at + Vector2(4, 3)]), iron)
		Mementos.CHARGE_PERK:
			# Crystal ball: a violet glass ball with a pale glint, on a dark brass stand.
			draw_circle(at + Vector2(0, -2), 5.5, Color("8a5ac8"))
			draw_arc(at + Vector2(0, -2), 5.5, 0.0, TAU, 16, Color("3a2458"), 1.0)
			draw_circle(at + Vector2(-2, -4), 1.5, Color("e8dcff"))
			draw_colored_polygon(PackedVector2Array([at + Vector2(-4, 3), at + Vector2(4, 3), at + Vector2(6, 7), at + Vector2(-6, 7)]), Color("6a4a20"))
		Mementos.LANDING_PERK:
			# Boarding pass: a pale ticket with a navy band, a torn-off stub and a bar code.
			var ticket := Rect2(at + Vector2(-8, -4), Vector2(16, 8))
			draw_rect(ticket, Color("eef2f8"))
			draw_rect(Rect2(ticket.position, Vector2(16, 2)), Color("2a3a6a"))
			for stub_y: float in [-1.0, 1.0, 3.0]:
				draw_line(at + Vector2(3, stub_y), at + Vector2(3, stub_y + 1), Color("8a8a96"), 1.0)
			for bar_x: float in [-6.0, -4.0, -3.0, -1.0]:
				draw_line(at + Vector2(bar_x, 0), at + Vector2(bar_x, 3), Color("1a1a1e"), 1.0)
			draw_rect(ticket, Color("555555"), false, 1.0)
		Mementos.BOSS_DAMAGE_PERK:
			# Gold gavel: a gold head on a slanted handle, over a dark sounding block.
			var gavel_gold := Color("d4a62a")
			draw_line(at + Vector2(-1, -2), at + Vector2(6, 5), Color("a87a1a"), 2.0)
			draw_set_transform(at + Vector2(-2, -3), PI / 4.0, Vector2.ONE)
			draw_rect(Rect2(Vector2(-5, -2.5), Vector2(10, 5)), gavel_gold)
			draw_rect(Rect2(Vector2(-5, -2.5), Vector2(10, 5)), Color("6a4a10"), false, 1.0)
			draw_set_transform(Vector2.ZERO)
			draw_rect(Rect2(at + Vector2(-7, 5), Vector2(7, 2)), Color("3a2a1a"))


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
