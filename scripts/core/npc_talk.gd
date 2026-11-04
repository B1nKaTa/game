class_name NpcTalk
extends RefCounted

# What someone says when Grandpa talks to them: the next line at each press, in order and round
# again, shown for a few seconds or until the next press.
const SHOW_TIME := 3.5
# A line types itself out at this many letters a second, and the speaker blips as it does.
const REVEAL_RATE := 45.0

var _lines: Array[String] = []
var _next := 0
var _shown := ""
var _left := 0.0
var _age := 0.0


# start picks the first line, round the list: callers pass the run count, so each run opens on the next.
func _init(lines: Array[String], start := 0) -> void:
	_lines = lines
	if not _lines.is_empty():
		_next = posmod(start, _lines.size())


# Talking answers the interact key only in reach, and only when nothing else that answers it, such
# as a ware or the Retirement Plan, is nearer. Pass the distances of those that are in their own reach.
static func answers(distance: float, reach: float, rivals: Array[float]) -> bool:
	if distance > reach:
		return false
	for rival in rivals:
		if rival < distance:
			return false
	return true


func talk() -> String:
	if _lines.is_empty():
		return ""
	_shown = _lines[_next]
	_next = (_next + 1) % _lines.size()
	_left = SHOW_TIME
	_age = 0.0
	return _shown


# Shows one line now for something that just happened, without moving the order on.
func say(line: String) -> void:
	if line.is_empty():
		return
	_shown = line
	_left = SHOW_TIME
	_age = 0.0


func tick(delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
	_age += delta


# The line in the bubble, or nothing once it has faded.
func showing() -> String:
	return _shown if _left > 0.0 else ""


# How many letters of the line in the bubble have typed out so far.
func revealed_count() -> int:
	return mini(int(_age * REVEAL_RATE), showing().length())


func revealed() -> String:
	return showing().left(revealed_count())


func is_revealing() -> bool:
	return revealed_count() < showing().length()
