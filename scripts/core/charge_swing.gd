class_name ChargeSwing
extends RefCounted

const CHARGE_TIME := 0.7
const DAMAGE := 30
const KNOCKBACK := 220.0

var _charging := false
var _time := 0.0


func start() -> void:
	_charging = true
	_time = 0.0


func release() -> bool:
	var ready := _charging and _time >= CHARGE_TIME
	_charging = false
	_time = 0.0
	return ready


func tick(delta: float) -> void:
	if _charging:
		_time += delta


func is_charging() -> bool:
	return _charging


func progress() -> float:
	return minf(_time / CHARGE_TIME, 1.0)
