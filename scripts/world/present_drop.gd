class_name PresentDrop
extends Node2D

# A gift box dropped onto a warned spot. A red circle fills for its warning, with a short warned lane
# for each of the shots to come and the box's shadow growing as it falls. It lands, costing a pill to
# whoever stands under it and breaking props, then bursts into a ring of shots. It comes to nothing if
# the Santa falls first.
const WARNING := 0.9
const RADIUS := 18.0
const SHOTS := 6
const SHOT_SPEED := 125.0
const SPOKE := 64.0
const SPOKE_WIDTH := 10.0
const BURST_SHOW := 0.3
const COLOR := Color("e4524f")
const PAPER := Color("3aa05a")
const RIBBON := Color("e8c04a")
const SHADOW := Color(0.0, 0.0, 0.0)

var _source: Enemy
var _warning := WARNING
var _left := WARNING
var _start_angle := 0.0
var _landed := false
var _show_left := BURST_SHOW


static func shot_directions(start_angle: float) -> Array[Vector2]:
	return BossMoves.ring_directions(SHOTS, start_angle)


func setup(source: Enemy, warning: float, start_angle: float) -> void:
	_source = source
	_warning = warning
	_left = warning
	_start_angle = start_angle
	z_index = Projectile.SHOT_Z


# True once, on the moment it lands.
func advance(delta: float) -> bool:
	if _landed:
		return false
	_left -= delta
	if _left <= 0.0:
		_landed = true
		return true
	return false


func _process(delta: float) -> void:
	queue_redraw()
	if _landed:
		_show_left -= delta
		if _show_left <= 0.0:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if advance(delta):
		_source.land_ground_strike(global_position, RADIUS)
		_burst()


func _burst() -> void:
	if not is_instance_valid(_source.target):
		return
	for way in shot_directions(_start_angle):
		var shot := Projectile.new()
		shot.setup(way, SHOT_SPEED, _source.target, _source.attack_damage())
		shot.look = Projectile.LOOK_ORNAMENT
		get_parent().add_child(shot)
		shot.global_position = global_position + way * RADIUS * 0.5


func _draw() -> void:
	if _landed:
		var progress := 1.0 - maxf(_show_left, 0.0) / BURST_SHOW
		for i in 4:
			var way := Vector2.from_angle(TAU * i / 4.0 + 0.8)
			draw_rect(Rect2(way * RADIUS * progress - Vector2(4, 4), Vector2(8, 8)), Color(PAPER, 1.0 - progress))
		return
	var filled := clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)
	for way in shot_directions(_start_angle):
		draw_set_transform(Vector2.ZERO, way.angle())
		draw_rect(Rect2(RADIUS, -SPOKE_WIDTH / 2.0, SPOKE, SPOKE_WIDTH), Color(COLOR, 0.08 + 0.2 * filled))
		draw_rect(Rect2(RADIUS, -SPOKE_WIDTH / 2.0, SPOKE, SPOKE_WIDTH), Color(COLOR, 0.7), false, 1.0)
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO, RADIUS * filled, Color(COLOR, 0.15 + 0.3 * filled))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, COLOR, 2.0)
	# The box's shadow grows as it falls, and the box itself drops in from above.
	draw_circle(Vector2.ZERO, RADIUS * 0.7 * filled, Color(SHADOW, 0.35 * filled))
	var drop := Vector2(0.0, -60.0 * (1.0 - filled))
	draw_rect(Rect2(drop - Vector2(7, 7), Vector2(14, 14)), PAPER)
	draw_rect(Rect2(drop - Vector2(1.5, 7), Vector2(3, 14)), RIBBON)
	draw_rect(Rect2(drop - Vector2(7, 1.5), Vector2(14, 3)), RIBBON)
