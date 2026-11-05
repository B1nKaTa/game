class_name DodgeTimer
extends RefCounted

const DURATION := 0.2

var _active := 0.0
var _cooldown := 0.0


func try_start(cooldown: float, duration := DURATION) -> bool:
	if _active > 0.0 or _cooldown > 0.0:
		return false
	_active = duration
	_cooldown = cooldown
	return true


func tick(delta: float) -> void:
	if _active > 0.0:
		var used := minf(_active, delta)
		_active -= used
		delta -= used
	if _active <= 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)


func is_active() -> bool:
	return _active > 0.0


# The dodge is ready again at once, as Reading Glasses on a Chain give back. A dodge under way goes on.
func clear_cooldown() -> void:
	_cooldown = 0.0


func cooldown_left() -> float:
	return _cooldown
