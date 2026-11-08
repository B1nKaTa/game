class_name GavelStrike
extends GroundStrike

# The Chairman's gavel coming down on a warned spot: the heaviest attack, so its mark is the clearest.
# It lands as any warned spot does, but a second ring stands outside the first for its whole warning,
# and the gavel's shadow grows over the spot as it falls.
const RING_GAP := 8.0
const SHADOW := Color(0.04, 0.03, 0.06)
const HEAD := Color("5a3423")
const BAND := Color("e8c04a")
# The gavel that lands (art/props/gavel.png), drawn 1:1 over the dust; its growing shadow in the
# warning stays drawn, and so does the gavel when the picture is missing.
const ART := "gavel"


func _draw() -> void:
	if _landed:
		var progress := 1.0 - maxf(_show_left, 0.0) / SHOW_TIME
		draw_circle(Vector2.ZERO, _radius * minf(0.6 + progress, 1.0), Color(DUST_COLOR, 0.7 * (1.0 - progress)))
		var art := PropArt.texture(ART)
		if art != null:
			draw_texture(art, PropArt.centred(art), Color(1, 1, 1, 1.0 - progress))
			return
		_draw_gavel(1.0, HEAD, 1.0 - progress)
		return
	# The red rings only with Attack warnings on (AttackWarnings); otherwise the faint cue. The gavel's
	# growing shadow always shows.
	var red := AttackWarnings.drawn_by(_source)
	if _delay > 0.0:
		if red:
			draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, Color(COLOR, WAITING_ALPHA), 1.0)
		return
	var filled := fill()
	if red:
		draw_circle(Vector2.ZERO, _radius * filled, Color(COLOR, 0.15 + 0.3 * filled))
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, COLOR, 2.0)
		draw_arc(Vector2.ZERO, _radius + RING_GAP, 0.0, TAU, 32, COLOR, 2.0)
	else:
		AttackWarnings.draw_cue_circle(self, Vector2.ZERO, _radius, filled)
	_draw_gavel(0.3 + 0.7 * filled, SHADOW, 0.25 + 0.5 * filled)


# A gavel seen from above, its head across the spot and its handle off to one side.
func _draw_gavel(size: float, color: Color, alpha: float) -> void:
	var r := _radius * 0.8 * size
	draw_rect(Rect2(-r * 0.6, -r * 0.3, r * 1.2, r * 0.6), Color(color, alpha))
	draw_rect(Rect2(-r * 0.15, -r * 0.3, r * 0.3, r * 0.6), Color(BAND, alpha * 0.8))
	draw_line(Vector2(0.0, r * 0.3), Vector2(r * 0.25, r * 1.1), Color(color, alpha), maxf(3.0 * size, 1.0))
	draw_rect(Rect2(-r * 0.6, -r * 0.3, r * 1.2, r * 0.6), Color(0, 0, 0, alpha), false, 1.0)
