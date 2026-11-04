class_name MallCopBehavior
extends EnemyBehavior

# Rides his scooter down a warned lane at Grandpa, stopping short at anything solid. Then he stops and
# blows his whistle, which sends the nearest other enemy hurrying toward Grandpa for a while.
const START_RANGE := 210.0
const WINDUP := 0.8
const CHARGE_LENGTH := 260.0
const CHARGE_SPEED := 320.0
const LANE_WIDTH := 30.0
const HIT_RANGE := 16.0
const WARNING_RADIUS := 20.0
const WHISTLE_TIME := 0.6
const RALLY_TIME := 2.0
const COOLDOWN := 3.0
const FIRST_CHARGE := 1.2
const WALL_GRACE := 0.05
const WHISTLE_TEXT := "FWEEET!"

var _telegraph := Telegraph.new()
var _cooldown := FIRST_CHARGE
var _charge_left := 0.0
var _charged_for := 0.0
var _whistle_left := 0.0
var _way := Vector2.RIGHT
var _has_hit := false


# Which of the spots lies nearest the one at index me, or -1 when there is no other.
static func nearest_other(spots: Array[Vector2], me: int) -> int:
	if me < 0 or me >= spots.size():
		return -1
	var best := -1
	var best_distance := INF
	for i in spots.size():
		if i == me:
			continue
		var distance := spots[i].distance_squared_to(spots[me])
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


func tick(enemy: Enemy, delta: float) -> void:
	if _charge_left > 0.0:
		_charge(enemy, delta)
		return
	if _whistle_left > 0.0:
		_whistle_left -= delta
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_charge_left = CHARGE_LENGTH
			_charged_for = 0.0
			_has_hit = false
		return
	_cooldown -= delta
	if _cooldown <= 0.0 and enemy.distance_to_target() <= START_RANGE and enemy.target_in_view():
		_way = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_way, CHARGE_LENGTH, LANE_WIDTH, false)
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _charge(enemy: Enemy, delta: float) -> void:
	if _charged_for > WALL_GRACE and enemy.get_slide_collision_count() > 0:
		_stop(enemy)
		return
	_charged_for += delta
	enemy.hold_lane()
	_charge_left -= CHARGE_SPEED * delta
	enemy.desired_velocity = _way * CHARGE_SPEED
	if not _has_hit and enemy.global_position.distance_to(enemy.target_ground()) <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)
	if _charge_left <= 0.0:
		_stop(enemy)


# The scooter stops, and he whistles up help.
func _stop(enemy: Enemy) -> void:
	_charge_left = 0.0
	_cooldown = COOLDOWN
	_whistle_left = WHISTLE_TIME
	enemy.say(WHISTLE_TEXT, WHISTLE_TIME + 0.3)
	if not enemy.is_inside_tree():
		return
	var others: Array[Enemy] = []
	var spots: Array[Vector2] = []
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or (not other.is_dead() and other.answers_whistle()):
			others.append(other)
			spots.append(other.global_position)
	var called := nearest_other(spots, others.find(enemy))
	if called >= 0:
		others[called].rally(RALLY_TIME)
