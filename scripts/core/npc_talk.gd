class_name NpcTalk
extends RefCounted

# What someone says when Grandpa talks to them: the next line at each press, in order and round
# again, shown for a few seconds or until the next press.
const SHOW_TIME := 3.5

var _lines: Array[String] = []
var _next := 0
var _shown := ""
var _left := 0.0


func _init(lines: Array[String]) -> void:
	_lines = lines


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
	return _shown


func tick(delta: float) -> void:
	_left = maxf(_left - delta, 0.0)


# The line in the bubble, or nothing once it has faded.
func showing() -> String:
	return _shown if _left > 0.0 else ""
