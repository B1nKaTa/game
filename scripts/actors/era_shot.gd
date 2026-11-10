class_name EraShot
extends Node2D

# A younger Harold's straight throw: the Dance Hall's 45 record (flies through everyone in its way) or the
# Allotment's marrow (stops at the first it hits, or at its range or a wall, and splashes all near). Its hits
# go through Player.era_hit, so stat items apply and the denture items don't. Pays and spawns nothing.

const LOOK_DISC := "disc"
const LOOK_MARROW := "marrow"
const RADIUS := 5.0

var direction := Vector2.RIGHT
var damage := 7.0
var speed := 240.0
var max_range := 200.0
var pierce := true
var splash_radius := 0.0
var look := LOOK_DISC
var _flown := 0.0
var _hit := {}
var _spin := 0.0


static func for_disc() -> EraShot:
	var shot := EraShot.new()
	shot.look = LOOK_DISC
	shot.damage = 7.0
	shot.speed = 240.0
	shot.max_range = 200.0
	shot.pierce = true
	return shot


static func for_marrow() -> EraShot:
	var shot := EraShot.new()
	shot.look = LOOK_MARROW
	shot.damage = 14.0
	shot.speed = 170.0
	shot.max_range = 150.0
	shot.pierce = false
	shot.splash_radius = 24.0
	return shot


# Indexes of the bodies within radius of at (nearest point of each body), in their order.
static func splash_targets(at: Vector2, bodies: Array, radius: float) -> Array:
	var out := []
	for i in bodies.size():
		var body: Rect2 = bodies[i]
		if MeleeArc.closest_point(body, at).distance_to(at) <= radius:
			out.append(i)
	return out


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var step := direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step + direction * RADIUS, ThrownDentures.BLOCKED_BY)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		_land(player)
		return
	global_position += step
	_flown += step.length()
	_spin += delta * 12.0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var id := enemy.get_instance_id()
		if _hit.has(id) or enemy.is_queued_for_deletion() or enemy.submerged or enemy.is_dead():
			continue
		if not enemy.body_rect().grow(RADIUS).has_point(global_position):
			continue
		_hit[id] = true
		if player != null:
			player.era_hit(enemy, damage, direction * 60.0, global_position)
		if not pierce:
			_land(player)
			return
	if _flown >= max_range:
		_land(player)
		return
	queue_redraw()


# Where it stops: the marrow splashes everyone near who it has not already hit.
func _land(player: Player) -> void:
	if splash_radius > 0.0 and player != null:
		var enemies: Array[Enemy] = []
		var bodies := []
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if not _hit.has(enemy.get_instance_id()) and not enemy.is_queued_for_deletion() and not enemy.submerged and not enemy.is_dead():
				enemies.append(enemy)
				bodies.append(enemy.body_rect())
		for i in splash_targets(global_position, bodies, splash_radius):
			player.era_hit(enemies[i], damage, Vector2.ZERO, global_position)
	queue_free()


func _draw() -> void:
	if look == LOOK_MARROW:
		# A green ellipse along its flight with a darker stripe down its length: no crossing strokes.
		var points := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			points.append(Vector2(cos(a) * 7.0, sin(a) * 4.0).rotated(direction.angle()))
		draw_colored_polygon(points, Color("5e8c3a"))
		draw_line(-direction * 5.0, direction * 5.0, Color("3f6126"), 1.0)
	else:
		draw_circle(Vector2.ZERO, RADIUS, Color("1c1a1e"))
		draw_circle(Vector2.ZERO, 2.0, Color("d9493f"))
		draw_arc(Vector2.ZERO, 3.5, _spin, _spin + 1.2, 6, Color("4a4650"), 1.0)
