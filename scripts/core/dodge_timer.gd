class_name DodgeTimer
extends RefCounted

const DURATION := 0.2

# How many dodges he can make back to back. Velcro Shoes add one; each one spent comes back after a
# cooldown of its own, one at a time. With one charge it is the plain dodge: none until the cooldown ends.
var charges := 1
var _active := 0.0
var _cooldown := 0.0
var _cooldown_length := 0.0
var _spent := 0


func try_start(cooldown: float, duration := DURATION) -> bool:
	if _active > 0.0 or _spent >= maxi(charges, 1):
		return false
	_active = duration
	_cooldown_length = cooldown
	if _spent == 0:
		_cooldown = cooldown
	_spent += 1
	return true


func tick(delta: float) -> void:
	if _active > 0.0:
		var used := minf(_active, delta)
		_active -= used
		delta -= used
	if _active > 0.0 or _spent <= 0:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_spent -= 1
	_cooldown = _cooldown_length + _cooldown if _spent > 0 else 0.0


func is_active() -> bool:
	return _active > 0.0


# The dodge is ready again at once, every charge of it, as Reading Glasses on a Chain and the Pogo Cane
# give back. A dodge under way goes on.
func clear_cooldown() -> void:
	_cooldown = 0.0
	_spent = 0


func cooldown_left() -> float:
	return _cooldown if _spent > 0 else 0.0


# How many dodges he could start right now, once any dodge under way has ended.
func charges_ready() -> int:
	return maxi(charges, 1) - _spent
