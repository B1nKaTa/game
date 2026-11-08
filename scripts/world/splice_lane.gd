class_name SpliceLane
extends Node2D

# One lane of the Projectionist's splice: a strip of floor straight across the room, edged by two lengths
# of film with their sprocket holes. It fills red for its whole warning, and then the film snaps shut
# across it, the two edges slamming together; feet in the lane at that moment cost a pill, once. It lies
# at the room's origin and holds its strip in room space, and comes to nothing if he falls first.
const WIDTH := 36.0
const EDGE := 7.0
const SNAP_TIME := 0.08
const SHOW_TIME := 0.35
const COLOR := Color("e4524f")
const FILM := Color(0.07, 0.06, 0.05)
const FILM_EDGE := Color(0.32, 0.28, 0.2)
const SPROCKET := Color(0.78, 0.74, 0.62)
const FLASH := Color(1.0, 0.98, 0.9)

var _source: Enemy
var _strip := Rect2()
var _warning := 1.0
var _left := 1.0
var _snapped := false
var _show_left := SHOW_TIME
var _damage := -1


static func hits(strip: Rect2, feet: Vector2) -> bool:
	return strip.has_point(feet)


func setup(source: Enemy, strip: Rect2, warning: float, damage := -1) -> void:
	_source = source
	_strip = strip
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func strip() -> Rect2:
	return _strip


func has_snapped() -> bool:
	return _snapped


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)


# When, counted from now, it hurts: the moment it snaps. (-1, -1) once it has.
func danger_window() -> Vector2:
	if _snapped:
		return Vector2(-1.0, -1.0)
	return Vector2(_left, _left + SNAP_TIME)


func route_rects() -> Array:
	return [] if _snapped else [[_strip, danger_window()]]


# True once, on the moment it snaps.
func advance(delta: float) -> bool:
	if _snapped:
		_show_left -= delta
		return false
	_left -= delta
	if _left <= 0.0:
		_snapped = true
		return true
	return false


func is_finished() -> bool:
	return _snapped and _show_left <= 0.0


func threat_at(p: Vector2, strict: bool) -> int:
	if _snapped:
		return 0
	return 2 if _strip.grow(12.0 if strict else 4.0).has_point(p) else 0


func threat_imminent(p: Vector2) -> bool:
	return not _snapped and _left < 0.12 and _strip.grow(4.0).has_point(p)


func _process(delta: float) -> void:
	queue_redraw()
	if not _snapped and (not is_instance_valid(_source) or _source.is_dead()):
		queue_free()
		return
	if advance(delta) and is_instance_valid(_source) and is_instance_valid(_source.target):
		if hits(_strip, _source.target_ground()):
			_source.target.take_hit(_source.attack_damage(_damage))
	if is_finished():
		queue_free()


func _draw() -> void:
	var strip := Rect2(_strip.position - global_position, _strip.size)
	var across_x := strip.size.x < strip.size.y
	if not _snapped:
		var progress := fill()
		# The red strip only with Attack warnings on (AttackWarnings); otherwise the faint cue between the
		# two lengths of film, which always show.
		if AttackWarnings.drawn_by(_source):
			draw_rect(strip, Color(COLOR, 0.2 + 0.35 * progress))
			draw_rect(strip, COLOR, false, 2.0)
		else:
			AttackWarnings.draw_cue_rect(self, strip, progress)
		_draw_film(strip, across_x, 0.0)
		return
	# The film slams shut, then the flash of the splice fades.
	var shown := clampf(_show_left / SHOW_TIME, 0.0, 1.0)
	var closing := clampf((SHOW_TIME - _show_left) / SNAP_TIME, 0.0, 1.0)
	draw_rect(strip, Color(FLASH, 0.55 * shown))
	_draw_film(strip, across_x, closing, shown)


# The two lengths of film along the lane's long sides, moved in toward the middle by closing (0 to 1).
func _draw_film(strip: Rect2, across_x: bool, closing: float, alpha := 1.0) -> void:
	var gap := (strip.size.x if across_x else strip.size.y) / 2.0 - EDGE
	var shift := gap * closing
	for side in [-1.0, 1.0]:
		var band: Rect2
		if across_x:
			var x: float = strip.position.x + (0.0 if side < 0.0 else strip.size.x - EDGE) - side * shift
			band = Rect2(x, strip.position.y, EDGE, strip.size.y)
		else:
			var y: float = strip.position.y + (0.0 if side < 0.0 else strip.size.y - EDGE) - side * shift
			band = Rect2(strip.position.x, y, strip.size.x, EDGE)
		draw_rect(band, Color(FILM, 0.95 * alpha))
		draw_rect(band, Color(FILM_EDGE, alpha), false, 1.0)
		var length := band.size.y if across_x else band.size.x
		var at := 3.0
		while at < length - 3.0:
			var hole := Rect2(band.position + (Vector2(2.5, at) if across_x else Vector2(at, 2.5)), Vector2(2.0, 2.0))
			draw_rect(hole, Color(SPROCKET, alpha))
			at += 6.0
