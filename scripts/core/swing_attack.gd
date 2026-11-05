class_name SwingAttack
extends RefCounted

const DURATION := 0.1
# How an item has reshaped a swing, for Player to draw: the plain arc, Grandma's Rolling Pin's smash or
# The Reaper's Other Scythe's spinning sweep.
const STYLE_ARC := ""
const STYLE_PIN := "pin"
const STYLE_SWEEP := "sweep"

var direction: Vector2
var reach: float
var half_angle_deg: float
var damage: float
var push: float
var heavy: bool
var finisher: bool
# Items may reshape a swing the moment it starts (RunEffects.swing): how long it hits and is drawn,
# whether the same arc also reaches behind him, and how it looks. A swing hits only what its drawn
# shape covers, for as long as it is drawn.
var duration := DURATION
var both_ways := false
var style := STYLE_ARC
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


func set_duration(seconds: float) -> void:
	duration = maxf(seconds, 0.01)
	_time_left = duration


func tick(delta: float) -> void:
	_time_left -= delta


func is_active() -> bool:
	return _time_left > 0.0


# How far through its time it is, from 0 to 1, for drawing.
func progress() -> float:
	return clampf(1.0 - _time_left / duration, 0.0, 1.0)


func has_landed() -> bool:
	return _hit_ids.size() > _blocked


# How many enemies and blocks it reached that no shield stopped.
func landed_count() -> int:
	return _hit_ids.size() - _blocked


# A swing a shield stopped reached something, so it isn't a miss, but it didn't land either.
func has_reached_something() -> bool:
	return not _hit_ids.is_empty()


func mark_blocked() -> void:
	_blocked += 1


func try_hit(origin: Vector2, id: int, body: Rect2) -> bool:
	if not is_active() or _hit_ids.has(id):
		return false
	if not covers(origin, body):
		return false
	_hit_ids[id] = true
	return true


# Which way it shoves what it hits at a spot: forward, or straight away from him for a swing that
# reaches round to his sides or behind him.
func push_toward(origin: Vector2, at: Vector2) -> Vector2:
	if (both_ways or half_angle_deg >= 90.0) and not origin.is_equal_approx(at):
		return origin.direction_to(at) * push
	return direction * push


func covers(origin: Vector2, body: Rect2) -> bool:
	if MeleeArc.hits_body(origin, direction, reach, half_angle_deg, body):
		return true
	return both_ways and MeleeArc.hits_body(origin, -direction, reach, half_angle_deg, body)
