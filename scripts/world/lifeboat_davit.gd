class_name LifeboatDavit
extends RockBlock

# A lifeboat davit: a white steel arm bolted to the deck, with a lifeboat slung under it. Solid, and only
# blasts and bosses break it, like a rock. It can hide a coin, as furniture does.
const STEEL := Color("e8ebf0")
const STEEL_EDGE := Color("4a5060")
const BOAT := Color("e8773c")
const BOAT_EDGE := Color("5a2a14")


func art_id() -> String:
	return "lifeboat_davit"


func debris_color() -> Color:
	return STEEL


func _draw_placeholder() -> void:
	draw_rect(Rect2(-14, 8, 28, 5), STEEL_EDGE)
	draw_line(Vector2(-10, 10), Vector2(-10, -12), STEEL, 4.0)
	draw_line(Vector2(-10, -12), Vector2(8, -12), STEEL, 3.0)
	draw_line(Vector2(6, -12), Vector2(6, -5), STEEL_EDGE, 1.0)
	var boat := PackedVector2Array([Vector2(-6, -5), Vector2(14, -5), Vector2(11, 3), Vector2(-3, 3)])
	draw_colored_polygon(boat, BOAT)
	draw_polyline(boat + PackedVector2Array([boat[0]]), BOAT_EDGE, 1.0)


# Furniture, so it splinters like wood.
func break_sound() -> String:
	return "wood_break"
