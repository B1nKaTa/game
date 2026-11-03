class_name FoodTrolley
extends Barrel

# A trolley of food trays. Breaks to anything, like a barrel, and holds what a barrel holds.


func art_id() -> String:
	return "food_trolley"


func debris_color() -> Color:
	return look().tray


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-12, -12, 24, 24), p.tray_frame)
	draw_rect(Rect2(-12, -12, 24, 24), Color.BLACK, false, 1.0)
	for y in [-9.0, -1.0, 7.0]:
		draw_rect(Rect2(-10, y, 20, 5), p.tray)
		draw_circle(Vector2(-4, y + 2.5), 1.5, p.tray_food)
		draw_circle(Vector2(4, y + 2.5), 1.5, p.tray_food.darkened(0.3))
