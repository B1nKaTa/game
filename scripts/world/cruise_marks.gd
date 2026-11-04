class_name CruiseMarks
extends RefCounted

# The placeholder signs drawn on the Last Resort Cruise's people, so each reads without art. EnemyMarks
# hands its canvas over for these marks.
const MARKS := ["tray", "cue", "sunhat", "megaphone", "captain_hat"]
const TRAY := Color("c9cdd6")
const DOME := Color("eef1f6")
const CUE := Color("c9a25a")
const FIN := Color("5a6b8a")
const STRAW := Color("e8cf86")
const STRAW_BAND := Color("d9576b")
const SUNBURN := Color("ff6a4a")
const MEGAPHONE := Color("f2c230")
const SEQUIN := Color("fff6d8")
const CAP_WHITE := Color("fbfbff")
const CAP_PEAK := Color("15131a")
const BRAID := Color("e8c04a")


static func draws(mark: String) -> bool:
	return MARKS.has(mark)


static func draw_mark(canvas: CanvasItem, mark: String, half: Vector2) -> void:
	match mark:
		"tray":
			# A silver tray held out in front, with a dish under a dome.
			canvas.draw_rect(Rect2(-half.x - 2.0, 1.0, half.x * 2.0 + 4.0, 2.0), TRAY)
			canvas.draw_arc(Vector2(0.0, 1.0), 5.0, PI, TAU, 10, DOME, 2.0)
			canvas.draw_circle(Vector2(0.0, -5.0), 1.2, DOME)
		"cue":
			# A shuffleboard cue held across him, and a fin on his back.
			canvas.draw_line(Vector2(-half.x - 3.0, half.y - 2.0), Vector2(half.x + 4.0, -half.y + 4.0), CUE, 2.0)
			canvas.draw_line(Vector2(half.x + 1.0, -half.y + 6.0), Vector2(half.x + 6.0, -half.y + 2.0), CUE, 3.0)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-3.0, -half.y + 1.0), Vector2(3.0, -half.y + 1.0), Vector2(-1.0, -half.y - 8.0)]), FIN)
		"sunhat":
			# A wide straw hat and a bright red nose.
			canvas.draw_rect(Rect2(-half.x - 3.0, -half.y, half.x * 2.0 + 6.0, 3.0), STRAW)
			canvas.draw_rect(Rect2(-half.x * 0.5, -half.y - 5.0, half.x, 5.0), STRAW)
			canvas.draw_rect(Rect2(-half.x * 0.5, -half.y - 2.0, half.x, 2.0), STRAW_BAND)
			canvas.draw_circle(Vector2(0.0, -half.y + 7.0), 2.0, SUNBURN)
		"megaphone":
			# A sequinned dress and a yellow megaphone held up to call the next dance.
			for i in 5:
				canvas.draw_circle(Vector2(-half.x * 0.6 + i * half.x * 0.3, half.y * 0.2 + (i % 2) * 3.0), 1.3, SEQUIN)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(half.x - 2.0, -half.y * 0.5 - 2.0), Vector2(half.x + 10.0, -half.y * 0.5 - 7.0), Vector2(half.x + 10.0, -half.y * 0.5 + 5.0), Vector2(half.x - 2.0, -half.y * 0.5 + 1.0)]), MEGAPHONE)
			canvas.draw_line(Vector2(half.x + 10.0, -half.y * 0.5 - 7.0), Vector2(half.x + 10.0, -half.y * 0.5 + 5.0), Color.BLACK, 1.0)
		"captain_hat":
			# A white peaked cap with a gold badge, and gold braid on the shoulders.
			canvas.draw_rect(Rect2(-half.x * 0.75, -half.y - 7.0, half.x * 1.5, 7.0), CAP_WHITE)
			canvas.draw_rect(Rect2(-half.x * 0.85, -half.y - 1.0, half.x * 1.7, 3.0), CAP_PEAK)
			canvas.draw_circle(Vector2(0.0, -half.y - 4.0), 2.0, BRAID)
			for x in [-half.x + 2.0, half.x - 8.0]:
				canvas.draw_rect(Rect2(x, -half.y * 0.45, 6.0, 2.0), BRAID)
