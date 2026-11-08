class_name SideBars
extends RefCounted

# On a screen wider (or taller) than 16:9 the game picture keeps its shape and the window shows bars
# beside it. Instead of plain black, the bars take a dark frame in the current area's wall tone: a
# near-black fill that lightens a little toward the picture, with a thin wall-coloured edge beside it.
# RoomView sets them whenever a room is built; nothing else needs to know.
#
# Godot 4 has no call that paints the bars (Godot 3's black_bars_set_images is gone), and they stay
# black whatever the clear colour. So one extra viewport the size of the window paints the frame and
# the game's own picture where Godot would put it, and it is the only thing shown on the window: the
# game's viewport still renders but is taken off the screen, since two viewports shown on one window
# halve the frame rate. Mouse and input mapping stay Godot's own.

const HEIGHT := 64
const WIDTH := 32

static var _key := ""
static var _left: ImageTexture
static var _right: ImageTexture
static var _watch: BarWatch
# Off, the bars stay Godot's plain black (used to measure what the frame costs).
static var enabled := true


static func show_for(palette: RoomPalette) -> void:
	if palette == null or DisplayServer.get_name() == "headless":
		return
	var key := palette.wall.to_html() + palette.darkness.to_html()
	if key == _key:
		return
	_key = key
	var left := frame_image(palette.darkness, palette.wall, true)
	var right := frame_image(palette.darkness, palette.wall, false)
	# Updated in place, so a texture the frame is drawing is never freed under it.
	if _left == null:
		_left = ImageTexture.create_from_image(left)
		_right = ImageTexture.create_from_image(right)
	else:
		_left.update(left)
		_right.update(right)
	if _watch == null or not is_instance_valid(_watch):
		_watch = BarWatch.new()
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_watch)
	_watch.fill = palette.darkness.darkened(0.4)
	_watch.edge = palette.wall.darkened(0.2)
	_watch.repaint()


# Back to plain black bars, as on the title screen once a run is left. Before any room has set a frame
# the bars are Godot's own black already.
static func reset() -> void:
	if _left == null:
		return
	_key = ""
	var black := frame_image(Color.BLACK, Color.BLACK, true)
	_left.update(black)
	_right.update(black)
	if _watch != null and is_instance_valid(_watch):
		_watch.fill = Color.BLACK
		_watch.edge = Color.BLACK
		_watch.repaint()


# The left bar's edge is on its right side, next to the picture; the right bar's on its left.
static func frame_image(darkness: Color, wall: Color, edge_on_right: bool) -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	var deep := darkness.darkened(0.4)
	var near := darkness.lerp(wall, 0.35)
	for x in WIDTH:
		var toward := float(x) / (WIDTH - 1) if edge_on_right else 1.0 - float(x) / (WIDTH - 1)
		var tone := deep.lerp(near, toward * toward)
		var edge := x == WIDTH - 1 if edge_on_right else x == 0
		var colour := wall.darkened(0.2) if edge else tone
		for y in HEIGHT:
			image.set_pixel(x, y, colour)
	return image


# Where Godot puts the picture in a window of this size (Window._update_viewport_size, aspect "keep"):
# the view scaled to fit, by whole numbers when the stretch is integer and never below 1x, centred.
static func picture_rect(window: Vector2i, view: Vector2i, integer: bool) -> Rect2i:
	var aspect := float(view.x) / view.y
	var shown := Vector2(window)
	if aspect < float(window.x) / window.y:
		shown = Vector2(window.y * aspect, window.y)
	elif aspect > float(window.x) / window.y:
		shown = Vector2(window.x, window.x / aspect)
	var size := Vector2i(shown.floor())
	if integer:
		size = view * maxi(1, mini(size.x / view.x, size.y / view.y))
	var margin := Vector2i.ZERO
	if size.x < window.x:
		margin.x = roundi((window.x - size.x) / 2.0)
	if size.y < window.y:
		margin.y = roundi((window.y - size.y) / 2.0)
	return Rect2i(margin, size)


static func view_size() -> Vector2i:
	return Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))


# Shows the frame only while the window has bars, that is while the picture is smaller than the window.
# Then it keeps the frame viewport the size of the window and the game's viewport off the screen (Godot
# puts it back whenever the window changes, so it is taken off again every frame). With no bars the
# screen is Godot's own: the frame viewport is switched off and this only compares the window's size
# each frame, since no signal tells a viewport-stretched root that its window was resized.
class BarWatch extends Node:
	var fill := Color.BLACK
	var edge := Color.BLACK
	var _viewport: RID
	var _canvas: RID
	var _item: RID
	var _window := Vector2i.ZERO
	var _integer := true
	var _picture := Rect2i()
	var _shown := false
	var _enabled := true

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_viewport = RenderingServer.viewport_create()
		_canvas = RenderingServer.canvas_create()
		RenderingServer.viewport_attach_canvas(_viewport, _canvas)
		_item = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(_item, _canvas)
		RenderingServer.canvas_item_set_default_texture_filter(_item, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
		RenderingServer.viewport_set_update_mode(_viewport, RenderingServer.VIEWPORT_UPDATE_ALWAYS)
		RenderingServer.viewport_set_active(_viewport, false)

	func repaint() -> void:
		_window = Vector2i.ZERO

	func shown() -> bool:
		return _shown

	func _process(_delta: float) -> void:
		var window := DisplayServer.window_get_size()
		# A minimised window has no size; everything stays as it was until it comes back.
		if window.x <= 0 or window.y <= 0:
			return
		var root := get_tree().root
		var integer := root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER
		if window == _window and integer == _integer and SideBars.enabled == _enabled:
			if _shown:
				RenderingServer.viewport_attach_to_screen(root.get_viewport_rid(), Rect2(), DisplayServer.INVALID_WINDOW_ID)
			return
		_window = window
		_integer = integer
		_enabled = SideBars.enabled
		_picture = SideBars.picture_rect(window, SideBars.view_size(), integer)
		var bars := window.x > 0 and window.y > 0 and (_picture.size.x < window.x or _picture.size.y < window.y)
		if bars and SideBars.enabled:
			_show(root)
		elif _shown:
			_hand_back(root)

	func _show(root: Window) -> void:
		RenderingServer.viewport_set_size(_viewport, _window.x, _window.y)
		RenderingServer.canvas_item_clear(_item)
		RenderingServer.canvas_item_add_rect(_item, Rect2(Vector2(), Vector2(_window)), fill)
		var left := _picture.position.x
		var right := _picture.position.x + _picture.size.x
		if left > 0:
			# The edge beside the picture is one game pixel wide at the picture's scale.
			var line := maxi(1, _picture.size.x / SideBars.view_size().x)
			# The gradients leave out their own edge column, which would stretch as wide as a tenth of the bar.
			RenderingServer.canvas_item_add_texture_rect_region(_item, Rect2(0, 0, left, _window.y), SideBars._left.get_rid(), Rect2(0, 0, SideBars.WIDTH - 1, SideBars.HEIGHT))
			RenderingServer.canvas_item_add_texture_rect_region(_item, Rect2(right, 0, _window.x - right, _window.y), SideBars._right.get_rid(), Rect2(1, 0, SideBars.WIDTH - 1, SideBars.HEIGHT))
			RenderingServer.canvas_item_add_rect(_item, Rect2(left - line, 0, line, _window.y), edge)
			RenderingServer.canvas_item_add_rect(_item, Rect2(right, 0, line, _window.y), edge)
		RenderingServer.canvas_item_add_texture_rect(_item, Rect2(_picture), root.get_texture().get_rid())
		# Already on while shown: a repaint or a new size only redraws it.
		if not _shown:
			RenderingServer.viewport_set_active(_viewport, true)
		RenderingServer.viewport_attach_to_screen(_viewport, Rect2(Vector2(), Vector2(_window)), DisplayServer.MAIN_WINDOW_ID)
		RenderingServer.viewport_attach_to_screen(root.get_viewport_rid(), Rect2(), DisplayServer.INVALID_WINDOW_ID)
		_shown = true

	# Switches the frame off and gives the screen back to the game's own viewport, where Godot puts it.
	func _hand_back(root: Window) -> void:
		RenderingServer.viewport_attach_to_screen(_viewport, Rect2(), DisplayServer.INVALID_WINDOW_ID)
		RenderingServer.viewport_set_active(_viewport, false)
		RenderingServer.viewport_attach_to_screen(root.get_viewport_rid(), Rect2(_picture), DisplayServer.MAIN_WINDOW_ID)
		_shown = false

	func _exit_tree() -> void:
		var root := get_tree().root
		if _shown:
			_hand_back(root)
		for rid: RID in [_item, _canvas, _viewport]:
			RenderingServer.free_rid(rid)
		_viewport = RID()
