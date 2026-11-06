class_name LineTether
extends Node2D

# Madame Zara's On the Line: a phone cord from her to a marked circle round where Grandpa's feet stood
# when she called. For its warning the circle shows as a coiled cord on the floor, filling, with the
# cord running to it from her; then the line locks and for HOLD seconds he cannot leave the circle
# (Player.leash_to, LeashRule) while her other attacks run, each planned to leave him a safe spot inside
# it. It hurts no one itself, so it is drawn in the cord's own cream, never the warning red. It lets him
# go when its time is up, when it is dropped, when it leaves the room and when she falls.
const RADIUS := 88.0
const HOLD := 3.0
const CORD := Color("f1e6c8")
const CORD_DARK := Color("6b5a3c")
const FILL := Color(0.95, 0.9, 0.78, 0.1)
const COILS := 28
const FADE := 0.3

var _source: Enemy
var _warning := 0.8
var _left := 0.8
var _hold := HOLD
var _held_left := 0.0
var _locked := false
var _over := false
var _fade_left := FADE
var radius := RADIUS


# Whether a whole walk-grid cell lies inside a circle: every corner within its radius.
static func cell_inside(cell: Vector2i, center: Vector2, reach: float) -> bool:
	var tile := float(RoomBackdrop.TILE)
	var corner := Vector2(cell) * tile
	for offset: Vector2 in [Vector2.ZERO, Vector2(tile, 0.0), Vector2(tile, tile), Vector2(0.0, tile)]:
		if (corner + offset).distance_to(center) > reach:
			return false
	return true


# An open-floor test for OverlapRoute that is true only in cells lying wholly inside the circle (and
# open by base, when given). OverlapRoute asks it once per cell, so it answers for the cell: a plan made
# with it can only miss a way out inside the circle, never promise one outside it.
static func open_within(center: Vector2, reach: float, base := Callable()) -> Callable:
	return func(spot: Vector2) -> bool:
		if not cell_inside(WalkGrid.cell_of(spot), center, reach):
			return false
		return not base.is_valid() or base.call(spot)


func setup(source: Enemy, warning: float, hold := HOLD) -> void:
	_source = source
	_warning = warning
	_left = warning
	_hold = hold
	z_index = Projectile.SHOT_Z


func center() -> Vector2:
	return global_position


func is_warning() -> bool:
	return not _locked and not _over


func is_held() -> bool:
	return _locked and not _over


func is_over() -> bool:
	return _over


func held_left() -> float:
	return _held_left if is_held() else 0.0


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)


# The open-floor test for a plan made while it holds, or will: inside the circle only.
func open_test(base := Callable()) -> Callable:
	return open_within(global_position, radius, base)


# The line locks: from now until its hold runs out he cannot leave the circle.
func lock() -> void:
	if _locked or _over:
		return
	_locked = true
	_left = 0.0
	_held_left = _hold
	var target = _target()
	if target != null and target.has_method("leash_to"):
		target.leash_to(global_position, radius, _hold)


# The line drops without holding him, or lets him go early.
func drop() -> void:
	if _over:
		return
	var was_held := is_held()
	_over = true
	if was_held:
		_release()


func _target() -> Node:
	if is_instance_valid(_source) and is_instance_valid(_source.target):
		return _source.target
	return null


func _release() -> void:
	var target = _target()
	if target != null and target.has_method("end_leash") and target.has_method("leash_center"):
		# Only the hold this line put on him.
		if target.is_leashed() and target.leash_center().is_equal_approx(global_position):
			target.end_leash()


# Moves it on. Returns true once, on the moment the hold ends by its own time.
func advance(delta: float) -> bool:
	if _over:
		_fade_left -= delta
		return false
	if not _locked:
		_left = maxf(_left - delta, 0.0)
		return false
	_held_left -= delta
	if _held_left <= 0.0:
		_over = true
		_release()
		return true
	return false


# For a simulated player: outside the circle is better avoided while it warns, and a coming hit while
# it holds, since nothing inside lets him out. The circle itself never hurts, so nothing is imminent.
func threat_at(p: Vector2, strict: bool) -> int:
	if _over:
		return 0
	var margin := 12.0 if strict else 4.0
	if p.distance_to(global_position) <= radius - margin:
		return 0
	return 2 if _locked else 1


func threat_imminent(_p: Vector2) -> bool:
	return false


func _process(delta: float) -> void:
	queue_redraw()
	if not _over and (not is_instance_valid(_source) or _source.is_dead()):
		drop()
	advance(delta)
	if _over and _fade_left <= 0.0:
		queue_free()


func _exit_tree() -> void:
	# Leaving the room, or freed with it, lets him go.
	if is_held():
		_over = true
		_release()


func _draw() -> void:
	var alpha := clampf(_fade_left / FADE, 0.0, 1.0) if _over else 1.0
	if alpha <= 0.0:
		return
	var progress := 1.0 if _locked else fill()
	draw_circle(Vector2.ZERO, radius, Color(FILL, FILL.a * (0.4 + 0.6 * progress) * alpha))
	# A coiled cord laid round the circle: small loops along its edge, tighter once it locks.
	var width := 2.0 if _locked else 1.5
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(CORD_DARK, 0.8 * alpha), width + 2.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(CORD, alpha), width)
	var shown := COILS if _locked else maxi(int(COILS * progress), 1)
	for i in shown:
		var at := Vector2.from_angle(TAU * i / COILS) * radius
		draw_arc(at, 3.0, 0.0, TAU, 8, Color(CORD, alpha), 1.0)
	# The cord from her to the circle's edge.
	if is_instance_valid(_source) and not _source.is_dead():
		var from := to_local(_source.global_position)
		var way := from.normalized() if from.length() > 0.01 else Vector2.UP
		var edge := way * radius
		var length := from.distance_to(edge)
		var steps := maxi(int(length / 6.0), 2)
		var points := PackedVector2Array()
		for i in steps + 1:
			var share := i / float(steps)
			var along := edge.lerp(from, share)
			points.append(along + way.orthogonal() * sin(share * length / 4.0) * 2.5)
		draw_polyline(points, Color(CORD_DARK, alpha), 3.0)
		draw_polyline(points, Color(CORD, alpha), 1.5)
