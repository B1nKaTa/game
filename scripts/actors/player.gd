class_name Player
extends CharacterBody2D

signal died

const ATTACK_REACH := 44.0
const ATTACK_ANGLE := 60.0
const CHARGE_REACH := 56.0
const CHARGE_ANGLE := 75.0
const ATTACK_PUSH := 60.0
const DODGE_SPEED := 300.0
const CHARGE_SLOWDOWN := 0.4
const SWING_SHOW_TIME := 0.1

var run: RunState
var _combo := CaneCombo.new()
var _charge := ChargeSwing.new()
var _dodge := DodgeTimer.new()
var _aim := Vector2.RIGHT
var _dodge_direction := Vector2.RIGHT
var _swing_show := 0.0
var _swing_reach := 0.0
var _visual: SpriteVisual


func setup(run_state: RunState) -> void:
	run = run_state


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 18)
	shape.shape = rect
	add_child(shape)
	_visual = SpriteVisual.new()
	add_child(_visual)
	_visual.setup("grandpa", Vector2(20, 28), Color("7d9a5c"), 32)
	run.health.died.connect(died.emit)


func take_hit(amount: int) -> bool:
	if _dodge.is_active():
		return false
	return run.health.hit(amount)


func _physics_process(delta: float) -> void:
	_combo.tick(delta)
	_charge.tick(delta)
	_dodge.tick(delta)
	run.health.tick(delta)
	_swing_show = maxf(_swing_show - delta, 0.0)
	var to_mouse := get_global_mouse_position() - global_position
	if not to_mouse.is_zero_approx():
		_aim = to_mouse.normalized()
	_visual.set_facing_left(_aim.x < 0.0)
	_handle_attacks()
	_handle_movement()
	queue_redraw()


func _handle_attacks() -> void:
	if Input.is_action_just_pressed("charge"):
		_charge.start()
	if Input.is_action_just_released("charge"):
		if _charge.release():
			_swing(ChargeSwing.DAMAGE, CHARGE_REACH, CHARGE_ANGLE, ChargeSwing.KNOCKBACK)
	if Input.is_action_just_pressed("attack") and not _charge.is_charging():
		var damage := _combo.try_attack()
		if damage > 0:
			_swing(damage, ATTACK_REACH, ATTACK_ANGLE, ATTACK_PUSH)


func _swing(damage: float, reach: float, angle: float, push: float) -> void:
	_swing_show = SWING_SHOW_TIME
	_swing_reach = reach
	_visual.play("attack")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if MeleeArc.hits(global_position, _aim, reach, angle, enemy.global_position):
			enemy.take_damage(damage * run.stats.damage_mult, _aim * push)


func _handle_movement() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dodge") and _dodge.try_start(run.stats.dodge_cooldown):
		_dodge_direction = input.normalized() if input != Vector2.ZERO else _aim
	if _dodge.is_active():
		velocity = _dodge_direction * DODGE_SPEED
	else:
		var speed := run.stats.move_speed
		if _charge.is_charging():
			speed *= CHARGE_SLOWDOWN
		velocity = input * speed
		if _swing_show <= 0.0:
			_visual.play("walk" if input != Vector2.ZERO else "idle")
	move_and_slide()


func _draw() -> void:
	draw_line(Vector2.ZERO, _aim * 20.0, Color("a8692f"), 3.0)
	if _swing_show > 0.0:
		draw_arc(Vector2.ZERO, _swing_reach, _aim.angle() - 1.0, _aim.angle() + 1.0, 12, Color("ffe58a"), 3.0)
	if _charge.is_charging():
		draw_arc(Vector2.ZERO, 22.0, -PI / 2.0, -PI / 2.0 + TAU * _charge.progress(), 24, Color("f4c542"), 2.0)
