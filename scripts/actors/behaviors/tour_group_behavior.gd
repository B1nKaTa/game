class_name TourGroupBehavior
extends EnemyBehavior

# One member of a Tour Group. The guide walks toward Grandpa with a flag raised, and the two followers
# keep behind it. When the guide calls, every member warns of a lane the same way, and then all of
# them rush down it at once. With the guide gone the followers scatter and wander slowly about the
# room, harmless, until they are seen off. See TourGroup.
# The guide's call is every member's windup.
const CALL_WINDUP := TourGroup.CALL_TIME
const RUSH_LENGTH := 90.0
const RUSH_SPEED := 300.0
const LANE_WIDTH := 20.0
const HIT_RANGE := 18.0
const WARNING_RADIUS := 16.0
# A member of a group waits this long for its guide to gather it before it gathers a group itself.
const PACK_GRACE := 0.3
# Running into a wall this soon after setting off is only the wall it leaned on.
const WALL_GRACE := 0.05
# A follower this near its spot behind the guide stands still.
const FOLLOW_NEAR := 6.0
const CATCH_UP := 1.3
# Scattered, a follower walks at this share of its speed toward a new spot this often, this far away.
const SCATTER_SPEED := 0.45
const WANDER_EVERY := 1.8
const WANDER_REACH := 90.0
const LOST_TEXT := "Where did they go?"

var _group: TourGroup
var _wait := PACK_GRACE
var _seen_call := 0
var _seen_rush := 0
var _rush_left := 0.0
var _rushed_for := 0.0
var _way := Vector2.DOWN
var _has_hit := false
var _scattered := false
var _wander_left := 0.0
var _wander_to := Vector2.INF
var _flag: TourGroup.GuideFlag
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func is_scattered() -> bool:
	return _scattered


func tick(enemy: Enemy, delta: float) -> void:
	if _rush_left > 0.0:
		_rush(enemy, delta)
		return
	if _group == null:
		_join(enemy, delta)
		if _group == null:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
			return
	if TourGroup.scatters(_group.has_guide(), _group.is_guide(enemy)):
		_wander(enemy, delta)
		return
	_group.advance(enemy, delta)
	if _group.rushes != _seen_rush:
		_seen_rush = _group.rushes
		enemy.clear_warning()
		if _seen_call == _group.calls:
			_start_rush(_group.way)
		return
	if _group.calls != _seen_call:
		_seen_call = _group.calls
		if _group.telegraph.is_active():
			enemy.set_warning(_group.telegraph, WARNING_RADIUS, true)
			enemy.set_warning_lane(_group.way, RUSH_LENGTH, LANE_WIDTH)
	if _group.telegraph.is_active():
		return
	if _group.is_guide(enemy):
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
		return
	var spot := TourGroup.follow_spot(_group.guide.global_position, _group.guide.direction_to_target(), _group.place_of(enemy))
	if enemy.global_position.distance_to(spot) > FOLLOW_NEAR:
		enemy.desired_velocity = enemy.walk_direction_to(spot) * enemy.def.speed * CATCH_UP


func _join(enemy: Enemy, delta: float) -> void:
	if enemy.has_meta(TourGroup.META):
		_group = enemy.get_meta(TourGroup.META)
		return
	_wait -= delta
	if enemy.is_group_follower and _wait > 0.0:
		return
	_group = TourGroup.gather(enemy)
	_flag = TourGroup.GuideFlag.new()
	_flag.height = enemy.def.body_size.y
	enemy.add_child(_flag)


func _start_rush(way: Vector2) -> void:
	_way = way
	_rush_left = RUSH_LENGTH
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


# Lost without the guide: no more rushes, only a slow amble from spot to spot.
func _wander(enemy: Enemy, delta: float) -> void:
	if not _scattered:
		_scattered = true
		enemy.clear_warning()
		enemy.say(LOST_TEXT, TourGroup.SAY_TIME)
		_wander_left = 0.0
	_wander_left -= delta
	if _wander_left <= 0.0 or _wander_to == Vector2.INF:
		_wander_left = WANDER_EVERY
		var spot := enemy.global_position + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(WANDER_REACH * 0.4, WANDER_REACH)
		_wander_to = Enemy.clamp_inside_room(spot, enemy.room_cells)
	if enemy.global_position.distance_to(_wander_to) > FOLLOW_NEAR:
		enemy.desired_velocity = enemy.walk_direction_to(_wander_to) * enemy.def.speed * SCATTER_SPEED
