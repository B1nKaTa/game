class_name SideBars
extends RefCounted

# On a screen wider (or taller) than 16:9 the game picture keeps its shape and the window shows bars
# beside it. Instead of plain black, the bars take a dark frame in the current area's wall tone: a
# near-black fill that lightens a little toward the picture, with a thin wall-coloured edge beside it.
# RoomView sets them whenever a room is built; nothing else needs to know.

const HEIGHT := 64
const WIDTH := 32

static var _key := ""
static var _left: ImageTexture
static var _right: ImageTexture


static func show_for(palette: RoomPalette) -> void:
	if palette == null or DisplayServer.get_name() == "headless":
		return
	var key := palette.wall.to_html() + palette.darkness.to_html()
	if key == _key:
		return
	_key = key
	_left = ImageTexture.create_from_image(frame_image(palette.darkness, palette.wall, true))
	_right = ImageTexture.create_from_image(frame_image(palette.darkness, palette.wall, false))
	RenderingServer.black_bars_set_images(_left.get_rid(), RID(), _right.get_rid(), RID())


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
