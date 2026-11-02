class_name Lighting
extends RefCounted

const TORCH_SPACING := 10.0
const TALL_ROOM := 14


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
	for cell in torch_cells(room_cells):
		var light := make_light(palette.torch, 1.0, 1.6)
		light.position = RoomBackdrop.cell_center(cell)
		parent.add_child(light)
