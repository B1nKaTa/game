class_name TitleSeats
extends RefCounted

# Who sits where in the title screen's row of chairs. Each chair has one seat anchor, the point on its
# seat line its sitter sits on, and one sitter at most: a ghost claims the chair it drifts to when it
# sets off and lets go of the one it left, so two never meet on one seat. A seated frame is drawn with
# its own sit point (TitleFrames.HAROLD_SIT, GHOST_SIT) on the anchor, so a change of pose can never
# lift anyone off the seat.

var anchors: Array[Vector2] = []
var _sitter := {}


func _init(seat_anchors: Array[Vector2]) -> void:
	anchors = seat_anchors


# Takes seat for who, letting go of any seat who held. False, and nothing changes, when it is taken.
func claim(seat: int, who: int) -> bool:
	if seat < 0 or seat >= anchors.size():
		return false
	if _sitter.has(seat) and _sitter[seat] != who:
		return false
	release(who)
	_sitter[seat] = who
	return true


func release(who: int) -> void:
	for seat: int in _sitter.keys():
		if _sitter[seat] == who:
			_sitter.erase(seat)


func seat_of(who: int) -> int:
	for seat: int in _sitter:
		if _sitter[seat] == who:
			return seat
	return -1


func sitter(seat: int) -> int:
	return _sitter.get(seat, -1)


# The free seats among allowed, in order.
func open_seats(allowed: Array[int]) -> Array[int]:
	var open: Array[int] = []
	for seat in allowed:
		if not _sitter.has(seat):
			open.append(seat)
	return open


# Where a frame's picture goes, from the sitter's origin on the seat anchor, so its sit point lands on
# the anchor: straight up by the sit point's row, and centred across on its canvas.
static func frame_offset(sit: Vector2, frame_size: int) -> Vector2:
	return Vector2(-frame_size / 2.0, -sit.y)
