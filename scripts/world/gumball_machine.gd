class_name GumballMachine
extends Barrel

# A gumball machine on its red stand. Breaks to anything, like a barrel, and holds what a barrel holds.
const GUMS: Array[Color] = [Color("e04a5a"), Color("f2c230"), Color("5fb0e8"), Color("7fd06a"), Color("f08aa8")]


func art_id() -> String:
	return "gumball_machine"


func debris_color() -> Color:
	return GUMS[0]


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-5, 2, 10, 12), p.gumball_base)
	draw_rect(Rect2(-8, 12, 16, 3), p.gumball_base.darkened(0.3))
	draw_rect(Rect2(-2, 5, 4, 3), Color("c9cdd6"))
	for i in 9:
		var at := Vector2(-5 + (i % 3) * 5, -10 + floori(i / 3.0) * 4)
		draw_circle(at, 2.0, GUMS[i % GUMS.size()])
	draw_circle(Vector2(0, -6), 9.0, p.gumball_glass)
	draw_arc(Vector2(0, -6), 9.0, 0.0, TAU, 20, Color.BLACK, 1.0)
	draw_arc(Vector2(-3, -9), 4.0, 3.4, 4.6, 6, Color(1, 1, 1, 0.8), 1.0)
	draw_rect(Rect2(-3, -17, 6, 3), p.gumball_base)
