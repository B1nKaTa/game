class_name CollectionPlate
extends Node2D

# The Reverend's collection plate, thrown like a boomerang. While he winds up it marks the whole
# curve it will fly back along, and then it flies out and back along that path. Grandpa's feet near
# it cost a pill, once a throw, and a dodge passes through. It comes to nothing if the Reverend falls.
const COLOR := Color("e4524f")
const PLATE := Color("c9a25a")
const PLATE_RIM := Color("6e5228")
# The plate's picture (art/props/collection_plate.png): a brass dish, a strip of TURNS pre-drawn turns
# over a quarter turn, as it looks the same after one; the drawing stays for when it is missing.
const ART := "collection_plate"
const TURNS := 4
const HIT_RANGE := 14.0
const SPEED := 320.0
const MARK_RADIUS := 6.0
const MARK_EVERY := 2

var _source: Enemy
# The path from where it is thrown, relative to that point.
var _path: Array[Vector2] = []
var _warning := 0.7
var _left := 0.7
var _travelled := 0.0
var _total := 0.0
var _has_hit := false
var _damage := -1


# Where a plate is after flying a distance along a path that starts at the origin.
static func point_along(path: Array[Vector2], distance: float) -> Vector2:
	var from := Vector2.ZERO
	var left := distance
	for point in path:
		var step := from.distance_to(point)
		if left <= step and step > 0.0:
			return from.lerp(point, left / step)
		left -= step
		from = point
	return from


static func path_length(path: Array[Vector2]) -> float:
	var total := 0.0
	var from := Vector2.ZERO
	for point in path:
		total += from.distance_to(point)
		from = point
	return total


# The path is in room coordinates. The plate keeps it relative to where it is thrown from.
func setup(source: Enemy, start: Vector2, path: Array[Vector2], warning: float, damage := -1) -> void:
	_source = source
	_path.clear()
	for point in path:
		_path.append(point - start)
	_total = path_length(_path)
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_flying() -> bool:
	return _left <= 0.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if _left > 0.0:
		_left -= delta
		return
	_travelled += SPEED * delta
	if _travelled >= _total:
		queue_free()
		return
	if _has_hit or not is_instance_valid(_source.target):
		return
	var at := global_position + point_along(_path, _travelled)
	if at.distance_to(_source.target_ground()) <= HIT_RANGE and _source.target.take_hit(_source.attack_damage(_damage)):
		_has_hit = true


func _draw() -> void:
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		# Marks along the way back. The way out is the Reverend's own warned lane. The red marks only
		# with Attack warnings on (AttackWarnings); otherwise the faint cue.
		var red := AttackWarnings.drawn_by(_source)
		for i in range(_path.size() / 2, _path.size(), MARK_EVERY):
			if not red:
				AttackWarnings.draw_cue_circle(self, _path[i], MARK_RADIUS, progress)
				continue
			draw_circle(_path[i], MARK_RADIUS * progress, Color(COLOR, 0.15 + 0.3 * progress))
			draw_arc(_path[i], MARK_RADIUS, 0.0, TAU, 12, COLOR, 1.5)
		return
	var at := point_along(_path, _travelled)
	var spin := _travelled / 12.0
	var art := PropArt.texture(ART)
	if art != null:
		PropArt.draw_frame(self, art, PropArt.turn_frame(spin, TURNS, PI / 2.0), at)
		return
	draw_set_transform(at, spin, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, 7.0, PLATE_RIM)
	draw_circle(Vector2.ZERO, 5.5, PLATE)
	draw_circle(Vector2(2, -1), 1.5, PLATE.lightened(0.4))
	draw_set_transform(Vector2.ZERO)
