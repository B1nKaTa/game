class_name CinemaScreen
extends Node2D

# The screen on the north wall of a Flashback Cinema fighting room, playing one of CinemaScenes'
# flashbacks. Purely decorative: it adds no body, and it hangs on the wall the room's layout keeps for
# it, west of the north door's alcove, so it never covers a door. The projector's beam comes up to it
# from a port in the south wall (CinemaBeam), and a cool glow from the picture lights the front rows.
#
# The Projectionist drives it through cut_to_black, flash and set_burning, and reads is_dark.
const GROUP := "cinema_screens"
const SHADER := preload("res://scripts/world/cinema_screen.gdshader")
# The picture shows a scene frame at 1:1 inside a gold frame, with plain velvet drapes either side.
# A frame a little taller than the wall leaves room for keeps its width and loses a few rows top and
# bottom (at most MAX_CROP of its height); a wall much too small shrinks the picture instead.
const FRAME_WIDTH := 3.0
# The frame's picture (art/props/flashback_cinema/screen_trim.png): a 7x7 nine-slice, FRAME_WIDTH px
# corners round 1 px middles, which stretch along the picture's edges. Without it the frame is drawn.
const FRAME_ART := "screen_trim"
const MAX_CROP := 0.15
const DRAPE_GAP := 2.0
# On a wall one cell thick, as an old layout has, the picture shrinks to fit it.
const THIN_MARGIN := 3.0
const Z := -9
const GLOW_ENERGY := 0.5
const GLOW_SCALE := 1.1
# How quickly a cut fades the picture out and back in, and how long a flash takes to fade, in seconds.
const CUT_FADE := 0.12
const RETURN_FADE := 0.35
const FLASH_TIME := 0.35
const DARK_SHARE := 0.5

var scene_id := ""
var palette: RoomPalette
var _picture_rect := Rect2()
var _drapes_rect := Rect2()
var _texture: Texture2D
var _frames := CinemaScenes.FRAMES
var _picture: Node2D
var _material: ShaderMaterial
var _glow: PointLight2D
var _darkness := 0.0
var _dark_left := 0.0
var _flash := 0.0
var _burn := 0.0
var _seed := 0.0


# Where the screen hangs in a layout, in room pixels: the north wall from the west wall to just short
# of the north door's column, two cells deep when the layout's second row is wall all along it, as
# every Cinema fighting room's is, or one cell deep otherwise.
static func wall_rect(layout: RoomLayout) -> Rect2:
	var size := layout.size_in_cells()
	var door_x := layout.door_cell(RoomLayout.NORTH).x
	var depth := 2
	for x in range(1, door_x):
		if layout.symbol_at(Vector2i(x, 1)) != RoomLayout.SYMBOL_WALL:
			depth = 1
			break
	if size.y < 4:
		depth = 1
	var tile := float(RoomBackdrop.TILE)
	return Rect2(Vector2(tile, 0.0), Vector2((door_x - 1) * tile, depth * tile))


# The picture itself, centred on that wall: a frame at 1:1 when the wall is deep enough, at 1:1 across
# with a few rows trimmed when it is a little short (the Cinema's 64 px screen wall shows 58 of a
# frame's 64 rows), or shrunk to the wall, keeping its shape, when it is far too small.
static func picture_rect_for(wall: Rect2) -> Rect2:
	var frame := Vector2(CinemaScenes.FRAME_SIZE)
	var room := wall.size - Vector2(THIN_MARGIN, THIN_MARGIN) * 2.0
	var scale_factor := minf(1.0, room.x / frame.x)
	var size := frame * scale_factor
	if size.y > room.y:
		if size.y - room.y <= size.y * MAX_CROP:
			size.y = room.y
		else:
			size = frame * minf(scale_factor, room.y / frame.y)
	size = size.floor()
	return Rect2((wall.get_center() - size / 2.0).round(), size)


# Which rows of a frame a picture of this size shows: the middle ones, as (first row, row count).
static func shown_rows(picture: Vector2) -> Vector2:
	var frame := Vector2(CinemaScenes.FRAME_SIZE)
	var scale_factor := picture.x / frame.x if picture.x > 0.0 else 1.0
	var rows := minf(frame.y, picture.y / scale_factor)
	return Vector2((frame.y - rows) / 2.0, rows)


static func in_room(room: Node) -> CinemaScreen:
	for child in room.get_children():
		if child is CinemaScreen and not child.is_queued_for_deletion():
			return child
	return null


func setup(layout: RoomLayout, id: String, room_seed: int) -> void:
	scene_id = id
	_drapes_rect = wall_rect(layout)
	_picture_rect = picture_rect_for(_drapes_rect)
	_seed = float(posmod(room_seed, 97))


func _ready() -> void:
	add_to_group(GROUP)
	z_index = Z
	if palette == null:
		palette = RoomPalette.new()
	_texture = _load_scene(scene_id)
	_frames = clampi(int(_texture.get_width() / CinemaScenes.FRAME_SIZE.x), 1, CinemaScenes.MAX_FRAMES)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("frames", _frames)
	_material.set_shader_parameter("seed", _seed)
	_material.set_shader_parameter("picture_size", _picture_rect.size)
	_picture = Node2D.new()
	_picture.material = _material
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picture.draw.connect(_draw_picture)
	add_child(_picture)
	_glow = Lighting.make_light(palette.screen_glow, GLOW_ENERGY, GLOW_SCALE)
	_glow.position = Vector2(_picture_rect.get_center().x, _picture_rect.end.y + RoomBackdrop.TILE * 0.5)
	add_child(_glow)
	queue_redraw()


static func _load_scene(id: String) -> Texture2D:
	var path := CinemaScenes.art_path(id)
	if ResourceLoader.exists(path):
		var art: Texture2D = load(path)
		if art != null:
			return art
	return ImageTexture.create_from_image(CinemaScenes.placeholder_image(id))


func _process(delta: float) -> void:
	var dark_target := 1.0 if _dark_left > 0.0 else 0.0
	_dark_left = maxf(_dark_left - delta, 0.0)
	var fade_time := CUT_FADE if dark_target > _darkness else RETURN_FADE
	_darkness = move_toward(_darkness, dark_target, delta / fade_time)
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	_material.set_shader_parameter("darkness", _darkness)
	_material.set_shader_parameter("flash", _flash)
	_material.set_shader_parameter("burn", _burn)
	_glow.energy = GLOW_ENERGY * (1.0 - _darkness) + _flash * 0.6


# --- what the Projectionist drives ---

# The picture cuts to black for this long, then comes back.
func cut_to_black(seconds: float) -> void:
	_dark_left = maxf(_dark_left, seconds)


# A white flash over the picture that fades in FLASH_TIME, as a reel change's warning.
func flash(strength := 1.0) -> void:
	_flash = maxf(_flash, clampf(strength, 0.0, 1.0))


# The film catching fire: 0 is a whole picture, 1 a picture burnt through from the middle out.
func set_burning(progress: float) -> void:
	_burn = clampf(progress, 0.0, 1.0)


func burning() -> float:
	return _burn


# Whether the picture is black, or nearly, so the house is dark.
func is_dark() -> bool:
	return _darkness >= DARK_SHARE or _dark_left > 0.0


# The picture on the wall in global space, for anything that grows out of the screen.
func picture_rect() -> Rect2:
	return Rect2(to_global(_picture_rect.position), _picture_rect.size)


func darkness() -> float:
	return _darkness


# --- drawing ---

func _draw_picture() -> void:
	# The whole strip across (the shader picks the frame), the middle rows down.
	var rows := shown_rows(_picture_rect.size)
	var scale_y := float(_texture.get_height()) / CinemaScenes.FRAME_SIZE.y
	var source := Rect2(0.0, rows.x * scale_y, _texture.get_width(), rows.y * scale_y)
	_picture.draw_texture_rect_region(_texture, _picture_rect, source)


func _draw() -> void:
	var p := palette
	# Velvet drapes across the wall, gathered at the picture's sides, and the gold frame round it.
	var drape := _drapes_rect.grow_individual(-2.0, -1.0, -2.0, -1.0)
	draw_rect(drape, p.seat_velvet_dark)
	for fold in int(drape.size.x / 6.0):
		var x := drape.position.x + 3.0 + fold * 6.0
		if x > _picture_rect.position.x - FRAME_WIDTH - DRAPE_GAP and x < _picture_rect.end.x + FRAME_WIDTH + DRAPE_GAP:
			continue
		draw_line(Vector2(x, drape.position.y + 1.0), Vector2(x, drape.end.y - 1.0), p.seat_velvet.darkened(0.25), 1.0)
	draw_rect(Rect2(drape.position, Vector2(drape.size.x, 3.0)), p.deco_gold_dim)
	var frame := _picture_rect.grow(FRAME_WIDTH)
	var trim := PropArt.texture(FRAME_ART)
	if trim != null:
		draw_rect(_picture_rect, Color.BLACK)
		_draw_trim(trim, frame)
		return
	draw_rect(frame, p.deco_gold)
	draw_rect(frame, Color.BLACK, false, 1.0)
	draw_rect(_picture_rect.grow(1.0), Color.BLACK)


# The frame as a nine-slice round `frame`: the corners at 1:1, the 1 px middles stretched along each
# edge, so it fits a picture of any size on whole pixels.
func _draw_trim(trim: Texture2D, frame: Rect2) -> void:
	var b := FRAME_WIDTH
	var side := trim.get_width() - b
	var inner := frame.grow(-b)
	var xs := [frame.position.x, inner.position.x, inner.end.x]
	var ys := [frame.position.y, inner.position.y, inner.end.y]
	var widths := [b, inner.size.x, b]
	var heights := [b, inner.size.y, b]
	var sources := [0.0, b, side]
	var spans := [b, 1.0, b]
	for row in 3:
		for column in 3:
			if row == 1 and column == 1:
				continue
			var to := Rect2(xs[column], ys[row], widths[column], heights[row])
			var from := Rect2(sources[column], sources[row], spans[column], spans[row])
			draw_texture_rect_region(trim, to, from)
