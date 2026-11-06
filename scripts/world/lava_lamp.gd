class_name LavaLamp
extends BreakableBlock

# A lava lamp on the carpet: teal glass on a dark base, magenta wax inside, and a small soft light round
# it. It blocks nothing, anything that touches it breaks it, putting its light out, and it never holds
# anything, like a vase. Its picture is 32x48, standing up into the cell above.
const ART_SIZE := Vector2(32, 48)
const LIGHT_ENERGY := 0.45
const LIGHT_SCALE := 0.45


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(12, 28)


func art_id() -> String:
	return "lava_lamp"


func debris_color() -> Color:
	return look().lava_wax


func can_break_by(_source: String) -> bool:
	return true


func _ready() -> void:
	super._ready()
	var glow := Lighting.make_light(look().lava_light, LIGHT_ENERGY, LIGHT_SCALE)
	glow.position = Vector2(0, -8)
	add_child(glow)


func _draw_placeholder() -> void:
	var p := look()
	var base := PackedVector2Array([Vector2(-6, 14), Vector2(6, 14), Vector2(4, 6), Vector2(-4, 6)])
	draw_colored_polygon(base, Color("2a2533"))
	var glass := PackedVector2Array([Vector2(-4, 6), Vector2(4, 6), Vector2(5, -6), Vector2(3, -16), Vector2(-3, -16), Vector2(-5, -6)])
	draw_colored_polygon(glass, p.lava_glass)
	draw_circle(Vector2(-1, -2), 2.5, p.lava_wax)
	draw_circle(Vector2(1, -10), 2.0, p.lava_wax)
	draw_rect(Rect2(-3, -19, 6, 3), Color("2a2533"))
	draw_polyline(glass + PackedVector2Array([glass[0]]), Color.BLACK, 1.0)
	draw_polyline(base + PackedVector2Array([base[0]]), Color.BLACK, 1.0)


# Glass breaks like pottery.
func break_sound() -> String:
	return "rock_break"
