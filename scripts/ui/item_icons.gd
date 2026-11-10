class_name ItemIcons
extends RefCounted

# Item icons: 32 px PNGs at DIR/<id>.png, made apart from the code. Every place that shows an item (room
# pickups, shop wares, the HUD's item row and active slot, the case file) asks here and keeps its old look
# while there is no PNG.

const DIR := "res://art/icons/items/"

static var _test := {}
static var _cache := {}


static func path(id: String) -> String:
	return DIR + id + ".png"


static func texture(id: String) -> Texture2D:
	if id.is_empty():
		return null
	if _test.has(id):
		return _test[id]
	if _cache.has(id):
		return _cache[id]
	var found: Texture2D = null
	if ResourceLoader.exists(path(id)):
		found = load(path(id)) as Texture2D
	_cache[id] = found
	return found


static func set_for_test(id: String, icon: Texture2D) -> void:
	_test[id] = icon


static func clear_test() -> void:
	_test.clear()
	_cache.clear()
