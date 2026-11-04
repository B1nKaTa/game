class_name TourGroup
extends RefCounted

# A Tour Group: a guide with a flag and two followers. The group keeps one clock, run by its guide:
# every few seconds the guide raises the flag and calls out, every member shows a warning and a lane,
# all of them the same way (the guide's way to Grandpa), and when the call ends they rush down their
# lanes together, the followers copying the guide. If the guide falls, the tour is over: the followers
# scatter and wander slowly, and never rush again.
const META := &"tour_group"
const SIZE := 3
# Members this close that have no group yet join one, as summoned tourists do.
const GATHER_REACH := 160.0
const RUSH_EVERY := 4.5
const FIRST_CALL := 2.0
const CALL_TIME := 0.9
const CALL_TEXT := "This way, everyone!"
const SAY_TIME := 1.2
# Followers keep this far behind the guide, one to each side.
const FOLLOW_GAP := 26.0


# The guide's little flag on a pole, held over the head, so the one to hit first reads at a glance.
class GuideFlag extends Node2D:
	var height := 20.0

	func _draw() -> void:
		var top := Vector2(6.0, -height / 2.0 - 16.0)
		draw_line(Vector2(6.0, -height / 2.0 + 4.0), top, Color("3c4048"), 2.0)
		draw_colored_polygon(PackedVector2Array([top, top + Vector2(11.0, 3.5), top + Vector2(0.0, 7.0)]), Color("f2c230"))
		draw_polyline(PackedVector2Array([top, top + Vector2(11.0, 3.5), top + Vector2(0.0, 7.0)]), Color.BLACK, 1.0)


var members: Array[Enemy] = []
var guide: Enemy
var telegraph := Telegraph.new()
# Each call and each rush counts up once, so every member sees each exactly once.
var calls := 0
var rushes := 0
# The way every member rushes on the last call.
var way := Vector2.DOWN
var _timer := FIRST_CALL


# The way the whole group rushes: from the guide straight at Grandpa. A guide on top of him rushes down.
static func rush_lane(guide_at: Vector2, target: Vector2) -> Vector2:
	var lane := guide_at.direction_to(target)
	return lane if not lane.is_zero_approx() else Vector2.DOWN


# Where a follower walks: behind the guide as the guide faces, the first to one side, the second to the
# other.
static func follow_spot(guide_at: Vector2, facing: Vector2, place: int) -> Vector2:
	var back := -facing.normalized() if not facing.is_zero_approx() else Vector2.UP
	var side := back.orthogonal() * (1.0 if place % 2 == 1 else -1.0)
	return guide_at + back * FOLLOW_GAP + side * FOLLOW_GAP * 0.6


# Whether a member wanders off: only once the guide is gone, and never the guide itself.
static func scatters(guide_alive: bool, is_guide: bool) -> bool:
	return not guide_alive and not is_guide


# A group led by a member that has none yet: itself and the nearest members of its kind that have no
# group either, up to SIZE in all.
static func gather(enemy: Enemy) -> TourGroup:
	var group := TourGroup.new()
	group.guide = enemy
	group.members.append(enemy)
	enemy.set_meta(META, group)
	if not enemy.is_inside_tree():
		return group
	var near: Array = []
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or other.is_dead() or other.def != enemy.def or other.has_meta(META):
			continue
		var distance := other.global_position.distance_to(enemy.global_position)
		if distance <= GATHER_REACH:
			near.append([distance, other])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in near:
		if group.members.size() >= SIZE:
			break
		var joining: Enemy = entry[1]
		group.members.append(joining)
		joining.set_meta(META, group)
	return group


func has_guide() -> bool:
	return is_instance_valid(guide) and not guide.is_dead()


func is_guide(enemy: Enemy) -> bool:
	return enemy == guide


# 0 for the guide, then 1 and 2 for the followers, in the order they joined.
func place_of(enemy: Enemy) -> int:
	return maxi(members.find(enemy), 0)


# Only the guide's tick moves the group's clock, so three members never run it three times as fast.
func advance(enemy: Enemy, delta: float) -> void:
	if enemy != guide:
		return
	if telegraph.is_active():
		if telegraph.tick(delta):
			rushes += 1
		return
	_timer -= delta
	if _timer <= 0.0 and enemy.target_in_view():
		_timer = RUSH_EVERY
		way = rush_lane(enemy.global_position, enemy.target_ground())
		telegraph.start(CALL_TIME)
		calls += 1
		enemy.say(CALL_TEXT, SAY_TIME)
