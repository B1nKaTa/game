class_name TowerTiles
extends Node2D

# The Tower's falling ceiling, Sister Celestine's first card: a few cell-sized squares round Grandpa.
# Each square is marked by a red square that fills from its middle for the whole warning while the
# tile's shadow grows on it, then every tile falls at once: feet in a square at that moment cost a
# pill, once, and broken bits of tile lie a moment before they go. It lies at the room's origin, its
# squares in room coordinates, and comes to nothing if she falls first.
const COLOR := Color("e4524f")
const TILE := Color("d8cfb8")
const TILE_EDGE := Color("6d6252")
const TILE_DOTS := Color("a99f88")
const SHADOW := Color(0.0, 0.0, 0.0)
const DEBRIS_TIME := 0.45
# Feet this close outside a square still count, as the square is drawn with a thick edge.
const HIT_SPARE := 2.0
# The squares as a plan sees them: grown this much, hurting this long after the fall.
const ROUTE_SPARE := 3.0
const ROUTE_HIT_TIME := 0.05

var _source: Enemy
var _squares: Array[Rect2] = []
var _warning := 0.9
var _left := 0.9
var _fallen := false
var _debris_left := DEBRIS_TIME
var _damage := -1


# The square a cell's tile falls on.
static func square_of(cell: Vector2i) -> Rect2:
	var tile := float(RoomBackdrop.TILE)
	return Rect2(Vector2(cell) * tile, Vector2(tile, tile))


func setup(source: Enemy, cells: Array[Vector2i], warning: float, damage := -1) -> void:
	_source = source
	_squares.clear()
	for cell in cells:
		_squares.append(square_of(cell))
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func squares() -> Array[Rect2]:
	return _squares


func damage() -> int:
	return _damage


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)


func has_fallen() -> bool:
	return _fallen


# Whether it can still hurt anyone: once the tiles are down, it is spent.
func is_spent() -> bool:
	return _fallen


func covers(point: Vector2, margin := 0.0) -> bool:
	var local := point - global_position
	for square in _squares:
		if square.grow(margin).has_point(local):
			return true
	return false


# True once, on the moment the tiles fall.
func advance(delta: float) -> bool:
	if _fallen:
		_debris_left -= delta
		return false
	_left -= delta
	if _left <= 0.0:
		_fallen = true
		return true
	return false


# What it means for a point, for a simulated player: 2 in a square, 1 just beside one.
func threat_at(p: Vector2, strict: bool) -> int:
	if _fallen:
		return 0
	if covers(p, 8.0 if strict else HIT_SPARE + 1.0):
		return 2
	return 1 if covers(p, 18.0) else 0


func threat_imminent(p: Vector2) -> bool:
	return not _fallen and _left < 0.12 and covers(p, HIT_SPARE + 1.0)


# Its shapes for a plan made now: every square, hurting the moment the tiles fall.
func route_rects() -> Array:
	if _fallen:
		return []
	var shapes: Array = []
	for square in _squares:
		shapes.append([Rect2(square.position + global_position, square.size).grow(ROUTE_SPARE), Vector2(_left, _left + ROUTE_HIT_TIME)])
	return shapes


func _process(delta: float) -> void:
	queue_redraw()
	if _fallen:
		_debris_left -= delta
		if _debris_left <= 0.0:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if advance(delta) and is_instance_valid(_source.target) and covers(_source.target_ground(), HIT_SPARE):
		_source.hit_target(_source.attack_damage(_damage))


func _draw() -> void:
	if _fallen:
		# Broken bits of tile and a puff of plaster dust, fading.
		var fade := clampf(_debris_left / DEBRIS_TIME, 0.0, 1.0)
		for square in _squares:
			var middle := square.get_center()
			draw_circle(middle, square.size.x * 0.45 * (1.2 - fade * 0.2), Color(TILE, 0.25 * fade))
			for i in 5:
				var at := middle + Vector2.from_angle(i * 1.3 + 0.4) * (5.0 + i * 2.0)
				draw_rect(Rect2(at - Vector2(3.0, 2.0), Vector2(6.0, 4.0)), Color(TILE, fade))
				draw_rect(Rect2(at - Vector2(3.0, 2.0), Vector2(6.0, 4.0)), Color(TILE_EDGE, fade), false, 1.0)
		return
	var filled := fill()
	for square in _squares:
		var middle := square.get_center()
		draw_rect(square, Color(COLOR, 0.12 + 0.18 * filled))
		draw_rect(square.grow(-1.0), COLOR, false, 2.0)
		# The red fills out from the middle as the fall nears.
		var inner := Rect2(middle - square.size * filled * 0.5, square.size * filled)
		if inner.has_area():
			draw_rect(inner, Color(COLOR, 0.3))
		# The tile's shadow grows on the square, darker as it comes down.
		var shadow := square.size * (0.35 + 0.55 * filled)
		draw_rect(Rect2(middle - shadow * 0.5, shadow), Color(SHADOW, 0.15 + 0.3 * filled))
		# And the tile itself shows coming down in the last third.
		if filled > 0.66:
			var drop := (1.0 - filled) * 3.0 * 18.0
			var tile_rect := Rect2(middle - shadow * 0.5 - Vector2(0.0, drop), shadow)
			draw_rect(tile_rect, TILE)
			draw_rect(tile_rect, TILE_EDGE, false, 1.0)
			for i in 3:
				draw_rect(Rect2(tile_rect.position + Vector2(4.0 + i * 6.0, 5.0 + (i % 2) * 6.0), Vector2(2.0, 2.0)), TILE_DOTS)
