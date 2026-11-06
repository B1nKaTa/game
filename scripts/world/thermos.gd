class_name Thermos
extends Node2D

signal exploded

const FUSE_TIME := 1.2
# Kept in PlayerStats, which must not name this class. See PlayerStats.BASE_BLAST_RADIUS.
const BLAST_RADIUS := PlayerStats.BASE_BLAST_RADIUS
const BLAST_SHOW_TIME := 0.18
const DAMAGE := 30.0
const PUSH := 140.0
const PLAYER_DAMAGE := 1
const BODY_COLOR := Color("a8692f")
const WARNING_COLOR := Color("e4524f")
const BLAST_COLOR := Color("ffd24a")
# The same picture as the Thermos lying on the floor to be picked up (RoomView.ART_THERMOS).
const ART := "pickup_thermos"

# Upgrades from the bomb merchant. Damage is for enemies only, and the level decides what stone breaks.
var level := 0
var damage_mult := 1.0
# How far the blast reaches. The Big Bang option widens it.
var radius := BLAST_RADIUS
# How long it burns before it goes off. The Pressure Cooker lengthens it. Set before it enters the room.
var fuse_time := FUSE_TIME
var _player: Player
var _fuse := FUSE_TIME
var _gone_off := false
var _blast_left := 0.0


static func in_blast(center: Vector2, body: Rect2, reach := BLAST_RADIUS) -> bool:
	return center.distance_to(MeleeArc.closest_point(body, center)) <= reach


func setup(player: Player) -> void:
	_player = player


func _ready() -> void:
	_fuse = fuse_time
	Sfx.play("fuse_hiss")


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
		if not enemy.is_queued_for_deletion() and in_blast(global_position, enemy.body_rect(), radius):
			var push := global_position.direction_to(enemy.global_position) * PUSH
			if is_instance_valid(_player) and _player.run != null:
				_player.run.effects.land(enemy, blast_damage(), RunEffects.THERMOS, push)
			else:
				enemy.take_damage(blast_damage(), push)
	BreakableBlock.smash(get_tree(), global_position, radius, BreakableBlock.SOURCE_BLAST)
	ReinforcedRock.blast(get_tree(), global_position, radius, level)
	SecretWall.blast(get_tree(), global_position, radius)
	Chest.blast(get_tree(), global_position, radius)
	if is_instance_valid(_player) and global_position.distance_to(_player.feet().global_position) <= radius:
		_player.take_hit(PLAYER_DAMAGE, RunEffects.HURT_OWN_BLAST)
	exploded.emit()



func _draw() -> void:
	if _gone_off:
		var progress := 1.0 - _blast_left / BLAST_SHOW_TIME
		var color := blast_color(level)
		draw_circle(Vector2.ZERO, radius * minf(0.5 + progress, 1.0), Color(color, (0.55 + 0.08 * level) * (1.0 - progress)))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 2.0 + level)
		for ring in level:
			var ring_radius := radius * (0.3 + 0.2 * ring) * minf(0.5 + progress, 1.0)
			draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.8 * (1.0 - progress)), 1.5)
		return
	var urgency := 1.0 - _fuse / fuse_time
	var blink_on := int(_fuse * (6.0 + 14.0 * urgency)) % 2 == 0
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(WARNING_COLOR, 0.25 + 0.45 * urgency), 1.0)
	# With a picture, the fuse blinks it warning red, as the placeholder's body blinks.
	var art := PropArt.texture(ART)
	if art != null:
		PropArt.draw(self, art, Vector2(0, -2), WARNING_COLOR.lightened(0.2) if blink_on else Color.WHITE)
		return
	draw_rect(Rect2(-5, -9, 10, 15), WARNING_COLOR if blink_on else BODY_COLOR)
	draw_rect(Rect2(-5, -9, 10, 15), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-3, -12, 6, 3), Color("625e6f"))
