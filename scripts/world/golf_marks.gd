class_name GolfMarks
extends RefCounted

# The placeholder signs drawn on Fairway's End's own enemies, so each reads without art. EnemyMarks
# hands these marks over, with the body's half size.
const MARKS: Array[String] = ["caddie_bib", "golf_cap", "gopher_teeth", "pro_visor", "boater"]
const BIB := Color("fbfbf4")
const BIB_NUMBER := Color("2f5a2c")
const CAP := Color("2f5a2c")
const CAP_PEAK := Color("1c3a1a")
const CLUB_SHAFT := Color("c9cdd6")
const CLUB_HEAD := Color("4a4d55")
const TOOTH := Color("fbf7ef")
const NOSE := Color("2a1c14")
const EAR := Color("8a6440")
const VISOR := Color("fbfbf4")
const VISOR_BAND := Color("d9453b")
const COLLAR := Color("fbfbf4")
const PUTTER := Color("c9cdd6")
const STRAW := Color("e8cf86")
const STRAW_BAND := Color("1c2340")
const CREST := Color("e2c25a")
const MONOCLE := Color("e2c25a")


static func draws(mark: String) -> bool:
	return MARKS.has(mark)


static func draw_mark(canvas: CanvasItem, mark: String, half: Vector2) -> void:
	match mark:
		"caddie_bib":
			# A white caddie's bib with a number, and a bag strap across the chest.
			canvas.draw_rect(Rect2(-half.x * 0.7, -half.y * 0.4, half.x * 1.4, half.y * 1.0), BIB)
			canvas.draw_rect(Rect2(-half.x * 0.7, -half.y * 0.4, half.x * 1.4, half.y * 1.0), Color.BLACK, false, 1.0)
			canvas.draw_string(ThemeDB.fallback_font, Vector2(-4.0, half.y * 0.45), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, BIB_NUMBER)
			canvas.draw_rect(Rect2(-half.x * 0.6, -half.y - 4.0, half.x * 1.2, 5.0), CAP)
		"golf_cap":
			# A flat cap with a peak, and a driver held over the shoulder.
			canvas.draw_rect(Rect2(-half.x * 0.7, -half.y - 4.0, half.x * 1.4, 5.0), CAP)
			canvas.draw_rect(Rect2(-half.x * 0.2, -half.y - 1.0, half.x * 1.2, 2.0), CAP_PEAK)
			canvas.draw_line(Vector2(-half.x + 1.0, half.y * 0.4), Vector2(half.x + 4.0, -half.y - 2.0), CLUB_SHAFT, 1.5)
			canvas.draw_rect(Rect2(half.x + 2.0, -half.y - 5.0, 5.0, 4.0), CLUB_HEAD)
		"gopher_teeth":
			# Round ears, a dark nose and two big front teeth.
			canvas.draw_circle(Vector2(-half.x * 0.6, -half.y + 1.0), 2.5, EAR)
			canvas.draw_circle(Vector2(half.x * 0.6, -half.y + 1.0), 2.5, EAR)
			canvas.draw_circle(Vector2(0.0, -half.y * 0.2), 1.5, NOSE)
			canvas.draw_rect(Rect2(-2.5, 0.0, 2.0, 4.0), TOOTH)
			canvas.draw_rect(Rect2(0.5, 0.0, 2.0, 4.0), TOOTH)
		"pro_visor":
			# A white visor with a red band, a polo collar and a putter at his side.
			canvas.draw_rect(Rect2(-half.x * 0.7, -half.y - 2.0, half.x * 1.4, 3.0), VISOR_BAND)
			canvas.draw_rect(Rect2(-half.x * 0.1, -half.y, half.x * 1.1, 3.0), VISOR)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-6.0, -half.y * 0.35), Vector2(0.0, -half.y * 0.15), Vector2(6.0, -half.y * 0.35), Vector2(0.0, -half.y * 0.45)]), COLLAR)
			canvas.draw_line(Vector2(half.x + 3.0, -half.y * 0.3), Vector2(half.x + 3.0, half.y), PUTTER, 2.0)
			canvas.draw_rect(Rect2(half.x + 3.0, half.y - 3.0, 6.0, 3.0), PUTTER)
		"boater":
			# A straw boater with a navy band, a gold club crest on the blazer and a monocle.
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y - 7.0, half.x * 1.1, 8.0), STRAW)
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y - 3.0, half.x * 1.1, 2.0), STRAW_BAND)
			canvas.draw_rect(Rect2(-half.x * 0.85, -half.y, half.x * 1.7, 2.0), STRAW)
			canvas.draw_arc(Vector2(half.x * 0.25, -half.y * 0.65), 3.0, 0.0, TAU, 12, MONOCLE, 1.0)
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y * 0.1, 7.0, 8.0), CREST)
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y * 0.1, 7.0, 8.0), Color.BLACK, false, 1.0)
