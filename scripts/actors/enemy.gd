class_name Enemy
extends CharacterBody2D

signal defeated(enemy: Enemy)
signal summon_requested(enemy_def: EnemyDef, spawn_position: Vector2)

const KNOCKBACK_DECAY := 8.0
const BOSS_KNOCKBACK_SCALE := 0.2
const SUMMON_SPREAD := 40.0

var def: EnemyDef
var hp: float = 0.0
var target: Node2D
var desired_velocity := Vector2.ZERO
var _warning_fraction := 0.5
var _behavior: EnemyBehavior
var _knockback := Vector2.ZERO
var _dead := false
var _warning: Telegraph
var _warning_radius := 0.0
var _visual: SpriteVisual


func setup(enemy_def: EnemyDef, chase_target: Node2D, warning_fraction: float) -> void:
	def = enemy_def
	hp = def.max_hp
	target = chase_target
	_warning_fraction = warning_fraction
	_behavior = def.behavior_script.new()


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0 if def.ignores_walls else 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = def.body_size * 0.8
	shape.shape = rect
	add_child(shape)
	_visual = SpriteVisual.new()
	add_child(_visual)
	_visual.setup(def.id, def.body_size, def.color, def.frame_width)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	desired_velocity = Vector2.ZERO
	_behavior.tick(self, delta)
	velocity = desired_velocity + _knockback
	_knockback = _knockback.lerp(Vector2.ZERO, minf(KNOCKBACK_DECAY * delta, 1.0))
	move_and_slide()
	if def.ignores_walls:
		position = clamp_inside_room(position)
	queue_redraw()


static func clamp_inside_room(point: Vector2) -> Vector2:
	var tile := float(RoomBackdrop.TILE)
	return Vector2(
		clampf(point.x, tile, (RoomLayout.WIDTH - 1) * tile),
		clampf(point.y, tile, (RoomLayout.HEIGHT - 1) * tile))


func take_damage(amount: float, push: Vector2) -> void:
	if _dead:
		return
	hp -= amount
	_knockback += push * (BOSS_KNOCKBACK_SCALE if def.is_boss else 1.0)
	if hp <= 0.0:
		_dead = true
		defeated.emit(self)
		if is_inside_tree():
			queue_free()


func hit_target(amount: int) -> void:
	if is_instance_valid(target) and target.has_method("take_hit"):
		target.take_hit(amount)


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


func direction_to_target() -> Vector2:
	return global_position.direction_to(target.global_position)


func set_warning(telegraph: Telegraph, radius: float) -> void:
	_warning = telegraph
	_warning_radius = radius


func clear_warning() -> void:
	_warning = null


func shoot(direction: Vector2, speed: float) -> void:
	var projectile := Projectile.new()
	projectile.setup(direction, speed, target, def.damage)
	projectile.position = position
	get_parent().add_child(projectile)


func request_summon(count: int) -> void:
	if def.summon == null:
		return
	for i in count:
		var angle := TAU * i / float(count)
		summon_requested.emit(def.summon, position + Vector2.from_angle(angle) * SUMMON_SPREAD)


func _draw() -> void:
	if _warning != null and _warning.shows_warning(_warning_fraction):
		draw_arc(Vector2.ZERO, _warning_radius, 0.0, TAU, 32, Color("e4524f"), 2.0)
	if def != null and def.is_boss:
		var width := def.body_size.x + 20.0
		var top := -def.body_size.y / 2.0 - 8.0
		draw_rect(Rect2(-width / 2.0, top, width, 3.0), Color.BLACK)
		draw_rect(Rect2(-width / 2.0, top, width * maxf(hp, 0.0) / def.max_hp, 3.0), Color("e4524f"))
