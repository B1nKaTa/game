class_name SprinklerSweep
extends Node2D

# A floor boss's sprinkler sweep: a jet of water as long as REACH turns round him through three
# quarters of a circle. While he winds up, the whole arc it will sweep shows as a red sector with an
# arrow for the way it turns, and the quarter it never reaches, behind him and away from Grandpa, is
# edged in green. Then the jet sweeps the arc in SWEEP_TIME and costs a pill once if it passes over
# Grandpa's feet. Out of its reach or in the green quarter he is safe, and a dodge passes through it as
# through any hit. It comes to nothing if the boss falls first.
const REACH := 150.0
# The arc swept, and the quarter left dry.
const SWEEP := PI * 1.5
const SWEEP_TIME := 1.5
const ARM_WIDTH := 18.0
const COLOR := Color("e4524f")
const SAFE := Color("7fe0a0")
const WATER := Color(0.6, 0.85, 1.0)
const SPRAY := Color(0.88, 0.96, 1.0)
const SECTOR_STEPS := 36
# The dry quarter is filled faintly green, as the edge alone was lost on the grass, and the arc still to
# be swept stays faintly red while the jet turns.
const DRY_FILL := 0.18
const AHEAD_FILL := 0.12

var _source: Enemy
var _start := 0.0
var _turn := 1
var _warning := 0.8
var _left := 0.8
var _swept_for := 0.0
var _has_hit := false
var _damage := -1


# Where the jet starts, given the way to Grandpa: at one edge of the dry quarter behind the boss, so it
# reaches Grandpa's side halfway through and he has the windup and then some to step out.
static func start_angle(to_target_angle: float, turn: int) -> float:
	return to_target_angle + PI + signi(turn) * (TAU - SWEEP) / 2.0


# The jet's angle after sweeping for a while.
static func arm_angle(start: float, turn: int, time: float) -> float:
	return start + signi(turn) * SWEEP * clampf(time / SWEEP_TIME, 0.0, 1.0)


# How far round the sweep, from its start in its own turning way, a point lies, from 0 to TAU.
static func swept_angle_of(center: Vector2, start: float, turn: int, point: Vector2) -> float:
	var angle := (point - center).angle()
	return fposmod(signi(turn) * (angle - start), TAU)


# Whether the jet at an angle covers a point: within its reach and within half its width of it.
static func arm_hits(center: Vector2, angle: float, point: Vector2) -> bool:
	var offset := point - center
	if offset.length() > REACH:
		return false
	var way := Vector2.from_angle(angle)
	var along := offset.dot(way)
	if along < 0.0:
		return offset.length() <= ARM_WIDTH / 2.0
	return absf(offset.cross(way)) <= ARM_WIDTH / 2.0


# Whether the jet passed over a point between two moments of its sweep, so a fast sweep never skips him
# between frames.
static func swept_over(center: Vector2, start: float, turn: int, from_time: float, to_time: float, point: Vector2) -> bool:
	if point.distance_to(center) > REACH:
		return false
	if arm_hits(center, arm_angle(start, turn, to_time), point):
		return true
	var reached := swept_angle_of(center, start, turn, point)
	var from := SWEEP * clampf(from_time / SWEEP_TIME, 0.0, 1.0)
	var to := SWEEP * clampf(to_time / SWEEP_TIME, 0.0, 1.0)
	return reached >= from and reached <= to


# Whether a point is out of the sweep altogether: past its reach, or in the dry quarter.
static func is_safe(center: Vector2, start: float, turn: int, point: Vector2) -> bool:
	if point.distance_to(center) > REACH + ARM_WIDTH / 2.0:
		return true
	return swept_angle_of(center, start, turn, point) > SWEEP and not arm_hits(center, start, point) and not arm_hits(center, start + signi(turn) * SWEEP, point)


func setup(source: Enemy, to_target_angle: float, turn: int, warning: float, damage := -1) -> void:
	_source = source
	_turn = 1 if turn >= 0 else -1
	_start = start_angle(to_target_angle, _turn)
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func sweep_start() -> float:
	return _start


func sweep_turn() -> int:
	return _turn


func is_sweeping() -> bool:
	return _left <= 0.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	global_position = _source.global_position
	if _left > 0.0:
		_left -= delta
		return
	var was := _swept_for
	_swept_for += delta
	if not _has_hit and is_instance_valid(_source.target):
		if swept_over(global_position, _start, _turn, was, _swept_for, _source.target_ground()):
			if _source.target.take_hit(_source.attack_damage(_damage)):
				_has_hit = true
	if _swept_for >= SWEEP_TIME:
		queue_free()


func _sector(from: float, to: float, reach: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	for i in SECTOR_STEPS + 1:
		points.append(Vector2.from_angle(lerpf(from, to, i / float(SECTOR_STEPS))) * reach)
	return points


func _draw() -> void:
	var end := _start + _turn * SWEEP
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		var sector := _sector(_start, end, REACH)
		draw_colored_polygon(sector, Color(COLOR, 0.08 + 0.22 * progress))
		draw_polyline(sector + PackedVector2Array([Vector2.ZERO]), COLOR, 2.0)
		# The dry quarter, edged in green, so the one way out of the sweep is plain to see.
		var dry := _sector(end, _start + _turn * TAU, REACH)
		draw_colored_polygon(dry, Color(SAFE, DRY_FILL))
		draw_polyline(dry + PackedVector2Array([Vector2.ZERO]), Color(SAFE, 0.9), 3.0)
		# An arrow along the rim, pointing the way the jet will turn.
		var tip_angle := _start + _turn * 0.5
		var tip := Vector2.from_angle(tip_angle) * (REACH - 12.0)
		var back := Vector2.from_angle(_start) * (REACH - 12.0)
		draw_line(back, tip, COLOR, 3.0)
		var side := (tip - back).normalized()
		draw_line(tip, tip - side.rotated(0.5) * 9.0, COLOR, 3.0)
		draw_line(tip, tip - side.rotated(-0.5) * 9.0, COLOR, 3.0)
		return
	var angle := arm_angle(_start, _turn, _swept_for)
	var way := Vector2.from_angle(angle)
	# What the jet has still to sweep stays faintly red, so the way it is heading reads.
	var ahead := _sector(angle, end, REACH)
	draw_colored_polygon(ahead, Color(COLOR, AHEAD_FILL))
	draw_polyline(ahead, Color(COLOR, 0.6), 1.5)
	draw_line(Vector2.ZERO, way * REACH, Color(WATER, 0.75), ARM_WIDTH * 0.6)
	draw_line(Vector2.ZERO, way * REACH, SPRAY, 2.0)
	for i in 6:
		var at := way * REACH * (0.3 + i * 0.13) + way.orthogonal() * sin(_swept_for * 30.0 + i) * 4.0
		draw_circle(at, 2.0, SPRAY)
