class_name AisleLight
extends Node2D

# A small brass step light set in the carpet at the end of a seat row, with a little warm pool of its
# own. Flat on the floor, under the bodies, and it blocks and breaks to nothing.
const ENERGY := 0.55
const LIGHT_SCALE := 0.28
# The Cinema's own picture, art/props/flashback_cinema/aisle_light.png.
const ART_ID := "aisle_light"

var palette: RoomPalette


func _ready() -> void:
	z_index = Hole.FLOOR_Z
	var p := palette if palette != null else RoomPalette.new()
	var glow := Lighting.make_light(p.aisle_light, ENERGY, LIGHT_SCALE)
	add_child(glow)
	queue_redraw()


func _draw() -> void:
	var art := PropArt.texture(ART_ID)
	if art != null:
		PropArt.draw(self, art)
		return
	var p := palette if palette != null else RoomPalette.new()
	draw_rect(Rect2(-4, -2, 8, 4), p.deco_gold.darkened(0.35))
	draw_rect(Rect2(-3, -1, 6, 2), p.aisle_light)
