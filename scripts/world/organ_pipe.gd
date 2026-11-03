class_name OrganPipe
extends Node2D

# A rank of organ pipes set in the room's wall. It plays a chord on a steady beat, glowing before
# each one, and every chord sends a ring into the room that pushes Grandpa and enemies away from the
# wall. The ring does no damage, and neighbouring pipes take turns. A floor boss can make every pipe
# of his room glow and chord at once in a pattern of his own, with rings of his chosen reach.
const PERIOD := 3.2
const GLOW := 0.8
const WOOD := Color("3b2418")
const WOOD_EDGE := Color("1a0f0a")
const BRASS := Color("c9a25a")
const BRASS_DARK := Color("6e5228")
const GLOW_FILL := Color(1.0, 0.82, 0.5)
const GLOW_RING := Color(0.95, 0.6, 0.95)
const LIGHT_COLOR := Color(1.0, 0.78, 0.55)
const LIGHT_REST := 0.15
const LIGHT_CHORD := 1.0

var beat := PipeBeat.new(PERIOD, GLOW)
var inward := Vector2.DOWN
var _time := 0.0
# A floor boss's crescendo: a glow of its own length, then one chord with its own reach and damage.
var _forced_glow := 0.0
var _forced_glow_total := 0.0
var _forced_reach := PipeRing.REACH
var _forced_damage := 0
var _held_left := 0.0
var _overlay: Node2D
var _light: PointLight2D


# Neighbours alternate: a cell on the other colour of a checkerboard chords half a period later.
static func offset_for(cell: Vector2i, period: float) -> float:
	return period / 2.0 if posmod(cell.x + cell.y, 2) == 1 else 0.0


func setup(cell: Vector2i, inward_way: Vector2) -> void:
	beat.offset = offset_for(cell, PERIOD)
	inward = inward_way


func _ready() -> void:
	z_index = -9
	_overlay = Overlay.new()
	_overlay.pipe = self
	_overlay.z_as_relative = false
	_overlay.z_index = Projectile.SHOT_Z
	add_child(_overlay)
	_light = Lighting.make_light(LIGHT_COLOR, LIGHT_REST, 0.6)
	_light.position = inward * 12.0
	add_child(_light)


class Overlay extends Node2D:
	var pipe: OrganPipe

	func _draw() -> void:
		pipe._draw_overlay(self)


# Glows for glow_time, then chords once with a ring of the given reach and damage, then picks its
# own beat up again from the start, so a forced chord is never followed by a second one at once.
func force_chord(glow_time: float, reach: float, damage: int) -> void:
	_held_left = 0.0
	_forced_glow = maxf(glow_time, 0.01)
	_forced_glow_total = _forced_glow
	_forced_reach = reach
	_forced_damage = damage


func is_forced() -> bool:
	return _forced_glow > 0.0


# Stays quiet for a while, through its own chords, then picks its beat up again from the start.
func hold(seconds: float) -> void:
	_forced_glow = 0.0
	_held_left = seconds


# A crescendo that never chords, as when the boss who called it falls first.
func cancel_force() -> void:
	if _forced_glow > 0.0:
		_forced_glow = 0.0
		_time = beat.offset


func state() -> int:
	if _forced_glow > 0.0:
		return PipeBeat.GLOW
	if _held_left > 0.0:
		return PipeBeat.QUIET
	return beat.state_at(_time)


func glow_progress() -> float:
	if _forced_glow > 0.0:
		return clampf(1.0 - _forced_glow / maxf(_forced_glow_total, 0.001), 0.0, 1.0)
	return beat.glow_progress(_time)


# Where the ring starts: the face of the wall, on the room's side.
func ring_origin() -> Vector2:
	return global_position + inward * RoomBackdrop.TILE * 0.5


func _physics_process(delta: float) -> void:
	if _forced_glow > 0.0:
		_forced_glow -= delta
		if _forced_glow <= 0.0:
			_send_ring(_forced_reach, _forced_damage)
			_time = beat.offset
	elif _held_left > 0.0:
		_held_left -= delta
		if _held_left <= 0.0:
			_time = beat.offset
	else:
		var before := _time
		_time += delta
		if beat.chords_between(before, _time) > 0:
			_send_ring(PipeRing.REACH, 0)
	var glowing := state() == PipeBeat.GLOW
	_light.energy = LIGHT_CHORD if state() == PipeBeat.CHORD else (LIGHT_REST + 0.6 * glow_progress() if glowing else LIGHT_REST)
	_overlay.queue_redraw()


func _send_ring(reach: float, damage: int) -> void:
	var parent := get_parent()
	if parent == null or not is_inside_tree():
		return
	var ring := PipeRing.new()
	ring.setup(inward, reach, PipeRing.GROW_TIME * reach / PipeRing.REACH, damage)
	parent.add_child(ring)
	ring.global_position = ring_origin()


func _draw() -> void:
	# Three pipes of a rank, longest in the middle, standing in a dark wooden case.
	var half := RoomBackdrop.TILE / 2.0
	draw_set_transform(Vector2.ZERO, inward.angle() - PI / 2.0)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), WOOD)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), WOOD_EDGE, false, 2.0)
	var lengths := [20.0, 26.0, 20.0]
	for i in 3:
		var x := -9.0 + i * 9.0
		var length: float = lengths[i]
		var top := half - 2.0 - length
		draw_rect(Rect2(x - 3.0, top, 6.0, length), BRASS)
		draw_rect(Rect2(x - 3.0, top, 2.0, length), BRASS.lightened(0.25))
		draw_rect(Rect2(x - 3.0, top + length * 0.6, 6.0, 3.0), BRASS_DARK)
	draw_set_transform(Vector2.ZERO)


func _draw_overlay(layer: Node2D) -> void:
	var at := inward * RoomBackdrop.TILE * 0.5
	match state():
		PipeBeat.GLOW:
			var fill := glow_progress()
			layer.draw_circle(at, 6.0 + 6.0 * fill, Color(GLOW_FILL, 0.25 + 0.5 * fill))
			# A crescendo's ring hurts, so its whole reach shows while it glows, as any warning does.
			if _forced_glow > 0.0 and _forced_damage > 0:
				var start := inward.angle() - PI / 2.0
				layer.draw_arc(at, _forced_reach, start, start + PI, 32, Color(PipeRing.HURT_EDGE, 0.35 + 0.5 * fill), 2.0)
			else:
				layer.draw_arc(at, 10.0 + 4.0 * fill, 0.0, TAU, 16, Color(GLOW_RING, 0.4 + 0.5 * fill), 2.0)
		PipeBeat.CHORD:
			layer.draw_circle(at, 12.0, Color(GLOW_FILL, 0.8))
