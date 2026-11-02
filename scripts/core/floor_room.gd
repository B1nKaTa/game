class_name FloorRoom
extends RefCounted

var id: int = 0
var layer: int = 0
var room_type: String = ""
var layout: RoomLayout
var exits: Array[int] = []
var side_id: int = -1
var treasure_id: int = -1
var shop_id: int = -1
var parent_id: int = -1


# A detour hangs off a room on the route, so entering it never chooses a route.
func is_detour() -> bool:
	return room_type in [RoomLayout.TYPE_SIDE, RoomLayout.TYPE_TREASURE, RoomLayout.TYPE_SHOP]
