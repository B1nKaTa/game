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
