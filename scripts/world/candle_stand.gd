class_name CandleStand
extends BreakableBlock

# A tall brass stand of candles that lights the floor around it. It blocks nothing, anything that
# touches it breaks it, putting its light out, and it never holds anything, like grass.
const LIGHT_ENERGY := 0.7
const LIGHT_SCALE := 0.9


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(14, 24)


func art_id() -> String:
	return "candle_stand"


func debris_color() -> Color:
	return look().candle_wax


func can_break_by(_source: String) -> bool:
	return true


func _ready() -> void:
	super._ready()
	var light := Lighting.make_light(look().candle_flame, LIGHT_ENERGY, LIGHT_SCALE)
	light.position = Vector2(0, -12)
	add_child(light)
	Lighting.add_flicker(light, look().flicker)


func _draw_placeholder() -> void:
	var p := look()
	draw_line(Vector2(0, 12), Vector2(0, -6), p.brass, 2.0)
	draw_line(Vector2(-6, 12), Vector2(6, 12), p.brass, 2.0)
	draw_line(Vector2(-6, -6), Vector2(6, -6), p.brass, 2.0)
	for x in [-5.0, 0.0, 5.0]:
		draw_rect(Rect2(x - 1.5, -13, 3, 7), p.candle_wax)
		draw_circle(Vector2(x, -15), 1.8, p.candle_flame)
