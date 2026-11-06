class_name ReelLane
extends Node2D

# One lane of a reel change's hazard, straight across the room along a row or a column. It warns
# first, filling red, and then its thing comes down it from one end to the other: a custard pie
# thrown in a silent comedy, or a tumbleweed rolling through a western. Feet in the lane where it
# passes cost a pill, once. It lies at the lane's start and runs along its direction, over seats and
# all, and comes to nothing if the Projectionist falls first.
const LOOK_PIE := "pie"
const LOOK_TUMBLEWEED := "tumbleweed"
const WIDTH := 28.0
const WARNING := 0.9
const PIE_SPEED := 380.0
const TUMBLEWEED_SPEED := 200.0
# How near along the lane the thing must be to his feet to hit.
const HIT_REACH := 14.0
# A plan sees the lane's run in pieces this long, each hurting while the thing crosses it.
const PLAN_PIECE := 32.0
const COLOR := Color("e4524f")
const PIE_TIN := Color("c9cdd6")
const PIE_CREAM := Color("fbf3e6")
const PIE_CRUST := Color("d9a35a")
const WEED := Color("d8b27a")
const WEED_DARK := Color("6b4a2a")

var _source: Enemy
var _direction := Vector2.RIGHT
var _length := 300.0
var _warning := WARNING
var _left := WARNING
var _speed := PIE_SPEED
var _travelled := 0.0
var _look := LOOK_PIE
var _damage := -1
var _has_hit := false


static func speed_of(look: String) -> float:
	return TUMBLEWEED_SPEED if look == LOOK_TUMBLEWEED else PIE_SPEED


# Whether feet are hit by the thing a distance along a lane from origin running along direction.
static func hits(origin: Vector2, direction: Vector2, at_along: float, width: float, feet: Vector2) -> bool:
	var offset := feet - origin
	return absf(offset.dot(direction) - at_along) <= HIT_REACH and absf(offset.dot(direction.orthogonal())) <= width / 2.0


# The lane's pieces for OverlapRoute, for a lane at origin along direction that starts in delay
# seconds (its warning) and is crossed at speed: [Rect2, Vector2 window] pairs.
static func plan_rects(origin: Vector2, direction: Vector2, length: float, width: float, delay: float, speed: float) -> Array:
	var shapes: Array = []
	var across := direction.orthogonal().abs()
	var along_axis := direction.abs()
	var from := 0.0
	while from < length:
		var to := minf(from + PLAN_PIECE, length)
		var a := origin + direction * (from - HIT_REACH)
		var b := origin + direction * (to + HIT_REACH)
		var low := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - across * width / 2.0
		var high := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + across * width / 2.0
		var rect := Rect2(low, high - low)
		# Only the lane's own width across it, however the corners were made.
		if along_axis.x > 0.5:
			rect = Rect2(Vector2(low.x, origin.y - width / 2.0), Vector2(high.x - low.x, width))
		else:
			rect = Rect2(Vector2(origin.x - width / 2.0, low.y), Vector2(width, high.y - low.y))
		shapes.append([rect, Vector2(delay + from / speed, delay + to / speed)])
		from = to
	return shapes


func setup(source: Enemy, direction: Vector2, length: float, look: String, warning := WARNING, damage := -1) -> void:
	_source = source
	_direction = direction.normalized()
	_length = length
	_look = look
	_speed = speed_of(look)
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func look() -> String:
	return _look


func direction() -> Vector2:
	return _direction


func length() -> float:
	return _length


func is_warning() -> bool:
	return _left > 0.0


func is_over() -> bool:
	return _left <= 0.0 and _travelled >= _length + HIT_REACH


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)


# How far along the lane the thing is.
func travelled() -> float:
	return _travelled


# Its shapes for a plan made now: what is left of its run.
func route_rects() -> Array:
	if is_over():
		return []
	var shapes := plan_rects(global_position, _direction, _length, WIDTH, maxf(_left, 0.0) - (_travelled / _speed if _left <= 0.0 else 0.0), _speed)
	var left: Array = []
	for shape: Array in shapes:
		if (shape[1] as Vector2).y >= 0.0:
			left.append(shape)
	return left


# Moves it on. Returns how far along it was before this step, or -1 while it still warns.
func advance(delta: float) -> float:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0:
			return -1.0
		delta = -_left
		_left = 0.0
	var before := _travelled
	_travelled += _speed * delta
	return before


func _offset(p: Vector2) -> Vector2:
	var offset := p - global_position
	return Vector2(offset.dot(_direction), absf(offset.dot(_direction.orthogonal())))


# What it means for a point, for a simulated player: 2 in the lane ahead of the thing.
func threat_at(p: Vector2, strict: bool) -> int:
	if is_over():
		return 0
	var at := _offset(p)
	var margin := 12.0 if strict else 4.0
	if at.y > WIDTH / 2.0 + margin or at.x < -margin or at.x > _length + margin:
		return 0
	return 2 if at.x >= _travelled - HIT_REACH - margin else 0


func threat_imminent(p: Vector2) -> bool:
	if is_over():
		return false
	var at := _offset(p)
	if at.y > WIDTH / 2.0 + 4.0:
		return false
	if is_warning():
		return _left < 0.12 and at.x < 40.0
	var gap := at.x - _travelled
	return gap > -HIT_REACH and gap < 40.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	var before := advance(delta)
	if before >= 0.0 and not _has_hit and is_instance_valid(_source.target):
		var feet := _source.target_ground()
		var along := (feet - global_position).dot(_direction)
		# Every point it crossed this frame counts, however long the frame.
		var nearest := clampf(along, before, _travelled)
		if hits(global_position, _direction, nearest, WIDTH, feet) and _source.target.take_hit(_source.attack_damage(_damage)):
			_has_hit = true
	if is_over():
		queue_free()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _direction.angle())
	var lane := Rect2(0.0, -WIDTH / 2.0, _length, WIDTH)
	if is_warning():
		var progress := fill()
		draw_rect(Rect2(0.0, -WIDTH / 2.0, _length * progress, WIDTH), Color(COLOR, 0.15 + 0.3 * progress))
		draw_rect(lane, COLOR, false, 2.0)
		draw_set_transform(Vector2.ZERO)
		return
	# What is still ahead of it stays faintly warned.
	var ahead := maxf(_travelled - HIT_REACH, 0.0)
	if ahead < _length:
		draw_rect(Rect2(ahead, -WIDTH / 2.0, _length - ahead, WIDTH), Color(COLOR, 0.12))
		draw_rect(Rect2(ahead, -WIDTH / 2.0, _length - ahead, WIDTH), Color(COLOR, 0.6), false, 1.0)
	var at := Vector2(minf(_travelled, _length), 0.0)
	# Their art, res://art/props/pie.png and tumbleweed.png (32x32) at 1:1: the pie upright as it
	# flies, the tumbleweed turning as it rolls.
	var art := PropArt.texture(_look)
	if art != null:
		var turn := _travelled / 9.0 if _look == LOOK_TUMBLEWEED else 0.0
		draw_set_transform(at.rotated(_direction.angle()), turn)
		draw_texture_rect(art, Rect2(-art.get_size() / 2.0, art.get_size()), false)
		draw_set_transform(Vector2.ZERO)
		return
	if _look == LOOK_TUMBLEWEED:
		var spin := _travelled / 9.0
		draw_circle(at, 12.0, Color(WEED, 0.8))
		for i in 6:
			var a := spin + TAU * i / 6.0
			draw_arc(at + Vector2.from_angle(a) * 3.5, 7.5, a, a + 2.6, 8, WEED_DARK, 1.5)
		draw_arc(at, 12.0, 0.0, TAU, 16, Color.BLACK, 1.0)
	else:
		draw_set_transform(at.rotated(_direction.angle()), _direction.angle() + _travelled / 30.0)
		draw_circle(Vector2.ZERO, 9.0, PIE_TIN)
		draw_circle(Vector2.ZERO, 7.5, PIE_CRUST)
		draw_circle(Vector2.ZERO, 6.0, PIE_CREAM)
		draw_circle(Vector2(2.0, -1.5), 2.0, Color(1, 1, 1))
		draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 16, Color.BLACK, 1.0)
	draw_set_transform(Vector2.ZERO)
