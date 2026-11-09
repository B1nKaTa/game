class_name InkBlot
extends Node2D

# Where the Auditor's FINED stamp lands: a blot of stamp ink that slows Grandpa while his feet are on
# it, and fades LINGER seconds later. As with FilmTrail, the shooter's target is the one it slows, and
# his feet are compared with the blot in global space.

const RADIUS := 14.0
const LINGER := 3.0
const FADE := 0.6
const SLOW := 0.5
const SLOW_TIME := 0.3
# How often a slow is laid on him while he stands on it, so a long stand never piles slows up.
const SLOW_EVERY := 0.2
const INK := Color("3b2d5c")
# Flat on the floor, under the bodies and over the backdrop, as the film trail lies.
const Z := FilmTrail.Z

var _left := LINGER
var _slow_wait := 0.0
var _target: Node2D


# Bound to a stamp's landed_at, so at comes first. parent and target are left untyped, since either
# may have been freed by the time the stamp lands (a room he left, a decoy gone). A room out of the
# tree takes no blot.
static func spawn_at(at: Vector2, parent, target = null) -> void:
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var blot := InkBlot.new()
	blot.setup(target if is_instance_valid(target) else null)
	parent.add_child(blot)
	blot.global_position = at


func setup(target: Node2D) -> void:
	_target = target
	z_index = Z


# Its middle in the same space as a target's feet: global in the room, its own position out of a tree.
func centre() -> Vector2:
	return global_position if is_inside_tree() else position


func covers(p: Vector2, margin := 0.0) -> bool:
	return p.distance_to(centre()) <= RADIUS + margin


# What it means for a point, for a simulated player: 1 on the ink, which slows, else 0.
func threat_at(p: Vector2, strict: bool) -> int:
	return 1 if covers(p, 6.0 if strict else 0.0) else 0


func threat_imminent(_p: Vector2) -> bool:
	return false


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	queue_redraw()
	_slow_wait = maxf(_slow_wait - delta, 0.0)
	if _slow_wait > 0.0 or not is_instance_valid(_target):
		return
	var feet: Vector2 = _target.feet().global_position if _target.has_method("feet") else _target.global_position
	if covers(feet) and _target.has_method("slow"):
		_slow_wait = SLOW_EVERY
		_target.slow(SLOW, SLOW_TIME)


func _draw() -> void:
	var fade := clampf(_left / FADE, 0.0, 1.0)
	draw_circle(Vector2.ZERO, RADIUS, Color(INK, 0.55 * fade))
	draw_circle(Vector2(4, -3), RADIUS * 0.45, Color(INK, 0.4 * fade))
	draw_circle(Vector2(-6, 5), 3.0, Color(INK, 0.45 * fade))
