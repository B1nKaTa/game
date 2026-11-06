class_name SeanceTable
extends RockBlock

# The round seance table of a large hotline room, draped to the floor in plum with a gold fringe, a crystal
# ball in the middle and three candles round it, which light the carpet a little. Solid, it stops walkers
# and shots, and only blasts and bosses break it, putting the candles out. It can hide a coin at the
# furniture rate. Four table cells in a square are one table (SeanceProps.table_groups), so the 64x64
# art fits it; a table cell left on its own is a small side table.
const LARGE_SIZE := Vector2(64, 64)
const SMALL_SIZE := Vector2(32, 32)
const LIGHT_ENERGY := 0.5
const LIGHT_SCALE := 0.8

var large := true


func body_size() -> Vector2:
	return LARGE_SIZE if large else SMALL_SIZE


func art_size() -> Vector2:
	return body_size()


func art_id() -> String:
	return "seance_table" if large else "seance_table_small"


func debris_color() -> Color:
	return look().table_cloth.lightened(0.25)


func _ready() -> void:
	super._ready()
	if not large:
		return
	var glow := Lighting.make_light(look().candle_flame, LIGHT_ENERGY, LIGHT_SCALE)
	add_child(glow)
	Lighting.add_flicker(glow, look().flicker)


# The picture (art/props/seance_hotline/seance_table.png) is 44x40, smaller than the four cells the
# table blocks, so a dark rug of the cloth's colour under it shows the whole of what is solid.
func _draw() -> void:
	var art := art_texture()
	if art == null:
		super._draw()
		return
	var p := look()
	var radius := LARGE_SIZE.x / 2.0 - 3.0
	draw_circle(Vector2.ZERO, radius, p.table_cloth.darkened(0.35))
	draw_arc(Vector2.ZERO, radius - 2.0, 0.0, TAU, 32, p.table_fringe.darkened(0.3), 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color.BLACK, 1.0)
	draw_texture(art, PropArt.centred(art))


func _draw_placeholder() -> void:
	var p := look()
	var radius := 29.0 if large else 13.0
	draw_circle(Vector2.ZERO, radius, p.table_cloth)
	draw_arc(Vector2.ZERO, radius - 2.0, 0.0, TAU, 32, p.table_fringe, 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color.BLACK, 1.0)
	draw_circle(Vector2.ZERO, radius * 0.25, p.crystal_ball)
	draw_arc(Vector2.ZERO, radius * 0.25, 0.0, TAU, 14, Color.BLACK, 1.0)
	if not large:
		return
	for i in 3:
		var at := Vector2.from_angle(-PI / 2.0 + TAU * i / 3.0) * 17.0
		draw_rect(Rect2(at + Vector2(-1.5, -3), Vector2(3, 6)), p.candle_wax)
		draw_circle(at + Vector2(0, -5), 1.8, p.candle_flame)
