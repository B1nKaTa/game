class_name FloorRoom
extends RefCounted

var id: int = 0
var room_type: String = ""
var layout: RoomLayout
var cell := Vector2i.ZERO
# Which room each door leads to, keyed by the side of this room it stands on.
var doors := {}
# Picks this room's decor scatter, so two rooms sharing a layout still look different.
var decor_seed := 0
# Enemies added on top of the layout's own, because the room lies far along the main path.
var extra_enemies := 0


# A detour is a dead end hanging off a regular room, and never counts toward the floor's size.
func is_detour() -> bool:
	return room_type in [RoomLayout.TYPE_SIDE, RoomLayout.TYPE_TREASURE, RoomLayout.TYPE_SHOP, RoomLayout.TYPE_SECRET, RoomLayout.TYPE_VAULT]


# These rooms sit behind a wall or a stone that only a bomb opens, so nothing the floor needs may lead through them.
func needs_a_bomb() -> bool:
	return room_type == RoomLayout.TYPE_SECRET or room_type == RoomLayout.TYPE_VAULT


# The side whose door leads to that room, or Vector2i.ZERO when none does.
func side_towards(other_id: int) -> Vector2i:
	for side: Vector2i in doors:
		if doors[side] == other_id:
			return side
	return Vector2i.ZERO
