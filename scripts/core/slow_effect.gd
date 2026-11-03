class_name SlowEffect
extends RefCounted

# Timed slows on Grandpa, such as a sedative dart's. Several can run at once, and only the
# strongest counts. However strong, he always keeps enough speed to walk out of trouble.
const MIN_FACTOR := 0.4

# Each entry is [fraction, seconds left].
var _slows: Array = []


func apply(fraction: float, seconds: float) -> void:
	if fraction <= 0.0 or seconds <= 0.0:
		return
	_slows.append([clampf(fraction, 0.0, 1.0), seconds])


func tick(delta: float) -> void:
	for i in range(_slows.size() - 1, -1, -1):
		_slows[i][1] -= delta
		if _slows[i][1] <= 0.0:
			_slows.remove_at(i)


func is_active() -> bool:
	return not _slows.is_empty()


func speed_factor() -> float:
	var strongest := 0.0
	for slow: Array in _slows:
		strongest = maxf(strongest, slow[0])
	return maxf(1.0 - strongest, MIN_FACTOR)
