class_name BreakableBlock
extends StaticBody2D

signal broken(at: Vector2)

const FILL := Color("6b4a2a")
const EDGE := Color("3a2614")


func _ready() -> void:
	add_to_group("breakable")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)
	shape.shape = rect
	add_child(shape)
	queue_redraw()


func body_rect() -> Rect2:
	var half := Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE) / 2.0
	return Rect2(global_position - half, half * 2.0)


func take_blast() -> void:
	if is_queued_for_deletion():
		return
	broken.emit(global_position)
	queue_free()


func _draw() -> void:
	var half := RoomBackdrop.TILE / 2.0
	var rect := Rect2(-half, -half, half * 2.0, half * 2.0)
	draw_rect(rect, FILL)
	draw_rect(rect, EDGE, false, 2.0)
	draw_line(rect.position, rect.end, EDGE, 2.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), EDGE, 2.0)
