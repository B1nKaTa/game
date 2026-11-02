class_name RoomRules
extends RefCounted

const ICONS := {
	RoomLayout.TYPE_COMBAT: "C",
	RoomLayout.TYPE_ITEM: "I",
	RoomLayout.TYPE_HEALING: "H",
	RoomLayout.TYPE_SIDE: "?",
	RoomLayout.TYPE_MINI_BOSS: "M",
	RoomLayout.TYPE_FLOOR_BOSS: "B",
}


static func door_icon(room_type: String) -> String:
	return ICONS.get(room_type, "<")


static func pick_items(all: Array[ItemDef], run: RunState, count: int, rng: RandomNumberGenerator) -> Array[ItemDef]:
	var options: Array[ItemDef] = []
	for item in all:
		if not run.has_item(item.id):
			options.append(item)
	var picked: Array[ItemDef] = []
	while picked.size() < count and not options.is_empty():
		var index := rng.randi_range(0, options.size() - 1)
		picked.append(options[index])
		options.remove_at(index)
	return picked
