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
	if cardigan != null:
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
