class_name DecorLayer
extends Node2D

# Draws every piece of decor that blocks nothing and keeps no state of its own, in one
# node. Grass is its own node because it can be cut. The look comes from the palette,
# and a picture at res://art/decor/<kind>.png replaces a placeholder.
var _items: Array[Dictionary] = []
var _palette: RoomPalette


func setup(items: Array[Dictionary], palette: RoomPalette) -> void:
	_items = items
	_palette = palette
	z_index = -9


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	for item in _items:
		var kind: String = item["kind"]
		if kind == RoomDecor.GRASS:
			continue
		var at: Vector2 = RoomBackdrop.cell_center(item["cell"]) + item["offset"]
		var art := PropArt.texture("decor_" + kind)
		if art != null:
			draw_texture(art, at - art.get_size() / 2.0)
			continue
		draw_set_transform(at)
		_draw_placeholder(kind, item["variant"], at)
	draw_set_transform(Vector2.ZERO)


func _draw_placeholder(kind: String, variant: int, at: Vector2) -> void:
	var p := _palette
	var half := RoomBackdrop.TILE / 2.0
	match kind:
		RoomDecor.BONES:
			draw_line(Vector2(-7, 3), Vector2(5, -2 + variant), p.bones, 2.0)
			draw_line(Vector2(-4, -4), Vector2(6, 4), p.bones, 2.0)
			draw_circle(Vector2(-8, 3), 2.0, p.bones)
		RoomDecor.COBWEB:
			var corner := Vector2(-half + 2, -half + 2) if variant % 2 == 0 else Vector2(half - 2, -half + 2)
			var dir := 1.0 if variant % 2 == 0 else -1.0
			draw_line(corner, corner + Vector2(dir * 14, 0), p.cobweb, 1.0)
			draw_line(corner, corner + Vector2(0, 14), p.cobweb, 1.0)
			draw_line(corner, corner + Vector2(dir * 10, 10), p.cobweb, 1.0)
			draw_line(corner + Vector2(dir * 7, 0), corner + Vector2(0, 7), p.cobweb, 1.0)
			draw_line(corner + Vector2(dir * 12, 0), corner + Vector2(0, 12), p.cobweb, 1.0)
		RoomDecor.PUDDLE:
			var radius := 7.0 + variant * 1.5
			draw_set_transform(at, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, radius, p.puddle)
			draw_arc(Vector2.ZERO, radius * 0.6, 0.3, 2.0, 8, Color(1, 1, 1, 0.25), 1.0)
		RoomDecor.CRACK:
			var flip := -1.0 if variant % 2 == 0 else 1.0
			var points := PackedVector2Array([Vector2(-10 * flip, -8), Vector2(-3 * flip, -2), Vector2(-5 * flip, 4), Vector2(4 * flip, 8), Vector2(10 * flip, 12)])
			draw_polyline(points, p.floor_crack, 1.0)
			draw_line(Vector2(-3 * flip, -2), Vector2(5 * flip, -4), p.floor_crack, 1.0)
		RoomDecor.TORCH:
			draw_rect(Rect2(-2, -4, 4, 14), Color("4a3524"))
			draw_rect(Rect2(-5, 8, 10, 3), Color("2b2018"))
			draw_circle(Vector2(0, -7), 5.0, p.torch)
			draw_circle(Vector2(0, -8), 3.0, p.torch_flame)
		RoomDecor.LANTERN:
			draw_rect(Rect2(-5, -9, 10, 16), Color("2b2018"))
			draw_rect(Rect2(-4, -6, 8, 11), p.lantern)
			draw_rect(Rect2(-1, -4, 2, 7), Color(1, 1, 0.85))
		RoomDecor.STUMP:
			draw_rect(Rect2(-8, -3, 16, 12), p.stump)
			draw_rect(Rect2(-8, -3, 16, 12), Color.BLACK, false, 1.0)
			draw_set_transform(at + Vector2(0, -3), 0.0, Vector2(1.0, 0.45))
			draw_circle(Vector2.ZERO, 8.0, p.stump_top)
			draw_arc(Vector2.ZERO, 4.5, 0.0, TAU, 12, p.stump, 1.0)
		RoomDecor.MOSS:
			var radius := 9.0 + variant * 2.0
			draw_set_transform(at, 0.0, Vector2(1.0, 0.65))
			draw_circle(Vector2.ZERO, radius, Color(p.moss, 0.75))
			draw_circle(Vector2(radius * 0.4, -radius * 0.3), radius * 0.45, Color(p.moss.lightened(0.15), 0.75))
		RoomDecor.SAPLING:
			var lean := -3.0 if variant % 2 == 0 else 3.0
			draw_line(Vector2(0, 9), Vector2(lean, -8), p.sapling, 2.0)
			draw_line(Vector2(lean * 0.4, 1), Vector2(lean + 5, -5), p.sapling, 1.0)
			draw_line(Vector2(lean * 0.6, -2), Vector2(lean - 5, -7), p.sapling, 1.0)
		RoomDecor.PLANT:
			draw_rect(Rect2(-5, 2, 10, 8), p.plant_pot)
			draw_rect(Rect2(-5, 2, 10, 8), Color.BLACK, false, 1.0)
			for leaf in [Vector2(-7, -6), Vector2(0, -10), Vector2(7, -6), Vector2(-3, -3), Vector2(4, -2)]:
				draw_line(Vector2(0, 2), leaf, p.plant_leaf, 2.0)
				draw_circle(leaf, 2.0, p.plant_leaf)
		RoomDecor.IV_STAND:
			draw_line(Vector2(0, 10), Vector2(0, -12), p.iv_stand, 1.0)
			draw_line(Vector2(-6, 10), Vector2(6, 10), p.iv_stand, 1.0)
			draw_line(Vector2(-4, -12), Vector2(4, -12), p.iv_stand, 1.0)
			draw_rect(Rect2(1, -11, 5, 7), p.iv_bag)
			draw_line(Vector2(3.5, -4), Vector2(3.5, 2), p.iv_bag, 1.0)
		RoomDecor.GAUGE:
			draw_line(Vector2(0, 10), Vector2(0, 0), p.pipe, 2.0)
			draw_circle(Vector2(0, -4), 6.0, p.pipe.darkened(0.3))
			draw_circle(Vector2(0, -4), 5.0, p.gauge)
			draw_line(Vector2(0, -4), Vector2.from_angle(-2.4 + variant * 0.6) * 4.0 + Vector2(0, -4), p.gauge_needle, 1.0)
		RoomDecor.PIPE:
			var vertical := variant % 2 == 0
			var run := Vector2(0, 12) if vertical else Vector2(12, 0)
			draw_line(-run, run, p.pipe.darkened(0.35), 6.0)
			draw_line(-run, run, p.pipe, 4.0)
			draw_rect(Rect2(-run * 0.5 - Vector2(3, 3), Vector2(6, 6)), p.pipe.darkened(0.2))
		RoomDecor.COAL_DUST:
			var radius := 8.0 + variant * 1.5
			draw_set_transform(at, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, radius, p.coal_dust)
			draw_circle(Vector2(radius * 0.4, 0), 2.0, p.coal)
		RoomDecor.FURNACE:
			draw_rect(Rect2(-half + 1, -half + 1, half * 2.0 - 2, half * 2.0 - 2), p.furnace)
			draw_rect(Rect2(-9, -6, 18, 14), p.furnace_fire)
			draw_rect(Rect2(-6, -2, 12, 8), p.furnace_fire.lightened(0.4))
			for x in [-6.0, 0.0, 6.0]:
				draw_line(Vector2(x, -6), Vector2(x, 8), p.furnace, 2.0)
			draw_rect(Rect2(-half + 1, -half + 1, half * 2.0 - 2, half * 2.0 - 2), Color.BLACK, false, 1.0)
		RoomDecor.STAINED_GLASS:
			# A soft pane of colour lying on the floor, split by its leading.
			var glass := Lighting.stained_glass_color(at)
			draw_set_transform(at, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, 11.0, Color(glass, 0.22))
			draw_circle(Vector2.ZERO, 6.0, Color(glass.lightened(0.3), 0.18))
			draw_line(Vector2(-11, 0), Vector2(11, 0), Color(0, 0, 0, 0.18), 1.0)
			draw_line(Vector2(0, -11), Vector2(0, 11), Color(0, 0, 0, 0.18), 1.0)
		RoomDecor.COFFIN_STAND:
			var lie := variant % 2 == 0
			if not lie:
				draw_set_transform(at, PI / 2.0)
			draw_rect(Rect2(-13, 4, 26, 4), Color("7a2f3a"))
			draw_line(Vector2(-10, 8), Vector2(-10, 11), p.brass, 2.0)
			draw_line(Vector2(10, 8), Vector2(10, 11), p.brass, 2.0)
			var lid := PackedVector2Array([Vector2(-13, -2), Vector2(-8, -6), Vector2(13, -5), Vector2(13, 3), Vector2(-8, 4), Vector2(-13, 1)])
			draw_colored_polygon(lid, p.coffin_wood)
			draw_polyline(lid + PackedVector2Array([lid[0]]), Color.BLACK, 1.0)
			draw_line(Vector2(-6, -1), Vector2(11, -1), p.coffin_lid, 2.0)
		RoomDecor.BENCH:
			# Slats on two iron legs, seen from above.
			var turned := variant % 2 == 1
			if turned:
				draw_set_transform(at, PI / 2.0)
			for slat in 3:
				draw_rect(Rect2(-13, -6 + slat * 4, 26, 3), p.bench.lightened(0.08 * slat))
			draw_rect(Rect2(-13, -6, 26, 11), Color.BLACK, false, 1.0)
			for x in [-10.0, 10.0]:
				draw_line(Vector2(x, 5), Vector2(x, 9), Color("3c4048"), 2.0)
		RoomDecor.FOOD_TABLE:
			# A round food court table, two chairs and a forgotten tray.
			for side in [-1.0, 1.0]:
				draw_rect(Rect2(side * 11 - 3, -3, 6, 6), Color("d9453b"))
			draw_circle(Vector2.ZERO, 8.0, p.food_table)
			draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color.BLACK, 1.0)
			draw_rect(Rect2(-4, -3, 7, 5), Color("f2c230"))
			draw_circle(Vector2(3, 3), 1.5, Color("d9453b"))
		RoomDecor.FLUORESCENT:
			# The panel's glare lying on the polished floor, a long pale strip.
			draw_rect(Rect2(-12, -4, 24, 8), Color(p.fluorescent, 0.16))
			draw_rect(Rect2(-9, -2, 18, 4), Color(p.fluorescent, 0.22))
			draw_line(Vector2(-10, 0), Vector2(10, 0), Color(1, 1, 1, 0.3), 1.0)
