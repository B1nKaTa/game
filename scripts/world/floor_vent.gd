class_name FloorVent
extends Node2D

# A grate in the floor that flares on a steady rhythm. It glows and shows a warning ring before
# each flare, and a flare hurts whoever stands on it: Grandpa loses a pill, an enemy takes damage.
# A dodge passes through it, as with any hit. Bosses work the furnace and never feel it.
# Neighbouring vents take turns, and a floor boss can set every vent of its room to a pattern.
const GROUP := "floor_vents"
const PERIOD := 3.0
const WARN := 0.8
const FLARE := 0.5
const PLAYER_DAMAGE := 1
const ENEMY_DAMAGE := 20.0
# The flare covers a little less than the whole cell, so grazing its edge does not count.
const REACH := 13.0
const GRATE := Color("2a2523")
const GRATE_EDGE := Color("0f0c0b")
const SLOT := Color("120c0a")
const EMBER := Color("ff7a2a")
const WARN_FILL := Color(0.89, 0.32, 0.31)
const WARN_RING := Color("e4524f")
const FLAME_OUTER := Color("ff8a1f")
const FLAME_INNER := Color("fff1a8")
const GLOW_COLOR := Color(1.0, 0.55, 0.2)
const GLOW_REST := 0.15
const GLOW_FLARE := 1.1

var cycle := VentCycle.new(PERIOD, WARN, FLARE)
var _base_period := PERIOD
var _time := 0.0
# A floor boss's pattern overrides the rhythm for a while: a forced glow and flare, or a hold.
var _forced_warn := 0.0
var _forced_warn_total := 0.0
var _forced_flare := 0.0
var _held_left := 0.0
var _was_flaring := false
var _hit := {}
var _overlay: Node2D
var _glow: PointLight2D


# Neighbours alternate: a cell on the other colour of a checkerboard flares half a period later.
static func offset_for(cell: Vector2i, period: float) -> float:
	return period / 2.0 if posmod(cell.x + cell.y, 2) == 1 else 0.0


static func covers(center: Vector2, point: Vector2) -> bool:
	return absf(point.x - center.x) <= REACH and absf(point.y - center.y) <= REACH


static func touches(center: Vector2, body: Rect2) -> bool:
	return Rect2(center - Vector2(REACH, REACH), Vector2(REACH, REACH) * 2.0).intersects(body)


func setup(cell: Vector2i) -> void:
	cycle.offset = offset_for(cell, PERIOD)


func _ready() -> void:
	add_to_group(GROUP)
	z_index = -9
	_overlay = Overlay.new()
	_overlay.vent = self
	_overlay.z_as_relative = false
	_overlay.z_index = Projectile.SHOT_Z
	add_child(_overlay)
	_glow = Lighting.make_light(GLOW_COLOR, GLOW_REST, 0.5)
	add_child(_glow)


class Overlay extends Node2D:
	var vent: FloorVent

	func _draw() -> void:
		vent._draw_overlay(self)


# A floor boss's second phase makes the room's vents flare more often.
func set_period_scale(scale_factor: float) -> void:
	cycle.period = _base_period * scale_factor


# The vent glows for warn seconds, flares for flare seconds, then starts its rhythm afresh.
func force_flare(warn_time: float, flare_time: float) -> void:
	_held_left = 0.0
	_forced_warn = warn_time
	_forced_warn_total = warn_time
	_forced_flare = flare_time
	_restart_hit_list()


# The vent stays cold for a while, then starts its rhythm afresh.
func hold(seconds: float) -> void:
	_forced_warn = 0.0
	_forced_flare = 0.0
	_held_left = seconds


func state() -> int:
	if _forced_warn > 0.0:
		return VentCycle.WARN
	if _forced_flare > 0.0:
		return VentCycle.FLARE
	if _held_left > 0.0:
		return VentCycle.IDLE
	return cycle.state_at(_time)


func is_flaring() -> bool:
	return state() == VentCycle.FLARE


func is_warning() -> bool:
	return state() == VentCycle.WARN


# How far the glow has filled, from 0 as it starts to 1 as the flare comes.
func warn_progress() -> float:
	if _forced_warn > 0.0:
		return clampf(1.0 - _forced_warn / maxf(_forced_warn_total, 0.001), 0.0, 1.0)
	return cycle.warn_progress(_time)


func _physics_process(delta: float) -> void:
	if _forced_warn > 0.0:
		_forced_warn -= delta
	elif _forced_flare > 0.0:
		_forced_flare -= delta
		if _forced_flare <= 0.0:
			_restart_rhythm()
	elif _held_left > 0.0:
		_held_left -= delta
		if _held_left <= 0.0:
			_restart_rhythm()
	else:
		_time += delta
	var flaring := is_flaring()
	if flaring and not _was_flaring:
		_restart_hit_list()
	_was_flaring = flaring
	if flaring:
		_burn()
	_glow.energy = GLOW_FLARE if flaring else (GLOW_REST + 0.6 * warn_progress() if is_warning() else GLOW_REST)
	_overlay.queue_redraw()


# Picks the rhythm up again from its start, so a forced flare is never followed by a second one at once.
func _restart_rhythm() -> void:
	_time = cycle.offset


func _restart_hit_list() -> void:
	_hit.clear()


func _burn() -> void:
	if not is_inside_tree():
		return
	for player in get_tree().get_nodes_in_group("player"):
		var id: int = player.get_instance_id()
		if _hit.has(id) or not player.has_method("feet"):
			continue
		if covers(global_position, player.feet().global_position) and player.take_hit(PLAYER_DAMAGE):
			_hit[id] = true
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var id: int = enemy.get_instance_id()
		if _hit.has(id) or enemy.is_dead() or enemy.def.is_boss or enemy.submerged:
			continue
		if touches(global_position, enemy.body_rect()):
			_hit[id] = true
			enemy.take_damage(ENEMY_DAMAGE, Vector2.ZERO)


func _draw() -> void:
	var half := RoomBackdrop.TILE / 2.0 - 3.0
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), GRATE)
	for i in 4:
		var y := -half + 4.0 + i * 6.5
		draw_rect(Rect2(-half + 3.0, y, half * 2.0 - 6.0, 3.0), SLOT)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), GRATE_EDGE, false, 2.0)
	draw_rect(Rect2(-half + 4.0, -2.0, 3.0, 2.0), Color(EMBER, 0.5))


func _draw_overlay(layer: Node2D) -> void:
	match state():
		VentCycle.WARN:
			var fill := warn_progress()
			var size := REACH * 2.0
			layer.draw_rect(Rect2(-REACH, -REACH, size, size), Color(WARN_FILL, 0.15 + 0.35 * fill))
			layer.draw_rect(Rect2(-REACH, -REACH, size, size), WARN_RING, false, 2.0)
		VentCycle.FLARE:
			var wobble := sin(Time.get_ticks_msec() / 45.0 + position.x) * 2.0
			var outer := PackedVector2Array([Vector2(-REACH, REACH), Vector2(-REACH + 2.0, -4.0), Vector2(-5.0, -REACH - 10.0 + wobble), Vector2(0.0, -REACH - 4.0), Vector2(6.0, -REACH - 12.0 - wobble), Vector2(REACH - 2.0, -4.0), Vector2(REACH, REACH)])
			layer.draw_colored_polygon(outer, Color(FLAME_OUTER, 0.85))
			var inner := PackedVector2Array([Vector2(-7.0, REACH - 2.0), Vector2(-5.0, -2.0), Vector2(0.0, -REACH + wobble), Vector2(5.0, -2.0), Vector2(7.0, REACH - 2.0)])
			layer.draw_colored_polygon(inner, FLAME_INNER)
