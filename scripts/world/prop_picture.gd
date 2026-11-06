class_name PropPicture
extends Node2D

# A picture standing on the floor that does nothing else, such as a chest left open (Chest). Its bottom
# row stands on `feet`, below its origin, so it sorts among bodies by where it stands.
var texture: Texture2D
var feet := Vector2.ZERO


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if texture != null:
		draw_texture(texture, PropArt.standing(texture, feet))
