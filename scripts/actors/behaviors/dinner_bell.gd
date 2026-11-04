class_name DinnerBell
extends RefCounted

# Three Early Bird Diners shuffle along together with their trays. The table keeps one clock, run by
# its first living member: every few seconds that one rings the dinner bell, every member shows a
# warning and a lane toward Grandpa, and when the bell stops they all rush at once, each down its own
# lane, pulling up a little past where he stood.
const META := &"dinner_bell"
const SIZE := 3
# Diners this close that have no table yet join one, as summoned diners do.
const GATHER_REACH := 160.0
const RUSH_EVERY := 4.5
const FIRST_BELL := 2.2
const BELL_TIME := 0.9
const BELL_TEXT := "Ding ding! Dinner!"
const SAY_TIME := 1.2
# Each rush runs this far past where he stood, and never shorter or longer than these.
const RUSH_PAST := 30.0
const RUSH_MIN := 60.0
const RUSH_MAX := 160.0

var members: Array[Enemy] = []
var telegraph := Telegraph.new()
# Each bell and each rush counts up once, so every member sees each exactly once.
var bells := 0
var rushes := 0
var _lanes := {}
var _lengths := {}
var _timer := FIRST_BELL


# Each member's lane: straight from where it stands toward Grandpa. One standing on him rushes down.
static func rush_lanes(spots: Array[Vector2], target: Vector2) -> Array[Vector2]:
	var lanes: Array[Vector2] = []
	for at in spots:
		var way := at.direction_to(target)
		lanes.append(way if not way.is_zero_approx() else Vector2.DOWN)
	return lanes


# How far a member rushes: to where he stood and a little past, within RUSH_MIN and RUSH_MAX.
static func rush_length(from: Vector2, target: Vector2) -> float:
	return clampf(from.distance_to(target) + RUSH_PAST, RUSH_MIN, RUSH_MAX)


# A table around a diner that has none yet: itself and the nearest diners of its kind that have no
# table either, up to SIZE in all.
static func gather(enemy: Enemy) -> DinnerBell:
	var table := DinnerBell.new()
	table.members.append(enemy)
	enemy.set_meta(META, table)
	if not enemy.is_inside_tree():
		return table
	var near: Array = []
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or other.is_dead() or other.def != enemy.def or other.has_meta(META):
			continue
		var distance := other.global_position.distance_to(enemy.global_position)
		if distance <= GATHER_REACH:
			near.append([distance, other])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in near:
		if table.members.size() >= SIZE:
			break
		var joining: Enemy = entry[1]
		table.members.append(joining)
		joining.set_meta(META, table)
	return table


func leader() -> Enemy:
	for member in members:
		if is_instance_valid(member) and not member.is_dead():
			return member
	return null


func has_lane(enemy: Enemy) -> bool:
	return _lanes.has(enemy.get_instance_id())


func lane_of(enemy: Enemy) -> Vector2:
	return _lanes.get(enemy.get_instance_id(), Vector2.DOWN)


func length_of(enemy: Enemy) -> float:
	return _lengths.get(enemy.get_instance_id(), RUSH_MIN)


# Only the leader's tick moves the table's clock, so three members never run it three times as fast.
func advance(enemy: Enemy, delta: float) -> void:
	if enemy != leader():
		return
	if telegraph.is_active():
		if telegraph.tick(delta):
			rushes += 1
		return
	_timer -= delta
	if _timer <= 0.0 and enemy.target_in_view():
		_timer = RUSH_EVERY
		_ring(enemy)


func _ring(enemy: Enemy) -> void:
	var alive: Array[Enemy] = []
	var spots: Array[Vector2] = []
	for member in members:
		if is_instance_valid(member) and not member.is_dead():
			alive.append(member)
			spots.append(member.global_position)
	var target := enemy.target_ground()
	var lanes := rush_lanes(spots, target)
	_lanes.clear()
	_lengths.clear()
	for i in alive.size():
		_lanes[alive[i].get_instance_id()] = lanes[i]
		_lengths[alive[i].get_instance_id()] = rush_length(spots[i], target)
	telegraph.start(BELL_TIME)
	bells += 1
	enemy.say(BELL_TEXT, SAY_TIME)
