class_name Health
extends RefCounted

signal changed
signal died
# A hit that would have finished him left one pill instead, as the Life Jacket does.
signal rescued

const INVULN_TIME := 0.8

var max_pills: int
var pills: int
var _invuln := 0.0
# Extra pills the first heal of a run restores, as the bedpan memento gives. Spent by the first heal
# that finds him short of pills, so a heal at full health never wastes it.
var first_heal_bonus := 0
# Extra pills every heal restores, as the Stronger Dose option gives. Never past the maximum.
var heal_bonus := 0
# How many more hits that would finish him leave one pill instead. RunState fills it on every floor.
var lethal_saves := 0
# A half pill healed and waiting for its other half. See heal_half.
var half_pills := 0


func _init(start_pills: int) -> void:
	max_pills = start_pills
	pills = start_pills


func hit(amount: int) -> bool:
	if is_dead() or is_invulnerable():
		return false
	if amount > 0 and amount >= pills and lethal_saves > 0:
		lethal_saves -= 1
		pills = 1
		_invuln = INVULN_TIME
		changed.emit()
		rescued.emit()
		return true
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
	if amount > 0:
		bonus += heal_bonus
	pills = mini(pills + amount + bonus, max_pills)
	changed.emit()


# Half a pill, from the items that heal by halves. Every second half heals a whole pill.
func heal_half() -> void:
	if is_dead():
		return
	half_pills += 1
	if half_pills >= 2:
		half_pills = 0
		heal(1)


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
