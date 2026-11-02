class_name CaneThrow
extends RefCounted

const RETURN_DELAY := 3.0

enum State { HELD, FLYING, DROPPED, RETURNING }

var _state := State.HELD
var _dropped_time := 0.0


func try_throw() -> bool:
	if _state != State.HELD:
		return false
	_state = State.FLYING
	return true


func drop() -> void:
	if _state != State.FLYING:
		return
	_state = State.DROPPED
	_dropped_time = 0.0


func tick(delta: float) -> void:
	if _state != State.DROPPED:
		return
	_dropped_time += delta
	if _dropped_time >= RETURN_DELAY:
		_state = State.RETURNING


func catch_cane() -> void:
	_state = State.HELD
	_dropped_time = 0.0


func is_held() -> bool:
	return _state == State.HELD


func is_flying() -> bool:
	return _state == State.FLYING


func is_dropped() -> bool:
	return _state == State.DROPPED


func is_returning() -> bool:
	return _state == State.RETURNING
