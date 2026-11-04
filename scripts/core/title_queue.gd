class_name TitleQueue
extends RefCounted

# The title screen's queue of old souls. Every SERVE_TIME the NOW SERVING sign ticks on, the soul at
# the front is served, and the line shuffles one step forward. The soul served takes a new number at
# the machine and joins the back, Grandpa included, so the line never empties.

const SERVE_TIME := 3.5
const SHUFFLE_TIME := 0.8
const LINE_LENGTH := 7
# Soul ids are 0 to LINE_LENGTH - 1. Grandpa is this one, and starts a few places back.
const GRANDPA := 3

var now_serving: int
var souls: Array[int] = []
var _tickets := {}
var _left := SERVE_TIME
var _shuffle_left := 0.0


func _init(start_number: int) -> void:
	now_serving = start_number
	for i in LINE_LENGTH:
		souls.append(i)
		_tickets[i] = start_number + i


# Returns true on the tick a soul is served.
func tick(delta: float) -> bool:
	_shuffle_left = maxf(_shuffle_left - delta, 0.0)
	_left -= delta
	if _left > 0.0:
		return false
	_left += SERVE_TIME
	var served: int = souls.pop_front()
	souls.append(served)
	_tickets[served] = now_serving + LINE_LENGTH
	now_serving += 1
	_shuffle_left = SHUFFLE_TIME
	return true


# How far the last step forward has gone, from 0 just after a serve to 1 standing still.
func shuffle() -> float:
	return 1.0 - _shuffle_left / SHUFFLE_TIME


func ticket_of(soul: int) -> int:
	return int(_tickets.get(soul, 0))
