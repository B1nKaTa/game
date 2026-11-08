class_name WheelRing
extends Node2D

# The Wheel, Sister Celestine's third card: a ring of blades round her, which spins. The band it turns
# in is tinted and its blades outlined, filling, for the whole warning before it starts to turn; then
# it spins for SPIN_TIME, and feet a blade passes over cost a pill, once. The blades leave gaps between
# them, and the band leaves her a clear inside and the room a clear outside, so a step out of the band
# either way is always a way out. It lies where she stands and comes to nothing if she falls first.
const INNER := 36.0
const OUTER := 84.0
const BLADES := 3
const BLADE_ARC := PI * 70.0 / 180.0
# Radians a second, either way round.
const SPIN_SPEED := 2.0
const SPIN_TIME := 2.0
const FADE := 0.25
const COLOR := Color("e4524f")
const BLADE := Color("f2d27a")
const BLADE_EDGE := Color("5a3d12")
const HUB := Color("f2d27a")
# The band as a plan sees it: circles this far apart round its middle, each this much wider than half
# the band.
const ROUTE_STEP := 10.0
const ROUTE_SPARE := 3.0

var _source: Enemy
var _warning := 1.0
var _left := 1.0
var _spun := 0.0
var _start_angle := 0.0
var _turn_way := 1.0
var _fade_left := FADE
var _damage := -1
var _has_hit := false


static func in_band(center: Vector2, point: Vector2, margin := 0.0) -> bool:
	var distance := center.distance_to(point)
	return distance >= INNER - margin and distance <= OUTER + margin


# Whether a point lies under a blade when the wheel stands at this angle.
static func under_blade(center: Vector2, angle: float, point: Vector2, margin := 0.0) -> bool:
	if not in_band(center, point, margin):
		return false
	var spare := margin / maxf(center.distance_to(point), 1.0)
	var off := fposmod((point - center).angle() - angle, TAU)
	for i in BLADES:
		var from_a := TAU * i / BLADES
		var rel := fposmod(off - from_a + spare, TAU)
		if rel <= BLADE_ARC + spare * 2.0:
			return true
	return false


func setup(source: Enemy, warning: float, start_angle := 0.0, clockwise := true, damage := -1) -> void:
	_source = source
	_warning = warning
	_left = warning
	_start_angle = start_angle
	_turn_way = 1.0 if clockwise else -1.0
	_damage = damage
	z_index = Projectile.SHOT_Z


func damage() -> int:
	return _damage


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)


func is_warning() -> bool:
	return _left > 0.0


func is_spinning() -> bool:
	return _left <= 0.0 and _spun < SPIN_TIME


func is_spent() -> bool:
	return _left <= 0.0 and _spun >= SPIN_TIME


func angle() -> float:
	return _start_angle + _turn_way * SPIN_SPEED * minf(_spun, SPIN_TIME)


# Moves it on; returns whether a blade passed over the point in this step.
func advance(delta: float, point: Vector2) -> bool:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0:
			return false
		delta = -_left
	if _spun >= SPIN_TIME:
		_fade_left -= delta
		return false
	var before := angle()
	_spun += delta
	if _has_hit:
		return false
	# However long the step, check the turn it covered a few times over, so a blade never skips him.
	var after := angle()
	var checks := maxi(ceili(absf(after - before) / 0.1), 1)
	for i in checks + 1:
		if under_blade(global_position, lerpf(before, after, float(i) / checks), point):
			_has_hit = true
			return true
	return false


# What it means for a point, for a simulated player: 2 anywhere in the band while it is warned (every
# point of it is swept), and under a blade or just ahead of one while it spins; 1 in a gap.
func threat_at(p: Vector2, strict: bool) -> int:
	if is_spent():
		return 0
	var margin := 8.0 if strict else 3.0
	if is_warning():
		if in_band(global_position, p, margin):
			return 2
		return 1 if in_band(global_position, p, 18.0) else 0
	var ahead := angle() + _turn_way * SPIN_SPEED * 0.25
	if under_blade(global_position, angle(), p, margin) or under_blade(global_position, ahead, p, margin):
		return 2
	return 1 if in_band(global_position, p, 18.0) else 0


func threat_imminent(p: Vector2) -> bool:
	if is_spent():
		return false
	if is_warning():
		return _left < 0.12 and in_band(global_position, p, 3.0)
	return under_blade(global_position, angle() + _turn_way * SPIN_SPEED * 0.12, p, 3.0)


# Its shapes for a plan made now: circles round the band's middle, hurting for the whole spin.
func route_circles() -> Array:
	if is_spent():
		return []
	var start := maxf(_left, 0.0)
	var window := Vector2(start, start + SPIN_TIME - minf(_spun, SPIN_TIME) + 0.05)
	var middle := (INNER + OUTER) / 2.0
	var radius := (OUTER - INNER) / 2.0 + ROUTE_SPARE
	var steps := ceili(TAU * middle / ROUTE_STEP)
	var shapes: Array = []
	for i in steps:
		var at := global_position + Vector2.from_angle(TAU * i / steps) * middle
		shapes.append([Vector3(at.x, at.y, radius), window])
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


func _blade_points(from_angle: float, to_angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 10
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(from_angle, to_angle, float(i) / steps)) * OUTER)
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(to_angle, from_angle, float(i) / steps)) * INNER)
	return points


func _draw() -> void:
	var at := angle()
	var fade := clampf(_fade_left / FADE, 0.0, 1.0) if is_spent() else 1.0
	var red := AttackWarnings.drawn_by(_source)
	if is_warning() and red:
		var filled := fill()
		# The whole band it turns in, tinted and edged, so the clear inside and outside both read.
		draw_arc(Vector2.ZERO, (INNER + OUTER) / 2.0, 0.0, TAU, 48, Color(COLOR, 0.08 + 0.12 * filled), OUTER - INNER)
		draw_arc(Vector2.ZERO, INNER, 0.0, TAU, 40, COLOR, 1.5)
		draw_arc(Vector2.ZERO, OUTER, 0.0, TAU, 48, COLOR, 2.0)
	elif is_warning():
		# Warnings hidden (AttackWarnings): the band's edges and the blades as the faint dark cue.
		var cue := AttackWarnings.cue_color(fill())
		draw_arc(Vector2.ZERO, INNER, 0.0, TAU, 40, cue, AttackWarnings.CUE_LINE)
		draw_arc(Vector2.ZERO, OUTER, 0.0, TAU, 48, cue, AttackWarnings.CUE_LINE)
	for i in BLADES:
		var from_a := at + TAU * i / BLADES
		var blade := _blade_points(from_a, from_a + BLADE_ARC)
		if is_warning() and not red:
			AttackWarnings.draw_cue_polygon(self, blade, maxf(fill(), 0.8))
		elif is_warning():
			draw_colored_polygon(blade, Color(COLOR, 0.15 + 0.3 * fill()))
			var outline := blade.duplicate()
			outline.append(blade[0])
			draw_polyline(outline, COLOR, 2.0)
		else:
			draw_colored_polygon(blade, Color(BLADE, 0.55 * fade))
			var outline := blade.duplicate()
			outline.append(blade[0])
			draw_polyline(outline, Color(BLADE_EDGE, fade), 2.0)
			# Spokes back to her, a wheel's.
			draw_line(Vector2.from_angle(from_a + BLADE_ARC * 0.5) * 12.0, Vector2.from_angle(from_a + BLADE_ARC * 0.5) * INNER, Color(BLADE, 0.6 * fade), 2.0)
	if not is_warning():
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 16, Color(HUB, 0.7 * fade), 2.0)
