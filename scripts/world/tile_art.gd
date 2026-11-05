class_name TileArt
extends RefCounted

# A path's floor and wall pictures, from res://art/tiles/<set>/ (tools/art/env_art.py builds them):
#   floor_a_0.png, floor_a_1.png ...  the variants of the first floor tone (RoomPalette.floor_a)
#   floor_b_*.png, floor_c_*.png      the second and third tones
#   wall_*.png                        a wall cell
#   wall_face_*.png                   a wall cell with open floor below it (optional; wall_* stands in)
# Each cell keeps the tone of its 3x3 patch (RoomPalette.patch_of) and takes one of that tone's variants
# by noise, so the patches read as today's. A set missing a tone or its walls counts as missing, and
# RoomBackdrop draws the code patterns instead.
const DIR := "res://art/tiles/%s/"
const TONES := ["a", "b", "c"]
const MAX_VARIANTS := 8

static var _cache := {}

var floors: Array = [[], [], []]
var walls: Array[Texture2D] = []
var wall_faces: Array[Texture2D] = []


static func for_set(set_id: String) -> TileArt:
	if set_id.is_empty():
		return null
	if _cache.has(set_id):
		return _cache[set_id]
	var art := TileArt.new()
	var dir := DIR % set_id
	for tone in TONES.size():
		art.floors[tone] = _variants(dir + "floor_%s_" % TONES[tone])
	art.walls.assign(_variants(dir + "wall_"))
	art.wall_faces.assign(_variants(dir + "wall_face_"))
	var found: TileArt = art if art.is_complete() else null
	_cache[set_id] = found
	return found


static func _variants(prefix: String) -> Array[Texture2D]:
	var found: Array[Texture2D] = []
	for i in MAX_VARIANTS:
		var path := "%s%d.png" % [prefix, i]
		if not ResourceLoader.exists(path):
			break
		found.append(load(path))
	return found


func is_complete() -> bool:
	for tone in floors:
		if tone.is_empty():
			return false
	return not walls.is_empty()


static func pick(options: Array, cell: Vector2i, seed_value: int) -> Texture2D:
	var roll := RoomDecor.noise(cell, seed_value + 211)
	return options[mini(floori(roll * options.size()), options.size() - 1)]


func floor_tile(tone: int, cell: Vector2i, seed_value: int) -> Texture2D:
	return pick(floors[tone], cell, seed_value)


# faces_floor: open floor lies just south, so the wall shows its face there.
func wall_tile(cell: Vector2i, seed_value: int, faces_floor: bool) -> Texture2D:
	if faces_floor and not wall_faces.is_empty():
		return pick(wall_faces, cell, seed_value)
	return pick(walls, cell, seed_value)
