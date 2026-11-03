class_name ClosingRing
extends Node2D

# "Ho ho hold still": a ring around where Grandpa stood. While the Santa winds up it shows faintly at
# its full size, then it closes in, and its band costs pills to whoever it sweeps over. Whoever is
# still inside when it shuts is hurt too. It hurts once at most, and a dodge passes through its band,
# as through any hit. It comes to nothing if the Santa falls first.
const FROM := 120.0
const TO := 20.0
const CLOSE_TIME := 1.4
const WIDTH := 14.0
const SHUT_SHOW := 0.25
const COLOR := Color("e4524f")
const BAND := Color("ffe0a0")
const BAND_EDGE := Color("d93a3a")
const TINSEL := Color("7fd6c8")

var _source: Enemy
var _warning := 0.6
var _left := 0.6
var _closed_for := 0.0
var _damage := -1
var _has_hit := false
var _shut := false
var _shut_left := SHUT_SHOW


static func closing_radius(time: float) -> float:
	return lerpf(FROM, TO, clampf(time / CLOSE_TIME, 0.0, 1.0))


# Whether feet are caught: in the band as it closes, or anywhere inside once it has shut.
static func hits(center: Vector2, radius: float, width: float, feet: Vector2, shut: bool) -> bool:
	var distance := center.distance_to(feet)
	if shut:
		return distance <= radius + width / 2.0
	return absf(distance - radius) <= width / 2.0


func setup(source: Enemy, warning: float, damage := -1) -> void:
	_source = source
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func radius_now() -> float:
	return closing_radius(_closed_for)


func _process(delta: float) -> void:
	queue_redraw()
	if _shut:
		_shut_left -= delta
		if _shut_left <= 0.0:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead() or not is_instance_valid(_source.target):
		queue_free()
		return
	if _left > 0.0:
		_left -= delta
		return
	_closed_for += delta
	var done := _closed_for >= CLOSE_TIME
	if not _has_hit and hits(global_position, radius_now(), WIDTH, _source.target_ground(), done):
		var target := _source.target
		if target.has_method("take_hit") and target.take_hit(_source.attack_damage(_damage)):
			_has_hit = true
	if done:
		_shut = true


func _draw() -> void:
	if _left > 0.0:
		var filled := clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)
		draw_circle(Vector2.ZERO, FROM, Color(COLOR, 0.06 + 0.1 * filled))
		draw_arc(Vector2.ZERO, FROM, 0.0, TAU, 64, COLOR, 2.0)
		draw_arc(Vector2.ZERO, TO, 0.0, TAU, 24, Color(COLOR, 0.6), 1.0)
		return
	var radius := radius_now()
	var fade := clampf(_shut_left / SHUT_SHOW, 0.0, 1.0) if _shut else 1.0
	# Inside the band is where it will shut; outside it is safe.
	draw_circle(Vector2.ZERO, radius, Color(COLOR, 0.18 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(BAND, 0.9 * fade), WIDTH)
	draw_arc(Vector2.ZERO, radius + WIDTH / 2.0, 0.0, TAU, 64, Color(BAND_EDGE, fade), 2.0)
	draw_arc(Vector2.ZERO, radius - WIDTH / 2.0, 0.0, TAU, 64, Color(BAND_EDGE, fade), 2.0)
	for i in 12:
		var at := Vector2.from_angle(TAU * i / 12.0 + _closed_for * 2.0) * radius
		draw_circle(at, 2.0, Color(TINSEL, fade))
