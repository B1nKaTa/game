class_name BallWasher
extends Barrel

# A ball washer on its post by the tee, with a towel hung from it. It blocks walking and shots, breaks
# to anything, like a barrel, and holds what a barrel holds.


func art_id() -> String:
	return "ball_washer"


func debris_color() -> Color:
	return look().ball_washer


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-2, -2, 4, 15), Color("4a4d55"))
	draw_rect(Rect2(-7, 11, 14, 3), Color("4a4d55"))
	draw_rect(Rect2(-9, -13, 18, 12), p.ball_washer)
	draw_rect(Rect2(-9, -13, 18, 12), Color.BLACK, false, 1.0)
	draw_line(Vector2(0, -13), Vector2(0, -17), Color("c9cdd6"), 2.0)
	draw_line(Vector2(-4, -17), Vector2(4, -17), Color("c9cdd6"), 2.0)
	draw_rect(Rect2(9, -11, 4, 9), Color("fbfbf4"))
	draw_line(Vector2(9, -8), Vector2(13, -8), p.flag_cloth, 1.0)
