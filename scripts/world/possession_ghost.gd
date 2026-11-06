class_name PossessionGhost
extends Node2D

# Madame Zara's Possession: a ghostly copy of Grandpa walks his last two seconds of movement again.
# First the way it will walk shows for its warning, a dotted red trail of his steps with a red ring
# where it rises, the copy itself faint at the start. Then it walks the trail at the pace he walked it,
# and for the rest of its LIFE walks it back to where it rose, so it never jumps and everywhere it goes
# was shown. It is a pale violet copy at half alpha with wisps and a red ring round its feet, so it is
# never taken for him. Touching it costs a pill, once a touch: it hurts again only after his feet have
# left it. It lies at the room's origin, holds its trail in room space, and goes if she falls.
const LIFE := 4.0
const REACH := 12.0
const DAMAGE := 1
const COLOR := Color("e4524f")
const GHOST := Color(0.78, 0.62, 1.0, 0.5)
const GHOST_EDGE := Color(0.95, 0.9, 1.0, 0.6)
const WISP := Color(0.85, 0.75, 1.0, 0.35)
const FADE := 0.35
# How many trail points the planner's circles stand apart, and how much spare their windows get.
const ROUTE_EVERY := 2

var _source: Enemy
var _trail := PackedVector2Array()
var _step := 0.05
var _warning := 0.7
var _left := 0.7
var _time := 0.0
var _damage := DAMAGE
var _touching := false
var _hits := 0
var _fade_left := FADE
var _sprite: Sprite2D


# How long one pass of the trail takes.
static func pass_time(trail: PackedVector2Array, step: float) -> float:
	return maxf(trail.size() - 1, 0) * step


# Where the copy stands a time after it starts walking: along the trail at his pace, then back along
# it, and so on, for as long as it lasts.
static func ghost_at(trail: PackedVector2Array, step: float, time: float) -> Vector2:
	if trail.is_empty():
		return Vector2.ZERO
	var one := pass_time(trail, step)
	if one <= 0.0:
		return trail[0]
	var into := fposmod(maxf(time, 0.0), one * 2.0)
	if into > one:
		into = one * 2.0 - into
	var at := into / step
	var index := mini(floori(at), trail.size() - 2)
	return trail[index].lerp(trail[index + 1], clampf(at - index, 0.0, 1.0))


# The walk sampled for OverlapRoute: a circle on every ROUTE_EVERY-th moment of its walk, hurting a
# little either side of when the copy passes. delay counts from now to its first step; from is how far
# into its walk it already is. Returns [Vector3, Vector2] pairs.
static func plan_circles(trail: PackedVector2Array, step: float, delay: float, from := 0.0) -> Array:
	var shapes: Array = []
	if trail.is_empty():
		return shapes
	var every := step * ROUTE_EVERY
	var time := from
	while time <= LIFE + 0.001:
		var spot := ghost_at(trail, step, time)
		# Grown by as far as the copy walks either side of the moment, so its window holds it.
		var reach := REACH
		for k in range(-ROUTE_EVERY, ROUTE_EVERY + 1):
			reach = maxf(reach, REACH + spot.distance_to(ghost_at(trail, step, time + k * step)))
		shapes.append([Vector3(spot.x, spot.y, reach), Vector2(delay + time - from - every, delay + time - from + every)])
		time += every
	return shapes


func setup(source: Enemy, trail: PackedVector2Array, step: float, warning: float, damage := DAMAGE) -> void:
	_source = source
	_trail = trail
	_step = step
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z
	# His own look this frame, when his art has loaded, tinted and faded; otherwise an outline.
	if source != null and is_instance_valid(source.target) and source.target.has_method("afterimage_sprite"):
		_sprite = source.target.afterimage_sprite()
		if _sprite != null:
			_sprite.modulate = GHOST
			_sprite.position = -Player.FEET_OFFSET
			add_child(_sprite)


func trail() -> PackedVector2Array:
	return _trail


func is_warning() -> bool:
	return _left > 0.0


func is_walking() -> bool:
	return _left <= 0.0 and _time < LIFE


func is_over() -> bool:
	return _left <= 0.0 and _time >= LIFE


func is_spent() -> bool:
	return is_over()


func walked() -> float:
	return _time


func hits() -> int:
	return _hits


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)


# Where the copy's feet are now.
func now_at() -> Vector2:
	return ghost_at(_trail, _step, _time)


func route_circles() -> Array:
	if is_over():
		return []
	return plan_circles(_trail, _step, maxf(_left, 0.0), _time)


# Moves it on, and says whether feet at a point are touched for a new hit.
func advance(delta: float, feet: Vector2) -> bool:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0:
			return false
		delta = -_left
		_left = 0.0
	if _time >= LIFE:
		return false
	_time = minf(_time + delta, LIFE)
	var touching := feet.distance_to(now_at()) <= REACH
	var hit := touching and not _touching
	_touching = touching
	if hit:
		_hits += 1
	return hit


func threat_at(p: Vector2, strict: bool) -> int:
	if is_over():
		return 0
	var margin := 12.0 if strict else 4.0
	var time := _time
	# Anywhere it will walk in the next second and a half.
	while time <= minf(_time + 1.5, LIFE):
		if p.distance_to(ghost_at(_trail, _step, time)) <= REACH + margin:
			return 2
		time += _step
	return 0


func threat_imminent(p: Vector2) -> bool:
	if is_over():
		return false
	if is_warning():
		return _left < 0.12 and p.distance_to(now_at()) < REACH + 20.0
	return p.distance_to(now_at()) < REACH + 16.0 or p.distance_to(ghost_at(_trail, _step, _time + 0.15)) < REACH + 6.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if is_over():
		_fade_left -= delta
		if _sprite != null:
			_sprite.modulate.a = GHOST.a * clampf(_fade_left / FADE, 0.0, 1.0)
		if _fade_left <= 0.0:
			queue_free()
		return
	var feet: Vector2 = _source.target_ground() if is_instance_valid(_source.target) else Vector2.INF
	var at := now_at()
	if _sprite != null:
		_sprite.global_position = at - Player.FEET_OFFSET
		if _trail.size() > 1:
			var ahead := ghost_at(_trail, _step, _time + _step)
			if absf(ahead.x - at.x) > 0.2:
				_sprite.flip_h = ahead.x < at.x
	if advance(delta, feet) and is_instance_valid(_source.target):
		_source.target.take_hit(_source.attack_damage(_damage))


func _draw() -> void:
	var alpha := clampf(_fade_left / FADE, 0.0, 1.0) if is_over() else 1.0
	var at := now_at() - global_position
	if is_warning():
		# The way it will walk: his steps as a dotted red trail, filling, and a ring where it rises.
		var progress := fill()
		var stride := maxi(int(0.15 / _step), 1)
		for k in range(0, _trail.size(), stride):
			draw_circle(_trail[k] - global_position, 3.0, Color(COLOR, 0.35 + 0.5 * progress))
		var points := PackedVector2Array()
		for spot in _trail:
			points.append(spot - global_position)
		if points.size() > 1:
			draw_polyline(points, Color(COLOR, 0.25 + 0.3 * progress), 2.0)
		draw_arc(at, REACH + 6.0, 0.0, TAU, 20, COLOR, 2.0)
		draw_circle(at, (REACH + 6.0) * progress, Color(COLOR, 0.18))
	elif not is_over():
		# What it has still to walk in the next second, faint.
		var ahead := PackedVector2Array()
		var time := _time
		while time <= minf(_time + 1.0, LIFE):
			ahead.append(ghost_at(_trail, _step, time) - global_position)
			time += _step
		if ahead.size() > 1:
			draw_polyline(ahead, Color(COLOR, 0.35), 2.0)
	# The copy itself: faint while it waits to rise, then its red ring round the feet.
	var shown := (0.35 if is_warning() else 1.0) * alpha
	draw_arc(at, REACH, 0.0, TAU, 20, Color(COLOR, 0.85 * shown), 2.0)
	if _sprite == null:
		_draw_placeholder(at, shown)
	for i in 3:
		var drift := Time.get_ticks_msec() / 260.0 + i * 2.1
		draw_circle(at + Vector2(cos(drift) * 8.0, -6.0 - i * 9.0 + sin(drift) * 2.0), 3.0 - i * 0.6, Color(WISP, WISP.a * shown))


# Without his art: a pale, see-through stoop with a cane, the outline of a man and not a body.
func _draw_placeholder(feet: Vector2, alpha: float) -> void:
	var body := Rect2(feet + Vector2(-8.0, -36.0), Vector2(16.0, 24.0))
	draw_rect(body, Color(GHOST, GHOST.a * alpha))
	draw_rect(body, Color(GHOST_EDGE, GHOST_EDGE.a * alpha), false, 1.0)
	draw_circle(feet + Vector2(0.0, -42.0), 6.0, Color(GHOST, GHOST.a * alpha))
	draw_arc(feet + Vector2(0.0, -42.0), 6.0, 0.0, TAU, 12, Color(GHOST_EDGE, GHOST_EDGE.a * alpha), 1.0)
	draw_line(feet + Vector2(9.0, -22.0), feet + Vector2(11.0, -1.0), Color(GHOST_EDGE, GHOST_EDGE.a * alpha), 2.0)
	draw_rect(Rect2(feet + Vector2(-7.0, -12.0), Vector2(14.0, 10.0)), Color(GHOST, GHOST.a * 0.6 * alpha))
