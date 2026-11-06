class_name SeanceCircle
extends Node2D

# Madame Zara's second phase, the seance circle: the candles go out but for a wide ring of light round a
# point that drifts slowly through her room, and the rest of the room goes dim, not black. Spirits circle
# just outside the ring, and whenever Grandpa's feet stand outside it one swoops at him: a warned strike
# on his spot (SpiritSwoop) that costs a pill only if he is still outside the light when it lands. So the
# light is where he is safe from them, and it keeps moving.
#
# It differs from Matron Mercy's Lights Out on purpose: that light rides on him, 70 px wide in a room
# 0.85 dark; this one drifts on its own, is LIGHT_RADIUS wide, and the room around it is only DIM dark.
# Warnings, shots and marks draw above it, as they draw above Lights Out. It goes out when she falls.
const Z := LightsOut.Z
const LIGHT_RADIUS := 120.0
const DIM := 0.5
const CLEAR_SHARE := 0.8
const DRIFT_SPEED := 12.0
# How far inside the room's edge the light's middle keeps.
const INSET := 64.0
const SPIRITS := 4
const SPIRIT_GAP := 26.0
const SPIRIT_TURN := 0.7
# How long his feet may stand outside before the first swoop, and the time between swoops.
const FIRST_SWOOP := 0.5
const SWOOP_EVERY := 1.6
const FADE_IN := 0.8
const FADE_OUT := 0.6
const REACH := 4000.0
const RING := Color(1.0, 0.82, 0.5, 0.75)
const SPIRIT := Color(0.85, 0.8, 1.0, 0.7)

var _source: Enemy
var _room := Rect2()
var _center := Vector2.ZERO
var _goal := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _age := 0.0
var _out := false
var _fade_left := FADE_OUT
var _outside_for := 0.0
var _swoop_wait := 0.0
var _swoop: SpiritSwoop
var _spin := 0.0
var _hole: GradientTexture2D


# How dark the room outside the light is at a moment: fading in, held at DIM, fading out.
static func shade_at(age: float, out_for := -1.0) -> float:
	var shade := DIM * clampf(age / FADE_IN, 0.0, 1.0)
	if out_for >= 0.0:
		shade *= clampf(1.0 - out_for / FADE_OUT, 0.0, 1.0)
	return shade


static func in_light(center: Vector2, point: Vector2) -> bool:
	return point.distance_to(center) <= LIGHT_RADIUS


# The middle moved toward a goal at the drift speed over delta.
static func drifted(center: Vector2, goal: Vector2, delta: float) -> Vector2:
	return center.move_toward(goal, DRIFT_SPEED * delta)


# Where the light's middle may go: the room, kept INSET from its edge (or its middle, if too small).
static func drift_area(room: Rect2) -> Rect2:
	var inner := room.grow(-INSET)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return Rect2(room.get_center(), Vector2.ZERO)
	return inner


# For a plan looking horizon seconds ahead: cells wholly inside the light however it drifts meanwhile.
static func open_within(center: Vector2, horizon: float, base := Callable()) -> Callable:
	return LineTether.open_within(center, maxf(LIGHT_RADIUS - DRIFT_SPEED * horizon, 0.0), base)


func setup(source: Enemy, room: Rect2, start: Vector2, seed_value := 0) -> void:
	_source = source
	_room = room
	var area := drift_area(room)
	_center = start.clamp(area.position, area.end)
	_rng.seed = seed_value
	_goal = _pick_goal()
	z_index = Z


func center() -> Vector2:
	return _center


func light_radius() -> float:
	return LIGHT_RADIUS


func is_out() -> bool:
	return _out


func current_shade() -> float:
	return shade_at(_age, FADE_OUT - _fade_left if _out else -1.0)


func open_test(horizon: float, base := Callable()) -> Callable:
	return open_within(_center, horizon, base)


func covers(point: Vector2) -> bool:
	return in_light(_center, point)


func _pick_goal() -> Vector2:
	var area := drift_area(_room)
	return Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))


# Moves the light on, and says whether a spirit swoops at feet now (Vector2.INF for no feet).
func advance(delta: float, feet: Vector2) -> bool:
	_age += delta
	_spin += SPIRIT_TURN * delta
	if _out:
		_fade_left -= delta
		return false
	_center = drifted(_center, _goal, delta)
	if _center.distance_to(_goal) < 2.0:
		_goal = _pick_goal()
	_swoop_wait = maxf(_swoop_wait - delta, 0.0)
	if feet == Vector2.INF or covers(feet):
		_outside_for = 0.0
		return false
	_outside_for += delta
	if _outside_for < FIRST_SWOOP or _swoop_wait > 0.0 or (is_instance_valid(_swoop) and not _swoop.is_spent()):
		return false
	_swoop_wait = SWOOP_EVERY
	return true


func put_out() -> void:
	_out = true


# Where a spirit circles now, the first nearest a point.
func spirit_spots() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for i in SPIRITS:
		spots.append(_center + Vector2.from_angle(_spin + TAU * i / SPIRITS) * (LIGHT_RADIUS + SPIRIT_GAP))
	return spots


# For a simulated player: outside the light is a coming hit while the spirits circle.
func threat_at(p: Vector2, strict: bool) -> int:
	if _out:
		return 0
	var margin := 12.0 if strict else 4.0
	return 2 if p.distance_to(_center) > LIGHT_RADIUS - margin else 0


func threat_imminent(_p: Vector2) -> bool:
	return false


func _ready() -> void:
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0, 0, 0, 1))
	gradient.add_point(CLEAR_SHARE, Color(0, 0, 0, 0))
	_hole = GradientTexture2D.new()
	_hole.gradient = gradient
	_hole.width = 128
	_hole.height = 128
	_hole.fill = GradientTexture2D.FILL_RADIAL
	_hole.fill_from = Vector2(0.5, 0.5)
	_hole.fill_to = Vector2(1.0, 0.5)


func _process(delta: float) -> void:
	queue_redraw()
	if not _out and (not is_instance_valid(_source) or _source.is_dead()):
		put_out()
	var feet := Vector2.INF
	if not _out and is_instance_valid(_source) and is_instance_valid(_source.target):
		feet = _source.target_ground()
	if advance(delta, feet):
		_send_swoop(feet)
	if _out and _fade_left <= 0.0:
		queue_free()


func _send_swoop(feet: Vector2) -> void:
	if get_parent() == null:
		return
	var from := spirit_spots()
	from.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(feet) < b.distance_to(feet))
	_swoop = SpiritSwoop.new()
	_swoop.setup(_source, self, feet, from[0])
	get_parent().add_child(_swoop)
	_swoop.global_position = Vector2.ZERO


func _draw() -> void:
	var shade := current_shade()
	var center := to_local(_center)
	var lit := is_instance_valid(_source) and LightsOut.kept_lit(_source.target)
	if shade > 0.0 and not lit and _hole != null:
		var edge := LIGHT_RADIUS
		var square := Rect2(center - Vector2(edge, edge), Vector2(edge, edge) * 2.0)
		draw_texture_rect(_hole, square, false, Color(1, 1, 1, shade))
		var dark := Color(0, 0, 0, shade)
		draw_rect(Rect2(square.position.x - REACH, square.position.y - REACH, REACH * 2.0 + square.size.x, REACH), dark)
		draw_rect(Rect2(square.position.x - REACH, square.end.y, REACH * 2.0 + square.size.x, REACH), dark)
		draw_rect(Rect2(square.position.x - REACH, square.position.y, REACH, square.size.y), dark)
		draw_rect(Rect2(square.end.x, square.position.y, REACH, square.size.y), dark)
	var alpha := clampf(_age / FADE_IN, 0.0, 1.0) * (clampf(_fade_left / FADE_OUT, 0.0, 1.0) if _out else 1.0)
	# The ring's candle-warm edge, so the light's reach reads even where the dark is faint.
	draw_arc(center, LIGHT_RADIUS, 0.0, TAU, 72, Color(RING, RING.a * alpha), 2.0)
	for spot in spirit_spots():
		var at := to_local(spot)
		draw_circle(at, 6.0, Color(SPIRIT, SPIRIT.a * alpha))
		draw_circle(at + Vector2(-2.0, -1.0), 1.2, Color(0.1, 0.08, 0.2, alpha))
		draw_circle(at + Vector2(2.0, -1.0), 1.2, Color(0.1, 0.08, 0.2, alpha))
		draw_circle(at + Vector2(0.0, 7.0), 3.5, Color(SPIRIT, SPIRIT.a * 0.5 * alpha))
