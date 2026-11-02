class_name ReinforcedRock
extends BreakableBlock

# Blocks walking and shots like a rock, but nothing breaks it except a Thermos upgraded to the
# level this stone asks for. Auditor blasts, boss attacks and the cane leave it alone, so a
# player learns to come back for it.
signal resisted

const GLOW_PERIOD := 1.6

# Set before the stone enters the tree. A floor decides how strong a Thermos it wants.
var needed_level := 3
var _time := 0.0


# Every stone near a player's Thermos blast either breaks or resists, by the blast's level.
static func blast_among(blocks: Array, center: Vector2, radius: float, level: int) -> int:
	var broken := 0
	for block in blocks:
		if not block is ReinforcedRock or block.is_queued_for_deletion():
			continue
		if center.distance_to(MeleeArc.closest_point(block.body_rect(), center)) > radius:
			continue
		if block.break_with_level(level):
			broken += 1
	return broken


static func blast(tree: SceneTree, center: Vector2, radius: float, level: int) -> int:
	return blast_among(tree.get_nodes_in_group("breakable"), center, radius, level)


func art_id() -> String:
	return "reinforced_rock"


func debris_color() -> Color:
	return look().reinforced


func can_break_by(_source: String) -> bool:
	return false


# An ordinary blast, from anyone, does nothing here. The player's Thermos asks through blast().
func take_blast() -> void:
	pass


func break_with_level(level: int) -> bool:
	if is_queued_for_deletion():
		return false
	if level < needed_level:
		resisted.emit()
		return false
	_break()
	return true


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw_placeholder() -> void:
	var p := look()
	var pulse := 0.5 + 0.5 * sin(_time * TAU / GLOW_PERIOD)
	var half := RoomBackdrop.TILE / 2.0
	var body := Rect2(-half, -half, half * 2.0, half * 2.0)
	draw_rect(body, p.reinforced)
	draw_rect(body, p.reinforced_edge, false, 2.0)
	# Steel bands and rivets, then seams that glow, so it is plainly something special.
	for y in [-9.0, 7.0]:
		draw_rect(Rect2(-half + 1.0, y, half * 2.0 - 2.0, 3.0), p.reinforced.darkened(0.35))
	for corner: Vector2 in [Vector2(-11, -12), Vector2(11, -12), Vector2(-11, 14), Vector2(11, 14)]:
		draw_circle(corner, 1.5, p.reinforced.lightened(0.45))
	var glow := Color(p.reinforced_glow, 0.45 + 0.45 * pulse)
	draw_line(Vector2(-12, -4), Vector2(-3, 2), glow, 1.5)
	draw_line(Vector2(-3, 2), Vector2(2, -3), glow, 1.5)
	draw_line(Vector2(2, -3), Vector2(12, 3), glow, 1.5)
	draw_rect(body.grow(-1.0), Color(p.reinforced_glow, 0.12 * pulse), false, 1.0)
