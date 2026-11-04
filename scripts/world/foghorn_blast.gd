class_name FoghornBlast
extends Node2D

# What a foghorn blast looks like as it goes off: rings of sound rolling down its lane for a moment. The
# harm is worked out by whoever sounds it, so this only shows it.
const SHOW_TIME := 0.35
const WAVE := Color(0.85, 0.95, 1.0, 0.8)
const WAVES := 4

var _direction := Vector2.RIGHT
var _length := 300.0
var _width := 80.0
var _left := SHOW_TIME


# Whether a point stands in a blast's lane, which starts at origin and runs length along direction.
static func in_blast(origin: Vector2, direction: Vector2, length: float, width: float, point: Vector2) -> bool:
	var way := direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	var offset := point - origin
	var along := offset.dot(way)
	return along >= 0.0 and along <= length and absf(offset.dot(way.orthogonal())) <= width / 2.0


func setup(direction: Vector2, length: float, width: float) -> void:
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_length = length
	_width = width
	_left = SHOW_TIME
	z_index = Projectile.SHOT_Z


func _process(delta: float) -> void:
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		queue_free()


func _draw() -> void:
	var progress := clampf(1.0 - _left / SHOW_TIME, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, _direction.angle())
	for i in WAVES:
		var x := fposmod(progress * _length + i * _length / WAVES, _length)
		var height := _width / 2.0 * (0.5 + 0.5 * x / _length)
		draw_arc(Vector2(x - height, 0.0), height, -0.9, 0.9, 10, Color(WAVE, (1.0 - progress) * 0.9), 3.0)
	draw_set_transform(Vector2.ZERO)
