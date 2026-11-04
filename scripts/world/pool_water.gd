class_name PoolWater
extends Hole

# A cell of the deck's swimming pool. Like a hole, nobody who walks can cross it and nothing breaks
# it, while shots and the thrown dentures fly over and ghosts drift across. The water ripples gently
# under the night lights, with a tiled rim where it meets the deck.
const WATER := Color("1f6f9a")
const WATER_DEEP := Color("145073")
const SHINE := Color(0.75, 0.95, 1.0, 0.45)
const RIM := Color("d8dde3")

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var art := PropArt.texture("pool_water")
	if art != null:
		draw_texture(art, -art.get_size() / 2.0)
		return
	var half := RoomBackdrop.TILE / 2.0
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), WATER)
	draw_rect(Rect2(-half + 4, -half + 4, half * 2.0 - 8.0, half * 2.0 - 8.0), WATER_DEEP)
	for i in 2:
		var sway := sin(_time * 1.6 + i * 2.3 + position.x * 0.05) * 4.0
		var y := -6.0 + i * 11.0
		draw_line(Vector2(-10 + sway, y), Vector2(-2 + sway, y - 1.5), SHINE, 1.0)
		draw_line(Vector2(2 + sway, y + 1.0), Vector2(9 + sway, y), SHINE, 1.0)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), RIM, false, 2.0)
