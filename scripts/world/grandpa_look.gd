class_name GrandpaLook
extends Node2D

# What Grandpa wears: a hat over his head and a cardigan band over his chest, drawn above his sprite.
# The cane's colour is read by the Player for its placeholder cane line and swing arc. Placeholders,
# drawn in code until the art pass. Nothing here touches a stat.

# Relative to the Player's origin, for the 68 pixel frame: his hair tops out near y = -24 and his
# beard ends near y = -1, so a hat sits on the hair and the band on the cardigan below the beard.
const HEAD := Vector2(0, -18)
const CHEST := Vector2(0, 1)
const BAND_SIZE := Vector2(16, 5)
# The idle frame's face sits right of the middle when he faces right: skin from x = 3 to 10, with the
# eyes near y = -16, two pixels under HEAD. Aviator lenses sit there, mirrored when he faces left.
const EYES := Vector2(0, 2)
const LENS_NEAR := 4.0
const LENS_FAR := 8.5
const LENS_RADIUS := 2.2
const LENS_GLASS := Color(0.12, 0.1, 0.08, 0.92)
# The body's middle is a little right of the origin in the idle frame, so a tie hangs there.
const TIE_SHIFT := 2.0
const OUTLINE := Color(0.08, 0.06, 0.05)
const STRIPE_BAND := Color("d8323a")
# A swing arc stays at least this bright, so a dark cane skin never hides where the swing reaches.
const ARC_MIN_LUMINANCE := 0.55

# Slot -> CosmeticDef, as RunState.look holds it.
var _look: Dictionary = {}
# 1 when he faces right, -1 when left, so a cap's peak points the way he looks.
var facing := 1.0


func _ready() -> void:
	z_index = 1


func setup(look: Dictionary) -> void:
	_look = look
	queue_redraw()


func set_facing(direction: float) -> void:
	var wanted := -1.0 if direction < 0.0 else 1.0
	if wanted != facing:
		facing = wanted
		queue_redraw()


# The cane's colour with a skin worn, or the fallback without one.
static func cane_color(look: Dictionary, fallback: Color) -> Color:
	var cane := look.get(CosmeticDef.SLOT_CANE) as CosmeticDef
	return cane.color if cane != null else fallback


# The swing arc follows the cane's colour, lifted towards white when the skin is too dark to read.
static func arc_color(look: Dictionary, fallback: Color) -> Color:
	var color := cane_color(look, fallback)
	if color.get_luminance() < ARC_MIN_LUMINANCE:
		color = color.lerp(Color.WHITE, ARC_MIN_LUMINANCE - color.get_luminance() + 0.2)
	return color


static func has_stripes(look: Dictionary) -> bool:
	var cane := look.get(CosmeticDef.SLOT_CANE) as CosmeticDef
	return cane != null and cane.shape == "stripe"


func _draw() -> void:
	var cardigan := _look.get(CosmeticDef.SLOT_CARDIGAN) as CosmeticDef
	if cardigan != null and cardigan.shape == "tie":
		draw_tie(self, CHEST + Vector2(TIE_SHIFT * facing, 0), cardigan.color)
	elif cardigan != null:
		var band := Rect2(CHEST - BAND_SIZE / 2.0, BAND_SIZE)
		draw_rect(band, cardigan.color)
		draw_line(band.position + Vector2(BAND_SIZE.x / 2.0, 0), band.position + Vector2(BAND_SIZE.x / 2.0, BAND_SIZE.y), cardigan.color.darkened(0.35), 1.0)
		draw_rect(band, OUTLINE, false, 1.0)
	var hat := _look.get(CosmeticDef.SLOT_HAT) as CosmeticDef
	if hat != null:
		draw_hat(self, hat.shape, HEAD, hat.color, facing)


# Draws one hat shape over a head centred at head.
static func draw_hat(canvas: CanvasItem, shape: String, head: Vector2, color: Color, facing_dir := 1.0) -> void:
	match shape:
		"bucket":
			# Gerald's terrible bucket hat: a squat crown, a floppy brim drooping at both ends, and a
			# stitched line round it.
			var crown := PackedVector2Array([head + Vector2(-6, -5), head + Vector2(-5, -11), head + Vector2(5, -11), head + Vector2(6, -5)])
			var brim := PackedVector2Array([head + Vector2(-11, -2), head + Vector2(-7, -6), head + Vector2(7, -6), head + Vector2(11, -2), head + Vector2(7, -4), head + Vector2(-7, -4)])
			canvas.draw_colored_polygon(brim, color.darkened(0.15))
			canvas.draw_colored_polygon(crown, color)
			canvas.draw_line(head + Vector2(-5, -8), head + Vector2(5, -8), color.darkened(0.35), 1.0)
			canvas.draw_polyline(PackedVector2Array([crown[0], crown[1], crown[2], crown[3]]), OUTLINE, 1.0)
			canvas.draw_polyline(PackedVector2Array([brim[0], brim[1], brim[2], brim[3], brim[4], brim[5], brim[0]]), OUTLINE, 1.0)
		"flat_cap":
			var crown := Rect2(head + Vector2(-7, -9), Vector2(14, 5))
			canvas.draw_rect(crown, color)
			var peak := PackedVector2Array([head + Vector2(5 * facing_dir, -5), head + Vector2(11 * facing_dir, -4), head + Vector2(5 * facing_dir, -3)])
			canvas.draw_colored_polygon(peak, color.darkened(0.25))
			canvas.draw_rect(crown, OUTLINE, false, 1.0)
		"cone":
			var cone := PackedVector2Array([head + Vector2(-6, -6), head + Vector2(6, -6), head + Vector2(0, -20)])
			canvas.draw_colored_polygon(cone, color)
			canvas.draw_line(head + Vector2(-3, -11), head + Vector2(3, -11), Color.WHITE, 1.0)
			canvas.draw_circle(head + Vector2(0, -21), 2.0, Color("ffd24a"))
		"hood":
			# A dark arc over the head that falls to the shoulders.
			canvas.draw_arc(head + Vector2(0, 2), 10.0, PI, TAU, 16, color, 5.0)
			canvas.draw_line(head + Vector2(-10, 2), head + Vector2(-9, 14), color, 5.0)
			canvas.draw_line(head + Vector2(10, 2), head + Vector2(9, 14), color, 5.0)
			canvas.draw_arc(head + Vector2(0, 2), 12.5, PI, TAU, 16, OUTLINE, 1.0)
		"captain":
			# A white crown with a black band, a black peak the way he faces and a gold badge.
			var top := Rect2(head + Vector2(-8, -11), Vector2(16, 6))
			canvas.draw_rect(top, color)
			canvas.draw_rect(Rect2(head + Vector2(-8, -6), Vector2(16, 2)), OUTLINE)
			var visor := PackedVector2Array([head + Vector2(4 * facing_dir, -4), head + Vector2(11 * facing_dir, -3), head + Vector2(4 * facing_dir, -2)])
			canvas.draw_colored_polygon(visor, OUTLINE)
			canvas.draw_circle(head + Vector2(facing_dir, -8), 1.5, Color("ffd24a"))
			canvas.draw_rect(top, OUTLINE, false, 1.0)
		"visor":
			# A band with no crown, so his white hair shows over it, and a long bill the way he faces.
			var strap := Rect2(head + Vector2(-7, -7), Vector2(14, 3))
			canvas.draw_rect(strap, color)
			var bill := PackedVector2Array([head + Vector2(4 * facing_dir, -7), head + Vector2(13 * facing_dir, -5), head + Vector2(13 * facing_dir, -4), head + Vector2(4 * facing_dir, -4)])
			canvas.draw_colored_polygon(bill, color.darkened(0.2))
			canvas.draw_polyline(PackedVector2Array([bill[0], bill[1], bill[2], bill[3]]), OUTLINE, 1.0)
			canvas.draw_rect(strap, OUTLINE, false, 1.0)
		"aviators":
			# Two dark lenses in gold frames over his eyes, and an arm back to the ear.
			var eyes := head + EYES
			var near := eyes + Vector2(LENS_NEAR * facing_dir, 0)
			var far := eyes + Vector2(LENS_FAR * facing_dir, 0)
			canvas.draw_line(eyes + Vector2(-4 * facing_dir, -1), near + Vector2(-LENS_RADIUS * facing_dir, -1), color, 1.0)
			canvas.draw_line(near + Vector2(LENS_RADIUS * facing_dir, -1), far + Vector2(-LENS_RADIUS * facing_dir, -1), color, 1.0)
			for lens: Vector2 in [near, far]:
				canvas.draw_circle(lens, LENS_RADIUS, LENS_GLASS)
				canvas.draw_arc(lens, LENS_RADIUS, 0.0, TAU, 10, color, 1.0)
		"tiara":
			# Outlined first, since a gold tiara on white hair vanishes on the Mall's pale tile.
			canvas.draw_line(head + Vector2(-7, -7), head + Vector2(7, -7), OUTLINE, 4.0)
			for x: float in [-4.0, 0.0, 4.0]:
				var edge := PackedVector2Array([head + Vector2(x - 3, -6), head + Vector2(x + 3, -6), head + Vector2(x, -13 if x == 0.0 else -11)])
				canvas.draw_colored_polygon(edge, OUTLINE)
			canvas.draw_line(head + Vector2(-6, -7), head + Vector2(6, -7), color, 2.0)
			for x: float in [-4.0, 0.0, 4.0]:
				var point := PackedVector2Array([head + Vector2(x - 2, -7), head + Vector2(x + 2, -7), head + Vector2(x, -12 if x == 0.0 else -10)])
				canvas.draw_colored_polygon(point, color)
			canvas.draw_circle(head + Vector2(0, -9), 1.0, Color("e4524f"))


# A tie hanging from a knot at chest: a small knot and a long blade that widens to a point.
static func draw_tie(canvas: CanvasItem, chest: Vector2, color: Color) -> void:
	var knot := PackedVector2Array([chest + Vector2(-2, -2), chest + Vector2(2, -2), chest + Vector2(1, 1), chest + Vector2(-1, 1)])
	var blade := PackedVector2Array([chest + Vector2(-1, 1), chest + Vector2(1, 1), chest + Vector2(3, 8), chest + Vector2(0, 11), chest + Vector2(-3, 8)])
	canvas.draw_colored_polygon(blade, color)
	canvas.draw_colored_polygon(knot, color.darkened(0.2))
	canvas.draw_polyline(PackedVector2Array([blade[0], blade[4], blade[3], blade[2], blade[1]]), OUTLINE, 1.0)
	canvas.draw_polyline(PackedVector2Array([knot[0], knot[1], knot[2], knot[3], knot[0]]), OUTLINE, 1.0)
