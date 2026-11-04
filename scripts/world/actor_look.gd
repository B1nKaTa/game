class_name ActorLook
extends Node2D

# Everyone in the ending scenes but Harold, drawn in code like the NPCs until the art pass, with the
# feet at the origin. Filled in with the scenes.

const NAMES := {
	"harold": "Harold",
	"gerald": "Gerald",
}

var id := ""
var facing := 1
var walking := false
var clock := 0.0


static func display_name(actor_id: String) -> String:
	return str(NAMES.get(actor_id, actor_id.capitalize()))


static func head_of(_actor_id: String) -> Vector2:
	return Vector2(0, -30)


static func draw_hat(canvas: CanvasItem, shape: String, head: Vector2, color: Color, facing_dir: float) -> void:
	GrandpaLook.draw_hat(canvas, shape, head, color, facing_dir)


func _draw() -> void:
	draw_rect(Rect2(-8, -30, 16, 30), Color("8a7a5a"))
