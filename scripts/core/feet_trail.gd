class_name FeetTrail
extends RefCounted

# Where Grandpa's feet have been over the last few seconds, kept for Madame Zara's Possession, whose
# ghostly copy of him walks his last LENGTH seconds of movement again. Samples go in with the time they
# were taken; anything older than LENGTH (and a little spare) is let go.
const LENGTH := 2.0
const SPARE := 0.25

var _times := PackedFloat32Array()
var _spots := PackedVector2Array()


func record(time: float, at: Vector2) -> void:
	_times.append(time)
	_spots.append(at)
	var keep_from := 0
	while keep_from < _times.size() - 1 and _times[keep_from + 1] < time - LENGTH - SPARE:
		keep_from += 1
	if keep_from > 0:
		_times = _times.slice(keep_from)
		_spots = _spots.slice(keep_from)


func clear() -> void:
	_times.clear()
	_spots.clear()


# Whether it holds the whole of the last LENGTH seconds before now.
func covers(now: float) -> bool:
	return not _times.is_empty() and _times[0] <= now - LENGTH + 0.001


# Where his feet were at a time: between two samples, the point between them; before the first, the
# first; after the last, the last.
func at(time: float) -> Vector2:
	if _times.is_empty():
		return Vector2.ZERO
	if time <= _times[0]:
		return _spots[0]
	for i in range(1, _times.size()):
		if time <= _times[i]:
			var span := _times[i] - _times[i - 1]
			var share := 0.0 if span <= 0.0 else (time - _times[i - 1]) / span
			return _spots[i - 1].lerp(_spots[i], share)
	return _spots[_spots.size() - 1]


# His last LENGTH seconds before now, as points step seconds apart, oldest first: point k is where he
# stood at now - LENGTH + k * step.
func path(now: float, step: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := roundi(LENGTH / step)
	for k in count + 1:
		points.append(at(now - LENGTH + k * step))
	return points
