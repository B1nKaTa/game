class_name SeancePartition
extends CubicleWall

# A length of the hotline's cubicle partition: violet fabric in a teal frame, standing a little taller
# than its cell. Solid, and only blasts and bosses break it, like the office's partitions, and it can hide
# a coin at the furniture rate. A partition beside another one joins it, so a run reads as one wall, and
# the 64x48 art of two cells cuts into two 32x48 halves for it.
const ART_SIZE := Vector2(32, 48)

var joins_west := false
var joins_east := false


func art_id() -> String:
	return "cubicle_partition"


func debris_color() -> Color:
	return look().partition_fabric


func _draw_placeholder() -> void:
	var p := look()
	var left := -16.0
	var right := 16.0
	draw_rect(Rect2(left, -20, right - left, 30), p.partition_fabric)
	draw_rect(Rect2(left, -8, right - left, 3), p.partition_fabric.lightened(0.08))
	draw_rect(Rect2(left, -23, right - left, 3), p.partition_frame)
	draw_line(Vector2(left, 11), Vector2(right, 11), p.partition_frame.darkened(0.5), 2.0)
	if not joins_west:
		draw_rect(Rect2(left, -23, 3, 34), p.partition_frame)
	if not joins_east:
		draw_rect(Rect2(right - 3, -23, 3, 34), p.partition_frame)
	draw_line(Vector2(left, -23), Vector2(right, -23), Color.BLACK, 1.0)
	draw_line(Vector2(left, 12), Vector2(right, 12), Color.BLACK, 1.0)
	if not joins_west:
		draw_line(Vector2(left, -23), Vector2(left, 12), Color.BLACK, 1.0)
	if not joins_east:
		draw_line(Vector2(right, -23), Vector2(right, 12), Color.BLACK, 1.0)
