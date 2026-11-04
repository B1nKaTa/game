class_name Health
extends RefCounted

signal changed
signal died

const INVULN_TIME := 0.8

var max_pills: int
var pills: int
var _invuln := 0.0
# Extra pills the first heal of a run restores, as the bedpan memento gives. Spent by the first heal
# that finds him short of pills, so a heal at full health never wastes it.
var first_heal_bonus := 0


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


# A hit that would have landed but is shrugged off: no pill is lost, and he is safe for as long as
# after a hit, so the same hazard cannot land on the very next frame.
func shrug_off() -> void:
	_invuln = INVULN_TIME


func heal(amount: int) -> void:
	if is_dead():
		return
	var bonus := 0
	if first_heal_bonus > 0 and amount > 0 and pills < max_pills:
		bonus = first_heal_bonus
		first_heal_bonus = 0
	pills = mini(pills + amount + bonus, max_pills)
	changed.emit()


func raise_max(new_max: int) -> void:
	var difference := new_max - max_pills
	max_pills = new_max
	# A lower maximum never leaves him holding more pills than it allows.
	pills = mini(pills, max_pills)
	if difference > 0:
		pills += difference
	changed.emit()


func tick(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)


func is_dead() -> bool:
	return pills <= 0


func is_invulnerable() -> bool:
	return _invuln > 0.0


func invulnerability_left() -> float:
	return _invuln
