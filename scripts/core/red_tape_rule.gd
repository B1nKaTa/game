class_name RedTapeRule
extends RefCounted

# Red tape strung across the Head Office's lanes. Walking into it holds Grandpa in place for HOLD
# seconds, once each time he steps onto tape from clear floor, so once it lets go he walks on
# through. A dodge cuts it instead: he is never held while dodging, a dodge frees him from a hold,
# and the tape he dodges through stays cut for CUT_TIME. Enemies ignore it, and it never costs a pill.
const HOLD := 0.6
const CUT_TIME := 6.0

var _held_left := 0.0
var _was_on_tape := false


# Call once a physics frame with whether his feet stand on strung, uncut tape. True while he is held.
func step(on_tape: bool, dodging: bool, delta: float) -> bool:
	_held_left = maxf(_held_left - delta, 0.0)
	if dodging:
		_held_left = 0.0
		_was_on_tape = on_tape
		return false
	if on_tape and not _was_on_tape:
		_held_left = HOLD
	_was_on_tape = on_tape
	return _held_left > 0.0


func is_holding() -> bool:
	return _held_left > 0.0


func hold_left() -> float:
	return _held_left


# How long cut tape stays down, counting down from a cut. Zero means it is strung again.
static func cut_left_after(cut_left: float, delta: float) -> float:
	return maxf(cut_left - delta, 0.0)
