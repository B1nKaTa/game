class_name Projectile
extends Node2D

const HIT_RADIUS := 12.0
const LIFETIME := 5.0
# Shots fly above the dark of Lights Out, so one is never unseen.
const SHOT_Z := 55
const DART_BARREL := Color("dff3ff")
const DART_PLUNGER := Color("7fb7d8")
const DART_NEEDLE := Color("f4f4f4")
# What a plain shot looks like: a sheet of paper, a wishing-well coin or a bauble from a present.
const LOOK_PAPER := ""
const LOOK_COIN := "coin"
const LOOK_ORNAMENT := "ornament"
const COIN_GOLD := Color("e8c04a")
const COIN_SHINE := Color("fff4c0")
const ORNAMENT_RED := Color("d93a3a")
# Head Office: a note of hold music, a black quaver.
const LOOK_NOTE := "note"
const NOTE_INK := Color("15131a")
const NOTE_GLOW := Color(1.0, 0.95, 0.75, 0.8)

# A sedative dart slows Grandpa by this much for this long when it lands. Zero means a plain shot.
var slow_fraction := 0.0
var slow_time := 0.0
var look := LOOK_PAPER
var _velocity := Vector2.ZERO
var _target: Node2D
var _damage := 1
var _age := 0.0


func setup(direction: Vector2, speed: float, target: Node2D, damage: int) -> void:
	_velocity = direction.normalized() * speed
	_target = target
	_damage = damage
	z_index = SHOT_Z


func make_dart(fraction: float, seconds: float) -> void:
	slow_fraction = fraction
	slow_time = seconds
	rotation = _velocity.angle()
	queue_redraw()


func is_dart() -> bool:
	return slow_fraction > 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME or not is_instance_valid(_target):
		queue_free()
		return
	var next := global_position + _velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	global_position = next
	if global_position.distance_to(_target.global_position) <= HIT_RADIUS:
		var landed: bool = _target.take_hit(_damage)
		if landed and is_dart() and _target.has_method("slow"):
			_target.slow(slow_fraction, slow_time)
		queue_free()


func _draw() -> void:
	if is_dart():
		draw_rect(Rect2(-7, -2.5, 10, 5), DART_BARREL)
		draw_rect(Rect2(-7, -2.5, 10, 5), Color.BLACK, false, 1.0)
		draw_rect(Rect2(-10, -1.5, 3, 3), DART_PLUNGER)
		draw_line(Vector2(3, 0), Vector2(9, 0), DART_NEEDLE, 1.0)
		return
	if look == LOOK_COIN:
		draw_circle(Vector2.ZERO, 5.0, COIN_GOLD)
		draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 16, Color.BLACK, 1.0)
		draw_arc(Vector2.ZERO, 3.0, 0.0, TAU, 12, COIN_SHINE, 1.0)
		return
	if look == LOOK_ORNAMENT:
		draw_circle(Vector2.ZERO, 5.0, ORNAMENT_RED)
		draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 16, Color.BLACK, 1.0)
		draw_rect(Rect2(-1.5, -7.0, 3.0, 2.5), COIN_GOLD)
		draw_circle(Vector2(-1.5, -1.5), 1.5, COIN_SHINE)
		return
	if look == LOOK_NOTE:
		# A pale glow behind, so a black note reads on dark carpet as well as pale.
		draw_circle(Vector2(0.0, 1.0), 6.0, NOTE_GLOW)
		draw_circle(Vector2(-1.0, 3.0), 3.0, NOTE_INK)
		draw_line(Vector2(1.5, 3.0), Vector2(1.5, -6.0), NOTE_INK, 1.5)
		draw_line(Vector2(1.5, -6.0), Vector2(5.0, -3.0), NOTE_INK, 1.5)
		return
	draw_rect(Rect2(-4, -5, 8, 10), Color("efe8d2"))
	draw_rect(Rect2(-4, -5, 8, 10), Color.BLACK, false, 1.0)
