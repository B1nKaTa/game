class_name PropArt
extends RefCounted

# Props are drawn in code until art exists. A picture at res://art/props/<id>.png
# replaces the placeholder, the same way enemy art does.
static var _cache := {}


static func texture(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var path := "res://art/props/%s.png" % id
	var found: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[id] = found
	return found
