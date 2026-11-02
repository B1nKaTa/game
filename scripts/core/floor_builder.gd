class_name FloorBuilder
extends RefCounted

# A random walk can box itself in, so a failed attempt simply tries again from the same generator.
const MAX_ATTEMPTS := 50


static func build(rng: RandomNumberGenerator, def: FloorDef) -> FloorMap:
	return build_from_pool(rng, def, RoomCatalog.load_valid(def.rooms_dir))


static func build_from_pool(rng: RandomNumberGenerator, def: FloorDef, pool: Array[RoomLayout]) -> FloorMap:
	var by_type := {}
	for layout in pool:
		if not by_type.has(layout.room_type):
			by_type[layout.room_type] = []
		by_type[layout.room_type].append(layout)
	for room_type: String in _types_a_floor_cannot_lack(def):
		if not by_type.has(room_type):
			push_error("No valid layouts for room type: %s" % room_type)
			return null
	for attempt in MAX_ATTEMPTS:
		var map := _try_build(rng, def, _LayoutPicker.new(by_type, rng))
		if map != null:
			return map
	push_error("Could not fit floor '%s' on its %s grid" % [def.id, str(def.grid_size)])
	return null


static func _types_a_floor_cannot_lack(def: FloorDef) -> Array[String]:
	var types: Array[String] = [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_FLOOR_BOSS]
	if def.item_rooms > 0:
		types.append(RoomLayout.TYPE_ITEM)
	if def.healing_rooms > 0:
		types.append(RoomLayout.TYPE_HEALING)
	return types


static func _try_build(rng: RandomNumberGenerator, def: FloorDef, picker: _LayoutPicker) -> FloorMap:
	var path_cells := _walk_main_path(rng, def)
	if path_cells.is_empty():
		return null
	var path_types := _main_path_types(def)
	var branch_types := _branch_types(rng, def)
	_maybe_move_a_reward_onto_the_path(rng, def, path_types, branch_types)
	var map := FloorMap.new()
	for i in path_cells.size():
		var room := _add_room(map, path_types[i], path_cells[i], picker)
		map.main_path.append(room.id)
		if i > 0:
			map.join(map.room(map.main_path[i - 1]), room)
	map.start_id = map.main_path[0]
	map.boss_id = map.main_path[-1]
	for room_type in branch_types:
		if _attach(rng, map, _regular_rooms_except(map, [map.boss_id]), room_type, picker, def) == null:
			return null
	if not _attach_detours(rng, map, def, picker):
		return null
	return map


# Never touches itself, so the main path reads as a line on the map and leaves room for branches.
static func _walk_main_path(rng: RandomNumberGenerator, def: FloorDef) -> Array[Vector2i]:
	var at := Vector2i(rng.randi_range(0, def.grid_size.x - 1), rng.randi_range(0, def.grid_size.y - 1))
	var cells: Array[Vector2i] = [at]
	while cells.size() < def.main_path_rooms:
		var options: Array[Vector2i] = []
		for side in RoomLayout.SIDES:
			var next: Vector2i = at + side
			if _on_grid(def, next) and _touches_only(cells, next, at):
				options.append(next)
		if options.is_empty():
			return []
		at = options[rng.randi_range(0, options.size() - 1)]
		cells.append(at)
	return cells


static func _touches_only(cells: Array[Vector2i], next: Vector2i, allowed: Vector2i) -> bool:
	for cell in cells:
		if cell != allowed and absi(cell.x - next.x) + absi(cell.y - next.y) <= 1:
			return false
	return true


static func _on_grid(def: FloorDef, cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, def.grid_size).has_point(cell)


static func _main_path_types(def: FloorDef) -> Array[String]:
	var types: Array[String] = []
	for i in def.main_path_rooms:
		types.append(RoomLayout.TYPE_COMBAT)
	types[def.main_path_rooms / 2] = RoomLayout.TYPE_MINI_BOSS
	types[-1] = RoomLayout.TYPE_FLOOR_BOSS
	return types


static func _branch_types(rng: RandomNumberGenerator, def: FloorDef) -> Array[String]:
	var count := rng.randi_range(def.min_rooms, def.max_rooms) - def.main_path_rooms
	var types: Array[String] = []
	for i in def.item_rooms:
		types.append(RoomLayout.TYPE_ITEM)
	for i in def.healing_rooms:
		types.append(RoomLayout.TYPE_HEALING)
	while types.size() < count:
		types.append(RoomLayout.TYPE_COMBAT)
	# Array.shuffle would use the global generator and break "same seed, same floor".
	for i in range(types.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swapped := types[i]
		types[i] = types[j]
		types[j] = swapped
	return types


# Rewards belong on branches, but finding one on the way now and then keeps the path from feeling bare.
static func _maybe_move_a_reward_onto_the_path(rng: RandomNumberGenerator, def: FloorDef, path_types: Array[String], branch_types: Array[String]) -> void:
	if rng.randf() >= def.path_reward_chance:
		return
	var path_spots: Array[int] = []
	for i in range(1, path_types.size()):
		if path_types[i] == RoomLayout.TYPE_COMBAT:
			path_spots.append(i)
	var reward_spots: Array[int] = []
	for i in branch_types.size():
		if branch_types[i] != RoomLayout.TYPE_COMBAT:
			reward_spots.append(i)
	if path_spots.is_empty() or reward_spots.is_empty():
		return
	var on_path := path_spots[rng.randi_range(0, path_spots.size() - 1)]
	var on_branch := reward_spots[rng.randi_range(0, reward_spots.size() - 1)]
	path_types[on_path] = branch_types[on_branch]
	branch_types[on_branch] = RoomLayout.TYPE_COMBAT


static func _attach_detours(rng: RandomNumberGenerator, map: FloorMap, def: FloorDef, picker: _LayoutPicker) -> bool:
	var regular := _regular_rooms_except(map, [map.boss_id])
	var middle := _regular_rooms_except(map, [map.start_id, map.boss_id])
	for room_type: String in [RoomLayout.TYPE_TREASURE, RoomLayout.TYPE_SHOP]:
		if picker.has(room_type) and _attach(rng, map, middle, room_type, picker, def) == null:
			return false
	var combat: Array[FloorRoom] = []
	for room in regular:
		if room.room_type == RoomLayout.TYPE_COMBAT:
			combat.append(room)
	if picker.has(RoomLayout.TYPE_SIDE):
		for room in combat:
			if rng.randf() < def.side_room_chance:
				var one_parent: Array[FloorRoom] = [room]
				_attach(rng, map, one_parent, RoomLayout.TYPE_SIDE, picker, def)
	if picker.has(RoomLayout.TYPE_SECRET):
		_attach(rng, map, combat, RoomLayout.TYPE_SECRET, picker, def)
	return true


static func _regular_rooms_except(map: FloorMap, excluded: Array[int]) -> Array[FloorRoom]:
	var list: Array[FloorRoom] = []
	for room in map.main_rooms():
		if not excluded.has(room.id):
			list.append(room)
	return list


# Adds a room at a random free cell beside one of the parents, or returns null if none has one.
static func _attach(rng: RandomNumberGenerator, map: FloorMap, parents: Array[FloorRoom], room_type: String, picker: _LayoutPicker, def: FloorDef) -> FloorRoom:
	var spots: Array[Dictionary] = []
	for parent in parents:
		for side in RoomLayout.SIDES:
			var cell: Vector2i = parent.cell + side
			if _on_grid(def, cell) and map.room_at(cell) == null:
				spots.append({"parent": parent, "cell": cell})
	if spots.is_empty():
		return null
	var spot: Dictionary = spots[rng.randi_range(0, spots.size() - 1)]
	var room := _add_room(map, room_type, spot["cell"], picker)
	map.join(spot["parent"], room)
	return room


static func _add_room(map: FloorMap, room_type: String, cell: Vector2i, picker: _LayoutPicker) -> FloorRoom:
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.room_type = room_type
	room.cell = cell
	room.layout = picker.pick(room_type)
	map.rooms.append(room)
	return room


class _LayoutPicker:
	var _by_type: Dictionary
	var _rng: RandomNumberGenerator
	var _remaining := {}

	func _init(by_type: Dictionary, rng: RandomNumberGenerator) -> void:
		_by_type = by_type
		_rng = rng

	func has(room_type: String) -> bool:
		return _by_type.has(room_type)

	func pick(room_type: String) -> RoomLayout:
		if not _by_type.has(room_type):
			return null
		if _remaining.get(room_type, []).is_empty():
			_remaining[room_type] = _by_type[room_type].duplicate()
		var options: Array = _remaining[room_type]
		var index := _rng.randi_range(0, options.size() - 1)
		var layout: RoomLayout = options[index]
		options.remove_at(index)
		return layout
