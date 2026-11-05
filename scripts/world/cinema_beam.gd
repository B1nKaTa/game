class_name CinemaBeam
extends Node2D

# The projector's beam: a faint warm wedge of light from a port in the south wall up to the screen,
# with dust drifting in it. It lies at a z between the floor's flat things and the bodies, and stays
# faint, so nothing standing in it is ever harder to see. When the screen is cut to black the
# projector is off, and the beam goes with it.
const Z := -7
const PORT_HALF_WIDTH := 3.0
# The wedge's brightness at the port and at the screen, before the room's dim light.
const ALPHA_AT_PORT := 0.16
const ALPHA_AT_SCREEN := 0.05
const MOTES := 18
const MOTE_ALPHA := 0.45
const MOTE_DRIFT := 9.0

var palette: RoomPalette
var _screen: CinemaScreen
var _port := Vector2.ZERO
var _top_left := Vector2.ZERO
var _top_right := Vector2.ZERO
var _time := 0.0


# The beam runs from a port in the middle of the south wall, below the picture, up to the picture's
# bottom edge.
func setup(screen: CinemaScreen, picture: Rect2, room_size: Vector2) -> void:
	_screen = screen
	_port = Vector2(picture.get_center().x, room_size.y - RoomBackdrop.TILE * 0.5)
	_top_left = Vector2(picture.position.x + 6.0, picture.end.y)
	_top_right = Vector2(picture.end.x - 6.0, picture.end.y)


func _ready() -> void:
	z_as_relative = false
	z_index = Z
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	if palette == null:
		palette = RoomPalette.new()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


# A point inside the wedge for a share of the way up (0 at the port) and a share across (0 to 1).
func spot_in_beam(up: float, across: float) -> Vector2:
	var left := _port.lerp(_top_left, up) - Vector2(PORT_HALF_WIDTH * (1.0 - up), 0.0)
	var right := _port.lerp(_top_right, up) + Vector2(PORT_HALF_WIDTH * (1.0 - up), 0.0)
	return left.lerp(right, across)


func strength() -> float:
	if _screen == null or not is_instance_valid(_screen):
		return 1.0
	return 1.0 - _screen.darkness()


func _draw() -> void:
	var on := strength()
	if on <= 0.01:
		return
	var warm := palette.projector_beam
	var flicker := 0.92 + 0.08 * sin(_time * 23.0) * sin(_time * 7.0)
	var at_port := Color(warm, ALPHA_AT_PORT * on * flicker)
	var at_screen := Color(warm, ALPHA_AT_SCREEN * on * flicker)
	var points := PackedVector2Array([_port + Vector2(-PORT_HALF_WIDTH, 0), _port + Vector2(PORT_HALF_WIDTH, 0), _top_right, _top_left])
	draw_polygon(points, PackedColorArray([at_port, at_port, at_screen, at_screen]))
	# The port glows in the south wall.
	draw_rect(Rect2(_port - Vector2(5, 3), Vector2(10, 6)), Color(warm, 0.5 * on))
	# Dust drifting slowly up the beam, each mote on its own slow wander.
	for i in MOTES:
		var rise := fposmod(i * 0.137 + _time * (0.012 + 0.004 * (i % 3)), 1.0)
		var across := 0.5 + 0.42 * sin(i * 2.3 + _time * 0.3 + rise * 3.0)
		var at := spot_in_beam(0.08 + rise * 0.9, across) + Vector2(sin(_time * 0.7 + i) * MOTE_DRIFT * 0.3, 0.0)
		var twinkle := 0.5 + 0.5 * sin(_time * 1.3 + i * 1.7)
		draw_rect(Rect2(at, Vector2.ONE), Color(warm, MOTE_ALPHA * twinkle * on))
