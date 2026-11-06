class_name UsherTorch
extends Node2D

# The pale beam of an Usher's torch on the carpet, showing where he looks. It never hurts: it only
# says what he can see. It brightens as he takes notice of Grandpa standing in it (UsherBehavior's
# spot timer), so the moment before his "Shh!" reads. It hangs on the Usher and lies flat on the floor,
# under every body and above the carpet, as the projector's beam does.
const Z := -7
const LIGHT := Color(1.0, 0.95, 0.72)
const BASE_ALPHA := 0.1
const NOTICED_ALPHA := 0.24
const EDGE_ALPHA := 0.32
const STEPS := 16

var look := Vector2.RIGHT
var length := 150.0
var half_angle_deg := 22.0
# How far he has taken notice, from 0 to 1.
var noticed := 0.0
# The room's floor inside its walls, in global coordinates: the beam stops at its edge rather than
# shining on over the walls (an empty rect leaves it whole).
var bounds := Rect2()


# How far a ray from origin along way runs before it leaves the rect, at most cap.
static func reach_in(origin: Vector2, way: Vector2, rect: Rect2, cap: float) -> float:
	if not rect.has_area():
		return cap
	var reach := cap
	if way.x > 0.0001:
		reach = minf(reach, (rect.end.x - origin.x) / way.x)
	elif way.x < -0.0001:
		reach = minf(reach, (rect.position.x - origin.x) / way.x)
	if way.y > 0.0001:
		reach = minf(reach, (rect.end.y - origin.y) / way.y)
	elif way.y < -0.0001:
		reach = minf(reach, (rect.position.y - origin.y) / way.y)
	return clampf(reach, 0.0, cap)


func _init() -> void:
	z_as_relative = false
	z_index = Z


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var half := deg_to_rad(half_angle_deg)
	var base := look.angle() - half
	var fill := PackedVector2Array([Vector2.ZERO])
	for i in STEPS + 1:
		var way := Vector2.from_angle(base + 2.0 * half * i / STEPS)
		fill.append(way * reach_in(global_position, way, bounds, length))
	var alpha := lerpf(BASE_ALPHA, NOTICED_ALPHA, clampf(noticed, 0.0, 1.0))
	draw_colored_polygon(fill, Color(LIGHT, alpha))
	var edge := fill.duplicate()
	edge.append(Vector2.ZERO)
	draw_polyline(edge, Color(LIGHT, EDGE_ALPHA * (0.6 + 0.4 * noticed)), 1.0)
