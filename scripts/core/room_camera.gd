class_name RoomCamera
extends RefCounted


# Where the camera rests: centered along any axis the room fits in the view,
# otherwise following the focus and stopping at the room's edges. Whole pixels,
# because the view is drawn at its own low resolution.
static func center_for(room_size: Vector2, focus: Vector2, view_size: Vector2) -> Vector2:
	return Vector2(
		_axis(room_size.x, focus.x, view_size.x),
		_axis(room_size.y, focus.y, view_size.y)).round()


static func _axis(room: float, focus: float, view: float) -> float:
	if room <= view:
		return room / 2.0
	return clampf(focus, view / 2.0, room - view / 2.0)
