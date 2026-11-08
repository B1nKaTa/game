class_name MapFade
extends RefCounted

# The small map lies over the play area's top right (Hud.MAP_PANEL), so in a large room a warning there
# would lie under it. While any warning shape overlaps the map's part of the view, the map, its floor
# name and its panel fade to FADED, so the warning shows through; they come back when it is gone.
#
# A screen-colour window (WarningWindow, removed) opened on faint red floors such as the parlour's wine
# carpet, so this reads the warnings themselves. Shapes are exact where a node gives them (route_rects,
# route_circles, lane_rect, a ground strike's radius) and a generous circle round the node otherwise:
# fading for a shape just beside the map does no harm, hiding one under it would.

const FADED := 0.35
# How fast the alpha moves, per second, either way.
const SPEED := 5.0
# The circle taken for a warning node that gives no shape of its own, and round a winding-up enemy.
const LOOSE_REACH := 40.0
const WINDUP_REACH := 56.0

# Whether nodes of a script can show a warning at all, by script, so the room's props, tiles and decor
# cost one look-up a frame each rather than the whole passing-effect test.
static var _kinds := {}


# The map's panel in world space, for the camera's canvas transform.
static func world_rect(canvas: Transform2D) -> Rect2:
	var inverse := canvas.affine_inverse()
	var a := inverse * Hud.MAP_PANEL.position
	var b := inverse * Hud.MAP_PANEL.end
	return Rect2(a, Vector2.ZERO).expand(b)


# Whether any warning in the room overlaps area (world space).
static func covered(room: Node, area: Rect2) -> bool:
	if room == null:
		return false
	for child in room.get_children():
		if not _may_warn(child):
			continue
		for shape in shapes_of(child):
			if _overlaps(shape, area):
				return true
	return false


# The warning shapes a room child shows now: Rect2s, and Vector3s (x, y, radius) for circles.
static func shapes_of(node: Node) -> Array:
	if not is_instance_valid(node) or node.is_queued_for_deletion() or not (node is Node2D):
		return []
	var item := node as Node2D
	if not item.visible:
		return []
	if node is Enemy:
		var enemy := node as Enemy
		if enemy.is_winding_up() and AttackWarnings.drawn_for(enemy.def):
			return [_circle(enemy.global_position, WINDUP_REACH)]
		return []
	if not _may_warn(node):
		return []
	if node is GroundStrike:
		var strike := node as GroundStrike
		return [_circle(strike.global_position, strike.radius())] if strike.cue() == GroundStrike.CUE_MARK else []
	var found: Array = []
	if node.has_method("route_rects"):
		for pair: Array in node.route_rects():
			found.append(pair[0])
	if node.has_method("route_circles"):
		for pair: Array in node.route_circles():
			found.append(pair[0])
	if node.has_method("lane_rect"):
		found.append(node.lane_rect())
	if not found.is_empty() or node.has_method("route_rects") or node.has_method("route_circles"):
		return found
	var reach := LOOSE_REACH
	for method in ["radius", "length"]:
		if node.has_method(method):
			reach = maxf(reach, float(node.call(method)))
	return [_circle(item.global_position, reach)]


# Enemies, and the room's passing attack effects (RoomView.is_passing_effect) but for shots, bursts and
# the items' own effects, which are Harold's, not warnings.
static func _may_warn(node: Node) -> bool:
	if node is Enemy:
		return true
	var script: Variant = node.get_script()
	if script == null or node.is_in_group(ItemFx.GROUP):
		return false
	if not _kinds.has(script):
		_kinds[script] = not (node is Projectile or node is DeathBurst) and RoomView.is_passing_effect(node)
	return _kinds[script]


# The map's alpha one step on, toward FADED while covered and back to whole when not.
static func step(alpha: float, is_covered: bool, delta: float) -> float:
	return move_toward(alpha, FADED if is_covered else 1.0, SPEED * delta)


static func _circle(at: Vector2, radius: float) -> Vector3:
	return Vector3(at.x, at.y, radius)


static func _overlaps(shape: Variant, area: Rect2) -> bool:
	if shape is Rect2:
		return (shape as Rect2).intersects(area, true)
	if shape is Vector3:
		var c := Vector2(shape.x, shape.y)
		var nearest := c.clamp(area.position, area.end)
		return nearest.distance_to(c) <= shape.z
	return false
