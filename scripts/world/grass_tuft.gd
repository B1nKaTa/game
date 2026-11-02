class_name GrassTuft
extends BreakableBlock

# Decor that blocks nothing. A swing, a thrown cane, a blast or a boss cuts it, and it
# stays cut. It leaves the breakable group once cut, so nothing counts it twice.
var variant := 0
var cut := false


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(22, 18)


func art_id() -> String:
	return "grass"


func debris_color() -> Color:
	return look().grass


func can_break_by(_source: String) -> bool:
	return not cut


func hit_by(source: String) -> bool:
	if cut or not can_break_by(source):
		return false
	cut = true
	if is_in_group("breakable"):
		remove_from_group("breakable")
	var parent := get_parent()
	if parent != null and is_inside_tree():
		DeathBurst.spawn(parent, position, look().grass, false)
	queue_redraw()
	return true


func _draw_placeholder() -> void:
	var p := look()
	var heights := [8.0, 5.0, 9.0, 6.0]
	for i in 4:
		var x := -6.0 + i * 4.0
		var h: float = 2.0 if cut else heights[(i + variant) % 4]
		draw_line(Vector2(x, 6), Vector2(x + (i - 1.5) * (0.6 if cut else 1.5), 6.0 - h), p.grass_cut if cut else p.grass, 2.0)
