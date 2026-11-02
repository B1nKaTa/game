class_name Telegraph
extends RefCounted

var _duration := 0.0
var _remaining := 0.0


func start(duration: float) -> void:
	_duration = duration
	_remaining = duration


func tick(delta: float) -> bool:
	if _remaining <= 0.0:
		return false
	_remaining -= delta
	return _remaining <= 0.0


func is_active() -> bool:
	return _remaining > 0.0


func shows_warning(fraction: float) -> bool:
	return is_active() and _remaining <= _duration * fraction
