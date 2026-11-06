class_name ScytheSweep
extends Node2D

# Death, Sister Celestine's heavy card: a scythe sweeps through a marked arc, a sector out from where
# she stands toward Grandpa. The whole sector is tinted and outlined twice, filling, for its whole
# warning; then the blade sweeps from one edge to the other, and feet the blade passes over cost two
# pills, once. It lies where she stood and comes to nothing if she falls first.
const RADIUS := 110.0
const HALF_ARC := PI * 45.0 / 180.0
const SWEEP_TIME := 0.3
const FADE := 0.3
const COLOR := Color("e4524f")
const BLADE := Color("e9e4dc")
const BLADE_EDGE := Color("3a3540")
const SNATH := Color("5b4334")
# The scythe's picture (art/props/scythe.png): butt at its left, blade at its right curving down, its
# shaft along its middle row, drawn along the sweep line from the centre and mirrored to bend the way
# it sweeps. It must turn to any angle, so it is the one picture drawn turned; the drawing stays for
# when it is missing.
const ART := "scythe"
# The heavier attack's second outline stands this far outside the first.
const SECOND_RING_GAP := 6.0
# How far beside the blade's line feet still count as passed over.
const BLADE_SPARE := 6.0
# The sector as a plan sees it: circles this far apart over it, each this big.
const ROUTE_STEP := 14.0
const ROUTE_RADIUS := 13.0

var _source: Enemy
var _aim := 0.0
var _clockwise := true
var _warning := 1.0
var _left := 1.0
var _swept := 0.0
var _fade_left := FADE
var _damage := -1
var _has_hit := false


# Whether a point lies in the sector from origin, aim its middle, margin grown all round.
static func in_sector(origin: Vector2, aim: float, point: Vector2, margin := 0.0) -> bool:
	var offset := point - origin
	var distance := offset.length()
	if distance > RADIUS + margin:
		return false
	if distance < 1.0:
		return true
	return absf(angle_difference(aim, offset.angle())) <= HALF_ARC + margin / distance


# How far through the sweep, as an angle from the edge it starts on, the blade reaches a point's angle.
static func sweep_angle_of(origin: Vector2, aim: float, clockwise: bool, point: Vector2) -> float:
	var off := angle_difference(aim, (point - origin).angle())
	return HALF_ARC + (off if clockwise else -off)


# Whether the blade, turning from swept angle from_a to to_a, passes over a point in the sector.
static func swept_over(origin: Vector2, aim: float, clockwise: bool, from_a: float, to_a: float, point: Vector2) -> bool:
	if not in_sector(origin, aim, point):
		return false
	var at := sweep_angle_of(origin, aim, clockwise, point)
	var spare := BLADE_SPARE / maxf(origin.distance_to(point), 1.0)
	return at >= from_a - spare and at <= to_a + spare


func setup(source: Enemy, aim: float, warning: float, damage := -1, clockwise := true) -> void:
	_source = source
	_aim = aim
	_clockwise = clockwise
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func aim() -> float:
	return _aim


func damage() -> int:
	return _damage


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)


func is_warning() -> bool:
	return _left > 0.0


func is_sweeping() -> bool:
	return _left <= 0.0 and _swept < SWEEP_TIME


func is_spent() -> bool:
	return _left <= 0.0 and _swept >= SWEEP_TIME


func covers(point: Vector2, margin := 0.0) -> bool:
	return in_sector(global_position, _aim, point, margin)


func _blade_angle(time: float) -> float:
	return HALF_ARC * 2.0 * clampf(time / SWEEP_TIME, 0.0, 1.0)


# Moves it on; returns whether the blade passed over the point in this step.
func advance(delta: float, point: Vector2) -> bool:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0:
			return false
		delta = -_left
	if _swept >= SWEEP_TIME:
		_fade_left -= delta
		return false
	var from_a := _blade_angle(_swept)
	_swept += delta
	var to_a := _blade_angle(_swept)
	if _has_hit:
		return false
	if swept_over(global_position, _aim, _clockwise, from_a, to_a, point):
		_has_hit = true
		return true
	return false


# What it means for a point, for a simulated player: 2 where the blade has still to pass, 1 beside it.
func threat_at(p: Vector2, strict: bool) -> int:
	if is_spent():
		return 0
	if is_sweeping() and covers(p) and sweep_angle_of(global_position, _aim, _clockwise, p) < _blade_angle(_swept) - 0.2:
		return 0
	if covers(p, 10.0 if strict else 4.0):
		return 2
	return 1 if covers(p, 24.0) else 0


func threat_imminent(p: Vector2) -> bool:
	if is_spent():
		return false
	return (_left < 0.12 or is_sweeping()) and covers(p, 4.0)


# Its shapes for a plan made now: circles over the whole sector, hurting while the blade sweeps.
func route_circles() -> Array:
	if is_spent():
		return []
	var start := maxf(_left, 0.0)
	var window := Vector2(start, start + SWEEP_TIME - minf(_swept, SWEEP_TIME) + 0.05)
	var shapes: Array = []
	var origin := global_position
	var distance := ROUTE_STEP * 0.5
	while distance <= RADIUS + ROUTE_STEP * 0.5:
		var reach := minf(distance, RADIUS)
		var steps := maxi(ceili(reach * HALF_ARC * 2.0 / ROUTE_STEP), 1)
		for i in steps + 1:
			var angle := _aim - HALF_ARC + HALF_ARC * 2.0 * i / steps
			var at := origin + Vector2.from_angle(angle) * reach
			shapes.append([Vector3(at.x, at.y, ROUTE_RADIUS), window])
		distance += ROUTE_STEP
	return shapes


func _process(delta: float) -> void:
	queue_redraw()
	if is_spent():
		_fade_left -= delta
		if _fade_left <= 0.0:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	var feet := _source.target_ground() if is_instance_valid(_source.target) else Vector2.INF
	if advance(delta, feet):
		_source.hit_target(_source.attack_damage(_damage))


func _sector(radius: float, from_angle: float, to_angle: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var steps := 20
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(from_angle, to_angle, float(i) / steps)) * radius)
	return points


func _draw() -> void:
	var low := _aim - HALF_ARC
	var high := _aim + HALF_ARC
	var start_edge := low if _clockwise else high
	var sign_way := 1.0 if _clockwise else -1.0
	if is_spent():
		var fade := clampf(_fade_left / FADE, 0.0, 1.0)
		draw_colored_polygon(_sector(RADIUS, low, high), Color(BLADE, 0.12 * fade))
		return
	if _left > 0.0:
		var filled := fill()
		draw_colored_polygon(_sector(RADIUS, low, high), Color(COLOR, 0.1 + 0.25 * filled))
		var edge := _sector(RADIUS, low, high)
		edge.append(Vector2.ZERO)
		draw_polyline(edge, COLOR, 2.0)
		# Death costs two pills, so its arc is outlined twice.
		draw_arc(Vector2.ZERO, RADIUS + SECOND_RING_GAP, low, high, 20, COLOR, 1.5)
		# The part the blade will cross first fills first, from the edge it starts on.
		var reach := HALF_ARC * 2.0 * filled
		if reach > 0.01:
			draw_colored_polygon(_sector(RADIUS, start_edge, start_edge + reach * sign_way), Color(COLOR, 0.18))
		# The scythe waits on the starting edge.
		_draw_blade(start_edge, 0.6)
		return
	# Sweeping: the part still to cross stays tinted, the blade swings across.
	var at := start_edge + _blade_angle(_swept) * sign_way
	var rest := _sector(RADIUS, at, start_edge + HALF_ARC * 2.0 * sign_way)
	draw_colored_polygon(rest, Color(COLOR, 0.25))
	draw_colored_polygon(_sector(RADIUS, start_edge, at), Color(BLADE, 0.18))
	_draw_blade(at, 1.0)


func _draw_blade(angle: float, alpha: float) -> void:
	var art := PropArt.texture(ART)
	if art != null:
		draw_set_transform(Vector2.ZERO, angle, Vector2(1.0, -1.0 if _clockwise else 1.0))
		draw_texture(art, Vector2(0.0, -floorf(art.get_height() / 2.0)), Color(1, 1, 1, alpha))
		draw_set_transform(Vector2.ZERO)
		return
	var way := Vector2.from_angle(angle)
	var side := way.orthogonal() * (1.0 if _clockwise else -1.0)
	draw_line(Vector2.ZERO, way * RADIUS, Color(SNATH, alpha), 3.0)
	# A curved blade at the far end, bending toward the way it will sweep.
	var blade := PackedVector2Array()
	for i in 7:
		var t := i / 6.0
		blade.append(way * (RADIUS - t * 34.0) + side * sin(t * PI * 0.9) * 12.0)
	draw_polyline(blade, Color(BLADE_EDGE, alpha), 5.0)
	draw_polyline(blade, Color(BLADE, alpha), 3.0)
