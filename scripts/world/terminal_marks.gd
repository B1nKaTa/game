class_name TerminalMarks
extends RefCounted

# The placeholder signs drawn over Departures, Terminal Zero's enemies, so each type reads without art.
# EnemyMarks calls this after its own marks, so the shared file only gains one line.
const CAMERA := Color("2b2d33")
const LENS := Color("7fd6ff")
const SUN_HAT := Color("f2e6c8")
const HI_VIS := Color("f2c230")
const HI_VIS_STRIPE := Color("e8e8e0")
const HANDLE := Color("2b2d33")
const STRAP := Color("e8c04a")
const LUGGAGE_TAG := Color("fbf7ef")
const SECURITY_CAP := Color("1c2340")
const SECURITY_BADGE := Color("c9cdd6")
const WAND := Color("15131a")
const WAND_TIP := Color("7fe0a0")
const BRAID := Color("e8c04a")
const DEPARTURES_CAP := Color("15131a")
const STAMP_HANDLE := Color("7a2f3a")
const STAMP_PAD := Color("c4161c")


static func draw_mark(canvas: CanvasItem, mark: String, half: Vector2) -> void:
	match mark:
		"tour_camera":
			# A sun hat and a camera on a strap.
			canvas.draw_rect(Rect2(-half.x - 1.0, -half.y, half.x * 2.0 + 2.0, 3.0), SUN_HAT)
			canvas.draw_rect(Rect2(-half.x * 0.5, -half.y - 4.0, half.x, 4.0), SUN_HAT)
			canvas.draw_line(Vector2(-half.x * 0.6, -half.y + 5.0), Vector2(0.0, 2.0), CAMERA, 1.0)
			canvas.draw_rect(Rect2(-3.0, 1.0, 7.0, 5.0), CAMERA)
			canvas.draw_circle(Vector2(0.5, 3.5), 1.5, LENS)
		"hi_vis":
			# A high-visibility vest with a reflective band, and ear defenders.
			canvas.draw_rect(Rect2(-half.x, -half.y * 0.2, half.x * 2.0, half.y * 0.9), HI_VIS)
			canvas.draw_rect(Rect2(-half.x, half.y * 0.2, half.x * 2.0, 2.0), HI_VIS_STRIPE)
			canvas.draw_arc(Vector2(0.0, -half.y + 4.0), half.x * 0.7, PI, TAU, 10, CAMERA, 2.0)
		"suitcase":
			# A hard case with a handle on top, two straps and a luggage tag.
			canvas.draw_rect(Rect2(-5.0, -half.y - 4.0, 10.0, 4.0), HANDLE, false, 2.0)
			for x in [-half.x * 0.45, half.x * 0.45]:
				canvas.draw_line(Vector2(x, -half.y), Vector2(x, half.y), STRAP, 2.0)
			canvas.draw_line(Vector2(-half.x, 0.0), Vector2(half.x, 0.0), Color(0.0, 0.0, 0.0, 0.5), 1.0)
			canvas.draw_rect(Rect2(half.x - 2.0, -half.y + 2.0, 5.0, 4.0), LUGGAGE_TAG)
		"security_cap":
			# A dark peaked cap with a silver badge, and a scanning wand held out to one side.
			canvas.draw_rect(Rect2(-half.x * 0.7, -half.y - 5.0, half.x * 1.4, 6.0), SECURITY_CAP)
			canvas.draw_rect(Rect2(-half.x * 0.9, -half.y, half.x * 1.8, 2.0), SECURITY_CAP.darkened(0.4))
			canvas.draw_rect(Rect2(-2.0, -half.y - 4.0, 4.0, 3.0), SECURITY_BADGE)
			canvas.draw_rect(Rect2(-half.x * 0.35, -half.y * 0.2, 6.0, 7.0), SECURITY_BADGE)
			canvas.draw_line(Vector2(half.x - 2.0, 2.0), Vector2(half.x + 10.0, -6.0), WAND, 3.0)
			canvas.draw_circle(Vector2(half.x + 10.0, -6.0), 2.5, WAND_TIP)
		"departures_cap":
			# A tall peaked cap with gold braid, gold epaulettes, and a big rubber stamp in one hand.
			canvas.draw_rect(Rect2(-half.x * 0.6, -half.y - 9.0, half.x * 1.2, 10.0), DEPARTURES_CAP)
			canvas.draw_rect(Rect2(-half.x * 0.85, -half.y, half.x * 1.7, 3.0), DEPARTURES_CAP)
			canvas.draw_rect(Rect2(-half.x * 0.6, -half.y - 3.0, half.x * 1.2, 2.0), BRAID)
			for x in [-half.x, half.x - 6.0]:
				canvas.draw_rect(Rect2(x, -half.y * 0.55, 6.0, 3.0), BRAID)
			canvas.draw_rect(Rect2(half.x - 2.0, -2.0, 5.0, 9.0), STAMP_HANDLE)
			canvas.draw_rect(Rect2(half.x - 5.0, 7.0, 11.0, 5.0), STAMP_PAD)
