class_name ParkedCart
extends RockBlock

# A golf cart parked for the night, keys gone. Solid, and only blasts and bosses break it, like a rock.
# A hedge cell standing on its own in a layout is one of these. It can hide a coin, as furniture does:
# loose change down the seat.


func art_id() -> String:
	return "parked_cart"


func debris_color() -> Color:
	return look().golf_cart


func _draw_placeholder() -> void:
	var p := look()
	for corner in [Vector2(-13, -13), Vector2(8, -13), Vector2(-13, 10), Vector2(8, 10)]:
		draw_rect(Rect2(corner, Vector2(5, 4)), Color("1c1c22"))
	draw_rect(Rect2(-14, -11, 28, 22), p.golf_cart)
	draw_rect(Rect2(-14, -11, 28, 22), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-12, -13, 15, 26), Color(p.golf_cart_roof, 0.9))
	draw_rect(Rect2(6, -8, 6, 16), Color("6b6f78"))


# Furniture, so it splinters like wood.
func break_sound() -> String:
	return "wood_break"
