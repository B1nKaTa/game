class_name Thermos
extends Node2D

signal exploded

const FUSE_TIME := 1.2
const BLAST_RADIUS := 56.0
const BLAST_SHOW_TIME := 0.18
const DAMAGE := 30.0
const PUSH := 140.0
const PLAYER_DAMAGE := 1
const BODY_COLOR := Color("a8692f")
const WARNING_COLOR := Color("e4524f")
const BLAST_COLOR := Color("ffd24a")

var _player: Player
var _fuse := FUSE_TIME
var _gone_off := false
var _blast_left := 0.0


static func in_blast(center: Vector2, body: Rect2) -> bool:
	return center.distance_to(MeleeArc.closest_point(body, center)) <= BLAST_RADIUS


func setup(player: Player) -> void:
	_player = player


func tick_fuse(delta: float) -> bool:
	if _gone_off:
		return false
	_fuse -= delta
	if _fuse > 0.0:
		return false
	_gone_off = true
	return true


func _process(delta: float) -> void:
	if tick_fuse(delta):
		_explode()
	elif _gone_off:
		_blast_left -= delta
		if _blast_left <= 0.0:
			queue_free()
	queue_redraw()


func _explode() -> void:
	_blast_left = BLAST_SHOW_TIME
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_queued_for_deletion() and in_blast(global_position, enemy.body_rect()):
			enemy.take_damage(DAMAGE, global_position.direction_to(enemy.global_position) * PUSH)
	BreakableBlock.smash(get_tree(), global_position, BLAST_RADIUS, BreakableBlock.SOURCE_BLAST)
	if is_instance_valid(_player) and global_position.distance_to(_player.feet().global_position) <= BLAST_RADIUS:
		_player.take_hit(PLAYER_DAMAGE)
	exploded.emit()


func _draw() -> void:
	if _gone_off:
		var progress := 1.0 - _blast_left / BLAST_SHOW_TIME
		draw_circle(Vector2.ZERO, BLAST_RADIUS * minf(0.5 + progress, 1.0), Color(BLAST_COLOR, 0.55 * (1.0 - progress)))
		draw_arc(Vector2.ZERO, BLAST_RADIUS, 0.0, TAU, 32, BLAST_COLOR, 2.0)
		return
	var urgency := 1.0 - _fuse / FUSE_TIME
	var blink_on := int(_fuse * (6.0 + 14.0 * urgency)) % 2 == 0
	draw_arc(Vector2.ZERO, BLAST_RADIUS, 0.0, TAU, 32, Color(WARNING_COLOR, 0.25 + 0.45 * urgency), 1.0)
	draw_rect(Rect2(-5, -9, 10, 15), WARNING_COLOR if blink_on else BODY_COLOR)
	draw_rect(Rect2(-5, -9, 10, 15), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-3, -12, 6, 3), Color("625e6f"))
