class_name MallWalkerBehavior
extends EnemyBehavior

# Power-walks a loop round where its line started, in a line of three, and hurts whoever it bumps
# into. When the line's leader whistles, every member warns, then the whole line breaks off toward
# Grandpa for a while and goes back to its loop afterwards. See WalkerLine.
const LOOP_CELLS := Vector2i(4, 3)
const CONTACT_RANGE := 16.0
const CONTACT_EVERY := 0.8
const BREAK_SPEED := 1.5
const CATCH_UP := 1.6
const WARNING_RADIUS := 18.0
# A member of a group waits this long for its leader to gather it before it gathers a line itself.
const LINE_GRACE := 0.3
const NEAR_SPOT := 3.0


# Hurts on touch, then not again until CONTACT_EVERY has passed.
class ContactClock extends RefCounted:
	var _wait := 0.0

	# Whether touching now hurts. Call once a frame.
	func touch(delta: float, touching: bool) -> bool:
		_wait = maxf(_wait - delta, 0.0)
		if not touching or _wait > 0.0:
			return false
		_wait = CONTACT_EVERY
		return true


var _line: WalkerLine
var _wait := LINE_GRACE
var _contact := ContactClock.new()
var _seen_whistle := 0


# A rectangle LOOP_CELLS wide and high with a corner at origin, as corners in walking order: top left,
# top right, bottom right, bottom left. It is moved to lie inside the room, half a cell off the walls,
# and turned to start from another corner when is_open says the first way crosses something solid.
static func walker_loop(origin: Vector2, room_cells: Vector2i, is_open := Callable()) -> Array[Vector2]:
	var tile := float(RoomBackdrop.TILE)
	var size := Vector2(LOOP_CELLS) * tile
	var area := ForemanBehavior.room_rect(room_cells).grow(-tile / 2.0)
	var tries: Array[Vector2] = [origin, origin - Vector2(size.x, 0.0), origin - size, origin - Vector2(0.0, size.y)]
	var first: Array[Vector2] = []
	for top_left in tries:
		var at := Vector2(
			clampf(top_left.x, area.position.x, maxf(area.end.x - size.x, area.position.x)),
			clampf(top_left.y, area.position.y, maxf(area.end.y - size.y, area.position.y)))
		var corners: Array[Vector2] = [at, at + Vector2(size.x, 0.0), at + size, at + Vector2(0.0, size.y)]
		if first.is_empty():
			first = corners
		if not is_open.is_valid() or _loop_is_open(corners, is_open):
			return corners
	return first


static func _loop_is_open(corners: Array[Vector2], is_open: Callable) -> bool:
	for i in corners.size():
		var from := corners[i]
		var to := corners[(i + 1) % corners.size()]
		var steps := maxi(ceili(from.distance_to(to) / (RoomBackdrop.TILE / 2.0)), 1)
		for step in steps + 1:
			if not is_open.call(from.lerp(to, step / float(steps))):
				return false
	return true


static func loop_length(loop: Array[Vector2]) -> float:
	var total := 0.0
	for i in loop.size():
		total += loop[i].distance_to(loop[(i + 1) % loop.size()])
	return total


# The point a distance along the closed loop from its first corner. Any distance wraps round.
static func point_along(loop: Array[Vector2], distance: float) -> Vector2:
	if loop.is_empty():
		return Vector2.ZERO
	var total := loop_length(loop)
	if total <= 0.0:
		return loop[0]
	var left := fposmod(distance, total)
	for i in loop.size():
		var from := loop[i]
		var to := loop[(i + 1) % loop.size()]
		var edge := from.distance_to(to)
		if left <= edge:
			return from.lerp(to, left / edge) if edge > 0.0 else from
		left -= edge
	return loop[0]


func tick(enemy: Enemy, delta: float) -> void:
	if _contact.touch(delta, enemy.global_position.distance_to(enemy.target_ground()) <= CONTACT_RANGE):
		enemy.hit_target(enemy.def.damage)
	if _line == null:
		_join(enemy, delta)
		if _line == null:
			return
	_line.advance(enemy, delta, enemy.def.speed)
	if _line.whistles != _seen_whistle:
		_seen_whistle = _line.whistles
		enemy.set_warning(_line.telegraph, WARNING_RADIUS, true)
	if _line.telegraph.is_active():
		return
	enemy.clear_warning()
	if _line.is_breaking():
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * BREAK_SPEED
		return
	var spot := _line.spot_of(enemy)
	var away := enemy.global_position.distance_to(spot)
	if away > NEAR_SPOT:
		# Back on the loop at a brisk pace, then in step with the line.
		var pace := enemy.def.speed * (CATCH_UP if away > WalkerLine.GAP else 1.0)
		enemy.desired_velocity = enemy.global_position.direction_to(spot) * pace


func _join(enemy: Enemy, delta: float) -> void:
	if enemy.has_meta(WalkerLine.META):
		_line = enemy.get_meta(WalkerLine.META)
		return
	_wait -= delta
	if enemy.is_group_follower and _wait > 0.0:
		return
	var grid := enemy.walk_grid
	var is_open := Callable()
	if grid != null:
		is_open = func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))
	_line = WalkerLine.gather(enemy, walker_loop(enemy.global_position, enemy.room_cells, is_open))
