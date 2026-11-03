class_name EnemyBlast
extends Node2D

const SHOW_TIME := 0.2
const COLOR := Color("ff9a3c")
const WALL_LAYER := 1
const MAX_PROPS_IN_THE_WAY := 8

var _radius := 0.0
var _left := SHOW_TIME


static func reaches(center: Vector2, body: Rect2, radius: float) -> bool:
	return center.distance_to(MeleeArc.closest_point(body, center)) <= radius


# A wall shields whoever stands behind it, as a shot would stop there. Props do not, because
# the same blast breaks them, and holes are no cover because nothing fills them.
static func line_is_clear(space: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2) -> bool:
	var skip: Array[RID] = []
	for i in MAX_PROPS_IN_THE_WAY:
		var query := PhysicsRayQueryParameters2D.create(from, to, WALL_LAYER, skip)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return true
		if not hit.get("collider") is BreakableBlock:
			return false
		skip.append(hit["rid"])
	return true


# Hits enemies and Grandpa inside the radius, and breaks what a Thermos breaks, except secret
# walls and reinforced stone, which wait for the player's own Thermos.
static func go(parent: Node2D, center: Vector2, radius: float, enemy_damage: float, push: float, player: Node2D, player_damage: int) -> void:
	var tree := parent.get_tree()
	var space: PhysicsDirectSpaceState2D = parent.get_world_2d().direct_space_state
	var flash := EnemyBlast.new()
	flash._radius = radius
	parent.add_child(flash)
	flash.global_position = center
	for enemy: Enemy in tree.get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or not reaches(center, enemy.body_rect(), radius):
			continue
		if line_is_clear(space, center, enemy.global_position):
			enemy.take_damage(enemy_damage, center.direction_to(enemy.global_position) * push)
	BreakableBlock.smash(tree, center, radius, BreakableBlock.SOURCE_BLAST)
	if is_instance_valid(player) and player.has_method("feet"):
		var feet: Vector2 = player.feet().global_position
		if center.distance_to(feet) <= radius and line_is_clear(space, center, feet):
			player.take_hit(player_damage)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		queue_free()


func _draw() -> void:
	var progress := 1.0 - maxf(_left, 0.0) / SHOW_TIME
	draw_circle(Vector2.ZERO, _radius * minf(0.5 + progress, 1.0), Color(COLOR, 0.6 * (1.0 - progress)))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 32, COLOR, 2.0)
