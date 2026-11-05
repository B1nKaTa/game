class_name TapeSpread
extends Node2D

# Red tape the Chairman spreads across lanes of the room. Each cell shows as a red outline of the band
# for its warning, then is strung and holds Grandpa as any red tape does, and after a while the whole
# spread is taken down. It comes to nothing if the boss who laid it falls while it is only a warning.
# It lies at the room's origin, with each cell of tape at its own cell's middle.
const WARNING := 1.0
const LAST := 10.0

var _cells: Array[Vector2i] = []
var _across := true
var _warning := WARNING
var _left := LAST
var _strung := false
var _source: Enemy
var _has_source := false


func setup(cells: Array[Vector2i], across: bool, warning := WARNING, seconds := LAST, source: Enemy = null) -> void:
	_cells = cells
	_across = across
	_warning = warning
	_left = seconds
	_source = source
	_has_source = source != null


func _ready() -> void:
	for cell in _cells:
		var tape := RedTape.new()
		tape.across = _across
		tape.set_strung(false)
		tape.position = RoomBackdrop.cell_center(cell)
		add_child(tape)


func tapes() -> Array:
	var found: Array = []
	for child in get_children():
		if child is RedTape:
			found.append(child)
	return found


func cells() -> Array[Vector2i]:
	return _cells


# How long until the tape is strung, 0 once it is.
func warning_left() -> float:
	return 0.0 if _strung else maxf(_warning, 0.0)


func is_strung() -> bool:
	return _strung


func is_done() -> bool:
	return _strung and _left <= 0.0


# Runs the warning, then the tape's time. True once, on the moment the tape is strung.
func advance(delta: float) -> bool:
	if not _strung:
		_warning -= delta
		if _warning <= 0.0:
			_strung = true
			for tape in tapes():
				tape.set_strung(true)
			return true
		return false
	_left -= delta
	return false


func _process(delta: float) -> void:
	if not _strung and _has_source and (not is_instance_valid(_source) or _source.is_dead()):
		queue_free()
		return
	advance(delta)
	if is_done():
		queue_free()
