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
# A room's enemies stand still this long as Grandpa walks in, so he can read the room first.
const ROOM_WAKE_TIME := 0.6
# Half a cell's diagonal: a floor spot this close is the cell he stands in.
const SAME_CELL_REACH := 0.71
# What a boss's heaviest named attacks cost Grandpa, in pills.
const HEAVY_DAMAGE := 2
const MOUND_COLOR := Color("5a4a33")
const MOUND_EDGE := Color("2b2218")
const DAZE_COLOR := Color("ffe58a")
const SAY_COLOR := Color("fff6d8")
# Warnings draw above everything in the room, the dark of Lights Out included, so none is ever hidden.
const WARNING_Z := 60
# How often a walker looks again for its way to Grandpa, and how near a waypoint counts as reached.
const ROUTE_EVERY := 0.3
const WAYPOINT_REACH := 4.0

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
# Says whether a point is ground at all, and not wall or a hole. A room sets this.
var open_ground: Callable
# Underground it is only a moving mound: nothing can hit it and it crosses anything. See set_submerged.
var submerged := false
# The room's walkable cells, shared by its enemies. Without one, an enemy walks straight at Grandpa.
var walk_grid: WalkGrid
var _warning_fraction := 0.5
var _behavior: EnemyBehavior
var _knockback := Vector2.ZERO
var _dead := false
var _warning: Telegraph
var _warning_radius := 0.0
var _warning_whole := false
var _lane_direction := Vector2.RIGHT
var _lane_length := 0.0
var _lane_width := 0.0
var _visual: SpriteVisual
var _marks: EnemyMarks
var _show_bar := false
var _blew_itself_up := false
var _dismissed := false
var _blink_wait := 0.0
var _wake_left := 0.0
var _dazed_left := 0.0
var _say_text := ""
var _say_left := 0.0
var _warning_layer: Node2D
# The floor's difficulty, set once before the enemy enters the room.
var _health_mult := 1.0
var _pension_mult := 1.0
var _route_left := 0.0
var _routing := false
var _waypoint := Vector2.ZERO


func setup(enemy_def: EnemyDef, chase_target: Node2D, warning_fraction: float, show_health_bar := false) -> void:
	def = enemy_def
	hp = max_hp()
	target = chase_target
	_warning_fraction = warning_fraction
	_show_bar = show_health_bar
	_behavior = def.behavior_script.new()


# A deeper floor makes the same enemy tougher and better paid. Call it before the enemy enters the room.
func apply_floor(health_mult: float, pension_mult: float) -> void:
	_health_mult = health_mult
	_pension_mult = pension_mult
	hp = max_hp()


func max_hp() -> float:
	return def.max_hp * _health_mult


# What an attack costs Grandpa: its own damage when it names one, the enemy's usual damage otherwise.
func attack_damage(damage := -1) -> int:
	return damage if damage >= 0 else def.damage


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
	_warning_layer = WarningLayer.new()
	_warning_layer.enemy = self
	_warning_layer.z_index = WARNING_Z
	add_child(_warning_layer)


# Draws the enemy's warnings and call-outs on their own layer, high above the room.
class WarningLayer extends Node2D:
	var enemy: Enemy

	func _draw() -> void:
		enemy._draw_warning(self)


# Stars circle its head while it is stunned.
func daze(seconds: float) -> void:
	_dazed_left = maxf(_dazed_left, seconds)


func is_dazed() -> bool:
	return _dazed_left > 0.0


# A few words over its head, such as a called-out bingo number.
func say(text: String, seconds: float) -> void:
	_say_text = text
	_say_left = seconds


func set_submerged(value: bool) -> void:
	submerged = value
	collision_layer = 0 if value else 4
	if not def.ignores_walls:
		collision_mask = 0 if value else (1 | Hole.LAYER)
	if _visual != null:
		_visual.visible = not value
		_marks.visible = not value
	queue_redraw()


func is_dead() -> bool:
	return _dead


# Only something walking on the floor slides on a wet one. Ghosts and mounds don't.
func is_on_wet() -> bool:
	if def.ignores_walls or submerged or not is_inside_tree():
		return false
	return WetFloor.is_wet_at(get_tree(), global_position)


# Where Grandpa actually stands, since a ground attack is about his feet.
func target_ground() -> Vector2:
	return target.feet().global_position if target.has_method("feet") else target.global_position


func move_under_target() -> void:
	var spot := target_ground()
	if not summon_spot.is_valid():
		global_position = spot
		return
	# Right under his feet on open floor. Only a spot inside something solid moves to the nearest floor.
	var floor_spot: Vector2 = summon_spot.call(spot)
	global_position = spot if floor_spot.distance_to(spot) <= RoomBackdrop.TILE * SAME_CELL_REACH else floor_spot


func burst_from_ground() -> void:
	DeathBurst.spawn(get_parent(), position, def.color, false)


# A damage of -1 costs the enemy's usual damage. A boss's heaviest attacks pass 2.
func strike_ground(at: Vector2, radius: float, warning: float, delay := 0.0, follow_time := 0.0, damage := -1) -> void:
	if open_ground.is_valid() and not open_ground.call(at):
		return
	var strike := GroundStrike.new()
	strike.setup(self, radius, warning, delay, follow_time, damage)
	get_parent().add_child(strike)
	strike.global_position = at


# Lands spot by spot along a line, and stops at the first wall or hole like the warning lane does.
func strike_line(points: Array[Vector2], radius: float, warning: float, step: float, damage := -1) -> void:
	for i in points.size():
		if open_ground.is_valid() and not open_ground.call(points[i]):
			return
		strike_ground(points[i], radius, warning, i * step, 0.0, damage)


# Breaks props as any boss attack does. A wall between shields Grandpa, as it does from a blast.
func land_ground_strike(at: Vector2, radius: float, damage := -1) -> void:
	smash(at, radius)
	if not is_inside_tree() or not is_instance_valid(target):
		return
	var feet := target_ground()
	if GroundStrike.hits(at, radius, feet) and EnemyBlast.line_is_clear(get_world_2d().direct_space_state, at, feet):
		hit_target(attack_damage(damage))


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	_dazed_left = maxf(_dazed_left - delta, 0.0)
	_say_left = maxf(_say_left - delta, 0.0)
	if _warning_layer != null:
		_warning_layer.queue_redraw()
	if _wake_left > 0.0:
		_wake_left -= delta
		return
	_route_left -= delta
	desired_velocity = Vector2.ZERO
	_behavior.tick(self, delta)
	velocity = desired_velocity + _knockback
	_knockback = _knockback.lerp(Vector2.ZERO, minf(KNOCKBACK_DECAY * delta, 1.0))
	move_and_slide()
	if def.ignores_walls or submerged:
		position = clamp_inside_room(position, room_cells)
	_marks.show_facing(facing)
	queue_redraw()


static func clamp_inside_room(point: Vector2, cells: Vector2i) -> Vector2:
	var tile := float(RoomBackdrop.TILE)
	return Vector2(
		clampf(point.x, tile, (cells.x - 1) * tile),
		clampf(point.y, tile, (cells.y - 1) * tile))


# Summons pay nothing, or a boss left alive could be farmed forever.
# A deeper floor pays more, rounded up. The small allowance keeps a whole result from rounding past itself.
func coin_value() -> int:
	if is_summon or is_group_follower or _blew_itself_up or def.pension_drop <= 0:
		return 0
	return ceili(def.pension_drop * _pension_mult - 0.0001)


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
	if submerged:
		return false
	if shield_covers(facing, to_attacker, def.shield_half_angle):
		if _marks != null:
			_marks.flash_shield()
		hit_blocked.emit()
		return false
	take_damage(amount, push)
	return true


func wait_for_room_start() -> void:
	_wake_left = ROOM_WAKE_TIME


func self_destruct() -> void:
	_blew_itself_up = true


# Leaves without any last act, as a boss's helpers do when the boss falls.
func dismiss() -> void:
	_dismissed = true
	take_damage(INF, Vector2.ZERO)


func take_damage(amount: float, push: Vector2) -> void:
	if _dead:
		return
	# Only leaving outright reaches something underground, so a room can always finish.
	if submerged and not is_inf(amount):
		return
	if not is_inf(amount) and _behavior != null:
		amount *= _behavior.damage_scale(self)
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


# Shown for the part of the windup the player's stats allow, unless the whole of it must show.
func set_warning(telegraph: Telegraph, radius: float, whole_windup := false) -> void:
	_warning = telegraph
	_warning_radius = radius
	_warning_whole = whole_windup


func _warning_share() -> float:
	return 1.0 if _warning_whole else _warning_fraction


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
	if not is_inside_tree() or def.ignores_walls:
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
	return BossMoves.in_view(body_rect(), Vector2(room_cells) * RoomBackdrop.TILE, target_ground())


# Which way to walk toward Grandpa: straight while nothing stands between, otherwise around
# the walls and props cell by cell. Ghosts and anything underground always go straight.
func chase_direction() -> Vector2:
	if walk_grid == null or def.ignores_walls or submerged:
		return direction_to_target()
	if _route_left <= 0.0 or (_routing and global_position.distance_to(_waypoint) <= WAYPOINT_REACH):
		_route_left = ROUTE_EVERY
		_plan_route()
	return global_position.direction_to(_waypoint) if _routing else direction_to_target()


func _plan_route() -> void:
	var goal := target_ground()
	# The narrower half of its collision box. Sliding takes care of a pixel or two of scraping.
	var half_width := minf(def.body_size.x, def.body_size.y) * 0.4 - 1.0
	_routing = false
	if walk_grid.line_is_clear(global_position, goal, half_width):
		return
	var next := walk_grid.next_cell(WalkGrid.cell_of(global_position), WalkGrid.cell_of(goal))
	if next == WalkGrid.NO_CELL or next == WalkGrid.cell_of(goal):
		return
	_routing = true
	# Its collision box is 0.8 of its body, plus a hair, so a big body aims where it really fits.
	_waypoint = walk_grid.fit_point(next, def.body_size * 0.4 + Vector2(0.5, 0.5))


func target_motion() -> Vector2:
	return target.velocity if target is CharacterBody2D else Vector2.ZERO


func shoot(direction: Vector2, speed: float, damage := -1) -> Projectile:
	var projectile := Projectile.new()
	projectile.setup(direction, speed, target, attack_damage(damage))
	projectile.position = position
	get_parent().add_child(projectile)
	return projectile


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
	if submerged:
		var mound := PackedVector2Array([Vector2(-11, 7), Vector2(-7, 0), Vector2(-2, -4), Vector2(4, -3), Vector2(9, 2), Vector2(12, 7)])
		draw_colored_polygon(mound, MOUND_COLOR)
		draw_polyline(mound, MOUND_EDGE, 1.0)
	if def != null and shows_health_bar():
		var top := -def.body_size.y / 2.0 - 6.0
		var fraction := clampf(hp / max_hp(), 0.0, 1.0)
		draw_rect(Rect2(-BAR_WIDTH / 2.0, top, BAR_WIDTH, BAR_HEIGHT), Color.BLACK)
		draw_rect(Rect2(-BAR_WIDTH / 2.0, top, BAR_WIDTH * fraction, BAR_HEIGHT), Color("e4524f"))


func _draw_warning(layer: Node2D) -> void:
	if _warning != null and _warning.shows_warning(_warning_share()):
		var progress := _warning.warning_progress(_warning_share())
		layer.draw_circle(Vector2.ZERO, _warning_radius * progress, Color(0.89, 0.32, 0.31, 0.15 + 0.3 * progress))
		layer.draw_arc(Vector2.ZERO, _warning_radius, 0.0, TAU, 32, WARNING_COLOR, 2.0)
		if _lane_length > 0.0:
			var lane := Rect2(0.0, -_lane_width / 2.0, _lane_length * progress, _lane_width)
			var outline := Rect2(0.0, -_lane_width / 2.0, _lane_length, _lane_width)
			layer.draw_set_transform(Vector2.ZERO, _lane_direction.angle())
			layer.draw_rect(lane, Color(WARNING_COLOR, 0.15 + 0.3 * progress))
			layer.draw_rect(outline, WARNING_COLOR, false, 2.0)
			layer.draw_set_transform(Vector2.ZERO)
	if def == null:
		return
	var top := -def.body_size.y / 2.0
	if _dazed_left > 0.0:
		var spin := Time.get_ticks_msec() / 160.0
		for i in 3:
			var at := Vector2(0.0, top - 5.0) + Vector2.from_angle(spin + TAU * i / 3.0) * Vector2(11.0, 4.0)
			layer.draw_circle(at, 2.0, DAZE_COLOR)
			layer.draw_line(at - Vector2(3, 0), at + Vector2(3, 0), DAZE_COLOR, 1.0)
	if _say_left > 0.0 and not _say_text.is_empty():
		var font := ThemeDB.fallback_font
		var size := 10
		var width := font.get_string_size(_say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var at := Vector2(-width / 2.0, top - 12.0)
		layer.draw_string_outline(font, at, _say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color.BLACK)
		layer.draw_string(font, at, _say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, SAY_COLOR)
