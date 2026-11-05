class_name RoomDecor
extends RefCounted

# Decor blocks nothing. A layout places some by symbol, and the rest is a light scatter
# chosen from the room's own seed, so the same layout looks different in another room.
const GRASS := "grass"
const BONES := "bones"
const COBWEB := "cobweb"
const PUDDLE := "puddle"
const CRACK := "crack"
const TORCH := "torch"
const LANTERN := "lantern"
const STUMP := "stump"
const MOSS := "moss"
const SAPLING := "sapling"
const PLANT := "plant"
const IV_STAND := "iv_stand"
const GAUGE := "gauge"
const PIPE := "pipe"
const COAL_DUST := "coal_dust"
# A furnace mouth set in the wall, like a lantern, glowing orange.
const FURNACE := "furnace"
# A pool of coloured light on the floor, from a stained-glass window.
const STAINED_GLASS := "stained_glass"
# A coffin resting on a draped stand, against the panelling or out on the floor.
const COFFIN_STAND := "coffin_stand"
# A mall bench, a food court table with its chairs, and a fluorescent panel's pale pool of light.
const BENCH := "bench"
const FOOD_TABLE := "food_table"
const FLUORESCENT := "fluorescent"
# Head Office: a potted ficus in a corner of the carpet, and a swivel chair pushed away from a desk.
const FICUS := "ficus"
const OFFICE_CHAIR := "office_chair"
# Departures, Terminal Zero: a departures board on its stand, with rows of amber flight times.
const DEPARTURE_BOARD := "departure_board"
# Fairway's End at Midnight: a wisp of thin ground fog lying flat on the grass.
const FOG := "fog"
const SYMBOL_KINDS := {
	RoomLayout.SYMBOL_GRASS: GRASS,
	RoomLayout.SYMBOL_BONES: BONES,
	RoomLayout.SYMBOL_COBWEB: COBWEB,
	RoomLayout.SYMBOL_PUDDLE: PUDDLE,
	RoomLayout.SYMBOL_CRACK: CRACK,
	RoomLayout.SYMBOL_TORCH: TORCH,
	RoomLayout.SYMBOL_LANTERN: LANTERN,
	RoomLayout.SYMBOL_STUMP: STUMP,
}
# The scatter keeps this far from every door cell, so doors stay easy to see.
const DOOR_CLEARANCE := 1
const MAX_OFFSET := 6.0
const VARIANTS := 4
const NO_CELL := Vector2i(-1, -1)


static func noise(cell: Vector2i, seed_value: int) -> float:
	var n := cell.x * 374761393 + cell.y * 668265263 + seed_value * 1274126177
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0


static func is_light(kind: String) -> bool:
	return kind == TORCH or kind == LANTERN or kind == FURNACE or kind == STAINED_GLASS or kind == FLUORESCENT


# Every piece of decor in a room: {kind, cell, variant, offset}. Lanterns sit on wall cells.
static func plan(layout: RoomLayout, palette: RoomPalette, seed_value: int) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var used := {}
	var size := layout.size_in_cells()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in size.y:
		for x in size.x:
			var kind: String = SYMBOL_KINDS.get(layout.rows[y][x], "")
			if kind.is_empty():
				continue
			var cell := Vector2i(x, y)
			used[cell] = true
			items.append(_item(kind, cell, rng, false))
	var free_cells: Array[Vector2i] = []
	for y in range(1, size.y - 1):
		for x in range(1, size.x - 1):
			var cell := Vector2i(x, y)
			if layout.symbol_at(cell) == RoomLayout.SYMBOL_FLOOR and not _near_a_door(layout, cell):
				free_cells.append(cell)
	var wanted := roundi(free_cells.size() * palette.decor_density)
	var lights := 0
	var tries := 0
	while wanted > 0 and tries < wanted * 8 + 20:
		tries += 1
		var kind := _pick_kind(palette, rng, lights >= palette.scatter_lights)
		if kind.is_empty():
			break
		var cell := _pick_cell(layout, kind, free_cells, used, rng)
		if cell == NO_CELL:
			continue
		used[cell] = true
		items.append(_item(kind, cell, rng, kind != LANTERN and kind != FURNACE))
		wanted -= 1
		if is_light(kind):
			lights += 1
	return items


static func _item(kind: String, cell: Vector2i, rng: RandomNumberGenerator, jitter: bool) -> Dictionary:
	var offset := Vector2.ZERO
	if jitter and kind != TORCH and kind != COBWEB:
		offset = Vector2(rng.randf_range(-MAX_OFFSET, MAX_OFFSET), rng.randf_range(-MAX_OFFSET, MAX_OFFSET))
	return {"kind": kind, "cell": cell, "variant": rng.randi() % VARIANTS, "offset": offset}


static func _pick_kind(palette: RoomPalette, rng: RandomNumberGenerator, no_more_lights: bool) -> String:
	var kinds: Array[String] = []
	var total := 0.0
	for kind: String in palette.decor_weights:
		var weight := palette.weight_of(kind)
		if weight <= 0.0 or (no_more_lights and is_light(kind)):
			continue
		kinds.append(kind)
		total += weight
	if kinds.is_empty():
		return ""
	var roll := rng.randf() * total
	for kind in kinds:
		roll -= palette.weight_of(kind)
		if roll <= 0.0:
			return kind
	return kinds[-1]


# A cell for the kind, or NO_CELL when it finds none this time.
static func _pick_cell(layout: RoomLayout, kind: String, free_cells: Array[Vector2i], used: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	if kind == LANTERN or kind == FURNACE:
		return _pick_lantern_cell(layout, used, rng)
	if free_cells.is_empty():
		return NO_CELL
	var cell := free_cells[rng.randi_range(0, free_cells.size() - 1)]
	if used.has(cell):
		return NO_CELL
	if kind == COBWEB and not _in_a_corner(layout, cell):
		return NO_CELL
	return cell


# A lantern hangs in the wall of the room, never past a door or where the crack for a secret room goes.
static func _pick_lantern_cell(layout: RoomLayout, used: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var size := layout.size_in_cells()
	var cell := NO_CELL
	match rng.randi() % 4:
		0:
			cell = Vector2i(rng.randi_range(1, size.x - 2), 0)
		1:
			cell = Vector2i(rng.randi_range(1, size.x - 2), size.y - 1)
		2:
			cell = Vector2i(0, rng.randi_range(1, size.y - 2))
		_:
			cell = Vector2i(size.x - 1, rng.randi_range(1, size.y - 2))
	if used.has(cell) or layout.symbol_at(cell) != RoomLayout.SYMBOL_WALL:
		return NO_CELL
	for side in RoomLayout.SIDES:
		var door := layout.door_cell(side)
		if absi(cell.x - door.x) <= DOOR_CLEARANCE + 1 and absi(cell.y - door.y) <= DOOR_CLEARANCE + 1:
			return NO_CELL
	return cell


static func _near_a_door(layout: RoomLayout, cell: Vector2i) -> bool:
	for side in RoomLayout.SIDES:
		var door := layout.door_cell(side)
		if absi(cell.x - door.x) <= DOOR_CLEARANCE and absi(cell.y - door.y) <= DOOR_CLEARANCE:
			return true
	return false


static func _in_a_corner(layout: RoomLayout, cell: Vector2i) -> bool:
	var vertical := layout.is_solid_at(cell + Vector2i.UP) or layout.is_solid_at(cell + Vector2i.DOWN)
	var horizontal := layout.is_solid_at(cell + Vector2i.LEFT) or layout.is_solid_at(cell + Vector2i.RIGHT)
	return vertical and horizontal
