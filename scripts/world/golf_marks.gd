class_name GolfMarks
extends RefCounted

# The placeholder signs drawn on Fairway's End's own enemies, so each reads without art. EnemyMarks
# hands these marks over, with the body's half size.
const MARKS: Array[String] = ["caddie_bib", "boater"]
const BIB := Color("fbfbf4")
const BIB_NUMBER := Color("2f5a2c")
const CAP := Color("2f5a2c")
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
		"boater":
			# A straw boater with a navy band, a gold club crest on the blazer and a monocle.
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y - 7.0, half.x * 1.1, 8.0), STRAW)
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y - 3.0, half.x * 1.1, 2.0), STRAW_BAND)
			canvas.draw_rect(Rect2(-half.x * 0.85, -half.y, half.x * 1.7, 2.0), STRAW)
			canvas.draw_arc(Vector2(half.x * 0.25, -half.y * 0.65), 3.0, 0.0, TAU, 12, MONOCLE, 1.0)
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y * 0.1, 7.0, 8.0), CREST)
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y * 0.1, 7.0, 8.0), Color.BLACK, false, 1.0)
