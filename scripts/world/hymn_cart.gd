class_name HymnCart
extends Barrel

# A little cart stacked with hymn books. Breaks to anything, like a barrel, and holds what a barrel holds.


func art_id() -> String:
	return "hymn_cart"


func debris_color() -> Color:
	return look().hymn_book


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-12, -2, 24, 10), p.hymn_cart)
	draw_rect(Rect2(-12, -2, 24, 10), Color.BLACK, false, 1.0)
	for i in 4:
		draw_rect(Rect2(-10 + i * 5, -10 + (i % 2), 4, 8), p.hymn_book.lightened(0.1 * (i % 2)))
	draw_line(Vector2(12, -2), Vector2(15, -8), p.hymn_cart.darkened(0.3), 2.0)
	for x in [-8.0, 8.0]:
		draw_circle(Vector2(x, 10), 3.0, Color("2a2420"))
