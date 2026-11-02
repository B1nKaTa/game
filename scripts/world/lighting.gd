class_name Lighting
extends RefCounted

const TORCH_SPACING := 10.0
const TALL_ROOM := 14
const FILL_SPACING := 8.0
const FILL_ENERGY := 0.55
const FILL_SCALE := 2.6


# Along the top and bottom walls, plus the side walls of a tall room, since a
# torch's glow doesn't reach the middle of one from the top and bottom alone.
static func torch_cells(room_cells: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var columns := maxi(2, roundi(room_cells.x / TORCH_SPACING))
	for i in columns:
		var x := int((i + 0.5) * room_cells.x / columns)
		cells.append(Vector2i(x, 0))
		cells.append(Vector2i(x, room_cells.y - 1))
	if room_cells.y >= TALL_ROOM:
		cells.append(Vector2i(0, room_cells.y / 2))
		cells.append(Vector2i(room_cells.x - 1, room_cells.y / 2))
	return cells


static func make_light(color: Color, energy: float, scale_factor: float) -> PointLight2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var light := PointLight2D.new()
	light.texture = texture
	light.color = color
	light.energy = energy
	light.texture_scale = scale_factor
	return light


static func add_room_mood(parent: Node, room_cells: Vector2i, palette: RoomPalette) -> void:
	var modulate := CanvasModulate.new()
	modulate.color = palette.ambient
	parent.add_child(modulate)
	for cell in fill_cells(room_cells):
		var fill := make_light(palette.fill_light, FILL_ENERGY, FILL_SCALE)
		fill.position = RoomBackdrop.cell_center(cell)
		parent.add_child(fill)
	for cell in torch_cells(room_cells):
		var light := make_light(palette.torch, 1.0, 1.6)
		light.position = RoomBackdrop.cell_center(cell)
		parent.add_child(light)


# Torches and lanterns from the layout or the scatter give real pools of warm light.
static func add_decor_light(parent: Node, kind: String, at: Vector2, palette: RoomPalette) -> PointLight2D:
	var is_torch := kind == RoomDecor.TORCH
	var light := make_light(palette.torch if is_torch else palette.lantern_light, 1.0 if is_torch else 0.8, 1.4 if is_torch else 1.1)
	light.position = at
	parent.add_child(light)
	return light


# Faint wide lights spread through a room, so no part of a big room is pitch dark
# even a long way from every wall torch.
static func fill_cells(room_cells: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var columns := maxi(1, roundi(room_cells.x / FILL_SPACING))
	var rows := maxi(1, roundi(room_cells.y / FILL_SPACING))
	for row in rows:
		for column in columns:
			cells.append(Vector2i(int((column + 0.5) * room_cells.x / columns), int((row + 0.5) * room_cells.y / rows)))
	return cells
