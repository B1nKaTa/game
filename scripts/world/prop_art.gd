class_name PropArt
extends RefCounted

# Props are drawn in code until art exists. A picture at res://art/props/<id>.png replaces the
# placeholder, the same way enemy art does. A path can have its own: res://art/props/<art_set>/<id>.png
# wins over the shared one while that path's rooms are built (RoomView sets art_set from FloorDef.art()).
#
# States. A prop that changes (a chest opened, grass cut, a door locked) asks for <id>_<state>.png. A
# state with no picture draws that state's placeholder, so a half-drawn set never shows a wrong state.
#
# Every picture is drawn at its own size on whole pixels, centred on the prop unless the caller says
# where its bottom goes.
const DIR := "res://art/props/"

static var art_set := ""
static var _cache := {}


static func texture(id: String) -> Texture2D:
	var key := art_set + "/" + id
	if _cache.has(key):
		return _cache[key]
	var found: Texture2D = null
	if not art_set.is_empty():
		found = _load(DIR + art_set + "/" + id + ".png")
	if found == null:
		found = _load(DIR + id + ".png")
	_cache[key] = found
	return found


static func state_texture(id: String, state: String) -> Texture2D:
	return texture(id if state.is_empty() else id + "_" + state)


static func _load(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


# Where a picture's top-left goes to centre it on `at`, on a whole pixel so it never blurs or shimmers.
static func centred(art: Texture2D, at := Vector2.ZERO) -> Vector2:
	return (at - art.get_size() / 2.0).floor()


# Where a picture's top-left goes to stand its bottom row on `feet`, centred across.
static func standing(art: Texture2D, feet: Vector2) -> Vector2:
	return Vector2(floorf(feet.x - art.get_width() / 2.0), feet.y - art.get_height())


static func draw(canvas: CanvasItem, art: Texture2D, at := Vector2.ZERO, tint := Color.WHITE) -> void:
	canvas.draw_texture(art, centred(art, at), tint)


# A strip of square frames side by side (a flicker, or a spinning thing's pre-drawn turns): how many
# frames it holds, and one of them drawn centred on `at` on a whole pixel. The index wraps.
static func frame_count(art: Texture2D) -> int:
	return maxi(art.get_width() / maxi(art.get_height(), 1), 1)


static func draw_frame(canvas: CanvasItem, art: Texture2D, index: int, at := Vector2.ZERO, tint := Color.WHITE) -> void:
	var side := float(art.get_height())
	var frame := posmod(index, frame_count(art))
	var corner := (at - Vector2(side, side) / 2.0).floor()
	canvas.draw_texture_rect_region(art, Rect2(corner, Vector2(side, side)), Rect2(frame * side, 0.0, side, side), tint)


# Which of `frames` pre-drawn turns, spread evenly over `span` radians (a quarter turn for a plate, a
# half for a sheet), shows a thing turned by `angle`.
static func turn_frame(angle: float, frames: int, span: float) -> int:
	return int(floorf(fposmod(angle, span) / span * frames + 0.5)) % frames


static func clear_cache() -> void:
	_cache.clear()
