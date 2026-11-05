class_name SecretWall
extends BreakableBlock

const CRACK_COLOR := Color(0.0, 0.0, 0.0, 0.55)


# Finding a secret room is the player's reward, so only their Thermos opens one.
static func blast_among(blocks: Array, center: Vector2, radius: float) -> int:
	var opened := 0
	for block in blocks:
		if not block is SecretWall or block.is_queued_for_deletion():
			continue
		if center.distance_to(MeleeArc.closest_point(block.body_rect(), center)) > radius:
			continue
		if block.hit_by(SOURCE_BLAST):
			opened += 1
	return opened


static func blast(tree: SceneTree, center: Vector2, radius: float) -> int:
	return blast_among(tree.get_nodes_in_group("breakable"), center, radius)


func can_break_by(source: String) -> bool:
	return source == SOURCE_BLAST


# An Auditor's blast does nothing here. The player's Thermos asks through blast().
func take_blast() -> void:
	pass


# The crack is the only hint, so it stays faint.
func _draw() -> void:
	draw_line(Vector2(-3, -14), Vector2(1, -6), CRACK_COLOR, 1.0)
	draw_line(Vector2(1, -6), Vector2(-4, 1), CRACK_COLOR, 1.0)
	draw_line(Vector2(-4, 1), Vector2(2, 8), CRACK_COLOR, 1.0)
	draw_line(Vector2(2, 8), Vector2(0, 15), CRACK_COLOR, 1.0)
	draw_line(Vector2(1, -6), Vector2(7, -3), CRACK_COLOR, 1.0)
	draw_line(Vector2(-4, 1), Vector2(-9, 4), CRACK_COLOR, 1.0)


# The room plays the reveal itself when the crack opens.
func break_sound() -> String:
	return ""
