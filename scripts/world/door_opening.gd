class_name DoorOpening
extends Node2D

# How a door in a wall looks (Door): a gap two cells wide through the whole wall, with a jamb each side,
# the floor running on into darkness beyond, and a gate of iron bars across it while the room is shut.
# The gate rises into the dark when the way opens (Door.gate). A small sign hangs in the gap naming the
# room type beyond (DoorSign); a plain fight room shows none. Drawn on the walls' layer, under every
# body, and only again when the door's state or gate changes. Every floor draws its doors this way: the
# depth look gives its own stone, the others their palette's wall and floor.
#
# Drawn for a north door, in a frame where up is out of the room; other sides turn that frame.
const HALF_WIDTH := 32.0
# From the door cell's middle: the wall's inner face, and how far the dark runs past the wall.
const INNER := 16.0
const OUTER := 72.0
const JAMB_WIDTH := 6.0
const BAR_SPACING := 8.0
const BAR_TRAVEL := 40.0
const SIGN_AT := 40.0
const IRON := Color("2a2730")
const IRON_LIGHT := Color("6b6570")
const LOCK_GOLD := Color("e2b33c")
const LOCK_EDGE := Color("6a4b10")
const OUTLINE := Color(0.02, 0.02, 0.03)

var door: Door


func _ready() -> void:
	z_as_relative = false
	z_index = -9


func _frame_angle() -> float:
	match door.side():
		RoomLayout.SOUTH:
			return PI
		RoomLayout.WEST:
			return -PI / 2.0
		RoomLayout.EAST:
			return PI / 2.0
	return 0.0


func _floor_color() -> Color:
	if door.depth != null:
		return door.depth.ground_color
	return door.palette.floor_a if door.palette != null else Color("6a6677")


func _darkness() -> Color:
	return door.palette.darkness if door.palette != null else Color(0.04, 0.03, 0.05)


func _jamb_colors() -> Array[Color]:
	if door.depth != null:
		return [DepthLook.JAMB, DepthLook.JAMB_LIGHT, DepthLook.JAMB_DARK]
	var wall := door.palette.wall if door.palette != null else Color("3a3547")
	return [wall.lightened(0.12), wall.lightened(0.32), wall.darkened(0.45)]


func _draw() -> void:
	if door == null:
		return
	draw_set_transform(Vector2.ZERO, _frame_angle())
	_draw_gap()
	_draw_gate()
	_draw_jambs()
	draw_set_transform(Vector2.ZERO)
	_draw_sign()


# The floor carries on through the wall and fades to black in four bands.
func _draw_gap() -> void:
	var floor_color := _floor_color()
	var dark := _darkness()
	draw_rect(Rect2(-HALF_WIDTH, -OUTER - 8.0, HALF_WIDTH * 2.0, OUTER + 8.0 - INNER), dark)
	var shades := [0.9, 0.62, 0.4, 0.22]
	for band in shades.size():
		var y := -INNER - (band + 1) * 8.0
		draw_rect(Rect2(-HALF_WIDTH, y, HALF_WIDTH * 2.0, 8.0), dark.lerp(floor_color, shades[band]))
	# The threshold, worn lighter, and the dark line where the room's floor meets it.
	draw_rect(Rect2(-HALF_WIDTH + JAMB_WIDTH, -INNER - 2.0, HALF_WIDTH * 2.0 - JAMB_WIDTH * 2.0, 2.0), floor_color.lightened(0.08))


func _draw_jambs() -> void:
	var colors := _jamb_colors()
	for sign_x in [-1.0, 1.0]:
		var outer_x: float = sign_x * HALF_WIDTH
		var x := minf(outer_x, outer_x - sign_x * JAMB_WIDTH)
		var rect := Rect2(x, -OUTER, JAMB_WIDTH, OUTER - INNER)
		draw_rect(rect, colors[0])
		# The side that faces the gap catches the light; the stone courses show as dark lines.
		var lit_x: float = rect.end.x - 1.0 if sign_x < 0 else rect.position.x
		draw_rect(Rect2(lit_x, rect.position.y, 1.0, rect.size.y), colors[1])
		for course in range(int(-OUTER) + 6, int(-INNER), 7):
			draw_rect(Rect2(rect.position.x, course, JAMB_WIDTH, 1.0), colors[2])
		draw_rect(rect, OUTLINE, false, 1.0)
	# The jambs' feet, where the gap meets the room.
	draw_rect(Rect2(-HALF_WIDTH, -INNER - 1.0, JAMB_WIDTH, 1.0), OUTLINE)
	draw_rect(Rect2(HALF_WIDTH - JAMB_WIDTH, -INNER - 1.0, JAMB_WIDTH, 1.0), OUTLINE)


# Iron bars with two cross rails, raised by the gate's share into the dark beyond the wall.
func _draw_gate() -> void:
	var risen := door.gate()
	if risen >= 1.0:
		return
	var bottom := -INNER - risen * BAR_TRAVEL
	var top := bottom - (OUTER - INNER - 8.0)
	var clip_top := -OUTER + 2.0
	var x := -HALF_WIDTH + JAMB_WIDTH + 2.0
	while x < HALF_WIDTH - JAMB_WIDTH - 2.0:
		var y0 := maxf(top, clip_top)
		if bottom > y0:
			draw_rect(Rect2(x, y0, 2.0, bottom - y0), IRON)
			draw_rect(Rect2(x, y0, 1.0, bottom - y0), IRON_LIGHT)
			draw_rect(Rect2(x - 1.0, bottom - 2.0, 4.0, 2.0), IRON)
		x += BAR_SPACING
	for rail in [bottom - 8.0, top + 10.0]:
		if rail > clip_top:
			draw_rect(Rect2(-HALF_WIDTH + JAMB_WIDTH, rail, (HALF_WIDTH - JAMB_WIDTH) * 2.0, 3.0), IRON)
			draw_rect(Rect2(-HALF_WIDTH + JAMB_WIDTH, rail, (HALF_WIDTH - JAMB_WIDTH) * 2.0, 1.0), IRON_LIGHT)
	if door.chained:
		var a := Vector2(-HALF_WIDTH + JAMB_WIDTH, -OUTER + 6.0)
		var b := Vector2(HALF_WIDTH - JAMB_WIDTH, -INNER - 4.0)
		for ends in [[a, b], [Vector2(b.x, a.y), Vector2(a.x, b.y)]]:
			draw_line(ends[0], ends[1], PathSign.CHAIN_EDGE, 4.0)
			draw_line(ends[0], ends[1], PathSign.CHAIN_COLOR, 2.0)
	elif door.requires_key and not door.locked:
		# A padlock on the bars: the way opens with a Permission Slip.
		var at := Vector2(0, bottom - 16.0)
		draw_arc(at + Vector2(0, -3), 3.0, PI, TAU, 8, LOCK_EDGE, 2.0)
		draw_rect(Rect2(at + Vector2(-4, -2), Vector2(8, 7)), LOCK_EDGE)
		draw_rect(Rect2(at + Vector2(-3, -1), Vector2(6, 5)), LOCK_GOLD)
		draw_rect(Rect2(at + Vector2(-1, 0), Vector2(2, 2)), LOCK_EDGE)


# The sign stays upright whatever wall the door is in.
func _draw_sign() -> void:
	var out := Vector2(door.side())
	DoorSign.draw(self, out * SIGN_AT, door.icon())
