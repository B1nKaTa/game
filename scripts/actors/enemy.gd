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
# The windup's tell when its warning is not drawn: a short pale flash, softer than a hit's.
const WINDUP_CUE := Color(1.0, 0.96, 0.82)
const WINDUP_CUE_TIME := 0.07
# Gap between the top of the art and the bar.
const BAR_GAP := 3.0
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
# A third floor's floor boss has one attack that costs this, and it always shows an extra-clear warning.
const HEAVIEST_DAMAGE := 3
# How far outside a heaviest lane its second outline stands.
const HEAVIEST_LANE_GAP := 6.0
const MOUND_COLOR := Color("5a4a33")
const MOUND_EDGE := Color("2b2218")
const SMOKE_COLOR := Color("8f8a94")
const DAZE_COLOR := Color("ffe58a")
const SAY_COLOR := Color("fff6d8")
# Warnings draw above everything in the room, the dark of Lights Out included, so none is ever hidden.
const WARNING_Z := 60
# How often a walker looks again for its way to Grandpa, and how near a waypoint counts as reached.
const ROUTE_EVERY := 0.3
# A swing needs only a thin line: line_is_clear also samples both sides at Harold's end, so a body-wide
# line would make him immune to melee when he stands against a wall. Samples are 8 px apart, which
# a corner touched diagonally by two solid cells does not slip through in practice.
const STRIKE_LINE_HALF_WIDTH := 0.0
const WAYPOINT_REACH := 4.0
# A goal that moves further than this from where its route was planned gets a new route at once.
const ROUTE_GOAL_SLACK := 64.0
# A whistle sends an enemy toward Grandpa this much faster, until it is this near him.
const RALLY_SPEED := 1.5
const RALLY_NEAR := 30.0

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
var _shadow: ContactShadow
# The health bar, drawn over the enemy's own art at its top (BarLayer), and the share it last showed.
var _bar_layer: Node2D
var _bar_shown := -1.0
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
var _cone_direction := Vector2.RIGHT
var _cone_length := 0.0
var _cone_angle := 0.0
var _visual: SpriteVisual
var _marks: EnemyMarks
var _show_bar := false
var _blew_itself_up := false
var _dismissed := false
var _blink_wait := 0.0
var _wake_left := 0.0
var _dazed_left := 0.0
# An item's stun and slow. See stun and slow.
var _stun_left := 0.0
var _slow_left := 0.0
var _slow_share := 1.0
var _say_text := ""
var _say_left := 0.0
var _warning_layer: Node2D
# The floor's difficulty, set once before the enemy enters the room.
var _health_mult := 1.0
var _pension_mult := 1.0
var _route_left := 0.0
var _routing := false
var _waypoint := Vector2.ZERO
var _route_goal := Vector2.INF
# Set again by a running dash or charge every frame, and cleared before each behavior tick.
var _holding_lane := false
# A shove that carries it along for a while, as an organ pipe's ring does. It adds to any knockback.
var _push := Vector2.ZERO
var _push_left := 0.0
var _rally_left := 0.0
# More warned lanes beside the main one, each [direction, length, width].
var _extra_lanes: Array = []
var _lane_heaviest := false
# Set while one of Grandpa's hits lands with the Undertaker's Work Gloves: dying to it, it leaves
# nothing harmful behind. Behaviors read it in on_killed.
var harmless_death := false
# Set by items when the Auditor walks in: more pills a hit costs (Repeat Offender), what his Pension is
# multiplied by, and whether he always leaves an item (Brown Envelope).
var extra_damage := 0
var coin_mult := 1.0
var leaves_item := false
# How much sooner it notices Grandpa: sleepers wake this many times as far, and a room's wait as he
# walks in is cut by it (Squeaky Shoes). Set by the room from his stats when it spawns.
var notice_mult := 1.0
# The anim driver's state (see _update_anim): how long a once-played anim still shows, and whether
# it was winding up last frame.
var _anim_once_left := 0.0
var _was_winding := false



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
	return (damage if damage >= 0 else def.damage) + extra_damage


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0 if def.ignores_walls else (1 | Hole.LAYER)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = def.body_size * 0.8
	shape.shape = rect
	add_child(shape)
	# Its look stands on its feet, the body box bottom, so the room sorts it there among the others.
	y_sort_enabled = true
	_visual = SpriteVisual.new()
	add_child(_visual)
	_visual.set_feet(def.body_size.y / 2.0)
	_visual.setup(def.art(), def.body_size, def.color, def.frame_width)
	_visual.set_recolor(def.art_hue_from, def.art_hue_to, def.art_hue_width, def.art_value)
	_marks = EnemyMarks.new()
	_marks.setup(def)
	# Art draws its own hat or prop; the shield arc still shows over it.
	_marks.art_shown = _visual.has_art()
	_marks.position = Vector2(0.0, -def.body_size.y / 2.0)
	_visual.add_child(_marks)
	# A soft glow keeps every enemy readable, however far it is from the room's torches.
	add_child(Lighting.make_light(READ_GLOW_COLOR, READ_GLOW_ENERGY, READ_GLOW_SCALE))
	_warning_layer = WarningLayer.new()
	_warning_layer.enemy = self
	_warning_layer.z_index = WARNING_Z
	add_child(_warning_layer)
	_bar_layer = BarLayer.new()
	_bar_layer.enemy = self
	add_child(_bar_layer)
	# In the depth look's dark, warnings keep their full colour (DepthLook.keep_vivid).
	DepthLook.keep_vivid(_warning_layer)
	# Its feet touch the ground: a wall-mounted one hangs on the wall instead.
	if not def.wall_mounted:
		_shadow = ContactShadow.add_to(self, def.body_size.x * 0.95, Vector2(0.0, def.body_size.y / 2.0))
	_behavior.on_ready(self)


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


# An item's stun: stars over its head, and its behavior holds still for so long, while a knockback
# still carries it. Behaviors that daze themselves keep their own timers and never call this.
func stun(seconds: float) -> void:
	if def != null and (def.wall_mounted or submerged):
		return
	daze(seconds)
	_stun_left = maxf(_stun_left, seconds)


func is_stunned() -> bool:
	return _stun_left > 0.0


# An item's slow: its own walk runs at this share of its speed for so long. The strongest one counts.
func slow(share: float, seconds: float) -> void:
	_slow_share = clampf(share, 0.0, 1.0) if _slow_left <= 0.0 else minf(_slow_share, share)
	_slow_left = maxf(_slow_left, seconds)


func is_slowed() -> bool:
	return _slow_left > 0.0


# Whether it is winding up an attack: its warning's windup is still running.
func is_winding_up() -> bool:
	return _warning != null and _warning.is_active()


# Plays one of its anims once over seconds, as a behavior's own move (a whistle, a summon). Without
# that strip it falls back to the attack, then the idle. Looks only: nothing waits on it.
func play_anim(anim_name: String, seconds: float) -> void:
	if _visual == null or not _visual.has_art():
		return
	_visual.play_once(anim_name, seconds)
	_anim_once_left = seconds


func visual() -> SpriteVisual:
	return _visual


# Whether its red attack warnings are drawn: only with the Attack warnings setting on (AttackWarnings),
# for a boss or mini boss as for a regular. The timing behind them never changes.
func shows_warnings() -> bool:
	return AttackWarnings.drawn_for(def)


# Picks its anim and the way it faces from what it does (EnemyAnim). Looks only.
func _update_anim(delta: float) -> void:
	if _visual == null or not _visual.has_art():
		return
	var winding := is_winding_up()
	var to_target := direction_to_target() if is_instance_valid(target) else Vector2.ZERO
	# A behavior's own anim (play_anim), started with the windup or as it ends, plays on through both
	# rather than giving way to the plain windup or attack.
	var own := _anim_once_left > 0.0 and _visual.anim() != EnemyAnim.WINDUP and _visual.anim() != EnemyAnim.ATTACK
	if winding and not _was_winding:
		if not own:
			_visual.play_once(EnemyAnim.WINDUP, _warning.remaining())
			_anim_once_left = 0.0
		# With no shape on the floor, a pale flash marks the moment the windup starts.
		if not shows_warnings():
			_visual.flash(WINDUP_CUE, WINDUP_CUE_TIME)
	elif _was_winding and not winding and not _dead and not own:
		# The hit lands as the windup ends. Without an attack strip it carries on as it would.
		if SpriteVisual.has_anim(def.art(), EnemyAnim.ATTACK):
			_visual.play_once(EnemyAnim.ATTACK, EnemyAnim.ATTACK_TIME)
			_anim_once_left = EnemyAnim.ATTACK_TIME
	_was_winding = winding
	var busy := winding or _anim_once_left > 0.0
	if _anim_once_left > 0.0:
		_anim_once_left = maxf(_anim_once_left - delta, 0.0)
	elif not winding:
		_visual.play(EnemyAnim.pick(false, desired_velocity))
	if not def.art_flips:
		_visual.set_facing_left(false)
		return
	_visual.set_facing_left(EnemyAnim.faces_left(_visual.is_facing_left(), busy, desired_velocity, to_target))


# A few words over its head, such as a called-out bingo number.
# What a boss says sits over his head, or under his feet when over his head would reach into the
# HUD's top rows (Hud.BAND_BOTTOM on screen), and slides in from the screen's sides. at is his spot on
# screen and zoom the canvas's scale; returns the text's baseline start in his own space.
const SAY_SIZE := 10
const SAY_MARGIN := 4.0


static func say_spot(at: Vector2, zoom: float, body_height: float, width: float, view: Vector2) -> Vector2:
	var z := zoom if zoom > 0.0 else 1.0
	var spot := Vector2(-width / 2.0, -body_height / 2.0 - 12.0)
	if at.y + (spot.y - SAY_SIZE) * z < Hud.BAND_BOTTOM:
		spot.y = body_height / 2.0 + SAY_SIZE + 8.0
	var left := (SAY_MARGIN - at.x) / z
	var right := (view.x - SAY_MARGIN - at.x) / z - width
	if right >= left:
		spot.x = clampf(spot.x, left, right)
	return spot


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
		if _shadow != null:
			_shadow.visible = not value
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


# A damage of -1 costs the enemy's usual damage. A boss's heaviest attacks pass 2. A linger leaves the
# spot burning for that long after it lands.
func strike_ground(at: Vector2, radius: float, warning: float, delay := 0.0, follow_time := 0.0, damage := -1, linger := 0.0) -> GroundStrike:
	if open_ground.is_valid() and not open_ground.call(at):
		return null
	var strike := GroundStrike.new()
	strike.setup(self, radius, warning, delay, follow_time, damage, linger)
	get_parent().add_child(strike)
	strike.global_position = at
	return strike


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
	if _bar_layer != null and shows_health_bar():
		var share := clampf(hp / max_hp(), 0.0, 1.0)
		if not is_equal_approx(share, _bar_shown):
			_bar_shown = share
			_bar_layer.queue_redraw()
	if _wake_left > 0.0:
		_wake_left -= delta
		return
	_route_left -= delta
	desired_velocity = Vector2.ZERO
	_holding_lane = false
	_stun_left = maxf(_stun_left - delta, 0.0)
	if _stun_left <= 0.0:
		_behavior.tick(self, delta)
	if _slow_left > 0.0:
		_slow_left = maxf(_slow_left - delta, 0.0)
		desired_velocity *= _slow_share
	# Called by a whistle, it hurries to Grandpa whenever it would walk anyway, so it never drops an attack.
	if _rally_left > 0.0:
		_rally_left -= delta
		if not desired_velocity.is_zero_approx() and distance_to_target() > RALLY_NEAR:
			desired_velocity = chase_direction() * def.speed * RALLY_SPEED
	# Something bolted to the wall stays put, however hard it is hit.
	if def.wall_mounted:
		_knockback = Vector2.ZERO
		desired_velocity = Vector2.ZERO
	velocity = desired_velocity + _knockback
	if _push_left > 0.0:
		_push_left -= delta
		velocity += _push
	if slides_with_roll() and is_inside_tree():
		velocity += ShipDeck.slide_at(get_tree(), global_position)
	_knockback = _knockback.lerp(Vector2.ZERO, minf(KNOCKBACK_DECAY * delta, 1.0))
	move_and_slide()
	if def.ignores_walls or submerged:
		position = clamp_inside_room(position, room_cells)
	_marks.show_facing(facing)
	queue_redraw()


func _process(delta: float) -> void:
	_update_anim(delta)


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
	return ceili(def.pension_drop * _pension_mult * coin_mult - 0.0001)


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


# A shove for a while on top of its own walk, such as an organ pipe's ring. A boss barely moves, as
# with any knockback, and nothing bolted down or underground moves at all.
func apply_push(shove: Vector2, seconds: float) -> void:
	if def == null or def.wall_mounted or submerged:
		return
	_push = shove * (BOSS_KNOCKBACK_SCALE if def.is_boss else 1.0)
	_push_left = seconds


func is_pushed() -> bool:
	return _push_left > 0.0


# A rolling deck slides whatever walks on it, but a boss keeps its footing. Ghosts float over it, a
# mound is under it, something bolted to a wall never moves, and a running charge holds its lane.
func slides_with_roll() -> bool:
	return def != null and not def.ignores_walls and not def.wall_mounted and not submerged and not _holding_lane and not def.is_boss


# A dash or charge calls this each frame it runs, so a rolling deck never carries it off the lane it
# warned.
func hold_lane() -> void:
	_holding_lane = true


# Whether a Mall Cop's whistle can call it: anything that walks, but no boss.
func answers_whistle() -> bool:
	return def != null and not def.is_boss and not def.wall_mounted and not submerged


# A whistle sends it toward Grandpa faster for a while.
func rally(seconds: float) -> void:
	if answers_whistle():
		_rally_left = maxf(_rally_left, seconds)


func is_rallied() -> bool:
	return _rally_left > 0.0


func wait_for_room_start() -> void:
	_wake_left = ROOM_WAKE_TIME / maxf(notice_mult, 1.0)


# Waits as at the room's start, with no stun stars, while the room's rule is announced. Never cuts a
# longer wait short.
func hold(seconds: float) -> void:
	_wake_left = maxf(_wake_left, seconds)


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
	if hp > 0.0 and not is_inf(amount):
		Sfx.play("boss_hit" if def.is_boss else "enemy_hit")
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


# What walking into its body costs Grandpa right now. See ContactRule.
func contact_damage() -> int:
	var gone := _dead or _dismissed or is_queued_for_deletion()
	var asleep := _behavior != null and _behavior.is_sleeping(self)
	return ContactRule.damage(def, gone, _wake_left > 0.0, submerged, asleep)


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
	_cone_length = 0.0
	_extra_lanes.clear()
	_lane_heaviest = false


# The lane is the heaviest attack's, which shows a second outline outside the first, so a
# three-pill charge never reads as an ordinary one.
func mark_lane_heaviest() -> void:
	_lane_heaviest = true


func lane_is_heaviest() -> bool:
	return _lane_heaviest


# Adds one more lane to the warning, for an attack that flies down several at once, such as a fan of
# coins. Each ends at the first wall like the main lane, and all of them go with the warning.
func add_warning_lane(direction: Vector2, length: float, width: float, through_props := true) -> void:
	_extra_lanes.append([direction, _clear_length(direction, length, through_props), width])


func warning_lane_count() -> int:
	return _extra_lanes.size() + (1 if _lane_length > 0.0 else 0)


# Adds a cone to the warning, for a breath that fans out from the body. Angle is the whole width.
func set_warning_cone(direction: Vector2, length: float, angle_deg: float) -> void:
	_cone_direction = direction
	_cone_length = length
	_cone_angle = deg_to_rad(angle_deg)


func warning_cone_length() -> float:
	return _cone_length


func warning_cone_direction() -> Vector2:
	return _cone_direction


func warning_cone_angle() -> float:
	return rad_to_deg(_cone_angle)


# Adds a lane to the warning, for attacks that travel in a line. It ends at the first wall or
# hole, and shots stop at props too, while a boss breaks through them.
func set_warning_lane(direction: Vector2, length: float, width: float, through_props := true) -> void:
	_lane_direction = direction
	_lane_width = width
	_lane_length = _clear_length(direction, length, through_props)


func warning_lane_direction() -> Vector2:
	return _lane_direction


# How far the warned lane really runs, since it ends at the first wall.
func warning_lane_length() -> float:
	return _lane_length


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


# Whether its whole body is in what the camera shows. The camera centres on Grandpa's camera_focus,
# which the Telescope Cane moves ahead of his feet, so this asks the same point.
func target_in_view() -> bool:
	var focus: Vector2 = target.camera_focus() if target.has_method("camera_focus") else target_ground()
	return BossMoves.in_view(body_rect(), Vector2(room_cells) * RoomBackdrop.TILE, focus)


# Which way to walk toward Grandpa: straight while nothing stands between, otherwise around
# the walls and props cell by cell. Ghosts and anything underground always go straight.
func chase_direction() -> Vector2:
	if walk_grid == null or def.ignores_walls or submerged:
		return direction_to_target()
	return _routed_direction(target_ground(), direction_to_target())


# Which way to walk toward any point, such as a spot on a loop or beside a partner: straight while
# nothing stands between, otherwise around the walls and props as chase_direction goes.
func walk_direction_to(point: Vector2) -> Vector2:
	var straight := global_position.direction_to(point)
	if walk_grid == null or def.ignores_walls or submerged:
		return straight
	return _routed_direction(point, straight)


# One route is kept at a time, so a goal far from the one it was planned for is planned afresh at once.
func _routed_direction(goal: Vector2, straight: Vector2) -> Vector2:
	var moved_goal := goal.distance_to(_route_goal) > ROUTE_GOAL_SLACK
	if moved_goal or _route_left <= 0.0 or (_routing and global_position.distance_to(_waypoint) <= WAYPOINT_REACH):
		_route_left = ROUTE_EVERY
		_plan_route(goal)
	return global_position.direction_to(_waypoint) if _routing else straight


# The narrower half of its collision box. Sliding takes care of a pixel or two of scraping.
func _route_half_width() -> float:
	return minf(def.body_size.x, def.body_size.y) * 0.4 - 1.0


# Whether nothing solid stands between it and Grandpa's feet, so a melee swing may begin. A ghost,
# anything underground and a room without a grid always may.
func can_strike_target() -> bool:
	if walk_grid == null or def.ignores_walls or submerged:
		return true
	return walk_grid.line_is_clear(global_position, target_ground(), STRIKE_LINE_HALF_WIDTH)


func _plan_route(goal: Vector2) -> void:
	_route_goal = goal
	_routing = false
	if walk_grid.line_is_clear(global_position, goal, _route_half_width()):
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
	if count > 0:
		Sfx.play("summon")
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
		Sfx.play("summon")
		summon_requested.emit(def.summon, spot)


func _draw() -> void:
	if submerged and def.hidden_look == "smoke":
		# A drifting wisp of soot, faint enough to read as nothing to hit.
		var drift := Time.get_ticks_msec() / 300.0
		for i in 3:
			var at := Vector2(cos(drift + i * 2.1) * 6.0, sin(drift * 1.3 + i) * 3.0 - i * 4.0)
			draw_circle(at, 7.0 - i * 1.5, Color(SMOKE_COLOR, 0.45 - i * 0.1))
	elif submerged:
		var mound := PackedVector2Array([Vector2(-11, 7), Vector2(-7, 0), Vector2(-2, -4), Vector2(4, -3), Vector2(9, 2), Vector2(12, 7)])
		draw_colored_polygon(mound, MOUND_COLOR)
		draw_polyline(mound, MOUND_EDGE, 1.0)


# With no ring, a mound about to rise under Grandpa is hidden by his body, so it gets the regulars' cue
# where he can see it: a short pale flash round the spot as the windup starts, then earth kicked up out
# from under him, never red and never wider than the hit.
func _draw_rising_cue(layer: Node2D) -> void:
	var elapsed := maxf(_warning._duration - _warning.remaining(), 0.0)
	var share := clampf(elapsed / maxf(_warning._duration, 0.01), 0.0, 1.0)
	if elapsed < WINDUP_CUE_TIME * 2.0:
		layer.draw_arc(Vector2(0.0, 6.0), 14.0, 0.0, TAU, 20, Color(WINDUP_CUE, 0.85), 2.0)
	var reach := 8.0 + 14.0 * share
	for i in 6:
		var way := Vector2.from_angle(TAU * i / 6.0 + share * 2.0)
		var hop := absf(sin(elapsed * 14.0 + i)) * 3.0
		layer.draw_circle(Vector2(0.0, 6.0) + way * Vector2(reach, reach * 0.45) - Vector2(0.0, hop), 1.5 + share, MOUND_COLOR)


# With the warnings hidden, a boss's or mini boss's slam, lanes and cone still show where they will hurt
# as the faint dark cue (AttackWarnings.draw_cue_circle and the rest), in the same shapes as the red ones
# and never red. A regular's body attack keeps only its windup flash.
# In her own Lights Out (a behavior whose is_dark() says so) the cue is drawn pale, since a dark one
# would vanish in the dark.
func _draw_boss_cue(layer: Node2D) -> void:
	var progress := _warning.warning_progress(_warning_share())
	var pale: bool = _behavior != null and _behavior.has_method("is_dark") and _behavior.is_dark()
	if _warning_radius > 0.0:
		AttackWarnings.draw_cue_circle(layer, Vector2.ZERO, _warning_radius, progress, pale)
	if _lane_length > 0.0:
		layer.draw_set_transform(Vector2.ZERO, _lane_direction.angle())
		AttackWarnings.draw_cue_lane(layer, Rect2(0.0, -_lane_width / 2.0, _lane_length, _lane_width), progress, pale)
		layer.draw_set_transform(Vector2.ZERO)
	for extra: Array in _extra_lanes:
		var way: Vector2 = extra[0]
		var length: float = extra[1]
		var width: float = extra[2]
		layer.draw_set_transform(Vector2.ZERO, way.angle())
		AttackWarnings.draw_cue_lane(layer, Rect2(0.0, -width / 2.0, length, width), progress, pale)
		layer.draw_set_transform(Vector2.ZERO)
	if _cone_length > 0.0:
		var base := _cone_direction.angle() - _cone_angle / 2.0
		var cone := PackedVector2Array([Vector2.ZERO])
		for i in 13:
			cone.append(Vector2.from_angle(base + _cone_angle * i / 12.0) * _cone_length)
		AttackWarnings.draw_cue_polygon(layer, cone, progress, pale)


# Where the health bar's top goes, in the enemy's own space: a few pixels over the top of its drawn art
# (SpriteVisual.idle_height above its feet), not over the hit box, which is shorter than most art.
func bar_top() -> float:
	if def == null:
		return 0.0
	var feet := def.body_size.y / 2.0
	var art := _visual.idle_height() if _visual != null else def.body_size.y
	return feet - maxf(art, def.body_size.y) - BAR_GAP - BAR_HEIGHT


func _draw_bar(layer: Node2D) -> void:
	if def == null or not shows_health_bar() or submerged:
		return
	var top := bar_top()
	var fraction := clampf(hp / max_hp(), 0.0, 1.0)
	var back := Rect2(-BAR_WIDTH / 2.0 - 1.0, top - 1.0, BAR_WIDTH + 2.0, BAR_HEIGHT + 2.0)
	layer.draw_rect(back, Color.BLACK)
	layer.draw_rect(Rect2(-BAR_WIDTH / 2.0, top, BAR_WIDTH, BAR_HEIGHT), Color("3a1414"))
	layer.draw_rect(Rect2(-BAR_WIDTH / 2.0, top, BAR_WIDTH * fraction, BAR_HEIGHT), Color("e4524f"))


# The health bar, drawn one z over the bodies so no sprite, its own or a neighbour's, hides it.
class BarLayer extends Node2D:
	var enemy: Node2D

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		enemy._draw_bar(self)


# The red warning shapes show only with Attack warnings on (shows_warnings); a hidden boss's become the
# faint cue (_draw_boss_cue). The stun's stars and what it says always show.
func _draw_warning(layer: Node2D) -> void:
	if shows_warnings() and _warning != null and _warning.shows_warning(_warning_share()):
		var progress := _warning.warning_progress(_warning_share())
		layer.draw_circle(Vector2.ZERO, _warning_radius * progress, Color(0.89, 0.32, 0.31, 0.15 + 0.3 * progress))
		layer.draw_arc(Vector2.ZERO, _warning_radius, 0.0, TAU, 32, WARNING_COLOR, 2.0)
		if _lane_length > 0.0:
			var lane := Rect2(0.0, -_lane_width / 2.0, _lane_length * progress, _lane_width)
			var outline := Rect2(0.0, -_lane_width / 2.0, _lane_length, _lane_width)
			layer.draw_set_transform(Vector2.ZERO, _lane_direction.angle())
			layer.draw_rect(lane, Color(WARNING_COLOR, 0.15 + 0.3 * progress))
			layer.draw_rect(outline, WARNING_COLOR, false, 2.0)
			if _lane_heaviest:
				layer.draw_rect(outline.grow(HEAVIEST_LANE_GAP), WARNING_COLOR, false, 2.0)
			layer.draw_set_transform(Vector2.ZERO)
		for extra: Array in _extra_lanes:
			var way: Vector2 = extra[0]
			var length: float = extra[1]
			var width: float = extra[2]
			layer.draw_set_transform(Vector2.ZERO, way.angle())
			layer.draw_rect(Rect2(0.0, -width / 2.0, length * progress, width), Color(WARNING_COLOR, 0.15 + 0.3 * progress))
			layer.draw_rect(Rect2(0.0, -width / 2.0, length, width), WARNING_COLOR, false, 2.0)
			layer.draw_set_transform(Vector2.ZERO)
		if _cone_length > 0.0:
			var base := _cone_direction.angle() - _cone_angle / 2.0
			var fill := PackedVector2Array([Vector2.ZERO])
			var outline := PackedVector2Array([Vector2.ZERO])
			for i in 13:
				var edge := Vector2.from_angle(base + _cone_angle * i / 12.0)
				fill.append(edge * _cone_length * progress)
				outline.append(edge * _cone_length)
			outline.append(Vector2.ZERO)
			if progress > 0.0:
				layer.draw_colored_polygon(fill, Color(WARNING_COLOR, 0.2 + 0.3 * progress))
			layer.draw_polyline(outline, WARNING_COLOR, 2.0)
	elif def != null and def.is_boss and _warning != null and _warning.shows_warning(_warning_share()):
		_draw_boss_cue(layer)
	elif submerged and def != null and def.hidden_look != "smoke" and is_winding_up():
		_draw_rising_cue(layer)
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
		var size := SAY_SIZE
		var width := font.get_string_size(_say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var screen := layer.get_global_transform_with_canvas()
		var at := say_spot(screen.origin, screen.get_scale().y, def.body_size.y, width, Vector2(RoomBackdrop.VIEW_SIZE))
		layer.draw_string_outline(font, at, _say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color.BLACK)
		layer.draw_string(font, at, _say_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, SAY_COLOR)
