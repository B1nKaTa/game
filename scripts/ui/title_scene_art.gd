class_name TitleSceneArt
extends Node2D

# The title screen's picture, drawn in code at the 640x360 view: the afterlife's Waiting Room, a line
# of shuffling old souls holding tickets with Grandpa among them, the "Take a Number" machine glowing
# at the back of the line and the NOW SERVING sign over the counter at its front.

const WALL := Color("1d1726")
const WALL_LOW := Color("241c30")
const TRIM := Color("3a2f48")
const FLOOR_A := Color("2a2133")
const FLOOR_B := Color("231b2b")
const FLOOR_TOP := 236.0
const TILE := 24.0
const FEET_Y := 262.0
const FRONT_X := 500.0
const SPACING := 38.0
const COUNTER := Rect2(540, 196, 100, 64)
const COUNTER_TOP := Color("6b4a32")
const COUNTER_FACE := Color("4a3324")
const SIGN := Rect2(528, 86, 104, 60)
const SIGN_BACK := Color("120e16")
const SIGN_EDGE := Color("5a4a6e")
const SIGN_TEXT := Color("ece9e0")
const NUMBER_COLOR := Color("ff5a40")
const MACHINE := Rect2(212, 206, 26, 56)
const MACHINE_BODY := Color("b8322c")
const MACHINE_GLOW := Color(1.0, 0.45, 0.3)
const TICKET := Color("f2ecd8")
const SOUL_COLORS: Array[Color] = [Color("9fb6c9"), Color("b7a6c9"), Color("a9c2b0"), Color("c9b9a2"), Color("a3a8c9"), Color("c2a3b1"), Color("b0bfc2")]
const SKIN := Color("e6cfb8")
const GRANDPA_CARDIGAN := Color("5d7a4a")
const GRANDPA_HAIR := Color("d9d9d9")
const GRANDPA_CAP := Color("6a5a48")
const CANE := Color("a8692f")
const OUTLINE := Color(0.05, 0.03, 0.07)

var queue := TitleQueue.new(41)
var _time := 0.0
var _last_served := -1


func _process(delta: float) -> void:
	_time += delta
	if queue.tick(delta):
		_last_served = queue.souls[-1]
	queue_redraw()


func _draw() -> void:
	_draw_room()
	_draw_counter()
	_draw_machine()
	var step := queue.shuffle()
	# Back to front, so nearer souls are drawn over the ones behind them.
	for i in range(queue.souls.size() - 1, -1, -1):
		var soul: int = queue.souls[i]
		var x := FRONT_X - i * SPACING + (1.0 - step) * -SPACING
		var alpha := 1.0
		if soul == _last_served:
			# The one just served takes a number again: they come in at the back from the machine.
			alpha = step
		_draw_soul(soul, Vector2(x, FEET_Y), alpha, i)
	if _last_served != -1 and step < 1.0:
		# Their old self walks on to the counter and fades.
		_draw_soul(_last_served, Vector2(FRONT_X + step * 30.0, FEET_Y), 1.0 - step, -1)
	_draw_sign()


func _draw_room() -> void:
	draw_rect(Rect2(0, 0, 640, FLOOR_TOP), WALL)
	draw_rect(Rect2(0, 170, 640, FLOOR_TOP - 170), WALL_LOW)
	draw_rect(Rect2(0, 168, 640, 3), TRIM)
	draw_rect(Rect2(0, FLOOR_TOP - 3, 640, 3), TRIM)
	var row := 0
	var y := FLOOR_TOP
	while y < 360.0:
		var x := -TILE if row % 2 == 1 else 0.0
		var column := 0
		while x < 640.0:
			draw_rect(Rect2(x, y, TILE, TILE / 2.0), FLOOR_A if (column + row) % 2 == 0 else FLOOR_B)
			x += TILE
			column += 1
		y += TILE / 2.0
		row += 1
	# Faint pools of light from lamps above the line.
	for lamp_x in [300.0, 420.0, 560.0]:
		for ring in 4:
			draw_circle(Vector2(lamp_x, FEET_Y + 4.0), 60.0 - ring * 12.0, Color(1.0, 0.9, 0.7, 0.025))
		draw_rect(Rect2(lamp_x - 12.0, 0, 24, 6), TRIM)
		draw_line(Vector2(lamp_x, 6), Vector2(lamp_x, 20), TRIM, 1.0)
		draw_circle(Vector2(lamp_x, 24), 5.0, Color(1.0, 0.92, 0.7, 0.8))


func _draw_counter() -> void:
	draw_rect(COUNTER, COUNTER_FACE)
	draw_rect(Rect2(COUNTER.position - Vector2(6, 6), Vector2(COUNTER.size.x + 6, 8)), COUNTER_TOP)
	draw_rect(Rect2(COUNTER.position + Vector2(10, 16), Vector2(64, 30)), COUNTER_TOP.darkened(0.3), false, 1.0)


func _draw_sign() -> void:
	draw_line(SIGN.position + Vector2(18, 0), Vector2(SIGN.position.x + 18, 0), TRIM, 1.0)
	draw_line(SIGN.position + Vector2(SIGN.size.x - 18, 0), Vector2(SIGN.position.x + SIGN.size.x - 18, 0), TRIM, 1.0)
	draw_rect(SIGN, SIGN_BACK)
	draw_rect(SIGN, SIGN_EDGE, false, 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, SIGN.position + Vector2(0, 16), tr("NOW SERVING"), HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 10, SIGN_TEXT)
	var number := "%03d" % queue.now_serving
	var glow := NUMBER_COLOR
	glow.a = 0.25
	draw_string(font, SIGN.position + Vector2(1, 49), number, HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 30, glow)
	draw_string(font, SIGN.position + Vector2(0, 48), number, HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 30, NUMBER_COLOR)


func _draw_machine() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 2.4)
	for ring in 5:
		var glow := MACHINE_GLOW
		glow.a = 0.035 + 0.02 * pulse
		draw_circle(MACHINE.get_center() + Vector2(0, -8), 44.0 - ring * 8.0, glow)
	draw_rect(Rect2(MACHINE.position.x + 10, MACHINE.position.y + 30, 6, MACHINE.size.y - 30), Color("3a3a42"))
	draw_rect(Rect2(MACHINE.position, Vector2(MACHINE.size.x, 34)), MACHINE_BODY)
	draw_rect(Rect2(MACHINE.position, Vector2(MACHINE.size.x, 34)), OUTLINE, false, 1.0)
	draw_rect(Rect2(MACHINE.position + Vector2(5, 22), Vector2(16, 3)), OUTLINE)
	# A ticket hangs from the slot.
	draw_rect(Rect2(MACHINE.position + Vector2(9, 25), Vector2(8, 7 + pulse * 2.0)), TICKET)
	var font := ThemeDB.fallback_font
	draw_string(font, MACHINE.position + Vector2(-20, -6), tr("TAKE A NUMBER"), HORIZONTAL_ALIGNMENT_CENTER, MACHINE.size.x + 40, 8, Color(1.0, 0.85, 0.7, 0.6 + 0.4 * pulse))


# One soul standing at its feet, facing the counter. place is its spot in line, or -1 for one leaving.
func _draw_soul(soul: int, feet: Vector2, alpha: float, place: int) -> void:
	if alpha <= 0.0:
		return
	var sway := sin(_time * 1.6 + soul * 1.3) * 1.2
	var moving := queue.shuffle() < 1.0 and place >= 0
	var bob := absf(sin(_time * 10.0)) * 1.5 if moving else 0.0
	var top := feet + Vector2(sway, -bob)
	if soul == TitleQueue.GRANDPA:
		_draw_grandpa(top, alpha)
		return
	var body := SOUL_COLORS[soul % SOUL_COLORS.size()]
	body.a = 0.85 * alpha
	var height := 30.0 + (soul % 3) * 3.0
	var hunch := 2.0 + (soul % 2) * 2.0
	var robe := PackedVector2Array([
		top + Vector2(-9, 0), top + Vector2(9, 0),
		top + Vector2(6 + hunch, -height), top + Vector2(-5 + hunch, -height),
	])
	var line := OUTLINE
	line.a = alpha
	draw_colored_polygon(robe, body)
	draw_polyline(robe + PackedVector2Array([robe[0]]), line, 1.0)
	var head := top + Vector2(1.0 + hunch, -height - 6.0)
	var face := body.lightened(0.25)
	draw_circle(head, 6.0, face)
	draw_arc(head, 6.0, 0, TAU, 16, line, 1.0)
	draw_circle(head + Vector2(3, -1), 1.0, line)
	_draw_ticket(top + Vector2(9 + hunch * 0.5, -height * 0.55), alpha)


func _draw_grandpa(top: Vector2, alpha: float) -> void:
	var line := OUTLINE
	line.a = alpha
	var cardigan := GRANDPA_CARDIGAN
	cardigan.a = alpha
	var trousers := Color("4a4a58", alpha)
	draw_rect(Rect2(top + Vector2(-6, -12), Vector2(12, 12)), trousers)
	var chest := PackedVector2Array([top + Vector2(-8, -11), top + Vector2(8, -11), top + Vector2(9, -27), top + Vector2(-5, -27)])
	draw_colored_polygon(chest, cardigan)
	draw_polyline(chest + PackedVector2Array([chest[0]]), line, 1.0)
	var head := top + Vector2(3, -33)
	var skin := SKIN
	skin.a = alpha
	draw_circle(head, 6.5, skin)
	draw_arc(head, 6.5, 0, TAU, 16, line, 1.0)
	var hair := GRANDPA_HAIR
	hair.a = alpha
	draw_rect(Rect2(head + Vector2(-7, -1), Vector2(4, 5)), hair)
	draw_rect(Rect2(head + Vector2(1, 3), Vector2(6, 3)), hair)
	var cap := GRANDPA_CAP
	cap.a = alpha
	draw_rect(Rect2(head + Vector2(-7, -8), Vector2(13, 5)), cap)
	draw_rect(Rect2(head + Vector2(3, -5), Vector2(6, 2)), cap)
	draw_circle(head + Vector2(4, -1), 1.0, line)
	var cane := CANE
	cane.a = alpha
	draw_line(top + Vector2(12, -16), top + Vector2(14, 0), cane, 2.0)
	draw_line(top + Vector2(9, -17), top + Vector2(13, -17), cane, 2.0)
	_draw_ticket(top + Vector2(-9, -18), alpha)


func _draw_ticket(at: Vector2, alpha: float) -> void:
	var paper := TICKET
	paper.a = alpha
	draw_rect(Rect2(at, Vector2(5, 7)), paper)
	draw_line(at + Vector2(1, 2), at + Vector2(4, 2), Color(0.3, 0.2, 0.2, alpha * 0.8), 1.0)
