class_name HoldMusic
extends Node2D

# Doreen's hold music. For its warning it shows, around her, the spiral the notes will make: a dotted
# red arm for each stream, each dot where a note will be once the last has left. Then the notes come
# out one step at a time, a few arms at once, each step turned a little further round, so they spread
# out in a slow spiral. Every note is a slow shot that stops at walls. It comes to nothing if she falls.
const COLOR := Color("e4524f")
const NOTE_LOOK := Projectile.LOOK_NOTE

var _source: Enemy
var _arms := 3
var _notes := 7
var _every := 0.15
var _turn := 0.3
var _speed := 90.0
var _start := 0.0
var _warning := 0.7
var _left := 0.7
var _sent := 0
var _wait := 0.0


# The way each note flies, in the order they leave: every arm's first note, then every arm's second.
static func note_ways(start: float, arms: int, notes: int, turn: float) -> Array[Vector2]:
	var ways: Array[Vector2] = []
	for step in notes:
		for arm in arms:
			ways.append(Vector2.from_angle(start + TAU * arm / float(arms) + turn * step))
	return ways


# Where one arm's notes stand, from her, as the last of them leaves: the first note furthest out.
static func spiral_points(start: float, arm: int, arms: int, notes: int, turn: float, every: float, speed: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for step in notes:
		var out := (notes - 1 - step) * every * speed + 12.0
		points.append(Vector2.from_angle(start + TAU * arm / float(arms) + turn * step) * out)
	return points


# How long the notes take to come out, from the first step to the last.
static func play_time(notes: int, every: float) -> float:
	return (notes - 1) * every


func setup(source: Enemy, warning: float, start: float, arms: int, notes: int, every: float, turn: float, speed: float) -> void:
	_source = source
	_warning = warning
	_left = warning
	_start = start
	_arms = arms
	_notes = notes
	_every = every
	_turn = turn
	_speed = speed
	z_index = Projectile.SHOT_Z


func is_playing() -> bool:
	return _left <= 0.0


func notes_sent() -> int:
	return _sent


func is_finished() -> bool:
	return _sent >= _notes


# Runs the warning, then says how many steps of notes are due now. The first is due the moment the
# warning ends, and the rest one every _every seconds after it.
func advance(delta: float) -> int:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0:
			return 0
		_wait = 0.0
	else:
		_wait -= delta
	var due := 0
	while _sent + due < _notes and _wait <= 0.0:
		due += 1
		_wait += _every
	_sent += due
	return due


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	global_position = _source.global_position
	var before := _sent
	var due := advance(delta)
	var ways := note_ways(_start, _arms, _notes, _turn)
	for step in range(before, before + due):
		for arm in _arms:
			_source.shoot(ways[step * _arms + arm], _speed).look = NOTE_LOOK
	if is_finished():
		queue_free()


func _draw() -> void:
	if _left <= 0.0:
		return
	var filled := clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)
	for arm in _arms:
		var points := spiral_points(_start, arm, _arms, _notes, _turn, _every, _speed)
		# From her, through the nearest note, out to the furthest.
		var line := PackedVector2Array([Vector2.ZERO])
		for i in range(points.size() - 1, -1, -1):
			line.append(points[i])
		draw_polyline(line, Color(COLOR, 0.25 + 0.35 * filled), 2.0)
		for point in points:
			draw_circle(point, 3.0 + 2.0 * filled, Color(COLOR, 0.4 + 0.4 * filled))
