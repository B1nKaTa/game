class_name ChargeSwing
extends RefCounted

const CHARGE_TIME := 0.7
const HOLD_DELAY := 0.2
const DAMAGE := 30
const KNOCKBACK := 220.0

var _holding := false
var _time := 0.0


func start() -> void:
	_holding = true
	_time = 0.0


func release() -> bool:
	var ready := _holding and _time >= CHARGE_TIME
	cancel()
	return ready


func cancel() -> void:
	_holding = false
	_time = 0.0


func tick(delta: float) -> void:
	if _holding:
		_time += delta


func is_holding() -> bool:
	return _holding


func is_charging() -> bool:
	return _holding and _time >= HOLD_DELAY


func progress() -> float:
	return clampf((_time - HOLD_DELAY) / (CHARGE_TIME - HOLD_DELAY), 0.0, 1.0)
