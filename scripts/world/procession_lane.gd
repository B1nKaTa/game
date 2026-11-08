class_name ProcessionLane
extends Node2D

# One lane of a funeral procession. It first shows the lane filling red, as any warned lane does,
# then a row of pallbearers with their coffin marches down it from one end to the other. Grandpa's
# feet in the lane where the row passes cost a pill, once. It comes to nothing if the boss who
# called it falls first.
const COLOR := Color("e4524f")
const SUIT := Color("2a2430")
const COFFIN := Color("4a2a1c")
const LID := Color("6b3d26")
const GLOVE := Color("f4f1e6")
const MARCH_SPEED := 300.0
# How long the marching row is, from its front to its back.
const ROW := 36.0

var _source: Enemy
var _direction := Vector2.RIGHT
var _length := 100.0
var _width := 40.0
var _warning := 1.0
var _left := 1.0
var _front := 0.0
var _damage := -1
var _has_hit := false


# Whether a point is under the marching row, whose front has come this far down a lane that starts
# at origin and runs along direction.
static func row_hits(origin: Vector2, direction: Vector2, width: float, front: float, point: Vector2) -> bool:
	var offset := point - origin
	var along := offset.dot(direction)
	var side := absf(offset.dot(direction.orthogonal()))
	return side <= width / 2.0 and along <= front and along >= front - ROW


# The lane starts where the procession enters and runs length along direction.
func setup(source: Enemy, direction: Vector2, length: float, width: float, warning: float, damage := -1) -> void:
	_source = source
	_direction = direction.normalized()
	_length = length
	_width = width
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_marching() -> bool:
	return _left <= 0.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if _left > 0.0:
		_left -= delta
		return
	_front += MARCH_SPEED * delta
	if _front - ROW > _length:
		queue_free()
		return
	if _has_hit or not is_instance_valid(_source.target):
		return
	if row_hits(global_position, _direction, _width, minf(_front, _length), _source.target_ground()):
		if _source.target.take_hit(_source.attack_damage(_damage)):
			_has_hit = true


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _direction.angle())
	# The red only with Attack warnings on (AttackWarnings); otherwise the faint cue, then the bearers and
	# their coffin themselves.
	var red := AttackWarnings.drawn_by(_source)
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		if red:
			draw_rect(Rect2(0.0, -_width / 2.0, _length * progress, _width), Color(COLOR, 0.15 + 0.3 * progress))
			draw_rect(Rect2(0.0, -_width / 2.0, _length, _width), COLOR, false, 2.0)
		else:
			AttackWarnings.draw_cue_lane(self, Rect2(0.0, -_width / 2.0, _length, _width), progress)
		draw_set_transform(Vector2.ZERO)
		return
	# The row: a coffin carried shoulder high between two bearers on each side.
	var back := clampf(_front - ROW, 0.0, _length)
	var front := clampf(_front, 0.0, _length)
	if red:
		draw_rect(Rect2(back, -_width / 2.0, front - back, _width), Color(COLOR, 0.12))
	var middle := _front - ROW / 2.0
	if middle >= 0.0 and middle <= _length:
		var half := _width / 2.0 - 4.0
		for x in [middle - 9.0, middle + 9.0]:
			for y in [-half, half]:
				draw_circle(Vector2(x, y), 5.0, SUIT)
				draw_circle(Vector2(x + 3.0, y * 0.7), 1.5, GLOVE)
		draw_rect(Rect2(middle - 15.0, -7.0, 30.0, 14.0), COFFIN)
		draw_rect(Rect2(middle - 15.0, -7.0, 30.0, 14.0), Color.BLACK, false, 1.0)
		draw_line(Vector2(middle - 12.0, 0.0), Vector2(middle + 12.0, 0.0), LID, 2.0)
	draw_set_transform(Vector2.ZERO)
