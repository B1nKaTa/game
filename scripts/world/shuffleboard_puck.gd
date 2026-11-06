class_name ShuffleboardPuck
extends Node2D

# A shuffleboard puck sent sliding across the deck. While the Shark winds up it marks its whole way,
# both the lane out and the lane it takes after bouncing once off whatever first stops it, then it
# slides along that way and stops at the second thing it meets. Grandpa's feet near it cost a pill,
# once a puck, and a dodge passes through. It comes to nothing if the Shark falls first.
const COLOR := Color("e4524f")
const PUCK := Color("2b3550")
const PUCK_TOP := Color("e8c04a")
const PUCK_RADIUS := 7.0
# The puck's picture (art/props/puck.png, 16 px), drawn 1:1 over its shadow; the drawing stays for when
# it is missing.
const ART := "puck"
const HIT_RANGE := 13.0
# A bounce starts this far off the wall, so the way back never begins inside it.
const WALL_BACKOFF := 4.0

var _source: Enemy
# The way from where it starts, relative to that point.
var _path: Array[Vector2] = []
var _warning := 0.7
var _left := 0.7
var _speed := 250.0
var _width := 20.0
var _travelled := 0.0
var _total := 0.0
var _has_hit := false
var _damage := -1


# The way a puck slides from start along direction for length: to the first thing that stops it, then
# bounced off it for what is left, ending at the second thing it meets. cast(from, to) answers an empty
# Dictionary for a clear way, or one with the "position" and "normal" of what it hit.
static func bounce_path(start: Vector2, direction: Vector2, length: float, cast: Callable) -> Array[Vector2]:
	var way := direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	var points: Array[Vector2] = [start]
	var hit: Dictionary = cast.call(start, start + way * length) if cast.is_valid() else {}
	if hit.is_empty():
		points.append(start + way * length)
		return points
	var normal: Vector2 = hit["normal"]
	var at: Vector2 = hit["position"]
	at += normal * WALL_BACKOFF
	points.append(at)
	var left := length - start.distance_to(at)
	if left <= 0.0:
		return points
	var back := way.bounce(normal).normalized()
	var second: Dictionary = cast.call(at, at + back * left)
	if second.is_empty():
		points.append(at + back * left)
	else:
		var second_at: Vector2 = second["position"]
		var second_normal: Vector2 = second["normal"]
		points.append(second_at + second_normal * WALL_BACKOFF)
	return points


# How many times a path turns: 1 for a puck that bounced, 0 for one that ran straight.
static func bounces(path: Array[Vector2]) -> int:
	return maxi(path.size() - 2, 0)


# The path is in room coordinates and starts where the puck starts.
func setup(source: Enemy, path: Array[Vector2], warning: float, speed: float, width: float, damage := -1) -> void:
	_source = source
	_path.clear()
	var start: Vector2 = path[0] if not path.is_empty() else Vector2.ZERO
	for i in range(1, path.size()):
		_path.append(path[i] - start)
	_total = CollectionPlate.path_length(_path)
	_warning = warning
	_left = warning
	_speed = speed
	_width = width
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_sliding() -> bool:
	return _left <= 0.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if _left > 0.0:
		_left -= delta
		return
	_travelled += _speed * delta
	if _travelled >= _total:
		queue_free()
		return
	if _has_hit or not is_instance_valid(_source.target):
		return
	var at := global_position + CollectionPlate.point_along(_path, _travelled)
	if at.distance_to(_source.target_ground()) <= HIT_RANGE and _source.target.take_hit(_source.attack_damage(_damage)):
		_has_hit = true


func _draw() -> void:
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		var from := Vector2.ZERO
		for point in _path:
			var length := from.distance_to(point)
			if length > 0.0:
				draw_set_transform(from, from.direction_to(point).angle())
				draw_rect(Rect2(0.0, -_width / 2.0, length * progress, _width), Color(COLOR, 0.15 + 0.3 * progress))
				draw_rect(Rect2(0.0, -_width / 2.0, length, _width), COLOR, false, 2.0)
				draw_set_transform(Vector2.ZERO)
			from = point
		# Where it bounces, so the turn reads before it happens.
		if _path.size() > 1:
			draw_arc(_path[0], _width / 2.0 + 3.0, 0.0, TAU, 16, COLOR, 2.0)
		return
	var at := CollectionPlate.point_along(_path, _travelled)
	draw_circle(at + Vector2(1, 2), PUCK_RADIUS, Color(0, 0, 0, 0.35))
	var art := PropArt.texture(ART)
	if art != null:
		draw_texture(art, PropArt.centred(art, at))
		return
	draw_circle(at, PUCK_RADIUS, PUCK)
	draw_arc(at, PUCK_RADIUS, 0.0, TAU, 16, Color.BLACK, 1.0)
	draw_circle(at, PUCK_RADIUS * 0.5, PUCK_TOP)
