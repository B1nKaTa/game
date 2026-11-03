class_name SwingAttack
extends RefCounted

const DURATION := 0.1

var direction: Vector2
var reach: float
var half_angle_deg: float
var damage: float
var push: float
var heavy: bool
var finisher: bool
var _time_left := DURATION
var _hit_ids := {}
var _blocked := 0


func _init(swing_direction: Vector2, swing_reach: float, swing_half_angle_deg: float, swing_damage: float, swing_push: float, is_heavy: bool, is_finisher: bool) -> void:
	direction = swing_direction
	reach = swing_reach
	half_angle_deg = swing_half_angle_deg
	damage = swing_damage
	push = swing_push
	heavy = is_heavy
	finisher = is_finisher


func tick(delta: float) -> void:
	_time_left -= delta


func is_active() -> bool:
	return _time_left > 0.0


func has_landed() -> bool:
	return _hit_ids.size() > _blocked


# A swing a shield stopped reached something, so it isn't a miss, but it didn't land either.
func has_reached_something() -> bool:
	return not _hit_ids.is_empty()


func mark_blocked() -> void:
	_blocked += 1


func try_hit(origin: Vector2, id: int, body: Rect2) -> bool:
	if not is_active() or _hit_ids.has(id):
		return false
	if not MeleeArc.hits_body(origin, direction, reach, half_angle_deg, body):
		return false
	_hit_ids[id] = true
	return true
