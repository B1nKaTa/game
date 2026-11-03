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

# Upgrades from the bomb merchant. Damage is for enemies only, and the level decides what stone breaks.
var level := 0
var damage_mult := 1.0
var _player: Player
var _fuse := FUSE_TIME
var _gone_off := false
var _blast_left := 0.0


static func in_blast(center: Vector2, body: Rect2) -> bool:
	return center.distance_to(MeleeArc.closest_point(body, center)) <= BLAST_RADIUS


func setup(player: Player) -> void:
	_player = player


func blast_damage() -> float:
	return DAMAGE * damage_mult


# Each upgrade level brightens the blast and adds a ring, so the player can see what they paid for.
static func blast_color(upgrade_level: int) -> Color:
	var colors := [BLAST_COLOR, Color("ffb23a"), Color("ff7b2e"), Color("fff2c8")]
	return colors[clampi(upgrade_level, 0, colors.size() - 1)]


func is_fuse_burning() -> bool:
	return not _gone_off


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
			enemy.take_damage(blast_damage(), global_position.direction_to(enemy.global_position) * PUSH)
	BreakableBlock.smash(get_tree(), global_position, BLAST_RADIUS, BreakableBlock.SOURCE_BLAST)
	ReinforcedRock.blast(get_tree(), global_position, BLAST_RADIUS, level)
	SecretWall.blast(get_tree(), global_position, BLAST_RADIUS)
	if is_instance_valid(_player) and global_position.distance_to(_player.feet().global_position) <= BLAST_RADIUS:
		_player.take_hit(PLAYER_DAMAGE)
	exploded.emit()


func _draw() -> void:
	if _gone_off:
		var progress := 1.0 - _blast_left / BLAST_SHOW_TIME
		var color := blast_color(level)
		draw_circle(Vector2.ZERO, BLAST_RADIUS * minf(0.5 + progress, 1.0), Color(color, (0.55 + 0.08 * level) * (1.0 - progress)))
		draw_arc(Vector2.ZERO, BLAST_RADIUS, 0.0, TAU, 32, color, 2.0 + level)
		for ring in level:
			var ring_radius := BLAST_RADIUS * (0.3 + 0.2 * ring) * minf(0.5 + progress, 1.0)
			draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.8 * (1.0 - progress)), 1.5)
		return
	var urgency := 1.0 - _fuse / FUSE_TIME
	var blink_on := int(_fuse * (6.0 + 14.0 * urgency)) % 2 == 0
	draw_arc(Vector2.ZERO, BLAST_RADIUS, 0.0, TAU, 32, Color(WARNING_COLOR, 0.25 + 0.45 * urgency), 1.0)
	draw_rect(Rect2(-5, -9, 10, 15), WARNING_COLOR if blink_on else BODY_COLOR)
	draw_rect(Rect2(-5, -9, 10, 15), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-3, -12, 6, 3), Color("625e6f"))
