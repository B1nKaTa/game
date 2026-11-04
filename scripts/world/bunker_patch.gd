class_name BunkerPatch
extends Node2D

# Sand a floor boss spreads over warned patches of the course. First each cell shows a warning that
# fills, edged in red, so Grandpa can walk off it in time. Then the cells turn to sand for a while,
# which slows and stops dodges as any bunker does, and at last the sand is raked away and the patch
# takes itself up. It lies at the room's origin, with each cell at its own cell's middle. A warning comes
# to nothing if the boss that spread it falls first, and laid sand stays for its time, as it never hurts.
const WARNING := 1.0
const LAST := 8.0
const COLOR := Color("e4524f")
# What advance reports.
enum { NOTHING, LAID, RAKED }

var _cells: Array[Vector2i] = []
var _warning := WARNING
var _warning_left := WARNING
var _left := LAST
var _laid := false
var _palette: RoomPalette
var _source: Enemy
var _has_source := false


func setup(cells: Array[Vector2i], warning: float, seconds: float, palette: RoomPalette = null, source: Enemy = null) -> void:
	_cells = cells
	_warning = warning
	_warning_left = warning
	_left = seconds
	_palette = palette if palette != null else RoomPalette.new()
	_source = source
	_has_source = source != null
	# The warning draws above the room with every other mark, and the sand under everyone once laid.
	z_index = Projectile.SHOT_Z


func cells() -> Array[Vector2i]:
	return _cells


func is_laid() -> bool:
	return _laid


# Moves the patch's clock on: LAID once, the moment the sand goes down, and RAKED once, as it goes.
func advance(delta: float) -> int:
	if not _laid:
		_warning_left -= delta
		if _warning_left <= 0.0:
			_laid = true
			return LAID
		return NOTHING
	if _left <= 0.0:
		return NOTHING
	_left -= delta
	return RAKED if _left <= 0.0 else NOTHING


func sand_traps() -> Array:
	var traps: Array = []
	for child in get_children():
		if child is SandTrap:
			traps.append(child)
	return traps


func lay() -> void:
	z_index = 0
	for cell in _cells:
		var sand := SandTrap.new()
		sand.palette = _palette
		sand.position = RoomBackdrop.cell_center(cell)
		add_child(sand)
	queue_redraw()


func _process(delta: float) -> void:
	if not _laid and _has_source and (not is_instance_valid(_source) or _source.is_dead()):
		queue_free()
		return
	match advance(delta):
		LAID:
			lay()
		RAKED:
			queue_free()
	if not _laid:
		queue_redraw()


func _draw() -> void:
	if _laid:
		return
	var filled := clampf(1.0 - _warning_left / maxf(_warning, 0.01), 0.0, 1.0)
	var tile := float(RoomBackdrop.TILE)
	for cell in _cells:
		var rect := Rect2(Vector2(cell) * tile, Vector2(tile, tile)).grow(-2.0)
		draw_rect(rect, Color(COLOR, 0.1 + 0.3 * filled))
		draw_rect(rect, COLOR, false, 2.0)
		# A few grains already show where the sand will lie.
		for spot in SandTrap.grain_spots(cell, 5):
			draw_rect(Rect2(RoomBackdrop.cell_center(cell) + spot * filled, Vector2(2, 2)), _palette.sand_grain)
