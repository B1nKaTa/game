class_name CutsceneStage
extends Node2D

# The set behind an ending scene, drawn in code in stage units (CutsceneSteps.VIEW, drawn at 2x). The
# actors stand on CutsceneSteps.GROUND_Y; the text box covers the screen below about y = 143, so
# everything that matters sits above that. Placeholders until the art pass, like the rest.

const STAGES: Array[String] = [
	"stairs_home", "fence", "funeral", "hospital", "garage", "gerald_house", "airport_home",
	"office_top", "waiting_room", "departures_desk", "kitchen", "bathroom", "living_room",
]
const GROUND := CutsceneSteps.GROUND_Y
const W := 320.0
const H := 180.0
const OUTLINE := Color(0.08, 0.06, 0.05)

# Where the props of each set stand, for the scripts to place actors against.
const STAIRS_FOOT := Vector2(176, GROUND)
const STAIRS_TOP := Vector2(286, 62)
const FENCE_X := 196.0
const COFFIN := Vector2(150, 116)
const BED := Vector2(150, 112)
const SLOT := Vector2(46, 104)
const ARMCHAIR := Vector2(196, GROUND)
const LADDER_TOP := Vector2(170, 92)

var stage_name := ""


func set_stage(new_name: String) -> void:
	stage_name = new_name
	queue_redraw()


func _draw() -> void:
	match stage_name:
		"stairs_home":
			_draw_stairs_home()
		"fence":
			_draw_fence()
		"funeral":
			_draw_funeral()
		"hospital":
			_draw_hospital()
		"garage":
			_draw_garage()
		"gerald_house":
			_draw_gerald_house()
		"airport_home":
			_draw_airport()
		"office_top":
			_draw_office()
		"waiting_room":
			_draw_waiting_room()
		"departures_desk":
			_draw_departures()
		"kitchen":
			_draw_kitchen()
		"bathroom":
			_draw_bathroom()
		"living_room":
			_draw_living_room()
		_:
			draw_rect(Rect2(0, 0, W, H), Color("1a161c"))


# --- shared pieces ---

func _room(wall: Color, floor_color: Color) -> void:
	draw_rect(Rect2(0, 0, W, GROUND - 6), wall)
	draw_rect(Rect2(0, GROUND - 6, W, H - GROUND + 6), floor_color)
	draw_rect(Rect2(0, GROUND - 8, W, 3), floor_color.darkened(0.35))


func _wallpaper(wall: Color, stripe: Color, step := 16.0) -> void:
	var x := 0.0
	while x < W:
		draw_rect(Rect2(x, 0, 3, GROUND - 8), stripe)
		x += step
	draw_rect(Rect2(0, 72, W, 2), wall.darkened(0.3))


func _window(at: Rect2, sky: Color) -> void:
	draw_rect(at, sky)
	draw_rect(at, Color("5a4030"), false, 2.0)
	draw_line(Vector2(at.get_center().x, at.position.y), Vector2(at.get_center().x, at.end.y), Color("5a4030"), 2.0)
	draw_line(Vector2(at.position.x, at.get_center().y), Vector2(at.end.x, at.get_center().y), Color("5a4030"), 2.0)


func _door(at: Rect2, color: Color) -> void:
	draw_rect(at, color)
	draw_rect(at, OUTLINE, false, 1.0)
	draw_circle(Vector2(at.end.x - 4, at.get_center().y + 4), 1.5, Color("d4a62a"))


func _sign(text: String, center: Vector2, back: Color, fore: Color, size := 8) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var box := Rect2(center - Vector2(width / 2.0 + 4, size), Vector2(width + 8, size + 6))
	draw_rect(box, back)
	draw_rect(box, OUTLINE, false, 1.0)
	draw_string(font, Vector2(center.x - width / 2.0, center.y + 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, fore)


func _staircase(foot: Vector2, top: Vector2, steps: int, wood: Color) -> void:
	var rise := (foot.y - top.y) / steps
	var run := (top.x - foot.x) / steps
	for i in steps:
		var step := Rect2(foot.x + run * i - 4, foot.y - rise * (i + 1), W - (foot.x + run * i - 4), rise)
		draw_rect(step, wood if i % 2 == 0 else wood.darkened(0.08))
		draw_line(step.position, Vector2(step.end.x, step.position.y), wood.lightened(0.25), 1.0)
	# The banister along the steps.
	draw_line(foot + Vector2(-4, -26), top + Vector2(-4, -26), Color("5a3a22"), 2.0)
	for i in range(0, steps + 1, 2):
		var post := foot.lerp(top, float(i) / steps)
		draw_line(post + Vector2(-4, -26), post + Vector2(-4, -2), Color("5a3a22"), 1.0)


# --- the sets ---

func _draw_stairs_home() -> void:
	_room(Color("6a5a7a"), Color("6b4a32"))
	_wallpaper(Color("6a5a7a"), Color("74648a"))
	_window(Rect2(30, 34, 40, 34), Color("2a3a5a"))
	_staircase(STAIRS_FOOT, STAIRS_TOP, 8, Color("8a5a3a"))
	# A hall rug and a framed photo of a younger, angrier Harold.
	draw_rect(Rect2(70, GROUND - 4, 70, 6), Color("8c2a2a"))
	draw_rect(Rect2(100, 36, 22, 26), Color("3a2a1a"))
	draw_rect(Rect2(103, 39, 16, 20), Color("c8b89a"))
	draw_line(Vector2(107, 52), Vector2(115, 52), Color("3a2a1a"), 1.0)


func _draw_fence() -> void:
	draw_rect(Rect2(0, 0, W, GROUND), Color("7ab0d8"))
	draw_circle(Vector2(276, 24), 10, Color("f2e2a0"))
	draw_rect(Rect2(0, GROUND - 14, W, H), Color("5a8a3a"))
	# Harold's house on the left, Gerald's on the right, both the same and both worse for it.
	_house(Rect2(-10, 46, 96, GROUND - 52), Color("b89a7a"), Color("8c2a2a"))
	_house(Rect2(236, 46, 96, GROUND - 52), Color("9aa8b8"), Color("4a5a6a"))
	# The fence between the gardens.
	for x in range(int(FENCE_X) - 70, int(FENCE_X) + 6, 7):
		draw_rect(Rect2(x, GROUND - 26, 5, 22), Color("e8e0d0"))
		draw_rect(Rect2(x, GROUND - 26, 5, 22), Color("9a907a"), false, 1.0)
	draw_rect(Rect2(FENCE_X - 72, GROUND - 20, 80, 3), Color("d8d0c0"))
	# Gerald's prize roses and a gnome that has seen things.
	for x: float in [256.0, 266.0, 300.0]:
		draw_circle(Vector2(x, GROUND - 16), 4, Color("c8323a"))
	draw_rect(Rect2(226, GROUND - 14, 6, 8), Color("3a6aa8"))
	draw_colored_polygon(PackedVector2Array([Vector2(225, GROUND - 14), Vector2(233, GROUND - 14), Vector2(229, GROUND - 22)]), Color("c8323a"))


func _house(at: Rect2, wall: Color, roof: Color) -> void:
	draw_rect(at, wall)
	draw_colored_polygon(PackedVector2Array([at.position + Vector2(-6, 0), Vector2(at.end.x + 6, at.position.y), Vector2(at.get_center().x, at.position.y - 28)]), roof)
	_window(Rect2(at.position.x + 14, at.position.y + 12, 22, 18), Color("2a3a5a"))
	_door(Rect2(at.end.x - 38, at.end.y - 40, 20, 40), roof.darkened(0.2))


func _draw_funeral() -> void:
	_room(Color("3a2e3e"), Color("4a3a2e"))
	_wallpaper(Color("3a2e3e"), Color("42344a"), 24.0)
	# Tall candles, a stained window and the lectern on the right.
	_window(Rect2(130, 18, 40, 48), Color("6a3a8a"))
	for x: float in [100.0, 200.0]:
		draw_rect(Rect2(x, 76, 4, 44), Color("e8e0d0"))
		draw_circle(Vector2(x + 2, 74), 3, Color("ffd24a"))
	draw_rect(Rect2(236, 94, 26, 34), Color("5a3a22"))
	draw_colored_polygon(PackedVector2Array([Vector2(232, 94), Vector2(266, 94), Vector2(262, 88), Vector2(236, 88)]), Color("6a4a2a"))
	# The coffin on its trestle, open.
	draw_rect(Rect2(COFFIN.x - 34, COFFIN.y + 2, 68, 10), Color("2a1a10"))
	draw_rect(Rect2(COFFIN.x - 36, COFFIN.y - 6, 72, 10), Color("6a3a1a"))
	draw_rect(Rect2(COFFIN.x - 33, COFFIN.y - 5, 66, 4), Color("e8d8f0"))
	draw_rect(Rect2(COFFIN.x - 36, COFFIN.y - 6, 72, 10), OUTLINE, false, 1.0)
	_sign("IN LOVING MEMORY", Vector2(150, 84), Color("2a1a2a"), Color("d8c8e0"), 7)


func _draw_hospital() -> void:
	_room(Color("c8d8d0"), Color("9aa8a0"))
	draw_rect(Rect2(0, 60, W, 2), Color("a8b8b0"))
	_window(Rect2(220, 26, 46, 36), Color("8ab8e8"))
	# The bed, a drip stand and a heart monitor on the wall.
	draw_rect(Rect2(BED.x - 40, BED.y, 80, 8), Color("eef0f2"))
	draw_rect(Rect2(BED.x - 40, BED.y + 8, 80, 4), Color("8a96a0"))
	draw_rect(Rect2(BED.x - 42, BED.y - 14, 4, 30), Color("8a96a0"))
	draw_rect(Rect2(BED.x + 38, BED.y - 6, 4, 22), Color("8a96a0"))
	draw_rect(Rect2(BED.x - 36, BED.y - 4, 14, 5), Color.WHITE)
	draw_line(Vector2(BED.x - 56, 60), Vector2(BED.x - 56, GROUND - 4), Color("8a96a0"), 1.0)
	draw_rect(Rect2(BED.x - 60, 58, 8, 12), Color(0.7, 0.85, 1.0, 0.8))
	draw_rect(Rect2(64, 30, 40, 26), Color("1a2420"))
	draw_rect(Rect2(64, 30, 40, 26), OUTLINE, false, 1.0)


func _draw_garage() -> void:
	# The garage as a casino: dark walls, neon, a card table and the door on its runners on the right.
	_room(Color("1e1a2a"), Color("2a2a2e"))
	for i in 5:
		draw_rect(Rect2(20 + i * 30, 16, 18, 4), [Color("ff4fd8"), Color("4fd8ff"), Color("ffd24a")][i % 3])
	_sign("HAROLD'S PALACE", Vector2(110, 40), Color("2a1030"), Color("ff7ae8"), 9)
	draw_rect(Rect2(68, 108, 84, 6), Color("2f7a4a"))
	draw_rect(Rect2(68, 108, 84, 6), Color("1a3a22"), false, 1.0)
	draw_rect(Rect2(76, 114, 4, 14), Color("3a2a1a"))
	draw_rect(Rect2(140, 114, 4, 14), Color("3a2a1a"))
	# The garage door frame, open: the door itself is an actor that comes down.
	draw_rect(Rect2(232, 30, 6, GROUND - 30), Color("5a5a60"))
	draw_rect(Rect2(306, 30, 6, GROUND - 30), Color("5a5a60"))
	draw_rect(Rect2(238, 30, 68, GROUND - 36), Color("0e0c14"))
	draw_rect(Rect2(232, 26, 80, 6), Color("5a5a60"))


func _draw_gerald_house() -> void:
	# Gerald's front room: a door with a letter slot, his armchair, his awful wallpaper.
	_room(Color("8a9a6a"), Color("6b5a3a"))
	_wallpaper(Color("8a9a6a"), Color("94a474"), 10.0)
	_door(Rect2(30, 68, 32, GROUND - 74), Color("4a5a6a"))
	draw_rect(Rect2(SLOT.x - 6, SLOT.y - 2, 12, 3), Color("d4a62a"))
	_window(Rect2(110, 30, 44, 34), Color("7ab0d8"))
	draw_rect(Rect2(200, 40, 30, 22), Color("3a2a1a"))
	draw_rect(Rect2(203, 43, 24, 16), Color("c8b89a"))
	_sign("GERALD'S", Vector2(215, 54), Color("c8b89a"), Color("3a2a1a"), 6)
	draw_rect(Rect2(250, 98, 40, 26), Color("6a3a3a"))
	draw_rect(Rect2(250, 90, 8, 34), Color("6a3a3a"))


func _draw_airport() -> void:
	_room(Color("c0c8d8"), Color("8a8a96"))
	_window(Rect2(20, 20, 280, 40), Color("8ab8e8"))
	draw_colored_polygon(PackedVector2Array([Vector2(60, 44), Vector2(110, 40), Vector2(116, 44), Vector2(110, 46)]), Color.WHITE)
	_sign("ARRIVALS", Vector2(160, 74), Color("2a3a6a"), Color("ffd24a"), 9)
	draw_rect(Rect2(230, 84, 60, 40), Color("4a4a56"))
	draw_rect(Rect2(236, 88, 48, 32), Color("1a1a20"))
	_sign("WELCOME HOME", Vector2(260, 104), Color("1a1a20"), Color("7aff8a"), 6)


func _draw_office() -> void:
	# The top of Head Office: a city of clouds below the window, the big desk and the big chair.
	_room(Color("4a3a2a"), Color("6a1a1a"))
	draw_rect(Rect2(20, 14, 280, 64), Color("e8d8b8"))
	for x: float in [40.0, 90.0, 150.0, 220.0, 270.0]:
		draw_circle(Vector2(x, 62), 14, Color("fff6e8"))
	draw_rect(Rect2(20, 14, 280, 64), Color("2a1a10"), false, 2.0)
	draw_rect(Rect2(150, 14, 2, 64), Color("2a1a10"))
	# The big chair beside the desk, high-backed, on a swivel, with its seat at the height Harold
	# stands on to sit in it (new_management.gd's CHAIR).
	draw_rect(Rect2(270, 62, 26, 42), Color("2a1a1a"))
	draw_rect(Rect2(270, 62, 26, 42), Color("d4a62a"), false, 1.0)
	draw_rect(Rect2(264, 104, 38, 5), Color("3a2222"))
	draw_rect(Rect2(280, 109, 6, 14), Color("3a3a40"))
	draw_rect(Rect2(272, 123, 22, 3), Color("3a3a40"))
	draw_rect(Rect2(150, 104, 110, 24), Color("5a3a22"))
	draw_rect(Rect2(150, 104, 110, 4), Color("7a5a3a"))
	_sign("CHAIRMAN", Vector2(205, 118), Color("d4a62a"), Color("2a1a10"), 6)


func _draw_waiting_room() -> void:
	_room(Color("5a6a5a"), Color("4a4030"))
	draw_rect(Rect2(0, 56, W, 2), Color("4a5a4a"))
	# The run door, the ticket machine and the NOW SERVING sign.
	draw_rect(Rect2(40, 54, 44, GROUND - 60), Color("1a1418"))
	draw_rect(Rect2(40, 54, 44, GROUND - 60), Color("d4a62a"), false, 2.0)
	_sign("RETURN", Vector2(62, 48), Color("2a1a10"), Color("ffd24a"), 7)
	draw_rect(Rect2(196, 92, 14, 30), Color("c8323a"))
	draw_rect(Rect2(199, 98, 8, 3), Color("eeeeee"))
	_sign("PLEASE TAKE A NUMBER", Vector2(240, 30), Color("1a1418"), Color("ff6a4a"), 8)
	for x: float in [250.0, 266.0, 282.0]:
		draw_rect(Rect2(x, 106, 12, 6), Color("6a5a7a"))
		draw_rect(Rect2(x, 112, 2, 10), Color("3a3a40"))


func _draw_departures() -> void:
	_room(Color("5a6a8a"), Color("4a4a56"))
	_sign("DEPARTURES   GATE 0   ONE WAY", Vector2(160, 24), Color("1a1a20"), Color("ffd24a"), 8)
	_window(Rect2(20, 40, 100, 40), Color("e8e0f0"))
	draw_rect(Rect2(180, 98, 80, 30), Color("6a6a78"))
	draw_rect(Rect2(180, 98, 80, 4), Color("8a8a96"))
	_sign("CHECK OUT", Vector2(220, 114), Color("2a3a6a"), Color("eeeeee"), 6)


func _draw_kitchen() -> void:
	_room(Color("d8c890"), Color("8a7a6a"))
	for x in range(0, int(W), 12):
		draw_line(Vector2(x, 80), Vector2(x, GROUND - 8), Color("c8b880"), 1.0)
	_window(Rect2(40, 26, 40, 32), Color("7ab0d8"))
	draw_rect(Rect2(230, 50, 60, 70), Color("e8e8e0"))
	draw_rect(Rect2(230, 50, 60, 70), OUTLINE, false, 1.0)
	draw_line(Vector2(230, 80), Vector2(290, 80), OUTLINE, 1.0)
	# The kitchen table, where the sandwich waits.
	draw_rect(Rect2(110, 106, 80, 5), Color("8a5a3a"))
	draw_rect(Rect2(116, 111, 4, 17), Color("6a4a2a"))
	draw_rect(Rect2(180, 111, 4, 17), Color("6a4a2a"))


func _draw_bathroom() -> void:
	_room(Color("a8c8c8"), Color("e8e8e8"))
	for x in range(0, int(W), 10):
		draw_line(Vector2(x, 70), Vector2(x, GROUND - 8), Color("98b8b8"), 1.0)
	for y in range(70, int(GROUND) - 8, 10):
		draw_line(Vector2(0, y), Vector2(W, y), Color("98b8b8"), 1.0)
	# The bath, the toilet and a mirror.
	draw_rect(Rect2(200, 100, 96, 24), Color.WHITE)
	draw_rect(Rect2(200, 100, 96, 24), Color("8a9a9a"), false, 1.0)
	draw_rect(Rect2(204, 102, 88, 6), Color("8ac8e8"))
	draw_rect(Rect2(290, 82, 4, 18), Color("b8b8c0"))
	draw_rect(Rect2(40, 104, 22, 20), Color.WHITE)
	draw_rect(Rect2(38, 96, 26, 8), Color("f0f0f0"))
	draw_rect(Rect2(36, 84, 30, 12), Color.WHITE)
	draw_rect(Rect2(36, 84, 30, 40), Color("8a9a9a"), false, 1.0)
	draw_rect(Rect2(100, 30, 34, 40), Color("c8e0f0"))
	draw_rect(Rect2(100, 30, 34, 40), Color("8a9a9a"), false, 2.0)


func _draw_living_room() -> void:
	_room(Color("8a6a5a"), Color("5a4a3a"))
	_wallpaper(Color("8a6a5a"), Color("94746a"), 14.0)
	_window(Rect2(30, 30, 40, 34), Color("2a3a5a"))
	# A ceiling lamp on its flex, the television, and his armchair facing it.
	draw_line(Vector2(LADDER_TOP.x, 0), Vector2(LADDER_TOP.x, 36), Color("2a2a2a"), 1.0)
	draw_rect(Rect2(LADDER_TOP.x - 6, 36, 12, 5), Color("d8c8a0"))
	draw_rect(Rect2(250, 92, 44, 32), Color("3a2a1a"))
	draw_rect(Rect2(252, 70, 40, 26), Color("2a2a30"))
	draw_rect(Rect2(255, 73, 34, 20), Color("8ab8d8"))
	draw_rect(Rect2(255, 73, 34, 20), OUTLINE, false, 1.0)
	_draw_armchair(ARMCHAIR)


func _draw_armchair(at: Vector2) -> void:
	draw_rect(Rect2(at.x - 20, at.y - 18, 40, 18), Color("7a3a2a"))
	draw_rect(Rect2(at.x - 22, at.y - 26, 8, 26), Color("6a2a1a"))
	draw_rect(Rect2(at.x + 14, at.y - 26, 8, 26), Color("6a2a1a"))
