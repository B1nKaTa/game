class_name Lighting
extends RefCounted

const TORCH_SPACING := 10.0
const TALL_ROOM := 14
const FILL_SPACING := 8.0
const FILL_ENERGY := 0.32
const FILL_SCALE := 2.6
# A pool of light through a stained-glass window, in one of the window's colours.
const STAINED_GLASS_COLORS: Array[Color] = [Color(0.95, 0.35, 0.45), Color(0.4, 0.55, 1.0), Color(0.95, 0.8, 0.35), Color(0.45, 0.85, 0.5), Color(0.75, 0.45, 0.95)]
const STAINED_GLASS_ENERGY := 0.55
const STAINED_GLASS_SCALE := 0.9
# A fluorescent panel overhead, cool and even.
const FLUORESCENT_ENERGY := 0.6
const FLUORESCENT_SCALE := 1.2


# The same spot always gets the same colour, so a room looks the same each time it is drawn.
static func stained_glass_color(at: Vector2) -> Color:
	var pick := posmod(int(at.x / 7.0) * 31 + int(at.y / 5.0) * 17, STAINED_GLASS_COLORS.size())
	return STAINED_GLASS_COLORS[pick]


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


# Every light shares one radial texture, so a room or an enemy coming in builds no new gradient.
static var _shared_texture: GradientTexture2D


static func _light_texture() -> GradientTexture2D:
	if _shared_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		_shared_texture = GradientTexture2D.new()
		_shared_texture.gradient = gradient
		_shared_texture.width = 256
		_shared_texture.height = 256
		_shared_texture.fill = GradientTexture2D.FILL_RADIAL
		_shared_texture.fill_from = Vector2(0.5, 0.5)
		_shared_texture.fill_to = Vector2(1.0, 0.5)
	return _shared_texture


static func make_light(color: Color, energy: float, scale_factor: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _light_texture()
	light.color = color
	light.energy = energy
	light.texture_scale = scale_factor
	return light


static func add_room_mood(parent: Node, room_cells: Vector2i, palette: RoomPalette, depth: DepthLook = null, rows: PackedStringArray = PackedStringArray()) -> void:
	if depth != null:
		add_depth_mood(parent, room_cells, depth, rows)
		return
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
		add_flicker(light, palette.flicker)


# The depth look's light (DepthLook): a dark ambient, a warm sconce on the north wall's faces, a faint
# wide fill so no corner goes black, and a vignette over the view. Fewer lights than the flat look.
static func add_depth_mood(parent: Node, room_cells: Vector2i, depth: DepthLook, rows: PackedStringArray) -> void:
	var modulate := CanvasModulate.new()
	modulate.color = depth.ambient
	parent.add_child(modulate)
	for cell in fill_cells(room_cells, DepthLook.FILL_SPACING):
		var fill := make_light(depth.fill_light, DepthLook.FILL_ENERGY, DepthLook.FILL_SCALE)
		fill.position = RoomBackdrop.cell_center(cell)
		parent.add_child(fill)
	# A set with no sconce picture hangs no sconce lights, so no light shines from a bare wall.
	var sconces: Array[Vector2i] = []
	if depth.sconce != null:
		sconces = DepthLook.sconce_cells(rows)
	for cell in sconces:
		var light := make_light(depth.sconce_light, DepthLook.SCONCE_ENERGY, DepthLook.SCONCE_SCALE)
		light.position = depth.sconce_flame(cell) + Vector2(0, 10)
		parent.add_child(light)
		add_flicker(light, DepthLook.FLICKER)
	parent.add_child(Vignette.new())


# Torches and lanterns from the layout or the scatter give real pools of warm light.
static func add_decor_light(parent: Node, kind: String, at: Vector2, palette: RoomPalette) -> PointLight2D:
	var is_torch := kind == RoomDecor.TORCH
	var light: PointLight2D
	if kind == RoomDecor.FURNACE:
		light = make_light(palette.furnace_fire, 1.0, 1.6)
	elif kind == RoomDecor.STAINED_GLASS:
		light = make_light(stained_glass_color(at), STAINED_GLASS_ENERGY, STAINED_GLASS_SCALE)
	elif kind == RoomDecor.FLUORESCENT:
		light = make_light(palette.fluorescent, FLUORESCENT_ENERGY, FLUORESCENT_SCALE)
	else:
		light = make_light(palette.torch if is_torch else palette.lantern_light, 1.0 if is_torch else 0.8, 1.4 if is_torch else 1.1)
	light.position = at
	parent.add_child(light)
	add_flicker(light, palette.flicker)
	return light


# A floor of open fires gives every flame a slight, uneven wobble. Nothing wobbles at 0.
static func add_flicker(light: PointLight2D, amount: float) -> void:
	if amount <= 0.0:
		return
	var wobble := LightFlicker.new()
	wobble.amount = amount
	light.add_child(wobble)


# Faint wide lights spread through a room, so no part of a big room is pitch dark
# even a long way from every wall torch.
static func fill_cells(room_cells: Vector2i, spacing := FILL_SPACING) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var columns := maxi(1, roundi(room_cells.x / spacing))
	var rows := maxi(1, roundi(room_cells.y / spacing))
	for row in rows:
		for column in columns:
			cells.append(Vector2i(int((column + 0.5) * room_cells.x / columns), int((row + 0.5) * room_cells.y / rows)))
	return cells
