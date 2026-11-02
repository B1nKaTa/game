class_name HitStop
extends RefCounted

const HEAVY_HIT := 0.06
const CANE_HIT := 0.06
const FINISHER := 0.03
const MAX_TIME := 0.1

var _left := 0.0


static func duration_for(heavy: bool, finisher: bool) -> float:
	if heavy:
		return HEAVY_HIT
	if finisher:
		return FINISHER
	return 0.0


func request(seconds: float) -> void:
	_left = minf(maxf(_left, seconds), MAX_TIME)


func tick(real_delta: float) -> void:
	_left = maxf(_left - real_delta, 0.0)


func cancel() -> void:
	_left = 0.0


func is_active() -> bool:
	return _left > 0.0


func time_scale() -> float:
	return 0.0 if is_active() else 1.0
