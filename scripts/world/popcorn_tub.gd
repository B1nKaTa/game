class_name PopcornTub
extends Node2D

# A tub of popcorn lobbed onto a warned spot. A red circle fills for its warning, with a short warned
# spoke for each kernel to come, while the striped tub sails in on a high arc from whoever threw it and
# its shadow grows on the spot. It lands, costing a pill to whoever stands under it, then bursts into a
# ring of kernels that fly out along the spokes. It breaks nothing, since a vendor is no boss, and comes
# to nothing if the thrower falls first.
const WARNING := 0.9
const RADIUS := 18.0
const KERNELS := 6
const KERNEL_SPEED := 120.0
const SPOKE := 56.0
const SPOKE_WIDTH := 10.0
const ARC := 44.0
const BURST_SHOW := 0.3
const COLOR := Color("e4524f")
const TUB := Color("f4efe0")
const TUB_STRIPE := Color("c9a24a")
const POPCORN := Color("fff4c0")
const SHADOW := Color(0.0, 0.0, 0.0)
# How near its spot a point counts as better avoided for a simulated player: the spokes' reach.
const AVOID_REACH := RADIUS + SPOKE

var _source: Enemy
var _warning := WARNING
var _left := WARNING
var _start_angle := 0.0
var _from := Vector2.INF
var _landed := false
var _show_left := BURST_SHOW


static func kernel_directions(start_angle: float) -> Array[Vector2]:
	return BossMoves.ring_directions(KERNELS, start_angle)


static func hits(center: Vector2, feet: Vector2) -> bool:
	return center.distance_to(feet) <= RADIUS


# Puts one down for an enemy, flying in from where it stands. Walls and holes take no tub.
static func lob(enemy: Enemy, at: Vector2, start_angle: float) -> PopcornTub:
	if enemy.open_ground.is_valid() and not enemy.open_ground.call(at):
		return null
	var tub := PopcornTub.new()
	tub.setup(enemy, WARNING, start_angle)
	tub.lob_from(enemy.global_position)
	enemy.get_parent().add_child(tub)
	tub.global_position = at
	return tub


func setup(source: Enemy, warning: float, start_angle: float) -> void:
	_source = source
	_warning = warning
	_left = warning
	_start_angle = start_angle
	z_index = Projectile.SHOT_Z


func lob_from(point: Vector2) -> void:
	_from = point


func has_landed() -> bool:
	return _landed


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)


# True once, on the moment it lands.
func advance(delta: float) -> bool:
	if _landed:
		return false
	_left -= delta
	if _left <= 0.0:
		_landed = true
		return true
	return false


# What it means for a point, for a simulated player: 2 under the coming tub, 1 along its spokes.
func threat_at(p: Vector2, strict: bool) -> int:
	if _landed:
		return 0
	var distance := p.distance_to(global_position)
	if distance <= RADIUS + (12.0 if strict else 6.0):
		return 2
	return 1 if distance <= AVOID_REACH else 0


func threat_imminent(p: Vector2) -> bool:
	return not _landed and _left < 0.12 and p.distance_to(global_position) <= RADIUS + 6.0


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
		if is_instance_valid(_source.target) and hits(global_position, _source.target_ground()):
			_source.hit_target(_source.attack_damage())
		_burst()


func _burst() -> void:
	if not is_instance_valid(_source.target):
		return
	for way in kernel_directions(_start_angle):
		var kernel := Projectile.new()
		kernel.setup(way, KERNEL_SPEED, _source.target, _source.attack_damage())
		kernel.look = Projectile.LOOK_KERNEL
		get_parent().add_child(kernel)
		kernel.global_position = global_position + way * RADIUS * 0.5


func _draw() -> void:
	if _landed:
		var progress := 1.0 - maxf(_show_left, 0.0) / BURST_SHOW
		for i in 8:
			var way := Vector2.from_angle(TAU * i / 8.0 + 0.4)
			draw_circle(way * RADIUS * progress, 3.0, Color(POPCORN, 1.0 - progress))
		return
	var filled := fill()
	for way in kernel_directions(_start_angle):
		draw_set_transform(Vector2.ZERO, way.angle())
		draw_rect(Rect2(RADIUS, -SPOKE_WIDTH / 2.0, SPOKE, SPOKE_WIDTH), Color(COLOR, 0.08 + 0.2 * filled))
		draw_rect(Rect2(RADIUS, -SPOKE_WIDTH / 2.0, SPOKE, SPOKE_WIDTH), Color(COLOR, 0.7), false, 1.0)
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO, RADIUS * filled, Color(COLOR, 0.15 + 0.3 * filled))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, COLOR, 2.0)
	draw_circle(Vector2.ZERO, RADIUS * 0.6 * filled, Color(SHADOW, 0.35 * filled))
	# The tub flies in on its arc, striped and heaped with popcorn.
	var start := (_from - global_position) if _from != Vector2.INF else Vector2(0.0, -60.0)
	var at := start.lerp(Vector2.ZERO, filled) + Vector2(0.0, -sin(filled * PI) * ARC)
	var tub := PackedVector2Array([at + Vector2(-6, -5), at + Vector2(6, -5), at + Vector2(4, 6), at + Vector2(-4, 6)])
	draw_colored_polygon(tub, TUB)
	for x in [-3.0, 1.0]:
		draw_line(at + Vector2(x, -5), at + Vector2(x * 0.7, 6), TUB_STRIPE, 2.0)
	draw_polyline(tub + PackedVector2Array([tub[0]]), Color.BLACK, 1.0)
	for i in 3:
		draw_circle(at + Vector2(-4.0 + i * 4.0, -6.0), 2.5, POPCORN)
