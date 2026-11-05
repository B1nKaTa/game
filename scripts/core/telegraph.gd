class_name Telegraph
extends RefCounted

var _duration := 0.0
var _remaining := 0.0


# A windup at least this long is a heavy attack, and gives a quiet warning hum as it starts.
const HEAVY_WINDUP := 0.5


func start(duration: float) -> void:
	_duration = duration
	_remaining = duration
	if duration >= HEAVY_WINDUP:
		Sfx.play("attack_warning")


func tick(delta: float) -> bool:
	if _remaining <= 0.0:
		return false
	_remaining -= delta
	return _remaining <= 0.0


# How long the windup has left to run.
func remaining() -> float:
	return maxf(_remaining, 0.0)


func is_active() -> bool:
	return _remaining > 0.0


func shows_warning(fraction: float) -> bool:
	return is_active() and _remaining <= _duration * fraction


func warning_progress(fraction: float) -> float:
	if not shows_warning(fraction):
		return 0.0
	var window := _duration * fraction
	if window <= 0.0:
		return 1.0
	return clampf(1.0 - _remaining / window, 0.0, 1.0)
