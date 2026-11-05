class_name LaneDrop
extends Node2D

# A warned strip of floor, straight along a row or a column of the room. A faint outline shows it is
# coming, it fills red for its whole warning, and then it lands: a flurry of falling memos, or a bar of
# a bar chart rising out of the floor and standing a moment before it sinks. Grandpa's feet in the
# strip while it lands, or while a bar stands, cost a pill, once. It comes to nothing if the boss who
# called it falls first. It lies at the room's origin and holds its strip in room space.
const COLOR := Color("e4524f")
const WAITING_ALPHA := 0.35
const SHOW_TIME := 0.3
const LOOK_MEMOS := "memos"
const LOOK_BAR := "bar"
const MEMO := Color("f4efe0")
const MEMO_EDGE := Color("8e8878")
const BAR := Color("3b7dd8")
const BAR_TOP := Color("9fd0ff")
const BAR_EDGE := Color("0d1a2b")

var _source: Enemy
var _strip := Rect2()
var _delay := 0.0
var _warning := 1.0
var _left := 1.0
var _stand := 0.0
var _stand_left := 0.0
var _show_left := SHOW_TIME
var _landed := false
var _has_hit := false
var _damage := -1
var _look := LOOK_MEMOS


static func hits(strip: Rect2, feet: Vector2) -> bool:
	return strip.has_point(feet)


# A delay lets several strips land one after another. A bar stands for stand seconds once up.
func setup(source: Enemy, strip: Rect2, warning: float, delay := 0.0, stand := 0.0, damage := -1, look := LOOK_MEMOS) -> void:
	_source = source
	_strip = strip
	_warning = warning
	_left = warning
	_delay = delay
	_stand = stand
	_damage = damage
	_look = look
	z_index = Projectile.SHOT_Z


func strip() -> Rect2:
	return _strip


func look() -> String:
	return _look


func has_landed() -> bool:
	return _landed


func is_waiting() -> bool:
	return _delay > 0.0


# Whether landing, or a standing bar, would hurt someone whose feet are at point: a bar while it
# stands, memos only on the moment they land.
func hurts_at(point: Vector2) -> bool:
	var hurting := _stand_left > 0.0 if _stand > 0.0 else _show_left >= SHOW_TIME
	return _landed and hurting and hits(_strip, point)


func fill() -> float:
	if _delay > 0.0 or _warning <= 0.0:
		return 0.0
	return clampf(1.0 - _left / _warning, 0.0, 1.0)


# When, counted from now, the strip can hurt: x its start and y its end, or (-1, -1) once it never
# will again. Memos hurt on the moment they land, a bar for as long as it stands.
func danger_window() -> Vector2:
	if not _landed:
		var lands := maxf(_delay, 0.0) + maxf(_left, 0.0)
		return Vector2(lands, lands + maxf(_stand, 0.02))
	if _stand_left > 0.0 and not _has_hit:
		return Vector2(0.0, _stand_left)
	return Vector2(-1.0, -1.0)


func is_finished() -> bool:
	return _landed and _stand_left <= 0.0 and _show_left <= 0.0


# Runs the delay, the warning, the stand and the show. True once, on the moment it lands.
func advance(delta: float) -> bool:
	if not _landed:
		if _delay > 0.0:
			_delay -= delta
			return false
		_left -= delta
		if _left <= 0.0:
			_landed = true
			_stand_left = _stand
			return true
		return false
	if _stand_left > 0.0:
		_stand_left -= delta
		return false
	_show_left -= delta
	return false


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	var landed_now := advance(delta)
	if (landed_now or _stand_left > 0.0) and not _has_hit and is_instance_valid(_source.target):
		if hits(_strip, _source.target_ground()) and _source.target.take_hit(_source.attack_damage(_damage)):
			_has_hit = true
	if is_finished():
		queue_free()


func _draw() -> void:
	var strip_at := Rect2(_strip.position - global_position, _strip.size)
	if not _landed:
		if _delay > 0.0:
			draw_rect(strip_at, Color(COLOR, WAITING_ALPHA), false, 1.0)
			return
		var filled := fill()
		draw_rect(strip_at, Color(COLOR, 0.15 + 0.3 * filled))
		draw_rect(strip_at, COLOR, false, 2.0)
		return
	if _look == LOOK_BAR:
		# The bar stands full height while up, then sinks back into the floor.
		var height := 1.0 if _stand_left > 0.0 else clampf(_show_left / SHOW_TIME, 0.0, 1.0)
		var bar := Rect2(strip_at.position + Vector2(4.0, strip_at.size.y * (1.0 - height)), Vector2(strip_at.size.x - 8.0, strip_at.size.y * height))
		draw_rect(bar, Color(BAR, 0.8))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x, minf(6.0, bar.size.y))), BAR_TOP)
		draw_rect(bar, BAR_EDGE, false, 2.0)
		return
	# Memos flutter down over the strip and settle.
	var settle := 1.0 - clampf(_show_left / SHOW_TIME, 0.0, 1.0)
	var count := maxi(int(strip_at.size.x * strip_at.size.y / 900.0), 3)
	for i in count:
		var spot := strip_at.position + Vector2(fposmod(i * 37.0, strip_at.size.x), fposmod(i * 53.0, strip_at.size.y))
		spot.y += settle * 6.0
		draw_set_transform(spot, 0.3 * float(i % 5) - 0.6)
		draw_rect(Rect2(-4, -5, 8, 10), Color(MEMO, 1.0 - settle * 0.6))
		draw_rect(Rect2(-4, -5, 8, 10), Color(MEMO_EDGE, 1.0 - settle * 0.6), false, 1.0)
	draw_set_transform(Vector2.ZERO)
