class_name LensBeam
extends Node2D

# The Projectionist's lens beam: the projector's light, thrown out from where he stands like a
# searchlight, sweeping across the room through a set arc. The whole arc it will cross is tinted red
# for its whole windup, with the line it starts on outlined twice, as the heaviest attack's are, and
# filling; then the bright beam turns across the arc, the part still to cross staying tinted. Feet in
# the beam as it passes cost three pills, once. It lies where he stood as it began and turns about
# that point, and comes to nothing if he falls first.
const LENGTH := 340.0
const WIDTH := 26.0
const ARC_DEG := 100.0
const SWEEP_TIME := 2.2
# How far apart, at the beam's far end, the circles of one time slice of a plan lie.
const SLICE_ARC := 18.0
const CIRCLE_STEP := 18.0
const FADE := 0.25
const COLOR := Color("e4524f")
const LIGHT := Color(1.0, 0.96, 0.76, 0.62)
const LIGHT_CORE := Color(1.0, 1.0, 0.92, 0.85)
const LENS := Color(1.0, 0.98, 0.85)

var _source: Enemy
var _start := 0.0
var _turn := 0.0
var _warning := 1.2
var _left := 1.2
var _swept := 0.0
var _fade_left := FADE
var _damage := -1
var _has_hit := false


# The beam's angle a time into its sweep, from start turning through turn (radians, signed).
static func angle_at(start: float, turn: float, time: float) -> float:
	return start + turn * clampf(time / SWEEP_TIME, 0.0, 1.0)


# Whether a point lies in the beam from origin at angle.
static func covers(origin: Vector2, angle: float, point: Vector2) -> bool:
	var offset := point - origin
	var way := Vector2.from_angle(angle)
	var along := offset.dot(way)
	return along >= 0.0 and along <= LENGTH and absf(offset.dot(way.orthogonal())) <= WIDTH / 2.0


# Whether a beam turning from one angle to another passes over a point: the point is in reach and its
# angle lies between them, or the beam's width covers it at either end. However long a frame takes,
# nothing is skipped.
static func swept_over(origin: Vector2, from_angle: float, to_angle: float, point: Vector2) -> bool:
	if covers(origin, from_angle, point) or covers(origin, to_angle, point):
		return true
	var offset := point - origin
	var distance := offset.length()
	if distance > LENGTH or distance < 1.0:
		return false
	var turned := angle_difference(from_angle, to_angle)
	var at := angle_difference(from_angle, offset.angle())
	if turned >= 0.0:
		return at >= 0.0 and at <= turned
	return at <= 0.0 and at >= turned


# How much of its sweep still lies ahead of a point, as an angle: 0 when the beam is on it, negative
# once it has passed. For a point outside the arc, INF.
static func angle_ahead(origin: Vector2, angle_now: float, end_angle: float, point: Vector2) -> float:
	var offset := point - origin
	if offset.length() > LENGTH + WIDTH:
		return INF
	var to_end := angle_difference(angle_now, end_angle)
	var to_point := angle_difference(angle_now, offset.angle())
	var margin := (WIDTH / 2.0) / maxf(offset.length(), 1.0)
	if to_end >= 0.0:
		if to_point < -margin or to_point > to_end + margin:
			return INF
		return to_point
	if to_point > margin or to_point < to_end - margin:
		return INF
	return -to_point


# The beam sampled for OverlapRoute: in each time slice, circles along the beam where it lies then,
# each hurting for its slice. delay counts from now to the sweep's start. Returns [Vector3, Vector2]
# pairs: a circle (x, y, radius) and the window it hurts in.
static func plan_circles(origin: Vector2, start: float, turn: float, delay: float) -> Array:
	var shapes: Array = []
	var slices := maxi(ceili(absf(turn) * LENGTH / SLICE_ARC), 1)
	var slice_time := SWEEP_TIME / slices
	var radius := WIDTH / 2.0 + CIRCLE_STEP / 2.0
	for k in slices + 1:
		var way := Vector2.from_angle(start + turn * k / float(slices))
		var at := delay + k * slice_time
		var window := Vector2(at - slice_time * 0.5, at + slice_time * 0.5)
		var along := CIRCLE_STEP / 2.0
		while along <= LENGTH + CIRCLE_STEP / 2.0:
			var spot := origin + way * minf(along, LENGTH)
			shapes.append([Vector3(spot.x, spot.y, radius), window])
			along += CIRCLE_STEP
	return shapes


func setup(source: Enemy, start: float, turn: float, warning: float, damage := -1) -> void:
	_source = source
	_start = start
	_turn = turn
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_warning() -> bool:
	return _left > 0.0


func is_sweeping() -> bool:
	return _left <= 0.0 and _swept < SWEEP_TIME


func is_over() -> bool:
	return _left <= 0.0 and _swept >= SWEEP_TIME


func angle_now() -> float:
	return angle_at(_start, _turn, _swept)


func end_angle() -> float:
	return _start + _turn


func start_angle() -> float:
	return _start


func turn() -> float:
	return _turn


# How far the warning has filled, from 0 to 1.
func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)


# Its shapes for a plan made now: the rest of its sweep, from where it is.
func route_circles() -> Array:
	if is_over():
		return []
	var from := angle_now()
	var left_turn := end_angle() - from
	var shapes := plan_circles(global_position, from, left_turn, maxf(_left, 0.0))
	# A sweep partly done runs its remaining slices over the time it has left.
	if _left <= 0.0 and absf(_turn) > 0.0:
		var share := absf(left_turn / _turn)
		for shape: Array in shapes:
			var window: Vector2 = shape[1]
			shape[1] = window * share
	return shapes


# Moves the beam on. Returns the angles it turned between this time, or an empty array.
func advance(delta: float) -> Array:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0:
			return []
		delta = -_left
		_left = 0.0
	if _swept >= SWEEP_TIME:
		return []
	var before := angle_at(_start, _turn, _swept)
	_swept += delta
	return [before, angle_at(_start, _turn, _swept)]


# What it means for a point, for a simulated player: 2 anywhere the beam has still to cross.
func threat_at(p: Vector2, strict: bool) -> int:
	if is_over():
		return 0
	var margin := 12.0 if strict else 4.0
	var ahead := angle_ahead(global_position, angle_now(), end_angle(), p)
	if ahead == INF:
		return 2 if covers(global_position, angle_now(), p) else 0
	return 2 if ahead >= -margin / maxf(p.distance_to(global_position), 1.0) else 0


func threat_imminent(p: Vector2) -> bool:
	if is_warning():
		return _left < 0.12 and covers(global_position, _start, p)
	if not is_sweeping():
		return false
	var ahead := angle_ahead(global_position, angle_now(), end_angle(), p)
	return ahead != INF and ahead * p.distance_to(global_position) < 34.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if is_over():
		_fade_left -= delta
		if _fade_left <= 0.0:
			queue_free()
		return
	var turned := advance(delta)
	if turned.is_empty() or _has_hit or not is_instance_valid(_source.target):
		return
	if swept_over(global_position, turned[0], turned[1], _source.target_ground()):
		if _source.target.take_hit(_source.attack_damage(_damage)):
			_has_hit = true


func _sector(from: float, to: float, reach: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var steps := maxi(int(absf(to - from) / 0.06), 2)
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(from, to, i / float(steps))) * reach)
	return points


func _draw() -> void:
	if is_over():
		var fade := clampf(_fade_left / FADE, 0.0, 1.0)
		_draw_beam(end_angle(), fade)
		return
	var now := angle_now()
	var end := end_angle()
	# All it has still to cross shows, so the warning reads wherever he stands.
	if absf(end - now) > 0.01:
		var sector := _sector(now, end, LENGTH)
		draw_colored_polygon(sector, Color(COLOR, 0.1 + (0.12 * fill() if is_warning() else 0.06)))
		var edge := _sector(now, end, LENGTH)
		edge.append(Vector2.ZERO)
		draw_polyline(edge, Color(COLOR, 0.55), 1.0)
	if is_warning():
		# The line it starts on fills as any warned lane, with the heaviest attack's second outline.
		var progress := fill()
		draw_set_transform(Vector2.ZERO, _start)
		draw_rect(Rect2(0.0, -WIDTH / 2.0, LENGTH * progress, WIDTH), Color(COLOR, 0.15 + 0.3 * progress))
		draw_rect(Rect2(0.0, -WIDTH / 2.0, LENGTH, WIDTH), COLOR, false, 2.0)
		draw_rect(Rect2(0.0, -WIDTH / 2.0, LENGTH, WIDTH).grow(Enemy.HEAVIEST_LANE_GAP), COLOR, false, 2.0)
		draw_set_transform(Vector2.ZERO)
		draw_circle(Vector2.ZERO, 6.0 + 4.0 * progress, Color(LENS, 0.5 + 0.5 * progress))
		return
	_draw_beam(now, 1.0)


func _draw_beam(angle: float, alpha: float) -> void:
	draw_set_transform(Vector2.ZERO, angle)
	var beam := Rect2(0.0, -WIDTH / 2.0, LENGTH, WIDTH)
	draw_rect(beam, Color(LIGHT, LIGHT.a * alpha))
	draw_rect(Rect2(0.0, -WIDTH / 6.0, LENGTH, WIDTH / 3.0), Color(LIGHT_CORE, LIGHT_CORE.a * alpha))
	draw_rect(beam, Color(COLOR, alpha), false, 2.0)
	draw_rect(beam.grow(Enemy.HEAVIEST_LANE_GAP), Color(COLOR, 0.6 * alpha), false, 2.0)
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO, 9.0, Color(LENS, alpha))
