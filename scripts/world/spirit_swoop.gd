class_name SpiritSwoop
extends Node2D

# A spirit of Madame Zara's seance circle swooping at Grandpa while he stands outside the light: a red
# ring on his spot fills for WARNING while the spirit flies in from where it circled, then it strikes.
# Feet in the ring cost a pill, but only if they are still outside the light: stepping into the light,
# or out of the ring, is the way out. It lies at the room's origin and comes to nothing if she falls.
const RADIUS := 22.0
const WARNING := 0.8
const DAMAGE := 1
const HIT_TIME := 0.05
const SHOW_TIME := 0.3
const COLOR := Color("e4524f")
const SPIRIT := Color(0.85, 0.8, 1.0, 0.85)

var _source: Enemy
var _circle: SeanceCircle
var _spot := Vector2.ZERO
var _from := Vector2.ZERO
var _warning := WARNING
var _left := WARNING
var _landed := false
var _show_left := SHOW_TIME
var _damage := DAMAGE


func setup(source: Enemy, circle: SeanceCircle, spot: Vector2, from: Vector2, warning := WARNING, damage := DAMAGE) -> void:
	_source = source
	_circle = circle
	_spot = spot
	_from = from
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func spot() -> Vector2:
	return _spot


func has_landed() -> bool:
	return _landed


func is_spent() -> bool:
	return _landed


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)


func _lit(point: Vector2) -> bool:
	return is_instance_valid(_circle) and not _circle.is_out() and _circle.covers(point)


# Whether feet at a point are struck: in the ring, and outside the light.
func strikes(feet: Vector2) -> bool:
	return feet.distance_to(_spot) <= RADIUS and not _lit(feet)


func route_circles() -> Array:
	if _landed:
		return []
	return [[Vector3(_spot.x, _spot.y, RADIUS), Vector2(_left, _left + HIT_TIME)]]


# Moves it on. Returns true once, on the moment it strikes.
func advance(delta: float) -> bool:
	if _landed:
		_show_left -= delta
		return false
	_left -= delta
	if _left <= 0.0:
		_landed = true
		return true
	return false


func threat_at(p: Vector2, strict: bool) -> int:
	if _landed or _lit(p):
		return 0
	return 2 if p.distance_to(_spot) <= RADIUS + (12.0 if strict else 4.0) else 0


func threat_imminent(p: Vector2) -> bool:
	return not _landed and _left < 0.12 and p.distance_to(_spot) <= RADIUS + 4.0 and not _lit(p)


func _process(delta: float) -> void:
	queue_redraw()
	if not _landed and (not is_instance_valid(_source) or _source.is_dead()):
		queue_free()
		return
	if advance(delta) and is_instance_valid(_source) and is_instance_valid(_source.target):
		if strikes(_source.target_ground()):
			_source.target.take_hit(_source.attack_damage(_damage))
	if _landed and _show_left <= 0.0:
		queue_free()


func _draw() -> void:
	var at := _spot - global_position
	if not _landed:
		var progress := fill()
		draw_circle(at, RADIUS * progress, Color(COLOR, 0.15 + 0.3 * progress))
		draw_arc(at, RADIUS, 0.0, TAU, 24, COLOR, 2.0)
		# The spirit flying in from its place round the light.
		var spirit := (_from - global_position).lerp(at, progress * progress)
		draw_circle(spirit, 6.0, SPIRIT)
		draw_line(spirit, spirit.lerp(_from - global_position, 0.25), Color(SPIRIT, 0.4), 3.0)
		return
	var shown := clampf(_show_left / SHOW_TIME, 0.0, 1.0)
	draw_circle(at, RADIUS, Color(SPIRIT, 0.45 * shown))
	draw_arc(at, RADIUS, 0.0, TAU, 24, Color(COLOR, shown), 2.0)
