class_name ShoppingCart
extends Barrel

# An empty shopping cart left out overnight. Breaks to anything, like a barrel, and holds what a barrel holds.


func art_id() -> String:
	return "shopping_cart"


func debris_color() -> Color:
	return look().cart_wire


func _draw_placeholder() -> void:
	var p := look()
	var basket := PackedVector2Array([Vector2(-12, -10), Vector2(10, -10), Vector2(8, 4), Vector2(-10, 4)])
	draw_colored_polygon(basket, Color(p.cart_wire, 0.25))
	draw_polyline(basket + PackedVector2Array([basket[0]]), p.cart_wire, 2.0)
	for x in [-6.0, -1.0, 4.0]:
		draw_line(Vector2(x, -10), Vector2(x - 1.0, 4), p.cart_wire, 1.0)
	draw_line(Vector2(-11, -3), Vector2(9, -3), p.cart_wire, 1.0)
	draw_line(Vector2(10, -10), Vector2(14, -14), p.cart_handle, 3.0)
	draw_line(Vector2(-10, 4), Vector2(-10, 9), p.cart_wire, 1.0)
	draw_line(Vector2(8, 4), Vector2(8, 9), p.cart_wire, 1.0)
	for x in [-10.0, 8.0]:
		draw_circle(Vector2(x, 10), 2.5, Color("2a2a30"))
