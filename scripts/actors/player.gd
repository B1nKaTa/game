class_name Player
extends CharacterBody2D

signal died
signal swing_landed(heavy: bool, finisher: bool)
signal swing_missed(heavy: bool)
signal cane_thrown
signal cane_hit
signal cane_caught
signal hurt
signal bomb_requested(at: Vector2)
signal potion_drunk(potion: PotionDef)

const ATTACK_REACH := 44.0
const ATTACK_ANGLE := 60.0
const CHARGE_REACH := 56.0
const CHARGE_ANGLE := 75.0
const ATTACK_PUSH := 60.0
const DODGE_SPEED := 300.0
const CHARGE_SLOWDOWN := 0.4
const HURT_COLOR := Color("e4524f")
const SPRITE_FRAME_WIDTH := 68
const SPRITE_FEET_Y := 23.0
const FEET_BOX_SIZE := Vector2(14, 12)
const FEET_OFFSET := Vector2(0, 17)
const CROSSHAIR_GAP := 3.0
const CROSSHAIR_REACH := 8.0
const CROSSHAIR_COLOR := Color(1.0, 0.9, 0.55, 0.95)
const GHOST_EVERY := 0.05

var run: RunState
var show_crosshair := false
# Set by the full-loop check and balance probes, which have no mouse to aim with.
var aim_source := Callable()
var _ghost_left := 0.0
var _combo := CaneCombo.new()
var _charge := ChargeSwing.new()
var _cane := CaneThrow.new()
var _thrown_cane: ThrownCane
var _dodge := DodgeTimer.new()
var _aim := Vector2.RIGHT
var _dodge_direction := Vector2.RIGHT
var _active_swing: SwingAttack
var _visual: SpriteVisual
var _feet: Marker2D


static func arrival_position(cell: Vector2i) -> Vector2:
	return RoomBackdrop.cell_center(cell) - FEET_OFFSET


static func crosshair_lines(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		points.append(center + direction * CROSSHAIR_GAP)
		points.append(center + direction * CROSSHAIR_REACH)
	return points


func setup(run_state: RunState) -> void:
	run = run_state


# Doors and pickups use this point, because it is where he stands in the room.
func feet() -> Node2D:
	return _feet


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | Hole.LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = FEET_BOX_SIZE
	shape.shape = rect
	shape.position = FEET_OFFSET
	add_child(shape)
	_feet = Marker2D.new()
	_feet.position = FEET_OFFSET
	add_child(_feet)
	_visual = SpriteVisual.new()
	add_child(_visual)
	_visual.setup("grandpa", Vector2(20, 28), Color("7d9a5c"), SPRITE_FRAME_WIDTH)
	run.health.died.connect(died.emit)


func take_hit(amount: int) -> bool:
	if _dodge.is_active():
		return false
	var landed := run.health.hit(amount)
	if landed:
		if _visual != null:
			_visual.flash(HURT_COLOR, HurtLook.RED_TIME)
		hurt.emit()
	return landed


func _physics_process(delta: float) -> void:
	_combo.tick(delta)
	_charge.tick(delta)
	_dodge.tick(delta)
	run.health.tick(delta)
	run.tick_buff(delta)
	_advance_swing(delta)
	var to_mouse := _aim_point() - global_position
	if not to_mouse.is_zero_approx():
		_aim = to_mouse.normalized()
	_visual.set_facing_left(_aim.x < 0.0)
	_visual.set_alpha(HurtLook.alpha_for(_dodge.is_active(), run.health.invulnerability_left()))
	_handle_attacks()
	_handle_bomb()
	_handle_potion()
	_handle_movement()
	_leave_dodge_ghosts(delta)
	queue_redraw()


func _aim_point() -> Vector2:
	return aim_source.call() if aim_source.is_valid() else get_global_mouse_position()


func _leave_dodge_ghosts(delta: float) -> void:
	if not _dodge.is_active():
		_ghost_left = 0.0
		return
	_ghost_left -= delta
	if _ghost_left > 0.0 or get_parent() == null:
		return
	_ghost_left = GHOST_EVERY
	var ghost := _visual.make_ghost()
	if ghost != null:
		get_parent().add_child(ghost)
		ghost.global_position = global_position


# Spending is left to whoever can place it, so the practice room never wastes one.
func _handle_bomb() -> void:
	if Input.is_action_just_pressed("bomb") and bomb_requested.get_connections().size() > 0 and run.use_bomb():
		bomb_requested.emit(_feet.global_position)


func _handle_potion() -> void:
	if not Input.is_action_just_pressed("potion"):
		return
	var drunk := run.potion
	if run.drink_potion():
		if _visual != null:
			_visual.flash(drunk.color, 0.25)
		potion_drunk.emit(drunk)


func _handle_attacks() -> void:
	if not _cane.is_held():
		_charge.cancel()
		return
	if Input.is_action_just_pressed("throw"):
		_throw_cane()
		return
	if Input.is_action_just_pressed("attack"):
		var damage := _combo.try_attack()
		if damage > 0:
			_swing(damage, ATTACK_REACH, ATTACK_ANGLE, ATTACK_PUSH, false, damage == CaneCombo.DAMAGE[-1])
		_charge.start()
	if Input.is_action_just_released("attack"):
		if _charge.release():
			_swing(ChargeSwing.DAMAGE, CHARGE_REACH, CHARGE_ANGLE, ChargeSwing.KNOCKBACK, true, false)


func _throw_cane() -> void:
	var parent := get_parent()
	if parent == null or not _cane.try_throw():
		return
	_charge.cancel()
	var spawn := global_position + _aim * ThrownCane.LENGTH
	# His upper body can overlap a wall now, so the wall check starts from where he stands.
	var query := PhysicsRayQueryParameters2D.create(_feet.global_position, spawn, ThrownCane.WALL_LAYER)
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		var collider: Object = wall.get("collider")
		if collider is BreakableBlock:
			collider.hit_by(BreakableBlock.SOURCE_CANE)
		spawn = wall["position"] + wall["normal"] * ThrownCane.WALL_BACKOFF
	_thrown_cane = ThrownCane.new()
	_thrown_cane.setup(_cane, self, _aim, run.damage_mult())
	_thrown_cane.hit_enemy.connect(cane_hit.emit)
	_thrown_cane.caught.connect(cane_caught.emit)
	parent.add_child(_thrown_cane)
	_thrown_cane.global_position = spawn
	cane_thrown.emit()
	if not wall.is_empty():
		_cane.drop()


func cancel_charge() -> void:
	_charge.cancel()


func recall_cane() -> void:
	if is_instance_valid(_thrown_cane):
		_thrown_cane.queue_free()
	_thrown_cane = null
	_cane.catch_cane()


func _exit_tree() -> void:
	if is_instance_valid(_thrown_cane):
		_thrown_cane.queue_free()


func _swing(damage: float, reach: float, angle: float, push: float, heavy: bool, finisher: bool) -> void:
	_finish_swing()
	_active_swing = SwingAttack.new(_aim, reach, angle, damage * run.damage_mult(), push, heavy, finisher)
	_visual.play_once("attack", CaneCombo.LOCK_TIME)
	_strike_enemies()


func _advance_swing(delta: float) -> void:
	if _active_swing == null:
		return
	_active_swing.tick(delta)
	if _active_swing.is_active():
		_strike_enemies()
	else:
		_finish_swing()


func _strike_enemies() -> void:
	var swing := _active_swing
	var had_landed := swing.has_landed()
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.submerged:
			continue
		if swing.try_hit(global_position, enemy.get_instance_id(), enemy.body_rect()):
			enemy.take_strike(swing.damage, swing.direction * swing.push, global_position - enemy.global_position)
	for block: BreakableBlock in get_tree().get_nodes_in_group("breakable"):
		if block.is_queued_for_deletion() or not block.can_break_by(BreakableBlock.SOURCE_CANE):
			continue
		if swing.try_hit(global_position, block.get_instance_id(), block.body_rect()):
			block.hit_by(BreakableBlock.SOURCE_CANE)
	if swing.has_landed() and not had_landed:
		swing_landed.emit(swing.heavy, swing.finisher)


func _finish_swing() -> void:
	if _active_swing == null:
		return
	if not _active_swing.has_landed():
		swing_missed.emit(_active_swing.heavy)
	_active_swing = null


func _handle_movement() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dodge") and _dodge.try_start(run.stats.dodge_cooldown):
		_dodge_direction = input.normalized() if input != Vector2.ZERO else _aim
	if _dodge.is_active():
		velocity = _dodge_direction * DODGE_SPEED
	else:
		var speed := run.move_speed()
		if _charge.is_charging():
			speed *= CHARGE_SLOWDOWN
		velocity = input * speed
		if not _visual.is_playing_once():
			_visual.play("walk" if input != Vector2.ZERO else "idle")
	move_and_slide()


func _draw() -> void:
	var has_art := _visual.has_art()
	if _dodge.is_active() and not has_art:
		draw_line(-_dodge_direction * 6.0, -_dodge_direction * 26.0, Color(1.0, 1.0, 1.0, 0.35), 8.0)
	var swinging := _active_swing != null
	var pointing := _active_swing.direction if swinging else _aim
	if not has_art and _cane.is_held():
		draw_line(Vector2.ZERO, pointing * 20.0, Color("a8692f"), 3.0)
	if show_crosshair:
		var lines := crosshair_lines(get_local_mouse_position())
		draw_multiline(lines, Color.BLACK, 3.0)
		draw_multiline(lines, CROSSHAIR_COLOR, 1.0)
	if swinging:
		var center := _active_swing.direction.angle()
		var half_angle := deg_to_rad(_active_swing.half_angle_deg)
		draw_arc(Vector2.ZERO, _active_swing.reach, center - half_angle, center + half_angle, 12, Color("ffe58a"), 3.0)
	if _charge.is_charging():
		draw_arc(Vector2.ZERO, 22.0, -PI / 2.0, -PI / 2.0 + TAU * _charge.progress(), 24, Color("f4c542"), 2.0)
