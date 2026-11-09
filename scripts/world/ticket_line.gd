class_name TicketLine
extends Node2D

# A roll of bus tickets unspooled into a line along the floor. Enemies crossing it take a nip, each at most
# once a TICK. It pays nothing and spawns nothing; its hits go through Player.era_hit.

const LENGTH := 96.0
const UNROLL_TIME := 0.3
const LINGER := 3.0
const DAMAGE := 5.0
const TICK := 0.5
const WIDTH := 8.0

var direction := Vector2.RIGHT
var hits := 0
var _time := 0.0
var _last_hit := {}


# Whether a point (relative to where the line starts) lies on the unrolled length of it.
static func crosses(local: Vector2, way: Vector2, length: float) -> bool:
	var along := local.dot(way)
	var across := absf(local.dot(way.orthogonal()))
	return along >= 0.0 and along <= length and across <= WIDTH


# Whether this enemy may take a nip now, and if so marks it: once a TICK each.
func take_nip(id: int, now: float) -> bool:
	if _last_hit.has(id) and now - float(_last_hit[id]) < TICK:
		return false
	_last_hit[id] = now
	return true


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= UNROLL_TIME + LINGER:
		queue_free()
		return
	var length := LENGTH * clampf(_time / UNROLL_TIME, 0.0, 1.0)
	var player := get_tree().get_first_node_in_group("player") as Player
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.submerged:
			continue
		if not crosses(enemy.global_position - global_position, direction, length):
			continue
		if not take_nip(enemy.get_instance_id(), _time):
			continue
		if player != null:
			hits += 1
			# A nip at the feet, from the floor: plain damage that no shield faces.
			player.era_hit(enemy, DAMAGE, Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	var length := LENGTH * clampf(_time / UNROLL_TIME, 0.0, 1.0)
	var fade := clampf((UNROLL_TIME + LINGER - _time) / 0.5, 0.0, 1.0)
	var side := direction.orthogonal() * 3.0
	draw_line(side, direction * length + side, Color(Color("e8dcb0"), fade), 5.0)
	var dash := 0.0
	while dash < length:
		draw_line(direction * dash, direction * (dash + 2.0), Color(Color("a33b2b"), fade), 5.0)
		dash += 10.0
