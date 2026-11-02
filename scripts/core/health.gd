class_name Health
extends RefCounted

signal changed
signal died

const INVULN_TIME := 0.8

var max_pills: int
var pills: int
var _invuln := 0.0


func _init(start_pills: int) -> void:
	max_pills = start_pills
	pills = start_pills


func hit(amount: int) -> bool:
	if is_dead() or is_invulnerable():
		return false
	pills = maxi(pills - amount, 0)
	_invuln = INVULN_TIME
	changed.emit()
	if pills == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead():
		return
	pills = mini(pills + amount, max_pills)
	changed.emit()


func raise_max(new_max: int) -> void:
	var difference := new_max - max_pills
	max_pills = new_max
	if difference > 0:
		pills += difference
	changed.emit()


func tick(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)


func is_dead() -> bool:
	return pills <= 0


func is_invulnerable() -> bool:
	return _invuln > 0.0
