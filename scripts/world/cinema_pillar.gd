class_name CinemaPillar
extends StaticBody2D

# A round art-deco column holding up the circle. It stands in the wall layer, so it stops walkers and
# shots as a wall does, and nothing breaks it: not the cane, a blast or a charging boss. Routes never
# need to pass through one (RoomLayout.WALLS).
const SIZE := Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)
const ART_ID := "pillar"

var palette: RoomPalette


func _ready() -> void:
	add_to_group("pillars")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	add_child(shape)
	queue_redraw()


func _draw() -> void:
	var p := palette if palette != null else RoomPalette.new()
	# The Cinema's own picture (art/props/flashback_cinema/pillar.png) is a narrow shaft, so the plinth
	# under it still shows the whole cell it blocks.
	var art := PropArt.texture(ART_ID)
	if art != null:
		draw_rect(Rect2(-15, 4, 30, 11), p.pillar_edge)
		draw_rect(Rect2(-14, 5, 28, 9), p.pillar.darkened(0.2))
		draw_rect(Rect2(-15, 4, 30, 11), Color.BLACK, false, 1.0)
		draw_texture(art, PropArt.standing(art, Vector2(0, 12)))
		return
	# A square plinth on the carpet, the round shaft seen from a little above, and its gold bands.
	draw_rect(Rect2(-15, 4, 30, 11), p.pillar_edge)
	draw_rect(Rect2(-14, 5, 28, 9), p.pillar.darkened(0.2))
	draw_rect(Rect2(-10, -18, 20, 26), p.pillar)
	draw_rect(Rect2(-10, -18, 5, 26), p.pillar.lightened(0.12))
	for band in [-18.0, -2.0, 6.0]:
		draw_rect(Rect2(-11, band, 22, 2), p.deco_gold)
	draw_rect(Rect2(-10, -18, 20, 26), p.pillar_edge, false, 1.0)
	draw_rect(Rect2(-15, 4, 30, 11), Color.BLACK, false, 1.0)
