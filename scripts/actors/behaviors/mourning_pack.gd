class_name MourningPack
extends RefCounted

# Three Weeping Mourners grieve together. The pack keeps one clock, run by its first living member:
# every few seconds that one wails, every member shows a warning and a lane toward Grandpa, and when
# the wail ends they all lunge at once, each down its own lane.
const META := &"mourning_pack"
const SIZE := 3
# Mourners this close that have no pack yet join one, as summoned mourners do.
const GATHER_REACH := 160.0
const LUNGE_EVERY := 4.0
const FIRST_WAIL := 2.0
const WAIL_TIME := 0.8
const WAIL_TEXT := "Wooo..."
const SAY_TIME := 1.2

var members: Array[Enemy] = []
var telegraph := Telegraph.new()
# Each wail and each lunge counts up once, so every member sees each exactly once.
var wails := 0
var lunges := 0
var _lanes := {}
var _timer := FIRST_WAIL


# Each member's lane: straight from where it stands toward Grandpa. One standing on him lunges down.
static func lunge_lanes(spots: Array[Vector2], target: Vector2) -> Array[Vector2]:
	var lanes: Array[Vector2] = []
	for at in spots:
		var way := at.direction_to(target)
		lanes.append(way if not way.is_zero_approx() else Vector2.DOWN)
	return lanes


# A pack around a mourner that has none yet: itself and the nearest mourners of its kind that have
# no pack either, up to SIZE in all.
static func gather(enemy: Enemy) -> MourningPack:
	var pack := MourningPack.new()
	pack.members.append(enemy)
	enemy.set_meta(META, pack)
	if not enemy.is_inside_tree():
		return pack
	var near: Array = []
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or other.is_dead() or other.def != enemy.def or other.has_meta(META):
			continue
		var distance := other.global_position.distance_to(enemy.global_position)
		if distance <= GATHER_REACH:
			near.append([distance, other])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in near:
		if pack.members.size() >= SIZE:
			break
		var joining: Enemy = entry[1]
		pack.members.append(joining)
		joining.set_meta(META, pack)
	return pack


func leader() -> Enemy:
	for member in members:
		if is_instance_valid(member) and not member.is_dead():
			return member
	return null


func has_lane(enemy: Enemy) -> bool:
	return _lanes.has(enemy.get_instance_id())


func lane_of(enemy: Enemy) -> Vector2:
	return _lanes.get(enemy.get_instance_id(), Vector2.DOWN)


# Only the leader's tick moves the pack's clock, so three members never run it three times as fast.
func advance(enemy: Enemy, delta: float) -> void:
	if enemy != leader():
		return
	if telegraph.is_active():
		if telegraph.tick(delta):
			lunges += 1
		return
	_timer -= delta
	if _timer <= 0.0 and enemy.target_in_view():
		_timer = LUNGE_EVERY
		_begin_wail(enemy)


func _begin_wail(enemy: Enemy) -> void:
	var alive: Array[Enemy] = []
	var spots: Array[Vector2] = []
	for member in members:
		if is_instance_valid(member) and not member.is_dead():
			alive.append(member)
			spots.append(member.global_position)
	var lanes := lunge_lanes(spots, enemy.target_ground())
	_lanes.clear()
	for i in alive.size():
		_lanes[alive[i].get_instance_id()] = lanes[i]
	telegraph.start(WAIL_TIME)
	wails += 1
	enemy.say(WAIL_TEXT, SAY_TIME)
