class_name BreakableBlock
extends StaticBody2D

signal broken(at: Vector2)

const SOURCE_BLAST := "blast"
const SOURCE_BOSS := "boss"
const SOURCE_CANE := "cane"
const FILL := Color("6b4a2a")
const EDGE := Color("3a2614")

# Set before the block enters the tree, so a floor can recolor props.
var palette: RoomPalette


# Everything breakable near a point is hit once, whoever is doing the breaking.
static func smash(tree: SceneTree, center: Vector2, radius: float, source: String) -> int:
	return smash_among(tree.get_nodes_in_group("breakable"), center, radius, source)


static func smash_among(blocks: Array, center: Vector2, radius: float, source: String) -> int:
	var count := 0
	for block: BreakableBlock in blocks:
		if block.is_queued_for_deletion():
			continue
		if center.distance_to(MeleeArc.closest_point(block.body_rect(), center)) > radius:
			continue
		if source == SOURCE_BLAST:
			block.take_blast()
			count += 1
		elif block.hit_by(source):
			count += 1
	return count


func _ready() -> void:
	add_to_group("breakable")
	collision_layer = 1 if is_solid() else 0
	collision_mask = 0
	if is_solid():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = body_size()
		shape.shape = rect
		add_child(shape)
	queue_redraw()


func look() -> RoomPalette:
	if palette == null:
		palette = RoomPalette.new()
	return palette


# A crate blocks the way until a bomb or a boss breaks it.
func is_solid() -> bool:
	return true


func body_size() -> Vector2:
	return Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)


func art_id() -> String:
	return "crate"


func debris_color() -> Color:
	return look().crate


func can_break_by(source: String) -> bool:
	return source == SOURCE_BLAST or source == SOURCE_BOSS


func body_rect() -> Rect2:
	var half := body_size() / 2.0
	return Rect2(global_position - half, half * 2.0)


func hit_by(source: String) -> bool:
	if is_queued_for_deletion() or not can_break_by(source):
		return false
	_break()
	return true


func take_blast() -> void:
	hit_by(SOURCE_BLAST)


# What breaking it sounds like. Furniture splinters by default; stone and leaves say otherwise.
func break_sound() -> String:
	return "wood_break"


func _break() -> void:
	Sfx.play(break_sound())
	broken.emit(global_position)
	var parent := get_parent()
	if parent != null and is_inside_tree():
		DeathBurst.spawn(parent, position, debris_color(), false)
	queue_free()


func _draw() -> void:
	var art := PropArt.texture(art_id())
	if art != null:
		draw_texture(art, -art.get_size() / 2.0)
		return
	_draw_placeholder()


func _draw_placeholder() -> void:
	var half := RoomBackdrop.TILE / 2.0
	var rect := Rect2(-half, -half, half * 2.0, half * 2.0)
	draw_rect(rect, look().crate)
	draw_rect(rect, look().crate_edge, false, 2.0)
	draw_line(rect.position, rect.end, look().crate_edge, 2.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), look().crate_edge, 2.0)
