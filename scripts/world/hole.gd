class_name Hole
extends StaticBody2D

# Grandpa and enemies that walk can't cross it, and nothing breaks it. Shots and the
# thrown dentures fly over because it sits on its own layer, and ghosts ignore it.
const LAYER := 8

var palette: RoomPalette


func _ready() -> void:
	add_to_group("holes")
	collision_layer = LAYER
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)
	shape.shape = rect
	add_child(shape)
	queue_redraw()


func _draw() -> void:
	var art := PropArt.texture("hole")
	if art != null:
		draw_texture(art, -art.get_size() / 2.0)
		return
	var p := palette if palette != null else RoomPalette.new()
	var half := RoomBackdrop.TILE / 2.0
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), p.hole_rim)
	draw_rect(Rect2(-half + 3, -half + 3, half * 2.0 - 6.0, half * 2.0 - 6.0), p.hole)
	draw_rect(Rect2(-half + 5, -half + 5, half * 2.0 - 10.0, 3), Color(0, 0, 0, 0.5))
