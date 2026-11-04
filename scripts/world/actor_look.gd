class_name ActorLook
extends Node2D

# Everyone in the ending scenes but Harold, and the props they pass about, drawn in code like the NPCs
# until the art pass, with the feet at the origin. People are about Harold's height (his hair tops out
# 41 units above his feet). Gerald is the one that matters: a thin, bald old man in a tan cardigan,
# with a comb-over, a long nose and a scowl, unlike Harold in colour and outline, since Harold is stout,
# white-bearded and green.

const NAMES := {
	"harold": "Harold",
	"gerald": "Gerald",
	"dealer": "The Dealer",
	"chairman": "The Chairman",
	"doctor": "Doctor",
	"exterminator": "Exterminator",
	"mourners": "Mourners",
	"clerk": "Clerk",
	"movers": "Movers",
	"augustine": "Augustine",
	# Text with no speaker: a letter, a form, a sound.
	"note": "",
}
const PROPS: Array[String] = [
	"gavel", "file", "cheque", "letter", "wreath", "coffin_lid", "grapes", "grape", "photos",
	"souvenirs", "garage_door", "shirt", "boarding_pass", "torn_pass", "monitor", "monitor_flat",
	"sandwich", "ladder", "zzz", "baggage", "ticket", "spray",
]
const OUTLINE := Color(0.08, 0.06, 0.05)
const SKIN := Color("e8b48a")
const GERALD_SKIN := Color("e0b090")
const GERALD_CARDIGAN := Color("c8a46a")
const GERALD_TROUSERS := Color("5a4a6a")
const HEAD_HEIGHT := 34.0

var id := ""
var facing := 1
var walking := false
var clock := 0.0
# The one-shot playing, so an exterminator's spray shows while he swings.
var action := ""


static func display_name(actor_id: String) -> String:
	return str(NAMES.get(actor_id, actor_id.capitalize()))


static func is_known(actor_id: String) -> bool:
	return NAMES.has(actor_id) or PROPS.has(actor_id)


static func head_of(actor_id: String) -> Vector2:
	match actor_id:
		"gerald":
			return Vector2(0, -38)
		"chairman":
			return Vector2(0, -38)
	return Vector2(0, -HEAD_HEIGHT)


# A hat on any head: a sun hat for the holiday, or any of Harold's own.
static func draw_hat(canvas: CanvasItem, shape: String, head: Vector2, color: Color, facing_dir: float) -> void:
	if shape == "straw":
		canvas.draw_colored_polygon(PackedVector2Array([head + Vector2(-14, -4), head + Vector2(14, -4), head + Vector2(10, -7), head + Vector2(-10, -7)]), Color("e8c86a"))
		canvas.draw_rect(Rect2(head + Vector2(-6, -13), Vector2(12, 7)), Color("e8c86a"))
		canvas.draw_rect(Rect2(head + Vector2(-6, -8), Vector2(12, 2)), Color("c8323a"))
		canvas.draw_rect(Rect2(head + Vector2(-6, -13), Vector2(12, 7)), OUTLINE, false, 1.0)
		canvas.draw_polyline(PackedVector2Array([head + Vector2(-14, -4), head + Vector2(-10, -7), head + Vector2(10, -7), head + Vector2(14, -4), head + Vector2(-14, -4)]), OUTLINE, 1.0)
		return
	GrandpaLook.draw_hat(canvas, shape, head, color, facing_dir)


func _draw() -> void:
	match id:
		"gerald":
			_draw_gerald()
		"dealer":
			_person(Color("1a1a1e"), Color("2a2a30"), Color("e8b48a"), Color("3a2a1a"))
			draw_rect(Rect2(-4, -26, 8, 9), Color.WHITE)
			draw_rect(Rect2(-8, -37, 16, 3), Color("2f9a5a"))
			draw_line(Vector2(-3 + facing * 2, -28), Vector2(3 + facing * 2, -29), Color("5a2a1a"), 1.0)
		"chairman":
			_person(Color("1a1e2e"), Color("1a1e2e"), SKIN, Color("b8b8c0"), 1.2, 4.0)
			draw_rect(Rect2(-2, -28, 4, 12), Color("d4a62a"))
		"doctor":
			_person(Color.WHITE, Color("4a6a8a"), SKIN, Color("5a3a22"))
			draw_arc(Vector2(0, -24), 5, 0.2, PI - 0.2, 8, Color("3a3a40"), 1.0)
			draw_circle(Vector2(0, -40), 3, Color("d8d8e0"))
		"exterminator":
			_person(Color("e07a2a"), Color("e07a2a"), SKIN, Color("3a2a1a"))
			draw_rect(Rect2(-facing * 12.0 - 4, -30, 8, 16), Color("8a8a96"))
			draw_rect(Rect2(-5 + facing * 2, -33, 8, 5), Color("2a2a2e"))
			if action == "swing":
				_cloud(Vector2(facing * 18.0, -24), Color(0.75, 0.95, 0.6, 0.75))
		"mourners":
			for i in 3:
				_mourner(Vector2(-16 + i * 16, 0), i)
		"clerk":
			_person(Color("6a6a72"), Color("4a4a52"), SKIN, Color("3a2a1a"))
			draw_rect(Rect2(-7, -36, 5, 3), Color(0.8, 0.9, 1.0, 0.7), false, 1.0)
			draw_rect(Rect2(1, -36, 5, 3), Color(0.8, 0.9, 1.0, 0.7), false, 1.0)
			draw_rect(Rect2(facing * 6.0 - 3, -22, 7, 9), Color("c8b89a"))
		"movers":
			for x: float in [-20.0, 20.0]:
				draw_set_transform(Vector2(x, 0))
				_person(Color("3a5a9a"), Color("2a3a6a"), SKIN, Color("1a1a1a"), 1.1)
			draw_set_transform(Vector2.ZERO)
		"augustine":
			_person(Color("1e2a4a"), Color("1e2a4a"), Color("d8a07a"), Color("2a1a10"))
			draw_rect(Rect2(-7, -44, 14, 5), Color("1e2a4a"))
			draw_rect(Rect2(-8, -40, 16, 2), Color("d4a62a"))
			draw_rect(Rect2(-6, -22, 12, 2), Color("d4a62a"))
		_:
			_draw_prop()


# A person in a coat, trousers and shoes, with a round head. size widens him; tall raises his head.
func _person(coat: Color, trousers: Color, skin: Color, hair: Color, size := 1.0, tall := 0.0) -> void:
	var half := 7.0 * size
	var step := sin(clock * 12.0) * 3.0 if walking else 0.0
	draw_line(Vector2(-3, -12), Vector2(-3 + step, 0), trousers, 4.0)
	draw_line(Vector2(3, -12), Vector2(3 - step, 0), trousers, 4.0)
	draw_rect(Rect2(-5 + step, -1, 5, 2), OUTLINE)
	draw_rect(Rect2(1 - step, -1, 5, 2), OUTLINE)
	var coat_rect := Rect2(-half, -28 - tall, half * 2.0, 17 + tall)
	draw_rect(coat_rect, coat)
	draw_rect(coat_rect, OUTLINE, false, 1.0)
	var head := Vector2(0, -HEAD_HEIGHT - tall)
	draw_circle(head, 6, skin)
	draw_arc(head, 6, 0, TAU, 16, OUTLINE, 1.0)
	draw_arc(head, 6, PI * 1.05, TAU - 0.05, 10, hair, 3.0)
	draw_circle(head + Vector2(facing * 2.5, 0), 0.9, OUTLINE)


func _draw_gerald() -> void:
	var step := sin(clock * 12.0) * 3.0 if walking else 0.0
	# Thin legs in plum trousers, brown shoes.
	draw_line(Vector2(-2, -14), Vector2(-2 + step, 0), GERALD_TROUSERS, 3.0)
	draw_line(Vector2(2, -14), Vector2(2 - step, 0), GERALD_TROUSERS, 3.0)
	draw_rect(Rect2(-4 + step, -1, 4, 2), Color("4a2a1a"))
	draw_rect(Rect2(1 - step, -1, 4, 2), Color("4a2a1a"))
	# A narrow tan cardigan with buttons, a little stooped the way he faces.
	var body := PackedVector2Array([Vector2(-5, -13), Vector2(5, -13), Vector2(5 + facing, -29), Vector2(-5 + facing, -29)])
	draw_colored_polygon(body, GERALD_CARDIGAN)
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[0]]), OUTLINE, 1.0)
	for y: float in [-26.0, -22.0, -18.0]:
		draw_circle(Vector2(facing * 0.5, y), 0.7, Color("5a3a1a"))
	draw_line(Vector2(-5 + facing, -28), Vector2(-7 + facing, -16), GERALD_CARDIGAN.darkened(0.15), 2.0)
	draw_line(Vector2(5 + facing, -28), Vector2(7 + facing, -16), GERALD_CARDIGAN.darkened(0.15), 2.0)
	# A long thin neck and an egg-shaped bald head, with three comb-over strands across the top.
	var head := Vector2(facing * 1.5, -38)
	draw_line(Vector2(facing, -29), head + Vector2(0, 5), GERALD_SKIN, 2.0)
	_ellipse(head, Vector2(5, 7), GERALD_SKIN)
	_ellipse_outline(head, Vector2(5, 7))
	for i in 3:
		var y := head.y - 6.0 + i * 1.5
		draw_line(Vector2(head.x - facing * 5.0, y + 1.0), Vector2(head.x + facing * 4.0, y), Color("8a8a80"), 1.0)
	# A long nose, a scowling brow and a down-turned mouth.
	draw_colored_polygon(PackedVector2Array([head + Vector2(facing * 4.0, -1), head + Vector2(facing * 8.0, 2), head + Vector2(facing * 4.0, 2)]), GERALD_SKIN.darkened(0.1))
	draw_line(head + Vector2(facing * 1.0, -3), head + Vector2(facing * 4.0, -1.5), OUTLINE, 1.0)
	draw_circle(head + Vector2(facing * 2.5, -0.5), 0.8, OUTLINE)
	draw_arc(head + Vector2(facing * 2.0, 5), 2.0, PI + 0.4, TAU - 0.4, 6, OUTLINE, 1.0)


func _mourner(at: Vector2, index: int) -> void:
	var height := 28.0 + index * 2.0
	draw_rect(Rect2(at + Vector2(-5, -height + 10), Vector2(10, height - 10)), Color("1a1a1e"))
	draw_circle(at + Vector2(0, -height + 6), 5, SKIN)
	draw_rect(Rect2(at + Vector2(-6, -height), Vector2(12, 4)), Color("1a1a1e"))
	draw_line(at + Vector2(-2, -height + 8), at + Vector2(-1, -height + 10), Color("6ab8e8"), 1.0)


func _cloud(at: Vector2, color: Color) -> void:
	for offset: Vector2 in [Vector2(0, 0), Vector2(6, -3), Vector2(10, 2), Vector2(4, 5)]:
		draw_circle(at + Vector2(offset.x * facing, offset.y), 5, color)


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _ellipse_outline(center: Vector2, radii: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 17:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(points, OUTLINE, 1.0)


func _paper(rect: Rect2, ink := true) -> void:
	draw_rect(rect, Color("f2ecd8"))
	draw_rect(rect, OUTLINE, false, 1.0)
	if ink:
		for i in int(rect.size.y / 3.0) - 1:
			draw_line(rect.position + Vector2(2, 3 + i * 3), rect.position + Vector2(rect.size.x - 2, 3 + i * 3), Color("8a8a96"), 1.0)


func _draw_prop() -> void:
	match id:
		"gavel":
			draw_line(Vector2(-6, -4), Vector2(4, -10), Color("a87a1a"), 2.0)
			draw_rect(Rect2(2, -15, 9, 6), Color("d4a62a"))
			draw_rect(Rect2(2, -15, 9, 6), OUTLINE, false, 1.0)
		"file":
			draw_rect(Rect2(-10, -8, 20, 8), Color("d8b86a"))
			draw_rect(Rect2(-10, -8, 20, 8), OUTLINE, false, 1.0)
			draw_rect(Rect2(-8, -10, 8, 2), Color("d8b86a"))
		"cheque":
			draw_rect(Rect2(-9, -6, 18, 7), Color("c8e8c8"))
			draw_rect(Rect2(-9, -6, 18, 7), OUTLINE, false, 1.0)
			draw_line(Vector2(-6, -2), Vector2(4, -2), Color("2a5a2a"), 1.0)
		"letter":
			_paper(Rect2(-6, -4, 12, 8), false)
			draw_line(Vector2(-6, -4), Vector2(0, 0), Color("8a8a96"), 1.0)
			draw_line(Vector2(6, -4), Vector2(0, 0), Color("8a8a96"), 1.0)
			draw_rect(Rect2(2, -3, 3, 2), Color("c8323a"))
		"wreath":
			draw_arc(Vector2(0, -8), 7, 0, TAU, 16, Color("2a6a2a"), 4.0)
			draw_circle(Vector2(0, -15), 2, Color("c8323a"))
			draw_circle(Vector2(-6, -4), 2, Color("ffffff"))
			draw_circle(Vector2(6, -4), 2, Color("ffffff"))
		"coffin_lid":
			draw_rect(Rect2(-37, -12, 74, 8), Color("7a4a22"))
			draw_rect(Rect2(-37, -12, 74, 8), OUTLINE, false, 1.0)
			draw_line(Vector2(-6, -8), Vector2(6, -8), Color("d4a62a"), 1.0)
			draw_line(Vector2(0, -11), Vector2(0, -5), Color("d4a62a"), 1.0)
		"grapes":
			for spot: Vector2 in [Vector2(-3, -6), Vector2(3, -6), Vector2(0, -3), Vector2(-2, -9), Vector2(2, -9), Vector2(0, -12)]:
				draw_circle(spot, 2.2, Color("7a3a9a"))
			draw_line(Vector2(0, -12), Vector2(1, -15), Color("3a6a2a"), 1.0)
		"grape":
			draw_circle(Vector2(0, -2), 2.2, Color("7a3a9a"))
		"photos":
			for i in 3:
				var rect := Rect2(Vector2(-14 + i * 10, -14 + (i % 2) * 2), Vector2(9, 7))
				draw_rect(rect, Color.WHITE)
				draw_rect(rect.grow(-1), [Color("8ab8e8"), Color("e8c86a"), Color("5a8a3a")][i])
				draw_rect(rect, OUTLINE, false, 1.0)
		"souvenirs":
			draw_rect(Rect2(-8, -12, 16, 12), Color("c8323a"))
			draw_rect(Rect2(-8, -12, 16, 12), OUTLINE, false, 1.0)
			draw_line(Vector2(-4, -12), Vector2(-4, -18), OUTLINE, 1.0)
			draw_line(Vector2(4, -12), Vector2(4, -18), OUTLINE, 1.0)
			draw_line(Vector2(-4, -18), Vector2(4, -18), OUTLINE, 1.0)
			draw_rect(Rect2(-10, -20, 4, 9), Color("e8c86a"))
			draw_circle(Vector2(6, -16), 3, Color("4fd8ff"))
		"garage_door":
			draw_rect(Rect2(-34, -98, 68, 98), Color("8a8a96"))
			for i in 8:
				draw_line(Vector2(-34, -98 + i * 12.25), Vector2(34, -98 + i * 12.25), Color("5a5a60"), 1.0)
			draw_rect(Rect2(-34, -98, 68, 98), OUTLINE, false, 1.0)
		"shirt":
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(10, -8), Vector2(6, -8), Vector2(6, 0), Vector2(-6, 0), Vector2(-6, -8), Vector2(-10, -8)]), GERALD_CARDIGAN)
		"boarding_pass":
			draw_rect(Rect2(-10, -6, 20, 8), Color("eef2f8"))
			draw_rect(Rect2(-10, -6, 20, 2), Color("2a3a6a"))
			draw_rect(Rect2(-10, -6, 20, 8), OUTLINE, false, 1.0)
		"torn_pass":
			for spot: Vector2 in [Vector2(-8, -4), Vector2(-2, -9), Vector2(5, -3), Vector2(9, -10)]:
				draw_rect(Rect2(spot, Vector2(5, 4)), Color("eef2f8"))
				draw_rect(Rect2(spot, Vector2(5, 4)), OUTLINE, false, 1.0)
		"monitor", "monitor_flat":
			var line := PackedVector2Array()
			for i in 18:
				var x := -18.0 + i * 2.0
				var y := -10.0
				if id == "monitor" and int(i + clock * 12.0) % 9 == 4:
					y = -17.0
				line.append(Vector2(x, y))
			draw_polyline(line, Color("7aff8a") if id == "monitor" else Color("ff6a4a"), 1.0)
		"sandwich":
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -1), Vector2(6, -1), Vector2(0, -7)]), Color("e8c88a"))
			draw_line(Vector2(-5, -2), Vector2(5, -2), Color("7aa84a"), 1.0)
			draw_polyline(PackedVector2Array([Vector2(-6, -1), Vector2(6, -1), Vector2(0, -7), Vector2(-6, -1)]), OUTLINE, 1.0)
		"ladder":
			draw_line(Vector2(-8, 0), Vector2(-4, -40), Color("b8b8c0"), 2.0)
			draw_line(Vector2(8, 0), Vector2(4, -40), Color("b8b8c0"), 2.0)
			for i in 5:
				var y := -6.0 - i * 8.0
				draw_line(Vector2(-7 + i * 0.8, y), Vector2(7 - i * 0.8, y), Color("8a8a96"), 2.0)
		"zzz":
			var font := ThemeDB.fallback_font
			for i in 3:
				var rise := fmod(clock * 6.0 + i * 5.0, 15.0)
				draw_string(font, Vector2(i * 4.0, -rise), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 8 + i * 2, Color(1, 1, 1, 1.0 - rise / 15.0))
		"baggage":
			# Every item he picked up, strapped to his back in a tower.
			var colors := [Color("c8323a"), Color("3a5a9a"), Color("d4a62a"), Color("5a8a3a"), Color("8a4fbf"), Color("e07a2a")]
			for i in 6:
				var rect := Rect2(Vector2(-12 + (i % 2) * 4, -16 - i * 9), Vector2(20 - (i % 3) * 3, 9))
				draw_rect(rect, colors[i])
				draw_rect(rect, OUTLINE, false, 1.0)
		"ticket":
			draw_rect(Rect2(-5, -8, 10, 6), Color("eeeeee"))
			draw_rect(Rect2(-5, -8, 10, 6), OUTLINE, false, 1.0)
		"spray":
			_cloud(Vector2.ZERO, Color(0.75, 0.95, 0.6, 0.75))
