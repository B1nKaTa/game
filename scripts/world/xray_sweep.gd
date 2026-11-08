class_name XRaySweep
extends Node2D

# Sergeant Wanda's X-ray sweep: a scanning beam as tall (or as wide) as the room. It first shows where
# it starts, filling red as any warned lane does, with all the room it will cross tinted red and
# chevrons pointing its way, then crosses the whole room at an even speed, tinting what is left. Feet
# it passes over cost a pill, once, unless they stand on the one marked safe spot, the inspection mat
# (a SafeSpotMark the boss lays). A dodge passes through it, as through any hit. It comes to nothing
# if Wanda falls first. Placed at the room's origin, so its numbers are room positions.
const COLOR := Color("e4524f")
const BEAM := Color(0.55, 0.95, 1.0, 0.55)
const BEAM_CORE := Color(0.85, 1.0, 1.0, 0.85)
const WIDTH := 22.0
const SPEED := 240.0
# Feet this near the safe spot's middle are spared. A little wider than the mark itself.
const SAFE_REACH := SafeSpotMark.RADIUS + 4.0
# The stretch still to be scanned is tinted, from faint to clearer over the warning, so a room wider
# than the view still shows the warning round him while the beam's start is off screen.
const AHEAD_ALPHA_FROM := 0.08
const AHEAD_ALPHA_TO := 0.26
const AHEAD_ALPHA_SWEEPING := 0.2
# Chevrons over that stretch point the way the beam will come, this far apart.
const CHEVRON_STEP := 128.0

var _source: Enemy
var _room := Rect2()
# True when the beam stands upright and moves across the room from side to side.
var _along_x := true
var _from := 0.0
var _to := 0.0
var _at := 0.0
var _safe := Vector2.INF
var _warning := 1.0
var _left := 1.0
var _damage := -1
var _has_hit := false


# Where the beam starts and ends along its way: at the room's edge farther from Grandpa, so it reaches
# him last, and on to the other edge.
static func sweep_ends(room: Rect2, along_x: bool, feet: Vector2) -> Vector2:
	var low := room.position.x if along_x else room.position.y
	var high := room.end.x if along_x else room.end.y
	var at := feet.x if along_x else feet.y
	return Vector2(high, low) if at - low < high - at else Vector2(low, high)


# Whether the beam, moving from one place to the next in a frame, passed over a point, whatever the
# frame time.
static func crossed(before: float, after: float, point: float, width: float) -> bool:
	return point >= minf(before, after) - width / 2.0 and point <= maxf(before, after) + width / 2.0


static func spared(feet: Vector2, safe: Vector2) -> bool:
	return safe != Vector2.INF and feet.distance_to(safe) <= SAFE_REACH


# How long it lasts from the start of its warning until it has crossed the room.
static func duration(room: Rect2, along_x: bool, warning: float) -> float:
	return warning + (room.size.x if along_x else room.size.y) / SPEED


# The part of the room the beam has still to cross, from where it is now to where it ends.
static func ahead_rect(room: Rect2, along_x: bool, at: float, to: float) -> Rect2:
	var low := minf(at, to)
	var high := maxf(at, to)
	if along_x:
		return Rect2(low, room.position.y, high - low, room.size.y)
	return Rect2(room.position.x, low, room.size.x, high - low)


func setup(source: Enemy, room: Rect2, along_x: bool, feet: Vector2, safe: Vector2, warning: float, damage := -1) -> void:
	_source = source
	_room = room
	_along_x = along_x
	var ends := sweep_ends(room, along_x, feet)
	_from = ends.x
	_to = ends.y
	_at = _from
	_safe = safe
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_sweeping() -> bool:
	return _left <= 0.0


func beam_at() -> float:
	return _at


# Moves the beam on. Returns whether it has crossed the whole room.
func advance(delta: float) -> bool:
	if _left > 0.0:
		_left -= delta
		return false
	_at = move_toward(_at, _to, SPEED * delta)
	return is_equal_approx(_at, _to)


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	var before := _at
	var done := advance(delta)
	if is_sweeping() and not _has_hit and is_instance_valid(_source.target):
		var feet := _source.target_ground()
		if crossed(before, _at, feet.x if _along_x else feet.y, WIDTH) and not spared(feet, _safe):
			if _source.target.take_hit(_source.attack_damage(_damage)):
				_has_hit = true
	if done:
		queue_free()


func _way() -> Vector2:
	var heading := signf(_to - _from)
	return Vector2(heading, 0.0) if _along_x else Vector2(0.0, heading)


# With Attack warnings off (AttackWarnings): no red over the room. The beam's start is the faint dark
# cue with its chevrons pointing the way it will sweep, then the beam of light itself crosses; the
# safe-spot mark (SafeSpotMark) always shows.
func _draw_hidden() -> void:
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		var start := _beam_rect(_from)
		AttackWarnings.draw_cue_rect(self, start, progress)
		var middle := start.get_center()
		for i in 3:
			_draw_chevron(middle + _way() * (18.0 + i * 12.0), AttackWarnings.cue_color(1.0), 1.4)
		return
	var beam := _beam_rect(_at)
	draw_rect(beam, BEAM)
	draw_rect(beam.grow_individual(-WIDTH * 0.3, 0.0, -WIDTH * 0.3, 0.0) if _along_x else beam.grow_individual(0.0, -WIDTH * 0.3, 0.0, -WIDTH * 0.3), BEAM_CORE)


func _draw_chevron(tip: Vector2, color: Color, size := 1.0) -> void:
	var back := -_way() * 6.0 * size
	var side := (Vector2(0.0, 7.0) if _along_x else Vector2(7.0, 0.0)) * size
	draw_polyline(PackedVector2Array([tip + back - side, tip, tip + back + side]), color, 2.0 * size)


func _beam_rect(at: float) -> Rect2:
	if _along_x:
		return Rect2(at - WIDTH / 2.0, _room.position.y, WIDTH, _room.size.y)
	return Rect2(_room.position.x, at - WIDTH / 2.0, _room.size.x, WIDTH)


func _draw() -> void:
	var ahead := ahead_rect(_room, _along_x, _at, _to)
	if not AttackWarnings.drawn_by(_source):
		_draw_hidden()
		return
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		draw_rect(ahead, Color(COLOR, AHEAD_ALPHA_FROM + (AHEAD_ALPHA_TO - AHEAD_ALPHA_FROM) * progress))
		var start := _beam_rect(_from)
		draw_rect(start, Color(COLOR, 0.15 + 0.35 * progress))
		draw_rect(start, COLOR, false, 2.0)
		# Chevrons along the way it will sweep, next to its start and over the whole stretch.
		var middle := start.get_center()
		for i in 3:
			_draw_chevron(middle + _way() * (18.0 + i * 12.0), Color(COLOR, 0.4 + 0.5 * progress))
		var across := Vector2.DOWN if _along_x else Vector2.RIGHT
		var along_steps := floori((ahead.size.x if _along_x else ahead.size.y) / CHEVRON_STEP)
		var across_steps := floori((ahead.size.y if _along_x else ahead.size.x) / CHEVRON_STEP)
		for a in range(1, along_steps + 1):
			for b in across_steps + 1:
				var at := middle + _way() * a * CHEVRON_STEP + across * ((b + 0.5) * CHEVRON_STEP - (ahead.size.y if _along_x else ahead.size.x) / 2.0)
				_draw_chevron(at, Color(COLOR, 0.45 + 0.5 * progress), 1.6)
		return
	draw_rect(ahead, Color(COLOR, AHEAD_ALPHA_SWEEPING))
	var beam := _beam_rect(_at)
	draw_rect(beam, BEAM)
	draw_rect(beam.grow_individual(-WIDTH * 0.3, 0.0, -WIDTH * 0.3, 0.0) if _along_x else beam.grow_individual(0.0, -WIDTH * 0.3, 0.0, -WIDTH * 0.3), BEAM_CORE)
	draw_rect(beam, COLOR, false, 2.0)
