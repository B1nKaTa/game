class_name PuttRoll
extends Node2D

# A putt rolled along a curve that breaks to one side. While it is lined up the whole curve it will
# roll along is marked, spot by spot, with the cup at its end. Then the ball rolls the curve, and costs a
# pill if it reaches Grandpa's feet, once a putt; a dodge passes through, as through any hit. It comes to
# nothing if the one who putted it falls first.
const COLOR := Color("e4524f")
const BALL := Color("fbfbf4")
const CUP := Color("15131a")
const HIT_RANGE := 14.0
const SPEED := 260.0
const MARK_RADIUS := 6.0
const MARK_EVERY := 2

var _source: Enemy
# The curve from where it is putted, relative to that point.
var _path: Array[Vector2] = []
var _warning := 0.7
var _left := 0.7
var _travelled := 0.0
var _total := 0.0
var _has_hit := false
var _damage := -1


# The curve is in room coordinates. The roll keeps it relative to where it is putted from.
func setup(source: Enemy, start: Vector2, path: Array[Vector2], warning: float, damage := -1) -> void:
	_source = source
	_path.clear()
	for point in path:
		_path.append(point - start)
	_total = CollectionPlate.path_length(_path)
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_rolling() -> bool:
	return _left <= 0.0


func length() -> float:
	return _total


# Where the ball is after rolling a distance along the curve, relative to where it was putted.
func ball_at(distance: float) -> Vector2:
	return CollectionPlate.point_along(_path, distance)


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if _left > 0.0:
		_left -= delta
		return
	_travelled += SPEED * delta
	if _travelled >= _total:
		queue_free()
		return
	if _has_hit or not is_instance_valid(_source.target):
		return
	var at := global_position + ball_at(_travelled)
	if at.distance_to(_source.target_ground()) <= HIT_RANGE and _source.target.take_hit(_source.attack_damage(_damage)):
		_has_hit = true


func _draw() -> void:
	if not _path.is_empty():
		var end := _path[-1]
		draw_set_transform(end, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, 6.0, CUP)
		draw_set_transform(Vector2.ZERO)
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		var from := Vector2.ZERO
		for point in _path:
			draw_line(from, point, Color(COLOR, 0.25 + 0.3 * progress), 2.0)
			from = point
		for i in range(0, _path.size(), MARK_EVERY):
			draw_circle(_path[i], MARK_RADIUS * progress, Color(COLOR, 0.15 + 0.3 * progress))
			draw_arc(_path[i], MARK_RADIUS, 0.0, TAU, 12, COLOR, 1.5)
		return
	var at := ball_at(_travelled)
	draw_circle(at, 4.0, BALL)
	draw_arc(at, 4.0, 0.0, TAU, 12, Color.BLACK, 1.0)
