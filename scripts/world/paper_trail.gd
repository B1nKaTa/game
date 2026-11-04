class_name PaperTrail
extends Node2D

# The shredded paper a Paper Shredder leaves behind as it charges: a short trail of strips on the
# floor. It never hurts, but while Grandpa's feet are in it he is slowed, and after a while it is swept
# away. It keeps only its last few scraps, so the trail stays short. It lies at the room's origin,
# with each scrap where it fell.
const LINGER := 3.0
const RADIUS := 14.0
const MOST_SCRAPS := 6
const SLOW := 0.35
const SLOW_TIME := 0.4
# How often a slow is laid on him while he stands in it, so a long stand never piles slows up.
const SLOW_EVERY := 0.2
const FADE := 0.5
const PAPER := Color("f4efe0")
const PAPER_EDGE := Color("8e8878")
const INK := Color(0.2, 0.22, 0.3, 0.6)

var _scraps: Array[Vector2] = []
var _left := LINGER
var _target: Node2D
var _slow_wait := 0.0


# Whether a point lies on any scrap of a trail.
static func covers_any(scraps: Array[Vector2], radius: float, point: Vector2) -> bool:
	for scrap in scraps:
		if scrap.distance_to(point) <= radius:
			return true
	return false


func setup(target: Node2D, seconds := LINGER) -> void:
	_target = target
	_left = seconds
	z_index = -8


# A new scrap where the shredder is, dropping the oldest once the trail is at its longest.
func add_scrap(at: Vector2) -> void:
	_scraps.append(at)
	while _scraps.size() > MOST_SCRAPS:
		_scraps.remove_at(0)
	queue_redraw()


func scraps() -> Array[Vector2]:
	return _scraps


func covers(point: Vector2) -> bool:
	return _left > 0.0 and covers_any(_scraps, RADIUS, point)


func time_left() -> float:
	return _left


# Runs the trail's time, and says whether a slow is due on someone standing at point.
func advance(delta: float, point: Vector2) -> bool:
	_left -= delta
	_slow_wait = maxf(_slow_wait - delta, 0.0)
	if _slow_wait > 0.0 or not covers(point):
		return false
	_slow_wait = SLOW_EVERY
	return true


func _process(delta: float) -> void:
	queue_redraw()
	var feet := Vector2.INF
	if is_instance_valid(_target):
		feet = _target.feet().global_position if _target.has_method("feet") else _target.global_position
	if advance(delta, feet) and is_instance_valid(_target) and _target.has_method("slow"):
		_target.slow(SLOW, SLOW_TIME)
	if _left <= 0.0:
		queue_free()


func _draw() -> void:
	var fade := clampf(_left / FADE, 0.0, 1.0)
	for i in _scraps.size():
		var at := _scraps[i] - global_position
		for strip in 3:
			var lean := 0.5 + 0.9 * float((i + strip) % 3)
			var start := at + Vector2(-8.0 + strip * 6.0, -5.0 + (i + strip) % 2 * 4.0)
			var end := start + Vector2.from_angle(lean) * 9.0
			draw_line(start, end, Color(PAPER_EDGE, fade), 4.0)
			draw_line(start, end, Color(PAPER, fade), 2.0)
		draw_circle(at, 2.0, Color(INK, INK.a * fade))
