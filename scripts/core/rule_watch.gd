class_name RuleWatch
extends RefCounted

# One room's rule through its fight: active until Harold breaks it, then kept or lifted on the clear.

enum State { ACTIVE, BROKEN, KEPT, LIFTED }

const LOITER_TIME := 2.5
# The icon pulses this long before loitering counts.
const LOITER_WARN := 1.0

var rule := ""
var state := State.ACTIVE
# Whether the big notice has shown; it shows on the first entry only.
var announced := false
var _still := 0.0


func _init(room_rule := "") -> void:
	rule = room_rule


func is_open() -> bool:
	return state == State.ACTIVE or state == State.BROKEN


# Returns true the first time this breaks the rule, when the Auditor is called.
func report(action: String) -> bool:
	if state != State.ACTIVE or action != RoomRule.action_of(rule):
		return false
	state = State.BROKEN
	return true


func tick_still(delta: float, moved: bool) -> bool:
	if rule != RoomRule.NO_LOITERING or state != State.ACTIVE:
		return false
	_still = 0.0 if moved else _still + delta
	return _still >= LOITER_TIME and report(RoomRule.ACTION_LOITER)


# held: input action name -> whether it is held this frame.
func pulsing(held: Dictionary) -> bool:
	if state != State.ACTIVE:
		return false
	if rule == RoomRule.NO_LOITERING:
		return _still >= LOITER_TIME - LOITER_WARN
	var button := RoomRule.button_of(rule)
	return not button.is_empty() and held.get(button, false)


func finish() -> int:
	if state == State.ACTIVE:
		state = State.KEPT
	elif state == State.BROKEN:
		state = State.LIFTED
	return state


func to_dict() -> Dictionary:
	return {"rule": rule, "state": state, "announced": announced}


static func from_dict(raw: Dictionary) -> RuleWatch:
	var watch := RuleWatch.new(str(raw.get("rule", "")))
	watch.state = clampi(int(raw.get("state", State.ACTIVE)), State.ACTIVE, State.LIFTED)
	watch.announced = bool(raw.get("announced", false))
	return watch
