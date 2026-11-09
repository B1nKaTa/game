class_name NowServing
extends RefCounted

# The title screen's NOW SERVING board. Every few seconds it calls the next number, but it never calls
# Harold's: when the next number would be his, the board flickers, shows his number's first digits and
# a dash for a moment, and drops back a few numbers to climb again. So it is always one short.

const STEP_MIN := 3.0
const STEP_MAX := 5.5
# How long the board stutters before it drops back.
const FLICKER_TIME := 1.1
const DROP_MIN := 3
const DROP_MAX := 6
# Where the board starts below his number, so the first drop comes within about 10 seconds.
const START_BELOW := 2

var target: int
var shown: int
var flicker_left := 0.0
var _wait: float
var _rng := RandomNumberGenerator.new()


func _init(harold_ticket := 42, seed_value := 0) -> void:
	target = harold_ticket
	shown = max(target - START_BELOW, 0)
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_wait = _rng.randf_range(STEP_MIN, STEP_MAX)


# Moves the board on by delta seconds. Returns "advance" when it calls the next number, "skip" when it
# would have called his and drops back instead, and "" otherwise.
func tick(delta: float) -> String:
	if flicker_left > 0.0:
		flicker_left = max(flicker_left - delta, 0.0)
		return ""
	_wait -= delta
	if _wait > 0.0:
		return ""
	_wait = _rng.randf_range(STEP_MIN, STEP_MAX)
	var next := next_number(shown, target, _rng.randi_range(DROP_MIN, DROP_MAX))
	var skipped := next < shown
	shown = next
	if skipped:
		flicker_left = FLICKER_TIME
		return "skip"
	return "advance"


# The number after shown: one more, unless that is his, when it drops back by drop (never below 0).
static func next_number(current: int, harold_ticket: int, drop: int) -> int:
	if current + 1 >= harold_ticket:
		return max(harold_ticket - 1 - drop, 0)
	return current + 1


# What the board's three digits read now. While it stutters it shows his number's first digits and a
# dash in place of the last, or nothing on alternate beats; never his whole number.
func display(time: float) -> String:
	if flicker_left > 0.0:
		if int(time * 12.0) % 3 == 0:
			return ""
		return ("%03d" % target).substr(0, 2) + "-"
	return "%03d" % shown
