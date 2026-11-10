class_name ThrownThermos
extends Node2D

# The Overarm Bowler's Thermos: thrown in an arc toward the aim point, at most REACH away, stopping at the
# first wall, and bursting where it lands (a Thermos with the Pressure Cooker's extra fuse only).

const REACH := 160.0
const FLIGHT := 0.4
const ARC := 22.0

var from := Vector2.ZERO
var to := Vector2.ZERO
var room: Node
var _age := 0.0


static func landing(start: Vector2, aim_point: Vector2, reach := REACH) -> Vector2:
	var offset := aim_point - start
	if offset.length() <= reach:
		return aim_point
	return start + offset.normalized() * reach


# How high over the ground it flies at this share of its flight.
static func height(progress: float) -> float:
	return 4.0 * ARC * progress * (1.0 - progress)


func _ready() -> void:
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z
	global_position = from


func _process(delta: float) -> void:
	_age += delta
	var progress := clampf(_age / FLIGHT, 0.0, 1.0)
	global_position = from.lerp(to, progress)
	queue_redraw()
	if progress >= 1.0:
		if is_instance_valid(room) and room.has_method("land_thrown_bomb"):
			room.land_thrown_bomb(to)
		queue_free()


func _draw() -> void:
	var lift := Vector2(0, -height(clampf(_age / FLIGHT, 0.0, 1.0)))
	var art := PropArt.texture(Thermos.ART)
	if art != null:
		PropArt.draw(self, art, lift)
		return
	draw_rect(Rect2(lift + Vector2(-5, -9), Vector2(10, 15)), Thermos.BODY_COLOR)
	draw_rect(Rect2(lift + Vector2(-5, -9), Vector2(10, 15)), Color.BLACK, false, 1.0)
