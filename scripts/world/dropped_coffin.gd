class_name DroppedCoffin
extends BreakableBlock

# The coffin a Pallbearer lets fall when its partner does. It lies across the way they carried it as
# a solid prop for a while, then is taken away. A blast or a boss breaks it sooner. It never lands
# solid on Grandpa's feet, so it can never shut him in.
const WOOD := Color("4a2a1c")
const LID := Color("6b3d26")
const BRASS := Color("c9a25a")
const LONG := 44.0
const SHORT := 18.0
const FADE := 0.5
# Grandpa's feet this close to where it lands leave it something to look at, not something solid.
const FEET_CLEARANCE := 12.0

var horizontal := true
var solid := true
var time_left := 6.0


# Lays a coffin at a spot, lengthwise along across, for a number of seconds.
static func drop(parent: Node, at: Vector2, across: Vector2, feet: Vector2, seconds: float) -> DroppedCoffin:
	var coffin := DroppedCoffin.new()
	coffin.horizontal = absf(across.x) >= absf(across.y)
	coffin.time_left = seconds
	coffin.solid = not lands_on(at, coffin.body_size(), feet)
	parent.add_child(coffin)
	coffin.global_position = at
	return coffin


static func lands_on(at: Vector2, size: Vector2, feet: Vector2) -> bool:
	return Rect2(at - size / 2.0, size).grow(FEET_CLEARANCE).has_point(feet)


func is_solid() -> bool:
	return solid


func body_size() -> Vector2:
	return Vector2(LONG, SHORT) if horizontal else Vector2(SHORT, LONG)


func art_id() -> String:
	return "dropped_coffin"


# The picture lies east to west, so a coffin dropped along a column is turned upright.
func art_angle() -> float:
	return 0.0 if horizontal else PI / 2.0


func debris_color() -> Color:
	return WOOD


func _process(delta: float) -> void:
	time_left -= delta
	modulate.a = clampf(time_left / FADE, 0.0, 1.0)
	if time_left <= 0.0:
		queue_free()


func _draw_placeholder() -> void:
	draw_set_transform(Vector2.ZERO, 0.0 if horizontal else PI / 2.0)
	var shape := PackedVector2Array([Vector2(-22, -5), Vector2(-14, -9), Vector2(22, -7), Vector2(22, 7), Vector2(-14, 9), Vector2(-22, 5)])
	draw_colored_polygon(shape, WOOD)
	draw_polyline(shape + PackedVector2Array([shape[0]]), Color.BLACK, 1.0)
	draw_line(Vector2(-12, 0), Vector2(18, 0), LID, 2.0)
	for x in [-10.0, 4.0, 16.0]:
		draw_rect(Rect2(x - 2.0, -9.0, 4.0, 2.0), BRASS)
		draw_rect(Rect2(x - 2.0, 7.0, 4.0, 2.0), BRASS)
	draw_set_transform(Vector2.ZERO)
