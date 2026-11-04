class_name WeepingMournerBehavior
extends EnemyBehavior

# Drifts slowly toward Grandpa with the rest of its pack of three. When the pack's leader wails,
# every member warns of its lane, and then all three lunge together. See MourningPack.
const LUNGE_LENGTH := 70.0
const LUNGE_SPEED := 280.0
const LANE_WIDTH := 18.0
const HIT_RANGE := 18.0
const WARNING_RADIUS := 16.0
# A member of a group waits this long for its leader to gather it before it gathers a pack itself.
const PACK_GRACE := 0.3
# Running into a wall this soon after setting off is only the wall it leaned on.
const WALL_GRACE := 0.05

var _pack: MourningPack
var _wait := PACK_GRACE
var _seen_wail := 0
var _seen_lunge := 0
var _lunge_left := 0.0
var _lunged_for := 0.0
var _way := Vector2.DOWN
var _has_hit := false


func tick(enemy: Enemy, delta: float) -> void:
	if _lunge_left > 0.0:
		_lunge(enemy, delta)
		return
	if _pack == null:
		_join(enemy, delta)
		if _pack == null:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
			return
	_pack.advance(enemy, delta)
	if _pack.lunges != _seen_lunge:
		_seen_lunge = _pack.lunges
		enemy.clear_warning()
		if _pack.has_lane(enemy) and _seen_wail == _pack.wails:
			_start_lunge(_pack.lane_of(enemy))
		return
	if _pack.wails != _seen_wail:
		_seen_wail = _pack.wails
		if _pack.has_lane(enemy):
			enemy.set_warning(_pack.telegraph, WARNING_RADIUS, true)
			enemy.set_warning_lane(_pack.lane_of(enemy), LUNGE_LENGTH, LANE_WIDTH)
	if _pack.telegraph.is_active():
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _join(enemy: Enemy, delta: float) -> void:
	if enemy.has_meta(MourningPack.META):
		_pack = enemy.get_meta(MourningPack.META)
		return
	_wait -= delta
	if enemy.is_group_follower and _wait > 0.0:
		return
	_pack = MourningPack.gather(enemy)


func _start_lunge(way: Vector2) -> void:
	_way = way
	_lunge_left = LUNGE_LENGTH
	_lunged_for = 0.0
	_has_hit = false


func _lunge(enemy: Enemy, delta: float) -> void:
	if _lunged_for > WALL_GRACE:
		for i in enemy.get_slide_collision_count():
			if BossDash.stops_at(enemy.get_slide_collision(i).get_collider()):
				_lunge_left = 0.0
				return
	_lunged_for += delta
	enemy.hold_lane()
	_lunge_left -= LUNGE_SPEED * delta
	enemy.desired_velocity = _way * LUNGE_SPEED
	if not _has_hit and enemy.global_position.distance_to(enemy.target_ground()) <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)
