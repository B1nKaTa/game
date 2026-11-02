class_name FloorRoom
extends RefCounted

var id: int = 0
var room_type: String = ""
var layout: RoomLayout
var cell := Vector2i.ZERO
# Which room each door leads to, keyed by the side of this room it stands on.
var doors := {}


# A detour is a dead end hanging off a regular room, and never counts toward the floor's size.
func is_detour() -> bool:
	return room_type in [RoomLayout.TYPE_SIDE, RoomLayout.TYPE_TREASURE, RoomLayout.TYPE_SHOP, RoomLayout.TYPE_SECRET]


# The side whose door leads to that room, or Vector2i.ZERO when none does.
func side_towards(other_id: int) -> Vector2i:
	for side: Vector2i in doors:
		if doors[side] == other_id:
			return side
	return Vector2i.ZERO
