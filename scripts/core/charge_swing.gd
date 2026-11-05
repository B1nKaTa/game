class_name ChargeSwing
extends RefCounted

const CHARGE_TIME := 0.7
const HOLD_DELAY := 0.2
const DAMAGE := 30
const KNOCKBACK := 220.0

# How long this charge takes, which the Charging Crystal shortens. Never below HOLD_DELAY's worth.
var charge_time := CHARGE_TIME
var _holding := false
var _time := 0.0


func start() -> void:
	_holding = true
	_time = 0.0


func release() -> bool:
	var ready := _holding and _time >= charge_time
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
	return clampf((_time - HOLD_DELAY) / maxf(charge_time - HOLD_DELAY, 0.01), 0.0, 1.0)
