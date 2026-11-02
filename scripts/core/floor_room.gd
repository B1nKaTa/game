class_name FloorRoom
extends RefCounted

var id: int = 0
var layer: int = 0
var room_type: String = ""
var layout: RoomLayout
var exits: Array[int] = []
var side_id: int = -1
var parent_id: int = -1
