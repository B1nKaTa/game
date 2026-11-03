class_name DentureThrow
extends RefCounted

# Grandpa's false teeth, his thrown attack. His cane never leaves his hand, so this rules the throw
# alone: held, flying, lying where they stopped, then coming back to him on their own. Their time
# away is the throw's cooldown.
const RETURN_DELAY := 3.0
# Denture Adhesive's last level brings them back sooner.
const QUICK_RETURN_DELAY := 2.0
# How far they fly without Denture Adhesive.
const BASE_RANGE := 170.0

enum State { HELD, FLYING, DROPPED, RETURNING }

var return_delay := RETURN_DELAY
var _state := State.HELD
var _dropped_time := 0.0


func _init(delay := RETURN_DELAY) -> void:
	return_delay = delay


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
	if _dropped_time >= return_delay:
		_state = State.RETURNING


func catch_teeth() -> void:
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
