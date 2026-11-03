class_name SteamJet
extends Node2D

# A jet of steam along a straight lane. With a warning it first shows the lane filling red, as an
# enemy's lane does, then blows for a moment: Grandpa's feet anywhere in the lane cost a pill once.
# It comes to nothing if the enemy that started it falls before it blows.
const BLOW_TIME := 0.35
const COLOR := Color("e4524f")
const STEAM := Color(0.93, 0.95, 1.0, 0.8)
const STEAM_EDGE := Color(0.75, 0.8, 0.9, 0.55)
const PUFF_GAP := 12.0

var _source: Enemy
var _direction := Vector2.RIGHT
var _length := 100.0
var _width := 18.0
var _warning := 0.0
var _left := 0.0
var _blow_left := BLOW_TIME
var _damage := -1
var _has_hit := false


# Whether a point lies in a lane that starts at origin and runs length along direction.
static func lane_hits(origin: Vector2, direction: Vector2, length: float, width: float, point: Vector2) -> bool:
	var offset := point - origin
	var along := offset.dot(direction)
	var side := absf(offset.dot(direction.orthogonal()))
	return along >= 0.0 and along <= length and side <= width / 2.0


# The jet sits at the lane's start. A damage of -1 costs the enemy's usual damage.
func setup(source: Enemy, direction: Vector2, length: float, width: float, warning := 0.0, damage := -1) -> void:
	_source = source
	_direction = direction.normalized()
	_length = length
	_width = width
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_blowing() -> bool:
	return _left <= 0.0 and _blow_left > 0.0


func is_warning() -> bool:
	return _left > 0.0


func hits(point: Vector2) -> bool:
	return lane_hits(global_position, _direction, _length, _width, point)


func direction() -> Vector2:
	return _direction


func length() -> float:
	return _length


func width() -> float:
	return _width


func _process(delta: float) -> void:
	queue_redraw()
	if _left > 0.0:
		if not is_instance_valid(_source) or _source.is_dead():
			queue_free()
			return
		_left -= delta
		return
	_blow_left -= delta
	if _blow_left <= 0.0:
		queue_free()
		return
	if _has_hit or not is_instance_valid(_source) or not is_instance_valid(_source.target):
		return
	if hits(_source.target_ground()):
		_has_hit = true
		_source.hit_target(_source.attack_damage(_damage))


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _direction.angle())
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		draw_rect(Rect2(0.0, -_width / 2.0, _length * progress, _width), Color(COLOR, 0.15 + 0.3 * progress))
		draw_rect(Rect2(0.0, -_width / 2.0, _length, _width), COLOR, false, 2.0)
		return
	var fade := clampf(_blow_left / BLOW_TIME, 0.0, 1.0)
	var t := Time.get_ticks_msec() / 1000.0
	var steps := int(_length / PUFF_GAP)
	for i in steps + 1:
		var x := minf(i * PUFF_GAP + fposmod(t * 90.0, PUFF_GAP), _length)
		var wobble := sin(t * 20.0 + i) * _width * 0.12
		var size := _width * (0.35 + 0.2 * (i % 2))
		draw_circle(Vector2(x, wobble), size, Color(STEAM, STEAM.a * fade))
	draw_rect(Rect2(0.0, -_width / 2.0, _length, _width), Color(STEAM_EDGE, STEAM_EDGE.a * fade), false, 1.0)
