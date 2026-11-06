class_name CinemaMarks
extends RefCounted

# The placeholder signs drawn on the Flashback Cinema's people and things, so each reads without art.
# EnemyMarks hands its canvas over for these marks.
const MARKS := ["usher_cap", "popcorn_tray", "film_reel", "film_extra", "critic", "projectionist"]
const CAP := Color("2a1c3a")
const BRAID := Color("e8c04a")
const TORCH := Color("c9cdd6")
const TORCH_LENS := Color("fff6c8")
const TRAY := Color("f4efe0")
const TRAY_STRIPE := Color("c9a24a")
const POPCORN := Color("fff4c0")
const STRAP := Color("5a3b22")
const REEL_RIM := Color("2a2a30")
const REEL_HOLE := Color("15131a")
const REEL_HUB := Color("e8e2d6")
const FILM := Color(0.07, 0.06, 0.05)
const EXTRA_CAP := Color("4a4a4a")
const EXTRA_SUIT := Color("2c2c30")
const EXTRA_COLLAR := Color("d8d8d8")
const GRAIN := Color(1.0, 1.0, 1.0, 0.35)
const BERET := Color("7a2f3a")
const NOTEBOOK := Color("fbf7ef")
const PENCIL := Color("e8c04a")
const MONOCLE := Color("e8e2d6")
const VISOR := Color(0.2, 0.62, 0.42, 0.9)
const PROJECTOR := Color("2a2426")
const LENS := Color("bfe6ff")
const LENS_GLOW := Color(1.0, 0.96, 0.75, 0.7)


static func draws(mark: String) -> bool:
	return MARKS.has(mark)


static func draw_mark(canvas: CanvasItem, mark: String, half: Vector2) -> void:
	match mark:
		"usher_cap":
			# A pillbox cap with a gold band, a gold braid down the jacket, and a torch held out.
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y - 4.0, half.x * 1.1, 5.0), CAP)
			canvas.draw_rect(Rect2(-half.x * 0.55, -half.y, half.x * 1.1, 1.5), BRAID)
			canvas.draw_line(Vector2(-half.x * 0.4, -half.y * 0.4), Vector2(-half.x * 0.4, half.y * 0.6), BRAID, 1.0)
			canvas.draw_line(Vector2(half.x * 0.4, -half.y * 0.4), Vector2(half.x * 0.4, half.y * 0.6), BRAID, 1.0)
			canvas.draw_rect(Rect2(half.x - 1.0, -1.0, 7.0, 3.0), TORCH)
			canvas.draw_circle(Vector2(half.x + 6.5, 0.5), 2.0, TORCH_LENS)
		"popcorn_tray":
			# A striped tray of tubs on a strap round the neck, heaped with popcorn.
			canvas.draw_line(Vector2(-half.x * 0.5, -half.y + 4.0), Vector2(-half.x * 0.7, 1.0), STRAP, 1.0)
			canvas.draw_line(Vector2(half.x * 0.5, -half.y + 4.0), Vector2(half.x * 0.7, 1.0), STRAP, 1.0)
			canvas.draw_rect(Rect2(-half.x - 2.0, 1.0, half.x * 2.0 + 4.0, 6.0), TRAY)
			for i in 4:
				var x := -half.x + i * (half.x * 2.0 / 3.0)
				canvas.draw_line(Vector2(x, 1.0), Vector2(x, 7.0), TRAY_STRIPE, 1.5)
			for i in 5:
				canvas.draw_circle(Vector2(-half.x + 1.0 + i * half.x * 0.5, 0.0), 1.8, POPCORN)
		"film_reel":
			# A reel seen from the side: a dark rim, five holes round a pale hub, and a tail of film.
			var r := minf(half.x, half.y) + 1.0
			canvas.draw_circle(Vector2.ZERO, r, REEL_RIM)
			canvas.draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, Color.BLACK, 1.0)
			for i in 5:
				canvas.draw_circle(Vector2.from_angle(TAU * i / 5.0 - PI / 2.0) * r * 0.55, r * 0.22, REEL_HOLE)
			canvas.draw_circle(Vector2.ZERO, r * 0.2, REEL_HUB)
			canvas.draw_rect(Rect2(-r * 0.2, r - 2.0, r * 1.2, 3.0), FILM)
		"film_extra":
			# A dark suit with a pale collar, a flat cap, and the grain and scratches of old
			# black-and-white film over him, so a grey body never reads as a plain pale box.
			canvas.draw_rect(Rect2(-half.x, -half.y * 0.25, half.x * 2.0, half.y * 1.25), EXTRA_SUIT)
			canvas.draw_rect(Rect2(-half.x * 0.45, -half.y * 0.35, half.x * 0.9, 3.0), EXTRA_COLLAR)
			canvas.draw_rect(Rect2(-half.x * 0.7, -half.y - 2.0, half.x * 1.5, 3.0), EXTRA_CAP)
			canvas.draw_rect(Rect2(half.x * 0.3, -half.y - 1.0, half.x * 0.6, 2.0), EXTRA_CAP)
			canvas.draw_line(Vector2(-half.x * 0.3, -half.y + 3.0), Vector2(-half.x * 0.2, half.y - 1.0), GRAIN, 1.0)
			canvas.draw_line(Vector2(half.x * 0.5, -half.y * 0.2), Vector2(half.x * 0.45, half.y - 3.0), GRAIN, 1.0)
		"critic":
			# A burgundy beret, a monocle, and a notebook with a pencil held out.
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-half.x * 0.75, -half.y + 1.0), Vector2(half.x * 0.75, -half.y + 1.0), Vector2(half.x * 0.5, -half.y - 5.0), Vector2(-half.x * 0.4, -half.y - 6.0)]), BERET)
			canvas.draw_circle(Vector2(half.x * 0.3, -half.y - 6.0), 1.5, BERET)
			canvas.draw_arc(Vector2(half.x * 0.25, -half.y * 0.55), 3.0, 0.0, TAU, 12, MONOCLE, 1.0)
			canvas.draw_line(Vector2(half.x * 0.25, -half.y * 0.55 + 3.0), Vector2(half.x * 0.35, -half.y * 0.1), MONOCLE, 1.0)
			canvas.draw_rect(Rect2(half.x - 3.0, -2.0, 9.0, 11.0), NOTEBOOK)
			canvas.draw_rect(Rect2(half.x - 3.0, -2.0, 9.0, 11.0), Color.BLACK, false, 1.0)
			canvas.draw_line(Vector2(half.x + 7.0, -4.0), Vector2(half.x + 2.0, 7.0), PENCIL, 2.0)
		"projectionist":
			# A green eyeshade, and a hand-cranked projector held out, its lens glowing.
			canvas.draw_rect(Rect2(-half.x * 0.7, -half.y + 2.0, half.x * 1.4, 4.0), VISOR)
			canvas.draw_rect(Rect2(-half.x * 0.7, -half.y + 2.0, half.x * 1.4, 4.0), Color.BLACK, false, 1.0)
			canvas.draw_rect(Rect2(half.x - 6.0, -6.0, 14.0, 11.0), PROJECTOR)
			canvas.draw_circle(Vector2(half.x - 2.0, -9.0), 4.0, PROJECTOR)
			canvas.draw_circle(Vector2(half.x + 4.0, -9.0), 4.0, PROJECTOR)
			canvas.draw_circle(Vector2(half.x + 9.0, -0.5), 3.5, LENS)
			canvas.draw_circle(Vector2(half.x + 9.0, -0.5), 6.0, LENS_GLOW)
