class_name DeckLane
extends Node2D

# One lane of something crossing the deck. It first shows the lane filling red, as any warned lane does,
# then what it carries comes down it from one end to the other: a conga line of dancers for Lorraine,
# or a lifebuoy rolling on its edge for the Commodore. Grandpa's feet where it passes cost a pill, once,
# and a dodge passes through. It comes to nothing if the boss who sent it falls first.
const LOOK_CONGA := "conga"
const LOOK_LIFEBUOY := "lifebuoy"
const COLOR := Color("e4524f")
const CONGA_SPEED := 260.0
const BUOY_SPEED := 300.0
# How long the passing row is, from its front to its back.
const CONGA_ROW := 54.0
const BUOY_ROW := 26.0
const DANCERS: Array[Color] = [Color("f2c230"), Color("4fc3d9"), Color("e86a9a")]
const DANCER_RADIUS := 6.0
# Files of dancers stand side by side across the lane, no further apart than this, so the row shows the
# whole width it hurts.
const DANCER_GAP := 16.0
const SKIN := Color("f0c9a0")
const BUOY_WHITE := Color("fbfbff")
const BUOY_RED := Color("d9453b")

var _source: Enemy
var _target: Node2D
var _direction := Vector2.RIGHT
var _length := 100.0
var _width := 40.0
var _warning := 1.0
var _left := 1.0
var _front := 0.0
var _speed := CONGA_SPEED
var _look := LOOK_CONGA
var _damage := -1
var _has_hit := false


# Whether a point is under the passing row, whose front has come this far down a lane that starts at
# origin and runs along direction.
static func row_hits(origin: Vector2, direction: Vector2, width: float, front: float, row: float, point: Vector2) -> bool:
	var offset := point - origin
	var along := offset.dot(direction)
	var side := absf(offset.dot(direction.orthogonal()))
	return side <= width / 2.0 and along <= front and along >= front - row


static func row_for(look: String) -> float:
	return BUOY_ROW if look == LOOK_LIFEBUOY else CONGA_ROW


static func speed_for(look: String) -> float:
	return BUOY_SPEED if look == LOOK_LIFEBUOY else CONGA_SPEED


# Where each file of dancers stands across a lane of this width, from one edge to the other.
static func dancer_offsets(width: float) -> Array[float]:
	var span := width - DANCER_RADIUS * 2.0
	if span <= 0.0:
		var middle: Array[float] = [0.0]
		return middle
	var count := ceili(span / DANCER_GAP) + 1
	var offsets: Array[float] = []
	for i in count:
		offsets.append(-span / 2.0 + span * i / float(count - 1))
	return offsets


# The lane starts where the row enters and runs length along direction.
func setup(source: Enemy, direction: Vector2, length: float, width: float, warning: float, look := LOOK_CONGA, damage := -1) -> void:
	_source = source
	_target = source.target if source != null else null
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_length = length
	_width = width
	_warning = warning
	_left = warning
	_look = look
	_speed = speed_for(look)
	_damage = damage
	z_index = Projectile.SHOT_Z


func look() -> String:
	return _look


func is_moving() -> bool:
	return _left <= 0.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if _left > 0.0:
		_left -= delta
		return
	_front += _speed * delta
	if _front - row_for(_look) > _length:
		queue_free()
		return
	if _has_hit or not is_instance_valid(_target):
		return
	if row_hits(global_position, _direction, _width, minf(_front, _length), row_for(_look), _source.target_ground()):
		if _target.take_hit(_source.attack_damage(_damage)):
			_has_hit = true


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _direction.angle())
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		draw_rect(Rect2(0.0, -_width / 2.0, _length * progress, _width), Color(COLOR, 0.15 + 0.3 * progress))
		draw_rect(Rect2(0.0, -_width / 2.0, _length, _width), COLOR, false, 2.0)
		draw_set_transform(Vector2.ZERO)
		return
	var row := row_for(_look)
	var back := clampf(_front - row, 0.0, _length)
	var front := clampf(_front, 0.0, _length)
	draw_rect(Rect2(back, -_width / 2.0, front - back, _width), Color(COLOR, 0.12 if _look == LOOK_LIFEBUOY else 0.25))
	if _look == LOOK_LIFEBUOY:
		_draw_buoy(_front - row / 2.0)
	else:
		_draw_dancers(_front - row / 2.0)
	draw_set_transform(Vector2.ZERO)


# Files of three dancers side by side across the lane, each holding the hips of the one in front,
# kicking out in turn.
func _draw_dancers(middle: float) -> void:
	for side in dancer_offsets(_width):
		for i in DANCERS.size():
			var x := middle + 16.0 - i * 16.0
			if x < 0.0 or x > _length:
				continue
			var kick := 4.0 if (int(_front / 12.0) + i) % 2 == 0 else -4.0
			draw_line(Vector2(x - 3.0, side + 4.0), Vector2(x - 6.0, side + 4.0 + kick), DANCERS[i].darkened(0.4), 2.0)
			draw_circle(Vector2(x, side), DANCER_RADIUS, DANCERS[i])
			draw_circle(Vector2(x + 2.0, side - 1.0), 3.0, SKIN)
			draw_arc(Vector2(x, side), DANCER_RADIUS, 0.0, TAU, 12, Color.BLACK, 1.0)


# A red and white ring rolling on its edge, turning as it goes.
func _draw_buoy(middle: float) -> void:
	if middle < 0.0 or middle > _length:
		return
	var turn := _front / 11.0
	for i in 4:
		var start := turn + i * PI / 2.0
		draw_arc(Vector2(middle, 0.0), 10.0, start, start + PI / 2.0, 6, BUOY_RED if i % 2 == 0 else BUOY_WHITE, 6.0)
	draw_arc(Vector2(middle, 0.0), 13.0, 0.0, TAU, 20, Color.BLACK, 1.0)
	draw_arc(Vector2(middle, 0.0), 7.0, 0.0, TAU, 16, Color.BLACK, 1.0)
