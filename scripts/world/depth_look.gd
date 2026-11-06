class_name DepthLook
extends RefCounted

# The "depth" art direction (docs/art/art-direction-notes.md), for a floor whose FloorDef.art_style is
# STYLE. Every other floor keeps its flat tiles, light and code warnings exactly as before.
#
# Ground. One continuous base terrain over the whole room, with patches of a second terrain laid over it
# by a smooth noise on the cell corners, drawn with the 16 Wang tiles of res://art/tiles/<set>/depth/
# ground.png (index NW*8 + NE*4 + SW*2 + SE, a set bit being the patch). Puddles, cracks and grit are
# baked once into small textures and scattered at pixel offsets that ignore the grid.
# Walls. A wall cell with open floor south of it shows a front face (face_N.png), every other wall cell
# its top (cap.png), with a rim where a top meets the floor and a banded shadow cast on the floor south
# and east of each wall. Outside the room the tops run on a ragged distance into darkness, so the room
# reads as cut out of a solid mass. Collision never changes; all of this is drawn.
# Light. A dark ambient, warm sconces on the north wall faces, a faint fill, and a vignette over the
# view. Warnings, shots and ground marks draw unshaded (UNSHADED_Z and up), so the dark never dims them.
const STYLE := "depth"
const DIR := "res://art/tiles/%s/depth/"
const TILE := 32
const FACES := 8
# How often each face variant shows, plain ones first (tools/art/depth_art.py FACES).
const FACE_ODDS: Array[float] = [5.0, 5.0, 3.0, 3.0, 2.0, 0.6, 0.6, 0.4]
# The patches: corner noise above this lays the second terrain, and the noise's scale in cells.
const PATCH_LEVEL := 0.67
const PATCH_SCALE := 3.2
# Ambient light and the light sources (CanvasModulate multiplies every lit thing by AMBIENT).
const AMBIENT := Color(0.33, 0.30, 0.38)
const SCONCE_LIGHT := Color(1.0, 0.64, 0.34)
const SCONCE_ENERGY := 1.35
const SCONCE_SCALE := 1.9
const FILL_LIGHT := Color(0.95, 0.82, 0.68)
const FILL_ENERGY := 0.3
const FILL_SCALE := 3.6
# One wide fill every this many cells: fewer, larger lights than the flat look.
const FILL_SPACING := 12.0
const FLICKER := 0.06
# The even light bodies are shown in (SpriteVisual draws them unshaded in this look): a warm dim, so
# they sit in the torchlight yet never drop into a dark corner.
const BODY_LIGHT := Color(1.12, 1.07, 1.0)
const BODY_GAMMA := 0.76
# Sconces sit on north wall faces this far apart, never within DOOR_CLEAR cells of a door column.
const SCONCE_SPACING := 7
const DOOR_CLEAR := 2
const INNER_SCONCES := 2
const INNER_SPACING := 6.0
# Where the flame sits on the sconce picture, from its top-left.
const SCONCE_FLAME := Vector2(7, 5)
# Anything drawn at this z or above (shots, ground marks, warnings) is unshaded.
const UNSHADED_Z := 50
# Under the bodies and props (z 0), over the floor, its shadows and flat marks: the room falls off into
# the dark at the edges while everything that moves stays in its own even light.
const VIGNETTE_Z := -2
const VIGNETTE_STRENGTH := 0.7
# Shadow bands under a wall face (alpha per 4 px band) and beside a wall's east side.
const FACE_SHADOW: Array[float] = [0.42, 0.3, 0.2, 0.1]
const SIDE_SHADOW: Array[float] = [0.26, 0.12]
const RIM_LIGHT := Color(1.0, 0.92, 0.8, 0.22)
const EDGE_DARK := Color(0.03, 0.02, 0.03, 0.85)
# The mass outside the room: how far the wall tops reach past the border, in pixels.
const MASS_MIN := 6
const MASS_MAX := 20
const DECAL_DENSITY := 0.09
const JAMB := Color("4a4038")
const JAMB_LIGHT := Color("6e6152")
const JAMB_DARK := Color("221c18")

static var active := false
static var _cache := {}
static var _unshaded: CanvasItemMaterial

var ground: Texture2D
var cap: Texture2D
var faces: Array[Texture2D] = []
var sconce: Texture2D
var decals: Array[Texture2D] = []
# The mean colour of the base ground, for things that continue it (a door's opening).
var ground_color := Color("3b3029")


static func for_floor(floor_def: FloorDef) -> DepthLook:
	if floor_def == null or floor_def.art_style != STYLE:
		return null
	return for_set(floor_def.art())


static func for_set(set_id: String) -> DepthLook:
	if _cache.has(set_id):
		return _cache[set_id]
	var look: DepthLook = null
	var dir := DIR % set_id
	if ResourceLoader.exists(dir + "ground.png") and ResourceLoader.exists(dir + "cap.png") and ResourceLoader.exists(dir + "face_0.png"):
		look = DepthLook.new()
		look.ground = load(dir + "ground.png")
		look.cap = load(dir + "cap.png")
		for i in FACES:
			if ResourceLoader.exists(dir + "face_%d.png" % i):
				look.faces.append(load(dir + "face_%d.png" % i))
		if ResourceLoader.exists(dir + "sconce.png"):
			look.sconce = load(dir + "sconce.png")
		look.decals = _make_decals()
	_cache[set_id] = look
	return look


static func unshaded() -> CanvasItemMaterial:
	if _unshaded == null:
		_unshaded = CanvasItemMaterial.new()
		_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _unshaded


# Shots, ground marks and warnings keep their full colour in the dark. Called for each node a room gains.
static func keep_vivid(node: Node) -> void:
	if not active or not is_instance_valid(node) or not (node is CanvasItem):
		return
	var item := node as CanvasItem
	if item.z_index >= UNSHADED_Z and item.material == null:
		item.material = unshaded()


# ---------------------------------------------------------------- ground


# A smooth value noise on cell corners, 0 to 1, for where the patches lie.
static func corner_noise(corner: Vector2i, seed_value: int) -> float:
	var at := Vector2(corner) / PATCH_SCALE
	var base := Vector2i(floori(at.x), floori(at.y))
	var f := at - Vector2(base)
	f = f * f * (Vector2(3, 3) - 2.0 * f)
	var a := RoomDecor.noise(base, seed_value + 401)
	var b := RoomDecor.noise(base + Vector2i(1, 0), seed_value + 401)
	var c := RoomDecor.noise(base + Vector2i(0, 1), seed_value + 401)
	var d := RoomDecor.noise(base + Vector2i(1, 1), seed_value + 401)
	var coarse := lerpf(lerpf(a, b, f.x), lerpf(c, d, f.x), f.y)
	return coarse * 0.8 + RoomDecor.noise(corner, seed_value + 409) * 0.2


static func is_patch(corner: Vector2i, seed_value: int) -> bool:
	return corner_noise(corner, seed_value) > PATCH_LEVEL


static func ground_index(cell: Vector2i, seed_value: int) -> int:
	var nw := int(is_patch(cell, seed_value))
	var ne := int(is_patch(cell + Vector2i(1, 0), seed_value))
	var sw := int(is_patch(cell + Vector2i(0, 1), seed_value))
	var se := int(is_patch(cell + Vector2i(1, 1), seed_value))
	return nw * 8 + ne * 4 + sw * 2 + se


# ---------------------------------------------------------------- walls


static func _is_wall(rows: PackedStringArray, cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= rows[cell.y].length():
		return false
	return RoomLayout.WALL_LIKE.contains(rows[cell.y][cell.x])


static func _inside(rows: PackedStringArray, cell: Vector2i) -> bool:
	return cell.y >= 0 and cell.y < rows.size() and cell.x >= 0 and cell.x < rows[cell.y].length()


static func _is_floor(rows: PackedStringArray, cell: Vector2i) -> bool:
	return _inside(rows, cell) and not _is_wall(rows, cell)


# A wall cell shows its front when open floor lies just south of it.
static func is_face(rows: PackedStringArray, cell: Vector2i) -> bool:
	return _is_wall(rows, cell) and _is_floor(rows, cell + Vector2i.DOWN)


func _face_texture(cell: Vector2i, seed_value: int) -> Texture2D:
	var total := 0.0
	for i in faces.size():
		total += FACE_ODDS[i]
	var roll := RoomDecor.noise(cell, seed_value + 431) * total
	for i in faces.size():
		roll -= FACE_ODDS[i]
		if roll <= 0.0:
			return faces[i]
	return faces[0]


# The cells on north wall faces that hold a sconce: every SCONCE_SPACING along, kept off doors.
static func sconce_cells(rows: PackedStringArray) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var width := rows[0].length()
	var door_x := width / 2
	var count := maxi(2, roundi(float(width) / SCONCE_SPACING))
	for i in count:
		var x := int((i + 0.5) * width / count)
		if absi(x - door_x) <= DOOR_CLEAR:
			x = door_x - DOOR_CLEAR - 1 if x <= door_x else door_x + DOOR_CLEAR + 1
		var cell := Vector2i(x, 0)
		if is_face(rows, cell):
			cells.append(cell)
	# The north wall sits under the HUD in a room that fits the view, so the room's own wall blocks
	# carry a couple of sconces too, where their light and flame show. Picked by noise from the faces
	# off the border, kept INNER_SPACING apart from each other.
	var inner: Array[Vector2i] = []
	for y in range(2, rows.size() - 1):
		for x in range(1, width - 1):
			if is_face(rows, Vector2i(x, y)):
				inner.append(Vector2i(x, y))
	inner.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return RoomDecor.noise(a, 521) < RoomDecor.noise(b, 521))
	var picked: Array[Vector2i] = []
	for cell in inner:
		if picked.size() >= INNER_SCONCES:
			break
		var clear := true
		for other in picked:
			if other.distance_to(cell) < INNER_SPACING:
				clear = false
		if clear:
			picked.append(cell)
	cells.append_array(picked)
	return cells


func sconce_flame(cell: Vector2i) -> Vector2:
	var at := Vector2(cell * TILE) + Vector2(TILE / 2.0 - 8.0, 3.0)
	return at + SCONCE_FLAME


# ---------------------------------------------------------------- drawing


# The whole backdrop, painted once into one texture: thousands of small draws became one, which every
# light then lights in a single pass. at is where the texture's top-left goes in the room.
func bake(rows: PackedStringArray, seed_value: int, darkness: Color) -> Dictionary:
	var size := Vector2i(rows[0].length(), rows.size())
	var area := RoomBackdrop.overdraw_rect(Vector2(size * TILE))
	var painter := DepthPainter.new(Rect2i(Vector2i(area.position.floor()), Vector2i(area.size.ceil())))
	draw_room(painter, rows, seed_value, darkness)
	return {"texture": ImageTexture.create_from_image(painter.image), "at": painter.origin}


func draw_room(canvas, rows: PackedStringArray, seed_value: int, darkness: Color) -> void:
	var size := Vector2i(rows[0].length(), rows.size())
	var room := Rect2(Vector2.ZERO, Vector2(size * TILE))
	canvas.draw_rect(RoomBackdrop.overdraw_rect(room.size), darkness)
	_draw_mass(canvas, size, seed_value)
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if not _is_wall(rows, cell):
				var index := ground_index(cell, seed_value)
				canvas.draw_texture_rect_region(ground, Rect2(Vector2(cell * TILE), Vector2(TILE, TILE)), Rect2(index * TILE, 0, TILE, TILE))
	_draw_decals(canvas, rows, seed_value)
	_draw_shadows(canvas, rows)
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if _is_wall(rows, cell):
				_draw_wall(canvas, rows, cell, seed_value)
	if sconce != null:
		for cell in sconce_cells(rows):
			canvas.draw_texture(sconce, Vector2(cell * TILE) + Vector2(TILE / 2.0 - 8.0, 3.0))


func _draw_wall(canvas, rows: PackedStringArray, cell: Vector2i, seed_value: int) -> void:
	var at := Vector2(cell * TILE)
	if is_face(rows, cell):
		var top := 0
		# A wall one cell deep shows a strip of its top above the face.
		if not _is_wall(rows, cell + Vector2i.UP) and cell.y > 0:
			top = 9
			canvas.draw_texture_rect_region(cap, Rect2(at, Vector2(TILE, top)), Rect2(0, 0, TILE, top))
		canvas.draw_texture_rect_region(_face_texture(cell, seed_value), Rect2(at + Vector2(0, top), Vector2(TILE, TILE - top)), Rect2(0, 0, TILE, TILE - top))
		# The ledge: a dark line under the top and a lit lip on it.
		canvas.draw_rect(Rect2(at + Vector2(0, top), Vector2(TILE, 1)), EDGE_DARK)
		if top > 0:
			canvas.draw_rect(Rect2(at + Vector2(0, top - 1), Vector2(TILE, 1)), RIM_LIGHT)
			canvas.draw_rect(Rect2(at, Vector2(TILE, 1)), EDGE_DARK)
		# The foot of the face, where it meets the floor.
		canvas.draw_rect(Rect2(at + Vector2(0, TILE - 2), Vector2(TILE, 2)), Color(0, 0, 0, 0.35))
		for side in [Vector2i.LEFT, Vector2i.RIGHT]:
			if _is_floor(rows, cell + side):
				var edge_x := at.x if side == Vector2i.LEFT else at.x + TILE - 1
				canvas.draw_rect(Rect2(Vector2(edge_x, at.y + top), Vector2(1, TILE - top)), EDGE_DARK)
		return
	canvas.draw_texture(cap, at)
	# A top's rim where it meets the floor: lit on the inside, dark at the very edge, with a few stones
	# nudged out over the line so the edge never runs ruler-straight.
	for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not _is_floor(rows, cell + side):
			continue
		match side:
			Vector2i.UP:
				canvas.draw_rect(Rect2(at, Vector2(TILE, 1)), EDGE_DARK)
				canvas.draw_rect(Rect2(at + Vector2(0, 1), Vector2(TILE, 1)), RIM_LIGHT)
			Vector2i.DOWN:
				canvas.draw_rect(Rect2(at + Vector2(0, TILE - 1), Vector2(TILE, 1)), EDGE_DARK)
				_draw_bumps(canvas, at + Vector2(0, TILE), Vector2.RIGHT, Vector2.DOWN, cell, seed_value)
			Vector2i.LEFT:
				canvas.draw_rect(Rect2(at, Vector2(1, TILE)), EDGE_DARK)
				canvas.draw_rect(Rect2(at + Vector2(1, 0), Vector2(1, TILE)), RIM_LIGHT)
				_draw_bumps(canvas, at, Vector2.DOWN, Vector2.LEFT, cell, seed_value + 3)
			Vector2i.RIGHT:
				canvas.draw_rect(Rect2(at + Vector2(TILE - 1, 0), Vector2(1, TILE)), EDGE_DARK)
				_draw_bumps(canvas, at + Vector2(TILE, 0), Vector2.DOWN, Vector2.RIGHT, cell, seed_value + 5)


# Small stones of the wall top poking up to 3 px past a straight edge, along `along` from `start`.
func _draw_bumps(canvas, start: Vector2, along: Vector2, out: Vector2, cell: Vector2i, seed_value: int) -> void:
	for step in 8:
		var n := RoomDecor.noise(cell * 8 + Vector2i(step, step * 3), seed_value + 451)
		if n < 0.55:
			continue
		var depth := 1 + int(n * 3.0)
		var length := 3 + int(RoomDecor.noise(cell + Vector2i(step, 0), seed_value + 457) * 3.0)
		var p := start + along * (step * 4)
		var rect := Rect2(p, along * length + out * depth).abs()
		canvas.draw_texture_rect_region(cap, rect, Rect2(Vector2(posmod(int(p.x), 28), posmod(int(p.y), 28)), rect.size))
		# The dark line along the bump's outer side.
		var edge := Rect2(p + out * depth, along * length + out.abs()).abs()
		if out.x < 0 or out.y < 0:
			edge = Rect2(p + out * (depth + 1), along * length + out.abs()).abs()
		canvas.draw_rect(edge, EDGE_DARK)


func _draw_shadows(canvas, rows: PackedStringArray) -> void:
	for y in rows.size():
		for x in rows[y].length():
			var cell := Vector2i(x, y)
			if not _is_floor(rows, cell):
				continue
			var at := Vector2(cell * TILE)
			if _is_wall(rows, cell + Vector2i.UP):
				for band in FACE_SHADOW.size():
					canvas.draw_rect(Rect2(at + Vector2(0, band * 4), Vector2(TILE, 4)), Color(0, 0, 0, FACE_SHADOW[band]))
			if _is_wall(rows, cell + Vector2i.LEFT):
				for band in SIDE_SHADOW.size():
					canvas.draw_rect(Rect2(at + Vector2(band * 3, 0), Vector2(3, TILE)), Color(0, 0, 0, SIDE_SHADOW[band]))


# The solid mass round the room: wall tops reaching a ragged distance past the border, then darkness.
func _draw_mass(canvas, size: Vector2i, seed_value: int) -> void:
	var room_px := Vector2(size * TILE)
	var step := 4
	for x in range(-MASS_MAX, int(room_px.x) + MASS_MAX, step):
		var top := _reach(x / step, seed_value + 1)
		var bottom := _reach(x / step, seed_value + 2)
		_tile_cap(canvas, Rect2(x, -top, step, top))
		_tile_cap(canvas, Rect2(x, room_px.y, step, bottom))
		canvas.draw_rect(Rect2(x, -top - 1, step, 1), EDGE_DARK)
		canvas.draw_rect(Rect2(x, room_px.y + bottom, step, 1), EDGE_DARK)
	for y in range(0, int(room_px.y), step):
		var left := _reach(y / step, seed_value + 3)
		var right := _reach(y / step, seed_value + 4)
		_tile_cap(canvas, Rect2(-left, y, left, step))
		_tile_cap(canvas, Rect2(room_px.x, y, right, step))
		canvas.draw_rect(Rect2(-left - 1, y, 1, step), EDGE_DARK)
		canvas.draw_rect(Rect2(room_px.x + right, y, 1, step), EDGE_DARK)


func _reach(i: int, seed_value: int) -> int:
	var a := RoomDecor.noise(Vector2i(i / 3, 0), seed_value + 461)
	var b := RoomDecor.noise(Vector2i(i / 3 + 1, 0), seed_value + 461)
	var t := float(posmod(i, 3)) / 3.0
	return MASS_MIN + int(lerpf(a, b, t) * (MASS_MAX - MASS_MIN))


func _tile_cap(canvas, rect: Rect2) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	var y := rect.position.y
	while y < rect.end.y:
		var h := minf(rect.end.y - y, TILE - posmod(int(y), TILE))
		var x := rect.position.x
		while x < rect.end.x:
			var w := minf(rect.end.x - x, TILE - posmod(int(x), TILE))
			canvas.draw_texture_rect_region(cap, Rect2(x, y, w, h), Rect2(posmod(int(x), TILE), posmod(int(y), TILE), w, h))
			x += w
		y += h


# Decals: a few per room on open floor, at pixel offsets that ignore the cells, kept off wall feet.
func _draw_decals(canvas, rows: PackedStringArray, seed_value: int) -> void:
	if decals.is_empty():
		return
	for y in range(1, rows.size() - 1):
		for x in range(1, rows[y].length() - 1):
			var cell := Vector2i(x, y)
			if not _is_floor(rows, cell) or RoomDecor.noise(cell, seed_value + 471) > DECAL_DENSITY:
				continue
			var pick := decals[int(RoomDecor.noise(cell, seed_value + 473) * decals.size()) % decals.size()]
			var offset := Vector2(RoomDecor.noise(cell, seed_value + 479), RoomDecor.noise(cell, seed_value + 487)) * TILE - pick.get_size() / 2.0
			canvas.draw_texture(pick, (Vector2(cell * TILE) + Vector2(TILE / 2.0, TILE / 2.0) + offset * 0.8).floor())


# Puddles, cracks and grit, baked once as small textures with hard pixel edges.
static func _make_decals() -> Array[Texture2D]:
	var made: Array[Texture2D] = []
	made.append(_puddle(22, 12, 1))
	made.append(_puddle(30, 15, 2))
	made.append(_puddle(16, 9, 3))
	made.append(_crack(24, 4))
	made.append(_crack(18, 5))
	made.append(_grit(14, 6))
	made.append(_grit(18, 7))
	return made


static func _puddle(w: int, h: int, seed_value: int) -> Texture2D:
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var deep := Color(0.07, 0.08, 0.1, 0.62)
	var wet := Color(0.13, 0.15, 0.18, 0.5)
	var shine := Color(0.62, 0.66, 0.72, 0.55)
	for y in h:
		for x in w:
			var d := pow((x + 0.5 - w / 2.0) / (w / 2.0), 2) + pow((y + 0.5 - h / 2.0) / (h / 2.0), 2)
			d += (RoomDecor.noise(Vector2i(x / 3, y / 2), seed_value + 491) - 0.5) * 0.5
			if d < 0.55:
				image.set_pixel(x, y, deep)
			elif d < 1.0:
				image.set_pixel(x, y, wet)
	for i in 3:
		var sx := int(w * (0.3 + 0.12 * i))
		var sy := int(h * 0.35)
		if image.get_pixel(sx, sy).a > 0.0:
			image.set_pixel(sx, sy, shine)
			if i == 1 and sx + 1 < w:
				image.set_pixel(sx + 1, sy, shine)
	return ImageTexture.create_from_image(image)


static func _crack(length: int, seed_value: int) -> Texture2D:
	var image := Image.create(length + 2, 10, false, Image.FORMAT_RGBA8)
	var dark := Color(0.04, 0.03, 0.03, 0.55)
	var y := 5
	for x in length:
		if RoomDecor.noise(Vector2i(x, 0), seed_value + 497) > 0.62:
			y = clampi(y + (1 if RoomDecor.noise(Vector2i(x, 1), seed_value + 499) > 0.5 else -1), 1, 8)
		image.set_pixel(x + 1, y, dark)
		if RoomDecor.noise(Vector2i(x, 2), seed_value + 503) > 0.86:
			image.set_pixel(x + 1, clampi(y + 1, 0, 9), dark)
	return ImageTexture.create_from_image(image)


static func _grit(size: int, seed_value: int) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var dark := Color(0.08, 0.06, 0.05, 0.6)
	var light := Color(0.62, 0.56, 0.48, 0.55)
	for i in 9:
		var x := int(RoomDecor.noise(Vector2i(i, 0), seed_value + 509) * (size - 2))
		var yy := int(RoomDecor.noise(Vector2i(i, 1), seed_value + 509) * (size - 2))
		image.set_pixel(x, yy + 1, dark)
		image.set_pixel(x, yy, light if i % 3 == 0 else dark)
		if i % 4 == 0:
			image.set_pixel(x + 1, yy + 1, dark)
	return ImageTexture.create_from_image(image)


# Paints the backdrop into an Image with the few CanvasItem calls draw_room uses, all at 1:1 scale.
class DepthPainter extends RefCounted:
	var image: Image
	var origin: Vector2
	var _images := {}

	func _init(area: Rect2i) -> void:
		origin = Vector2(area.position)
		image = Image.create(area.size.x, area.size.y, false, Image.FORMAT_RGBA8)

	func _source(texture: Texture2D) -> Image:
		if not _images.has(texture):
			var source := texture.get_image()
			# A headless run keeps no pixels for its textures; it shows nothing anyway.
			if source == null or source.is_empty():
				_images[texture] = null
				return null
			if source.is_compressed():
				source.decompress()
			source.convert(Image.FORMAT_RGBA8)
			_images[texture] = source
		return _images[texture]

	func draw_rect(rect: Rect2, color: Color, _filled := true, _width := -1.0) -> void:
		var r := Rect2i(Vector2i((rect.position - origin).round()), Vector2i(rect.size.round()))
		r = r.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		if r.size.x <= 0 or r.size.y <= 0:
			return
		if color.a >= 0.999:
			image.fill_rect(r, color)
			return
		var patch := Image.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
		patch.fill(color)
		image.blend_rect(patch, Rect2i(Vector2i.ZERO, r.size), r.position)

	func draw_texture(texture: Texture2D, at: Vector2, _modulate := Color.WHITE) -> void:
		var source := _source(texture)
		if source == null:
			return
		image.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i((at - origin).round()))

	func draw_texture_rect_region(texture: Texture2D, rect: Rect2, src: Rect2, _modulate := Color.WHITE) -> void:
		var source := _source(texture)
		if source == null:
			return
		image.blend_rect(source, Rect2i(Vector2i(src.position.round()), Vector2i(src.size.round())), Vector2i((rect.position - origin).round()))
