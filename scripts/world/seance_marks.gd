class_name SeanceMarks
extends RefCounted

# The placeholder signs drawn on the Seance Hotline's own people and things, so each reads without art.
# EnemyMarks hands its canvas over for these marks. Later bosses add theirs to MARKS and the match.
const MARKS := ["psychic_headset", "gazer_veil", "poltergeist", "ectoplasm"]
const HEADSET := Color("2a2430")
const MIC := Color("c9cdd6")
const PHONE_GLOW := Color("8ce64d")
const CORD := Color("f1e6c8")
const VEIL := Color("3a1f4d")
const VEIL_COIN := Color("e8c04a")
const JEWEL := Color("e85fc8")
const BALL := Color("ad9bf3")
const BALL_SHINE := Color("faf9fb")
const GHOST_EYE := Color("1a1a2a")
const WISP := Color(0.9, 0.95, 1.0, 0.45)
const RECEIVER := Color("2a2430")
const GOO_SHINE := Color(0.55, 0.85, 0.65, 0.7)
const GOO_DRIP := Color("154f31")
const GOO_EYE := Color("e8f5e0")


static func draws(mark: String) -> bool:
	return MARKS.has(mark)


static func draw_mark(canvas: CanvasItem, mark: String, half: Vector2) -> void:
	match mark:
		"psychic_headset":
			# A headset over the head with its mic at the mouth, and a desk phone held out, its display
			# glowing green and its coiled cord hanging.
			canvas.draw_arc(Vector2(0.0, -half.y + 4.0), half.x * 0.75, PI, TAU, 12, HEADSET, 2.0)
			canvas.draw_rect(Rect2(-half.x * 0.85, -half.y + 2.0, 3.0, 5.0), HEADSET)
			canvas.draw_rect(Rect2(half.x * 0.85 - 3.0, -half.y + 2.0, 3.0, 5.0), HEADSET)
			canvas.draw_line(Vector2(half.x * 0.85 - 2.0, -half.y + 7.0), Vector2(half.x * 0.2, -half.y * 0.45), MIC, 1.0)
			canvas.draw_rect(Rect2(half.x - 2.0, -2.0, 8.0, 6.0), HEADSET)
			canvas.draw_rect(Rect2(half.x - 1.0, -1.0, 4.0, 2.0), PHONE_GLOW)
			for i in 3:
				canvas.draw_arc(Vector2(half.x + 2.0, 6.0 + i * 3.0), 1.5, 0.0, TAU, 6, CORD, 1.0)
		"gazer_veil":
			# A dark veil hung with gold coins and a pink jewel on the brow, and a crystal ball held in
			# both hands before her.
			canvas.draw_rect(Rect2(-half.x * 0.8, -half.y - 2.0, half.x * 1.6, 5.0), VEIL)
			for i in 4:
				canvas.draw_circle(Vector2(-half.x * 0.6 + i * half.x * 0.4, -half.y + 3.5), 1.2, VEIL_COIN)
			canvas.draw_circle(Vector2(0.0, -half.y), 1.8, JEWEL)
			canvas.draw_circle(Vector2(0.0, half.y * 0.15), 5.0, BALL)
			canvas.draw_arc(Vector2(0.0, half.y * 0.15), 5.0, 0.0, TAU, 16, Color.BLACK, 1.0)
			canvas.draw_circle(Vector2(-1.5, half.y * 0.15 - 1.5), 1.2, BALL_SHINE)
		"poltergeist":
			# Two hollow eyes, a wavy hem of wisps, and a phone receiver left off the hook, on hold.
			canvas.draw_circle(Vector2(-half.x * 0.35, -half.y * 0.45), 2.0, GHOST_EYE)
			canvas.draw_circle(Vector2(half.x * 0.35, -half.y * 0.45), 2.0, GHOST_EYE)
			canvas.draw_arc(Vector2(0.0, -half.y * 0.05), 2.5, 0.0, PI, 8, GHOST_EYE, 1.0)
			for i in 3:
				canvas.draw_circle(Vector2(-half.x * 0.66 + i * half.x * 0.66, half.y), 3.0, WISP)
			canvas.draw_rect(Rect2(half.x - 1.0, -half.y * 0.2, 4.0, 9.0), RECEIVER)
			canvas.draw_rect(Rect2(half.x - 2.0, -half.y * 0.2 - 1.0, 6.0, 3.0), RECEIVER)
			canvas.draw_rect(Rect2(half.x - 2.0, -half.y * 0.2 + 7.0, 6.0, 3.0), RECEIVER)
		"ectoplasm":
			# A wet shine, two pale eyes and drips running off the blob.
			canvas.draw_circle(Vector2(-half.x * 0.4, -half.y * 0.45), 2.5, GOO_SHINE)
			canvas.draw_circle(Vector2(-half.x * 0.25, -half.y * 0.05), 1.5, GOO_EYE)
			canvas.draw_circle(Vector2(half.x * 0.3, -half.y * 0.05), 1.5, GOO_EYE)
			for x in [-half.x * 0.5, half.x * 0.1, half.x * 0.6]:
				canvas.draw_rect(Rect2(x, half.y - 2.0, 2.0, 4.0), GOO_DRIP)
				canvas.draw_circle(Vector2(x + 1.0, half.y + 2.5), 1.5, GOO_DRIP)
