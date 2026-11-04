class_name DeckChair
extends Barrel

# A folding deck chair of striped canvas on a wooden frame. Breaks to anything, like a barrel, and holds
# what a barrel holds. A Sunburnt Sunbather lies looking just like one, so both are drawn by draw_chair.
const FRAME := Color("8a5a32")
const FRAME_EDGE := Color("3a2414")
const CANVAS := Color("f2ecd8")
const STRIPE := Color("2f7fc4")


static func draw_chair(canvas: CanvasItem, stripe := STRIPE) -> void:
	# The frame: two legs crossed under a seat that leans back toward the top.
	canvas.draw_line(Vector2(-11, 12), Vector2(9, -6), FRAME, 3.0)
	canvas.draw_line(Vector2(11, 12), Vector2(-9, -6), FRAME, 3.0)
	var seat := PackedVector2Array([Vector2(-10, -12), Vector2(10, -12), Vector2(12, 8), Vector2(-12, 8)])
	canvas.draw_colored_polygon(seat, CANVAS)
	for i in 3:
		var left := -10.0 + i * 8.0
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(left, -12), Vector2(left + 4, -12), Vector2(left + 4.8, 8), Vector2(left + 0.8, 8)]), stripe)
	canvas.draw_polyline(seat + PackedVector2Array([seat[0]]), FRAME_EDGE, 1.0)
	canvas.draw_line(Vector2(-13, -12), Vector2(13, -12), FRAME, 2.0)


func art_id() -> String:
	return "deck_chair"


func debris_color() -> Color:
	return STRIPE


func _draw_placeholder() -> void:
	draw_chair(self)
