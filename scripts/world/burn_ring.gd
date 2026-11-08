class_name BurnRing
extends Node2D

# The film catching fire in the Projectionist's second phase: a hole burns slowly out from the screen
# across the floor in front of it, a white ring of burning edge round a scorched inside. Standing inside
# burns Grandpa as fire does, a pill every BURN_EVERY, so the house shrinks toward the back rows. It
# grows to a cap that always leaves most of the room, and goes out when he falls. The screen shows the
# same burn (CinemaScreen.set_burning). It lies at the ring's middle, at the screen's foot.
const GROW_SPEED := 6.0
const MOST := 240.0
# The ring never grows past this share of the room's height.
const ROOM_SHARE := 0.5
const BURN_EVERY := 0.8
const DAMAGE := 1
const FADE := 0.6
const EDGE_WIDTH := 6.0
const SCORCH := Color(0.06, 0.03, 0.02, 0.6)
const EMBER := Color(1.0, 0.55, 0.15, 0.55)
const EDGE := Color(1.0, 0.98, 0.92)
const EDGE_GLOW := Color(1.0, 0.75, 0.35, 0.6)
const SCORCH_Z := -6

var _source: Enemy
var _cap := MOST
var _radius := 0.0
var _burn_wait := 0.0
var _fade_left := FADE
var _out := false
var _edge: Node2D


# How far the burn reaches after a time, for a room of this height.
static func radius_after(time: float, cap: float) -> float:
	return minf(GROW_SPEED * time, cap)


static func cap_for(room_height: float) -> float:
	return minf(MOST, room_height * ROOM_SHARE)


static func burns(center: Vector2, radius: float, feet: Vector2) -> bool:
	return feet.distance_to(center) <= radius


func setup(source: Enemy, cap: float) -> void:
	_source = source
	_cap = cap
	z_index = SCORCH_Z
	z_as_relative = false


# Carries on a burn laid again after its room was left, from the reach it had.
func resume(reach: float) -> void:
	_radius = clampf(reach, 0.0, _cap)


func _ready() -> void:
	_edge = Node2D.new()
	_edge.z_as_relative = false
	_edge.z_index = Projectile.SHOT_Z
	_edge.draw.connect(_draw_edge)
	add_child(_edge)


func radius() -> float:
	return _radius


func cap() -> float:
	return _cap


# How far it has burnt toward its cap, from 0 to 1, for the screen.
func progress() -> float:
	return clampf(_radius / maxf(_cap, 1.0), 0.0, 1.0)


# Grows it, and says whether a burn is due on feet at point.
func advance(delta: float, point: Vector2) -> bool:
	_radius = minf(_radius + GROW_SPEED * delta, _cap)
	_burn_wait = maxf(_burn_wait - delta, 0.0)
	if _burn_wait > 0.0 or not burns(global_position, _radius, point):
		return false
	_burn_wait = BURN_EVERY
	return true


# Its shape for a plan looking ahead horizon seconds: the circle it will have reached by then.
func route_circles(horizon := 4.0) -> Array:
	if _out:
		return []
	var reach := minf(_radius + GROW_SPEED * horizon, _cap)
	return [[Vector3(global_position.x, global_position.y, reach), Vector2(0.0, horizon)]]


func threat_at(p: Vector2, strict: bool) -> int:
	if _out:
		return 0
	var distance := p.distance_to(global_position)
	if distance <= _radius + (8.0 if strict else 3.0):
		return 2
	return 1 if distance <= _radius + 28.0 and _radius < _cap else 0


func threat_imminent(p: Vector2) -> bool:
	return not _out and p.distance_to(global_position) <= _radius + 5.0


func _process(delta: float) -> void:
	queue_redraw()
	if _edge != null:
		_edge.queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		_out = true
	if _out:
		_fade_left -= delta
		if _fade_left <= 0.0:
			queue_free()
		return
	var feet := _source.target_ground() if is_instance_valid(_source.target) else Vector2.INF
	if advance(delta, feet):
		var target := _source.target
		if target.has_method("take_fire_hit"):
			target.take_fire_hit(DAMAGE)
		else:
			target.take_hit(DAMAGE)
	var screen := CinemaScreen.in_room(get_parent()) if get_parent() != null else null
	if screen != null:
		screen.set_burning(progress())


func _alpha() -> float:
	return clampf(_fade_left / FADE, 0.0, 1.0) if _out else 1.0


func _draw() -> void:
	if _radius <= 0.5:
		return
	var alpha := _alpha()
	# Only the half in front of the screen shows: the rest lies in the wall.
	draw_colored_polygon(_half_disc(_radius), Color(SCORCH, SCORCH.a * alpha))
	draw_colored_polygon(_half_disc(maxf(_radius - 4.0, 1.0)), Color(EMBER, 0.12 * alpha))


static func _half_disc(reach: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 33:
		points.append(Vector2.from_angle(PI * i / 32.0) * reach)
	return points


func _draw_edge() -> void:
	if _radius <= 0.5:
		return
	var alpha := _alpha()
	var flicker := 0.85 + 0.15 * sin(Time.get_ticks_msec() / 90.0)
	_edge.draw_arc(Vector2.ZERO, _radius + 2.0, 0.0, PI, 48, Color(EDGE_GLOW, EDGE_GLOW.a * alpha * flicker), EDGE_WIDTH + 4.0)
	_edge.draw_arc(Vector2.ZERO, _radius, 0.0, PI, 48, Color(EDGE, alpha), EDGE_WIDTH)
	_edge.draw_arc(Vector2.ZERO, _radius - EDGE_WIDTH / 2.0 - 1.0, 0.0, PI, 48, Color(Enemy.WARNING_COLOR, 0.8 * alpha), 1.5)
