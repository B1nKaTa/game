class_name Enemy
extends CharacterBody2D

signal defeated(enemy: Enemy)
signal summon_requested(enemy_def: EnemyDef, spawn_position: Vector2)
signal health_changed(hp: float)
signal hit_blocked
signal blasted

const KNOCKBACK_DECAY := 8.0
const BOSS_KNOCKBACK_SCALE := 0.2
const SUMMON_SPREAD := 40.0
const BAR_WIDTH := 20.0
const BAR_HEIGHT := 2.0
const READ_GLOW_COLOR := Color(1.0, 0.95, 0.9)
const READ_GLOW_ENERGY := 0.3
const READ_GLOW_SCALE := 0.6
const WARNING_COLOR := Color("e4524f")
const BLINK_EVERY := 0.09
const BLINK_COLOR := Color("fff2c0")
const MAX_PROPS_ACROSS_A_LANE := 8

var def: EnemyDef
var hp: float = 0.0
var target: Node2D
var desired_velocity := Vector2.ZERO
var is_summon := false
var is_group_follower := false
var room_cells := RoomLayout.DEFAULT_SIZE
var facing := Vector2.RIGHT
# Sets each pack member apart, so they spread out around Grandpa.
var spawn_index := 0
# Where a summon wanted at some point really lands. A room sets this to keep them off solid cells.
var summon_spot: Callable
var _warning_fraction := 0.5
var _behavior: EnemyBehavior
var _knockback := Vector2.ZERO
var _dead := false
var _warning: Telegraph
var _warning_radius := 0.0
var _lane_direction := Vector2.RIGHT
var _lane_length := 0.0
var _lane_width := 0.0
var _visual: SpriteVisual
var _marks: EnemyMarks
var _show_bar := false
var _blew_itself_up := false
var _dismissed := false
var _blink_wait := 0.0


func setup(enemy_def: EnemyDef, chase_target: Node2D, warning_fraction: float, show_health_bar := false) -> void:
	def = enemy_def
	hp = def.max_hp
	target = chase_target
	_warning_fraction = warning_fraction
	_show_bar = show_health_bar
	_behavior = def.behavior_script.new()


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0 if def.ignores_walls else (1 | Hole.LAYER)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = def.body_size * 0.8
	shape.shape = rect
	add_child(shape)
	_visual = SpriteVisual.new()
	add_child(_visual)
	_visual.setup(def.id, def.body_size, def.color, def.frame_width)
	_marks = EnemyMarks.new()
	_marks.setup(def)
	add_child(_marks)
	# A soft glow keeps every enemy readable, however far it is from the room's torches.
	add_child(Lighting.make_light(READ_GLOW_COLOR, READ_GLOW_ENERGY, READ_GLOW_SCALE))


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	desired_velocity = Vector2.ZERO
	_behavior.tick(self, delta)
	velocity = desired_velocity + _knockback
	_knockback = _knockback.lerp(Vector2.ZERO, minf(KNOCKBACK_DECAY * delta, 1.0))
	move_and_slide()
	if def.ignores_walls:
		position = clamp_inside_room(position, room_cells)
	_marks.show_facing(facing)
	queue_redraw()


static func clamp_inside_room(point: Vector2, cells: Vector2i) -> Vector2:
	var tile := float(RoomBackdrop.TILE)
	return Vector2(
		clampf(point.x, tile, (cells.x - 1) * tile),
		clampf(point.y, tile, (cells.y - 1) * tile))


# Summons pay nothing, or a boss left alive could be farmed forever.
func coin_value() -> int:
	return 0 if is_summon or is_group_follower or _blew_itself_up else def.pension_drop


static func shield_covers(facing_way: Vector2, to_attacker: Vector2, half_angle_deg: float) -> bool:
	if half_angle_deg <= 0.0:
		return false
	return absf(facing_way.angle_to(to_attacker)) <= deg_to_rad(half_angle_deg)


func body_rect() -> Rect2:
	return Rect2(global_position - def.body_size / 2.0, def.body_size)


func shows_health_bar() -> bool:
	return _show_bar and def != null and not def.is_boss


# Bosses break what they reach, so cover does not last.
func smash(center: Vector2, radius: float) -> void:
	if is_inside_tree():
		BreakableBlock.smash(get_tree(), center, radius, BreakableBlock.SOURCE_BOSS)


# A hit struck from up close, which a shield can stop. Returns whether it landed.
func take_strike(amount: float, push: Vector2, to_attacker: Vector2) -> bool:
	if shield_covers(facing, to_attacker, def.shield_half_angle):
		if _marks != null:
			_marks.flash_shield()
		hit_blocked.emit()
		return false
	take_damage(amount, push)
	return true


func self_destruct() -> void:
	_blew_itself_up = true


# Leaves without any last act, as a boss's helpers do when the boss falls.
func dismiss() -> void:
	_dismissed = true
	take_damage(INF, Vector2.ZERO)


func take_damage(amount: float, push: Vector2) -> void:
	if _dead:
		return
	hp -= amount
	if _visual != null:
		_visual.flash()
	health_changed.emit(hp)
	queue_redraw()
	_knockback += push * (BOSS_KNOCKBACK_SCALE if def.is_boss else 1.0)
	if hp <= 0.0:
		_dead = true
		if not _dismissed and is_inside_tree():
			_behavior.on_killed(self)
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
	_lane_length = 0.0


# Adds a lane to the warning, for attacks that travel in a line. It ends at the first wall or
# hole, and shots stop at props too, while a boss breaks through them.
func set_warning_lane(direction: Vector2, length: float, width: float, through_props := true) -> void:
	_lane_direction = direction
	_lane_width = width
	_lane_length = _clear_length(direction, length, through_props)


func warning_lane_direction() -> Vector2:
	return _lane_direction


func _clear_length(direction: Vector2, length: float, through_props: bool) -> float:
	if not is_inside_tree():
		return length
	var space := get_world_2d().direct_space_state
	var skip: Array[RID] = []
	var mask := 1 if not through_props else 1 | Hole.LAYER
	var end := global_position + direction * length
	for i in MAX_PROPS_ACROSS_A_LANE:
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, end, mask, skip))
		if hit.is_empty():
			return length
		if through_props and hit.get("collider") is BreakableBlock:
			skip.append(hit["rid"])
			continue
		return global_position.distance_to(hit["position"])
	return length


func blink() -> void:
	_blink_wait -= get_physics_process_delta_time()
	if _blink_wait <= 0.0:
		_blink_wait = BLINK_EVERY * 2.0
		if _visual != null:
			_visual.flash(BLINK_COLOR, BLINK_EVERY)


func blast(radius: float, enemy_damage: float, push: float) -> void:
	var player_damage := def.damage
	EnemyBlast.go(get_parent(), global_position, radius, enemy_damage, push, target, player_damage)
	blasted.emit()


func enemies_alive() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


func target_in_view() -> bool:
	return BossMoves.in_view(target.global_position - global_position)


func target_motion() -> Vector2:
	return target.velocity if target is CharacterBody2D else Vector2.ZERO


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


# Marks each spot first, so a summon never appears without warning. Nothing comes if the
# boss falls while the marks are filling.
func request_summon_at(points: Array[Vector2], warning_time: float) -> void:
	if def.summon == null:
		return
	for point in points:
		var spot: Vector2 = summon_spot.call(point) if summon_spot.is_valid() else point
		var mark := SummonMark.new()
		mark.setup(warning_time)
		mark.position = spot
		mark.finished.connect(_on_summon_mark_finished.bind(spot))
		get_parent().add_child(mark)


func _on_summon_mark_finished(spot: Vector2) -> void:
	if not _dead:
		summon_requested.emit(def.summon, spot)


func _draw() -> void:
	if _warning != null and _warning.shows_warning(_warning_fraction):
		var progress := _warning.warning_progress(_warning_fraction)
		draw_circle(Vector2.ZERO, _warning_radius * progress, Color(0.89, 0.32, 0.31, 0.15 + 0.3 * progress))
		draw_arc(Vector2.ZERO, _warning_radius, 0.0, TAU, 32, WARNING_COLOR, 2.0)
		if _lane_length > 0.0:
			var lane := Rect2(0.0, -_lane_width / 2.0, _lane_length * progress, _lane_width)
			var outline := Rect2(0.0, -_lane_width / 2.0, _lane_length, _lane_width)
			draw_set_transform(Vector2.ZERO, _lane_direction.angle())
			draw_rect(lane, Color(WARNING_COLOR, 0.15 + 0.3 * progress))
			draw_rect(outline, WARNING_COLOR, false, 2.0)
			draw_set_transform(Vector2.ZERO)
	if def != null and shows_health_bar():
		var top := -def.body_size.y / 2.0 - 6.0
		var fraction := clampf(hp / def.max_hp, 0.0, 1.0)
		draw_rect(Rect2(-BAR_WIDTH / 2.0, top, BAR_WIDTH, BAR_HEIGHT), Color.BLACK)
		draw_rect(Rect2(-BAR_WIDTH / 2.0, top, BAR_WIDTH * fraction, BAR_HEIGHT), Color("e4524f"))
