class_name PsychicDesk
extends RockBlock

# A psychic's desk on the hotline's night shift: a phone whose little display glows green, a crystal ball
# on its stand and a few call slips. Solid, it stops walkers and shots, and only blasts and bosses break
# it, as a chapel pew does. It can hide a coin at the furniture rate: a tip left by a caller.
# Two desk cells side by side are one wide desk (SeanceProps.desk_groups), drawn over both cells and up
# into the cell above, so the 64x48 art fits it; a desk cell left on its own is a narrow desk.
const WIDE_SIZE := Vector2(64, 48)
const NARROW_SIZE := Vector2(32, 48)

var wide := true


func body_size() -> Vector2:
	return Vector2(RoomBackdrop.TILE * (2 if wide else 1), RoomBackdrop.TILE)


# The size its picture takes, a little taller than the cells it stands on.
func art_size() -> Vector2:
	return WIDE_SIZE if wide else NARROW_SIZE


func art_id() -> String:
	return "psychic_desk" if wide else "psychic_desk_narrow"


func debris_color() -> Color:
	return look().desk_top


func _draw_placeholder() -> void:
	var p := look()
	var half := art_size().x / 2.0 - 2.0
	# The desk's front panel and its top, seen from a little above.
	draw_rect(Rect2(-half, -2, half * 2.0, 15), p.desk_wood)
	draw_rect(Rect2(-half, -14, half * 2.0, 13), p.desk_top)
	draw_line(Vector2(-half, -2), Vector2(half, -2), p.desk_wood.darkened(0.4), 1.0)
	draw_rect(Rect2(-half, -14, half * 2.0, 27), Color.BLACK, false, 1.0)
	# The phone on the left: a dark handset on its base, the display glowing green.
	var phone := Vector2(-half + 4, -13)
	draw_rect(Rect2(phone, Vector2(11, 8)), Color("23202a"))
	draw_rect(Rect2(phone + Vector2(1, -3), Vector2(9, 3)), Color("2f2b38"))
	draw_rect(Rect2(phone + Vector2(2, 2), Vector2(5, 3)), p.phone_glow)
	if not wide:
		return
	# A few call slips in the middle and the crystal ball on its stand on the right.
	draw_rect(Rect2(-6, -11, 9, 6), Color("e8e2d2"))
	draw_rect(Rect2(-3, -9, 9, 6), Color("d9d2c2"))
	var ball := Vector2(half - 9, -16)
	draw_rect(Rect2(ball + Vector2(-5, 5), Vector2(10, 4)), p.table_fringe.darkened(0.3))
	draw_circle(ball, 6.0, p.crystal_ball)
	draw_arc(ball, 6.0, 0.0, TAU, 14, Color.BLACK, 1.0)
	draw_circle(ball + Vector2(-2, -2), 1.5, Color(1, 1, 1, 0.8))
