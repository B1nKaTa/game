class_name CaneCombo
extends RefCounted

const DAMAGE := [10, 10, 18]
const LOCK_TIME := 0.2
const WINDOW := 0.45

# How long each swing holds the next one back. The Lightweight and Heavy Head options change it.
var lock_time := LOCK_TIME
var _step := 0
var _lock := 0.0
var _window := 0.0


func try_attack() -> int:
	if _lock > 0.0:
		return 0
	var damage: int = DAMAGE[_step]
	_step = (_step + 1) % DAMAGE.size()
	_lock = lock_time
	_window = WINDOW
	return damage


func tick(delta: float) -> void:
	if _lock > 0.0:
		var used := minf(_lock, delta)
		_lock -= used
		delta -= used
	if _lock <= 0.0 and _window > 0.0:
		_window -= delta
		if _window <= 0.0:
			_window = 0.0
			_step = 0


func step() -> int:
	return _step
