class_name GroundStrike
extends Node2D

# A warned spot on the ground. A faint ring shows it is coming, a red circle fills for its whole
# warning, and then it lands: it breaks props and hurts Grandpa if his feet are inside. It comes
# to nothing if the boss that started it falls first. A strike that lingers leaves burning ground,
# which keeps hurting whoever stands in it, each body at most once per BURN_EVERY, until it burns out.
# It says when it lands, so an attack can leave something behind, such as a wet floor or a burst of shots.
signal landed(at: Vector2)

const COLOR := Color("e4524f")
const FOLLOW_COLOR := Color("ffd24a")
const DUST_COLOR := Color("b9a97a")
const SHOW_TIME := 0.2
const WAITING_ALPHA := 0.35
const BURN_EVERY := 0.6
const BURN_PLAYER_DAMAGE := 1
const BURN_ENEMY_DAMAGE := 10.0
const BURN_FADE := 0.4
const FIRE_OUTER := Color(1.0, 0.5, 0.08, 0.5)
const FIRE_INNER := Color(1.0, 0.85, 0.3, 0.75)
const FIRE_EDGE := Color("ffb02e")
const EMBER := Color("fff4c0")
const COAL := Color("1c1614")
const COAL_GLOW := Color("ff8a2a")
const THROW_ARC := 28.0
# What lands and what it leaves: a lump of coal that burns, or a thorny wreath that leaves a ring of
# thorns. Both hurt the same way.
const LOOK_COAL := "coal"
const LOOK_THORNS := "thorns"
# A coffin slammed down from above: the heaviest attack, so its mark is the clearest. A second ring
# stands outside the first and the coffin's shadow grows over the spot as it falls.
const LOOK_CASKET := "casket"
const CASKET_RING_GAP := 8.0
const CASKET_SHADOW := Color(0.05, 0.02, 0.03)
const CASKET_WOOD := Color("4a2a1c")
# A fountain jet bursting up out of the floor: the dust of its landing is spray.
const LOOK_SPLASH := "splash"
const SPLASH_COLOR := Color(0.6, 0.85, 1.0)
const WREATH := Color("3f6b34")
const WREATH_BLOOM := Color("d9576b")
const THORN := Color("2c4a24")
const THORN_TIP := Color("a7c48a")

var _source: Enemy
var _radius := 20.0
var _delay := 0.0
var _follow_left := 0.0
var _warning := 0.5
var _left := 0.5
var _landed := false
var _show_left := SHOW_TIME
# What landing costs Grandpa. -1 means the enemy's usual damage.
var _damage := -1
var _linger := 0.0
var _burn_left := 0.0
# When each body standing in the fire may be hurt again, by instance id.
var _burn_wait := {}
# Where a thrown lump of coal left from, drawn flying in over the warning. Unset means nothing is thrown.
var _thrown_from := Vector2.INF
var _look := LOOK_COAL


static func hits(center: Vector2, radius: float, feet: Vector2) -> bool:
	return center.distance_to(feet) <= radius


# Whether a body standing in burning ground is hurt now, given how long until it may be hurt again.
static func burns(center: Vector2, radius: float, point: Vector2, wait_left: float) -> bool:
	return wait_left <= 0.0 and hits(center, radius, point)


# A delay lets a line or a row land one after another. A pit follows him for follow_time before locking in.
func setup(source: Enemy, radius: float, warning: float, delay := 0.0, follow_time := 0.0, damage := -1, linger := 0.0) -> void:
	_source = source
	# Marks show above the room, the dark of Lights Out included.
	z_index = Projectile.SHOT_Z
	_radius = radius
	_warning = warning
	_left = warning
	_delay = delay
	_follow_left = follow_time
	_damage = damage
	_linger = linger


func throw_from(point: Vector2) -> void:
	_thrown_from = point


func set_look(kind: String) -> void:
	_look = kind


func look() -> String:
	return _look


func damage() -> int:
	return _damage


func linger() -> float:
	return _linger


func is_following() -> bool:
	return _follow_left > 0.0


func is_burning() -> bool:
	return _landed and _burn_left > 0.0


func radius() -> float:
	return _radius


# How far the warning has filled, from 0 to 1.
func fill() -> float:
	if _delay > 0.0 or _follow_left > 0.0 or _warning <= 0.0:
		return 0.0
	return clampf(1.0 - _left / _warning, 0.0, 1.0)


# True once, on the moment it lands.
func advance(delta: float) -> bool:
	if _landed:
		return false
	if _delay > 0.0:
		_delay -= delta
		return false
	if _follow_left > 0.0:
		_follow_left -= delta
		return false
	_left -= delta
	if _left <= 0.0:
		_landed = true
		_burn_left = _linger
		return true
	return false


# Counts down how long each body must wait before the fire may hurt it again.
func tick_burn(delta: float) -> void:
	_burn_left -= delta
	for id in _burn_wait.keys():
		_burn_wait[id] -= delta


func burn_wait_of(id: int) -> float:
	return _burn_wait.get(id, 0.0)


func mark_burned(id: int) -> void:
	_burn_wait[id] = BURN_EVERY


func _process(delta: float) -> void:
	queue_redraw()
	if _landed:
		if _burn_left > 0.0:
			_burn(delta)
			return
		_show_left -= delta
		if _show_left <= 0.0:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if is_following():
		global_position = _source.target_ground()
	if advance(delta):
		_source.land_ground_strike(global_position, _radius, _damage)
		landed.emit(global_position)
		# Whoever the landing just hurt is not burned again at once.
		if _linger > 0.0 and is_instance_valid(_source.target):
			mark_burned(_source.target.get_instance_id())


# Burning ground goes out early when the enemy that made it falls, as a warning that never landed does.
func _burn(delta: float) -> void:
	tick_burn(delta)
	if not is_instance_valid(_source) or _source.is_dead():
		_burn_left = minf(_burn_left, BURN_FADE)
		_show_left = 0.0
		return
	var target := _source.target
	if is_instance_valid(target):
		var id := target.get_instance_id()
		if burns(global_position, _radius, _source.target_ground(), burn_wait_of(id)) and target.take_hit(BURN_PLAYER_DAMAGE):
			mark_burned(id)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var id: int = enemy.get_instance_id()
		if enemy.is_dead() or enemy.def.is_boss or enemy.submerged:
			continue
		if burns(global_position, _radius, enemy.global_position, burn_wait_of(id)):
			mark_burned(id)
			enemy.take_damage(BURN_ENEMY_DAMAGE, Vector2.ZERO)


func _draw() -> void:
	if _landed and _burn_left > 0.0:
		if _look == LOOK_THORNS:
			_draw_thorns()
		else:
			_draw_fire()
		return
	if _landed:
		var progress := 1.0 - maxf(_show_left, 0.0) / SHOW_TIME
		var dust := SPLASH_COLOR if _look == LOOK_SPLASH else DUST_COLOR
		draw_circle(Vector2.ZERO, _radius * minf(0.6 + progress, 1.0), Color(dust, 0.7 * (1.0 - progress)))
		if _look == LOOK_SPLASH:
			for i in 6:
				var way := Vector2.from_angle(TAU * i / 6.0 + 0.3)
				draw_line(way * _radius * 0.3, way * _radius * (0.5 + progress), Color(SPLASH_COLOR, 1.0 - progress), 2.0)
		if _look == LOOK_CASKET:
			_draw_coffin(1.0, CASKET_WOOD, 1.0 - progress)
		return
	if _delay > 0.0:
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, Color(COLOR, WAITING_ALPHA), 1.0)
		return
	if is_following():
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, FOLLOW_COLOR, 2.0)
		draw_line(Vector2(-6, 0), Vector2(6, 0), FOLLOW_COLOR, 1.0)
		draw_line(Vector2(0, -6), Vector2(0, 6), FOLLOW_COLOR, 1.0)
		return
	var filled := fill()
	draw_circle(Vector2.ZERO, _radius * filled, Color(COLOR, 0.15 + 0.3 * filled))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, COLOR, 2.0)
	if _look == LOOK_CASKET:
		draw_arc(Vector2.ZERO, _radius + CASKET_RING_GAP, 0.0, TAU, 32, COLOR, 2.0)
		_draw_coffin(0.3 + 0.7 * filled, CASKET_SHADOW, 0.25 + 0.5 * filled)
	if _thrown_from != Vector2.INF:
		var start := _thrown_from - global_position
		var at := start.lerp(Vector2.ZERO, filled) + Vector2(0.0, -sin(filled * PI) * THROW_ARC)
		if _look == LOOK_THORNS:
			draw_arc(at, 5.0, 0.0, TAU, 12, WREATH, 3.0)
			draw_circle(at + Vector2(0, -5), 1.5, WREATH_BLOOM)
		else:
			draw_circle(at, 4.0, COAL_GLOW)
			draw_circle(at, 3.0, COAL)


# A coffin's outline across the spot, at a share of its full size.
func _draw_coffin(size: float, color: Color, alpha: float) -> void:
	var r := _radius * 0.9 * size
	var shape := PackedVector2Array([Vector2(-r * 0.35, -r), Vector2(r * 0.35, -r), Vector2(r * 0.5, -r * 0.45), Vector2(r * 0.3, r), Vector2(-r * 0.3, r), Vector2(-r * 0.5, -r * 0.45)])
	draw_colored_polygon(shape, Color(color, alpha))
	draw_polyline(shape + PackedVector2Array([shape[0]]), Color(0, 0, 0, alpha), 1.0)


# A ring of thorns reads as brambles, never as a warning: a dark green ring bristling with spikes.
func _draw_thorns() -> void:
	var fade := clampf(_burn_left / BURN_FADE, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius, Color(THORN, 0.25 * fade))
	draw_arc(Vector2.ZERO, _radius * 0.85, 0.0, TAU, 28, Color(THORN, 0.9 * fade), 4.0)
	for i in 14:
		var way := Vector2.from_angle(TAU * i / 14.0 + 0.2 * (i % 2))
		var base := way * _radius * 0.85
		var tip := base + way.rotated(0.5 if i % 2 == 0 else -0.5) * 6.0
		draw_line(base, tip, Color(THORN_TIP, fade), 1.0)
	for i in 3:
		draw_circle(Vector2.from_angle(TAU * i / 3.0 + 0.6) * _radius * 0.85, 2.0, Color(WREATH_BLOOM, fade))


# Burning ground reads as fire, never as a warning: a flickering orange pool with a bright rim and embers.
func _draw_fire() -> void:
	var fade := clampf(_burn_left / BURN_FADE, 0.0, 1.0)
	var t := Time.get_ticks_msec() / 1000.0
	var flicker := 0.85 + 0.15 * sin(t * 13.0 + position.x)
	draw_circle(Vector2.ZERO, _radius, Color(FIRE_OUTER, FIRE_OUTER.a * fade * flicker))
	draw_circle(Vector2.ZERO, _radius * 0.55, Color(FIRE_INNER, FIRE_INNER.a * fade * flicker))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, Color(FIRE_EDGE, fade), 1.5)
	for i in 5:
		var angle := TAU * i / 5.0 + t * 0.7
		var lift := fposmod(t * 1.6 + i * 0.37, 1.0)
		var at := Vector2.from_angle(angle) * _radius * 0.6 + Vector2(0.0, -lift * 8.0)
		draw_circle(at, 1.5, Color(EMBER, fade * (1.0 - lift)))
