class_name GapMark
extends SafeSpotMark

# The green mark on the open gap of the Chairman's bar chart. It always lies near Grandpa, in his own
# glow, on the pale office carpet, where the parlour's mint ring washed out to white. So it is a
# deeper green with a dark rim, which stays green however brightly it is lit.
const GAP_COLOR := Color("2fbf55")
const GAP_RIM := Color("0f4a22")
const GAP_CORE := Color(0.15, 0.75, 0.35, 0.35)


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_age * PULSE_SPEED)
	draw_circle(Vector2.ZERO, RADIUS, GAP_CORE)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, GAP_RIM, 4.0)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, GAP_COLOR, 2.0)
	draw_arc(Vector2.ZERO, RADIUS * (0.4 + 0.2 * pulse), 0.0, TAU, 16, GAP_RIM, 3.0)
	draw_arc(Vector2.ZERO, RADIUS * (0.4 + 0.2 * pulse), 0.0, TAU, 16, GAP_COLOR, 1.5)
