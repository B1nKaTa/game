class_name Lighting
extends RefCounted

const AMBIENT := Color(0.32, 0.32, 0.48)
const TORCH := Color(1.0, 0.62, 0.3)
const TORCH_CELLS: Array[Vector2i] = [Vector2i(4, 0), Vector2i(15, 0), Vector2i(4, 10), Vector2i(15, 10)]


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


static func add_room_mood(parent: Node) -> void:
	var modulate := CanvasModulate.new()
	modulate.color = AMBIENT
	parent.add_child(modulate)
	for cell in TORCH_CELLS:
		var light := make_light(TORCH, 1.0, 1.6)
		light.position = RoomBackdrop.cell_center(cell)
		parent.add_child(light)
