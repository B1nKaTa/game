class_name WalkerLine
extends RefCounted

# Three Mall Walkers power-walk one loop in a line. The line keeps one clock, run by its first living
# member: it walks the loop, and every few seconds that one whistles, every member shows a warning,
# and when the whistle ends the whole line breaks off toward Grandpa for a while before going back.
const META := &"walker_line"
const SIZE := 3
# Walkers this close that have no line yet join one, as summoned walkers do.
const GATHER_REACH := 160.0
const WHISTLE_EVERY := 7.5
const FIRST_WHISTLE := 2.5
const WHISTLE_TIME := 0.8
const BREAK_TIME := 2.0
const WHISTLE_TEXT := "Tweet tweet!"
const SAY_TIME := 1.0
# How far apart along the loop the members walk.
const GAP := 26.0

var members: Array[Enemy] = []
var loop: Array[Vector2] = []
var telegraph := Telegraph.new()
# Each whistle and each break counts up once, so every member sees each exactly once.
var whistles := 0
var breaks := 0
var progress := 0.0
var _timer := FIRST_WHISTLE
var _break_left := 0.0


# A line around a walker that has none yet: itself and the nearest walkers of its kind with no line
# either, up to SIZE in all, all walking the loop given.
static func gather(enemy: Enemy, walk_loop: Array[Vector2]) -> WalkerLine:
	var line := WalkerLine.new()
	line.loop = walk_loop
	line.members.append(enemy)
	enemy.set_meta(META, line)
	if not enemy.is_inside_tree():
		return line
	var near: Array = []
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or other.is_dead() or other.def != enemy.def or other.has_meta(META):
			continue
		var distance := other.global_position.distance_to(enemy.global_position)
		if distance <= GATHER_REACH:
			near.append([distance, other])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in near:
		if line.members.size() >= SIZE:
			break
		var joining: Enemy = entry[1]
		line.members.append(joining)
		joining.set_meta(META, line)
	return line


func leader() -> Enemy:
	for member in members:
		if is_instance_valid(member) and not member.is_dead():
			return member
	return null


# Where in the line a member walks: 0 at the front.
func place_of(enemy: Enemy) -> int:
	return maxi(members.find(enemy), 0)


func is_breaking() -> bool:
	return _break_left > 0.0


# The member's own spot on the loop, a gap behind the one ahead of it.
func spot_of(enemy: Enemy) -> Vector2:
	if loop.is_empty():
		return enemy.global_position
	return MallWalkerBehavior.point_along(loop, progress - place_of(enemy) * GAP)


# Only the leader's tick moves the line's clock, so three members never run it three times as fast.
func advance(enemy: Enemy, delta: float, walk_speed: float) -> void:
	if enemy != leader():
		return
	if telegraph.is_active():
		if telegraph.tick(delta):
			breaks += 1
			_break_left = BREAK_TIME
		return
	if _break_left > 0.0:
		_break_left -= delta
		return
	progress += walk_speed * delta
	_timer -= delta
	if _timer <= 0.0 and enemy.target_in_view():
		_timer = WHISTLE_EVERY
		telegraph.start(WHISTLE_TIME)
		whistles += 1
		enemy.say(WHISTLE_TEXT, SAY_TIME)
