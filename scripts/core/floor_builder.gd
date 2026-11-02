class_name FloorBuilder
extends RefCounted

const SIDE_CHANCE := 0.3
const SECOND_ROOM_TYPES := [
	RoomLayout.TYPE_ITEM,
	RoomLayout.TYPE_ITEM,
	RoomLayout.TYPE_HEALING,
	RoomLayout.TYPE_COMBAT,
]


static func build(rng: RandomNumberGenerator, pool: Array[RoomLayout]) -> FloorMap:
	var by_type := {}
	for layout in pool:
		if not by_type.has(layout.room_type):
			by_type[layout.room_type] = []
		by_type[layout.room_type].append(layout)
	var picker := _LayoutPicker.new(by_type, rng)
	var map := FloorMap.new()
	var layers := _plan_layers(rng)
	var previous: Array[FloorRoom] = []
	for layer_index in layers.size():
		var current: Array[FloorRoom] = []
		for room_type: String in layers[layer_index]:
			var layout := picker.pick(room_type)
			if layout == null:
				push_error("No valid layouts for room type: %s" % room_type)
				return null
			current.append(_add_room(map, layer_index, room_type, layout))
		_connect(previous, current, rng)
		previous = current
	map.start_id = 0
	map.boss_id = previous[0].id
	_attach_side_rooms(map, picker, rng)
	return map


static func _plan_layers(rng: RandomNumberGenerator) -> Array:
	var combat := RoomLayout.TYPE_COMBAT
	var first_item := [combat, RoomLayout.TYPE_ITEM]
	return [
		[combat],
		first_item,
		_open_layer(rng),
		[RoomLayout.TYPE_MINI_BOSS],
		[combat, SECOND_ROOM_TYPES[rng.randi_range(0, SECOND_ROOM_TYPES.size() - 1)]],
		_open_layer(rng),
		[RoomLayout.TYPE_HEALING],
		[RoomLayout.TYPE_FLOOR_BOSS],
	]


static func _open_layer(rng: RandomNumberGenerator) -> Array:
	if rng.randf() < 0.5:
		return [RoomLayout.TYPE_COMBAT]
	return [RoomLayout.TYPE_COMBAT, SECOND_ROOM_TYPES[rng.randi_range(0, SECOND_ROOM_TYPES.size() - 1)]]


static func _add_room(map: FloorMap, layer: int, room_type: String, layout: RoomLayout) -> FloorRoom:
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.layer = layer
	room.room_type = room_type
	room.layout = layout
	map.rooms.append(room)
	return room


static func _connect(from_rooms: Array[FloorRoom], to_rooms: Array[FloorRoom], rng: RandomNumberGenerator) -> void:
	if from_rooms.is_empty():
		return
	if from_rooms.size() == 2 and to_rooms.size() == 2:
		from_rooms[0].exits.append(to_rooms[0].id)
		from_rooms[1].exits.append(to_rooms[1].id)
		var crossing := from_rooms[rng.randi_range(0, 1)]
		var other := to_rooms[0].id if crossing == from_rooms[1] else to_rooms[1].id
		crossing.exits.append(other)
		return
	for from_room in from_rooms:
		for to_room in to_rooms:
			from_room.exits.append(to_room.id)


static func _attach_side_rooms(map: FloorMap, picker: _LayoutPicker, rng: RandomNumberGenerator) -> void:
	for room in map.main_rooms():
		if room.room_type != RoomLayout.TYPE_COMBAT or rng.randf() >= SIDE_CHANCE:
			continue
		var layout := picker.pick(RoomLayout.TYPE_SIDE)
		if layout == null:
			continue
		var side := _add_room(map, room.layer, RoomLayout.TYPE_SIDE, layout)
		side.parent_id = room.id
		room.side_id = side.id


class _LayoutPicker:
	var _by_type: Dictionary
	var _rng: RandomNumberGenerator
	var _remaining := {}

	func _init(by_type: Dictionary, rng: RandomNumberGenerator) -> void:
		_by_type = by_type
		_rng = rng

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
