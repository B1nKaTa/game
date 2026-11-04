class_name EarlyBirdDinerBehavior
extends EnemyBehavior

# Shuffles slowly toward Grandpa with the rest of its table of three, tray in hand. When the table's
# leader rings the dinner bell, every member warns of its lane, and then all three rush together to
# where he stood and a little past. See DinnerBell.
const RUSH_SPEED := 250.0
const LANE_WIDTH := 18.0
const HIT_RANGE := 18.0
const WARNING_RADIUS := 16.0
# The bell is the rush's windup, rung by the table, and its warning always shows whole.
const BELL_WINDUP := DinnerBell.BELL_TIME
# A member of a group waits this long for its leader to gather it before it gathers a table itself.
const TABLE_GRACE := 0.3
# Running into a wall this soon after setting off is only the wall it leaned on.
const WALL_GRACE := 0.05

var _table: DinnerBell
var _wait := TABLE_GRACE
var _seen_bell := 0
var _seen_rush := 0
var _rush_left := 0.0
var _rushed_for := 0.0
var _way := Vector2.DOWN
var _has_hit := false


func tick(enemy: Enemy, delta: float) -> void:
	if _rush_left > 0.0:
		_rush(enemy, delta)
		return
	if _table == null:
		_join(enemy, delta)
		if _table == null:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
			return
	_table.advance(enemy, delta)
	if _table.rushes != _seen_rush:
		_seen_rush = _table.rushes
		enemy.clear_warning()
		if _table.has_lane(enemy) and _seen_bell == _table.bells:
			_start_rush(_table.lane_of(enemy), _table.length_of(enemy))
		return
	if _table.bells != _seen_bell:
		_seen_bell = _table.bells
		if _table.has_lane(enemy):
			enemy.set_warning(_table.telegraph, WARNING_RADIUS, true)
			enemy.set_warning_lane(_table.lane_of(enemy), _table.length_of(enemy), LANE_WIDTH)
	if _table.telegraph.is_active():
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _join(enemy: Enemy, delta: float) -> void:
	if enemy.has_meta(DinnerBell.META):
		_table = enemy.get_meta(DinnerBell.META)
		return
	_wait -= delta
	if enemy.is_group_follower and _wait > 0.0:
		return
	_table = DinnerBell.gather(enemy)


func _start_rush(way: Vector2, length: float) -> void:
	_way = way
	_rush_left = length
	_rushed_for = 0.0
	_has_hit = false


func _rush(enemy: Enemy, delta: float) -> void:
	if _rushed_for > WALL_GRACE:
		for i in enemy.get_slide_collision_count():
			if BossDash.stops_at(enemy.get_slide_collision(i).get_collider()):
				_rush_left = 0.0
				return
	_rushed_for += delta
	enemy.hold_lane()
	_rush_left -= RUSH_SPEED * delta
	enemy.desired_velocity = _way * RUSH_SPEED
	if not _has_hit and enemy.global_position.distance_to(enemy.target_ground()) <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)
