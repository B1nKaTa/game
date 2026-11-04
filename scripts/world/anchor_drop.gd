class_name AnchorDrop
extends Node2D

# The Commodore's anchor, dropped from the davits onto a warned spot. It is the heaviest attack of his
# fight, so its mark is the clearest: a red circle fills for the whole windup, a second ring stands
# outside the first, and the anchor's shadow grows over the spot as it falls. When it lands it breaks
# props and costs three pills if Grandpa's feet are inside. It comes to nothing if he falls first.
const COLOR := Color("e4524f")
const RADIUS := 46.0
const RING_GAP := 8.0
const SHADOW := Color(0.02, 0.03, 0.06)
const IRON := Color("3c4250")
const IRON_EDGE := Color("12151c")
const CHAIN := Color("8a8f98")
const DROP_HEIGHT := 90.0
const SPLASH_SHOW := 0.3

var _source: Enemy
var _warning := 1.2
var _left := 1.2
var _landed := false
var _show_left := SPLASH_SHOW
var _damage := -1


func setup(source: Enemy, warning: float, damage := -1) -> void:
	_source = source
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func damage() -> int:
	return _damage


# How far the warning has filled, from 0 to 1.
func fill() -> float:
	if _warning <= 0.0:
		return 1.0
	return clampf(1.0 - _left / _warning, 0.0, 1.0)


# True once, on the moment it lands.
func advance(delta: float) -> bool:
	if _landed:
		return false
	_left -= delta
	if _left <= 0.0:
		_landed = true
		return true
	return false


func _process(delta: float) -> void:
	queue_redraw()
	if _landed:
		_show_left -= delta
		if _show_left <= 0.0:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if advance(delta):
		_source.land_ground_strike(global_position, RADIUS, _damage)


func _draw() -> void:
	if _landed:
		var progress := 1.0 - maxf(_show_left, 0.0) / SPLASH_SHOW
		draw_arc(Vector2.ZERO, RADIUS * (0.6 + 0.6 * progress), 0.0, TAU, 32, Color(CHAIN, 1.0 - progress), 3.0)
		_draw_anchor(Vector2.ZERO, 1.0)
		return
	var filled := fill()
	draw_circle(Vector2.ZERO, RADIUS * filled, Color(COLOR, 0.15 + 0.3 * filled))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, COLOR, 2.0)
	# The second ring: this is the one attack that costs three pills.
	draw_arc(Vector2.ZERO, RADIUS + RING_GAP, 0.0, TAU, 32, COLOR, 2.0)
	draw_circle(Vector2.ZERO, RADIUS * 0.75 * filled, Color(SHADOW, 0.4 * filled))
	var drop := Vector2(0.0, -DROP_HEIGHT * (1.0 - filled))
	draw_line(drop + Vector2(0.0, -DROP_HEIGHT), drop + Vector2(0.0, -14.0), CHAIN, 2.0)
	_draw_anchor(drop, 0.7 + 0.3 * filled)


func _draw_anchor(at: Vector2, size: float) -> void:
	var s := 16.0 * size
	draw_line(at + Vector2(0.0, -s), at + Vector2(0.0, s * 0.8), IRON, 4.0)
	draw_line(at + Vector2(-s * 0.5, -s * 0.55), at + Vector2(s * 0.5, -s * 0.55), IRON, 3.0)
	draw_arc(at + Vector2(0.0, -s * 1.1), s * 0.25, 0.0, TAU, 10, IRON, 2.0)
	draw_arc(at + Vector2(0.0, s * 0.1), s * 0.8, 0.25, PI - 0.25, 12, IRON, 4.0)
	draw_arc(at + Vector2(0.0, s * 0.1), s * 0.8, 0.25, PI - 0.25, 12, IRON_EDGE, 1.0)
