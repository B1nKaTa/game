class_name ScreenShake
extends RefCounted

const CHARGED_HIT := 4.0
const CHARGED_TIME := 0.15
const HURT := 3.0
const HURT_TIME := 0.12
const BOSS_DEATH := 8.0
const BOSS_DEATH_TIME := 0.45

var _magnitude := 0.0
var _duration := 0.0
var _left := 0.0


static func falloff(left: float, duration: float) -> float:
	if duration <= 0.0 or left <= 0.0:
		return 0.0
	var t := minf(left / duration, 1.0)
	return t * t


func start(magnitude: float, duration: float) -> void:
	if magnitude < current_magnitude():
		return
	_magnitude = magnitude
	_duration = duration
	_left = duration


func tick(real_delta: float) -> void:
	_left = maxf(_left - real_delta, 0.0)


func cancel() -> void:
	_left = 0.0


func is_active() -> bool:
	return _left > 0.0 and _magnitude > 0.0


func current_magnitude() -> float:
	return _magnitude * falloff(_left, _duration)


func offset(rng: RandomNumberGenerator) -> Vector2:
	var m := current_magnitude()
	if m <= 0.0:
		return Vector2.ZERO
	return Vector2(rng.randf_range(-m, m), rng.randf_range(-m, m)).round()
