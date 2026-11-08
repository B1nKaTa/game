class_name AttackWarnings
extends RefCounted

# Whether enemies draw their attack warnings (the red circles, lanes, cones, rings, fills and ground
# marks). Off by default, for regular enemies, mini bosses and floor bosses alike. A regular's tell is
# its windup pose and a brief pale flash as it starts (Enemy.WINDUP_CUE). A boss or mini boss has the
# same windup and flash, the faint dark cue below on the ground for an area or ground attack, and the
# big things its attacks are made of (the beam's lens, the Ouija board and planchette, the tarot cards,
# the anchor, the dancers), which always show. Safe-spot marks (SafeSpotMark, the mint) are not
# warnings: they show where to stand, so they always show too. The Game tab's "Attack warnings" setting
# turns every red shape back on (Settings.apply sets this). Timing, range and damage never change; only
# the drawing does.
static var shown := false

# With the setting off, an attack that lands on the ground with nothing flying in to give it away (the
# bingo caller's marks, a steam lane, a cord's band, a boss's slam ring or lane) still shows a faint cue
# where it will hurt: a dark, neutral shadow, never red, at CUE_ALPHA rising to CUE_ALPHA_LATE, that
# grows over the last part of the warning (from CUE_GROW_FROM of it). It is meant to be easy to miss in
# a crowd, not invisible.
const CUE_COLOR := Color(0.05, 0.04, 0.05)
const CUE_ALPHA := 0.25
const CUE_ALPHA_LATE := 0.35
const CUE_GROW_FROM := 0.6
const CUE_LINE := 1.0


static func drawn_for(def: EnemyDef) -> bool:
	return def != null and shown


# Whether a world attack (a lobbed tub, a cord's band, a puck's path, a boss's lane or falling star)
# draws the warning shapes of the enemy that started it. As with a ground strike, a source that is gone
# leaves its shapes drawn. Typed Variant, since a freed enemy cannot be passed as an Enemy.
static func drawn_by(source: Variant) -> bool:
	if not is_instance_valid(source) or not (source as Object).has_method("shows_warnings"):
		return true
	return source.shows_warnings()


# How far the hidden cue has grown, 0 to 1, for a warning filled this far (0 to 1).
static func cue_growth(filled: float) -> float:
	return smoothstep(CUE_GROW_FROM, 1.0, filled)


# The hidden cue's colour for a warning filled this far.
static func cue_color(filled: float) -> Color:
	return Color(CUE_COLOR, lerpf(CUE_ALPHA, CUE_ALPHA_LATE, cue_growth(filled)))


# The hidden cue in the shape of a red mark, drawn on canvas in its current transform: a thin dark edge
# from the start, filling in from the middle over the last part of the warning.
static func draw_cue_circle(canvas: CanvasItem, at: Vector2, radius: float, filled: float) -> void:
	var cue := cue_color(filled)
	canvas.draw_arc(at, radius, 0.0, TAU, 32, cue, CUE_LINE)
	var grown := radius * cue_growth(filled)
	if grown > 0.5:
		canvas.draw_circle(at, grown, cue)


# A lane (rect, its length along x): the edge, and a band down its middle that widens to fill it.
static func draw_cue_lane(canvas: CanvasItem, rect: Rect2, filled: float) -> void:
	var cue := cue_color(filled)
	canvas.draw_rect(rect, cue, false, CUE_LINE)
	var grown := rect.size.y * cue_growth(filled)
	if grown > 0.5:
		canvas.draw_rect(Rect2(rect.position.x, rect.get_center().y - grown / 2.0, rect.size.x, grown), cue)


# A patch of floor (a falling tile's square, a strip of floor): the edge, and a fill from its middle.
static func draw_cue_rect(canvas: CanvasItem, rect: Rect2, filled: float) -> void:
	var cue := cue_color(filled)
	canvas.draw_rect(rect, cue, false, CUE_LINE)
	var grown := rect.size * cue_growth(filled)
	if grown.x > 0.5 and grown.y > 0.5:
		canvas.draw_rect(Rect2(rect.get_center() - grown / 2.0, grown), cue)


# Any other shape (a sector, a cone, a blade), as its outline points: the edge, then the shape filling
# out from its middle.
static func draw_cue_polygon(canvas: CanvasItem, points: PackedVector2Array, filled: float) -> void:
	if points.size() < 3:
		return
	var cue := cue_color(filled)
	var edge := points.duplicate()
	edge.append(points[0])
	canvas.draw_polyline(edge, cue, CUE_LINE)
	var growth := cue_growth(filled)
	if growth <= 0.05:
		return
	var middle := Vector2.ZERO
	for point in points:
		middle += point
	middle /= points.size()
	var grown := PackedVector2Array()
	for point in points:
		grown.append(middle + (point - middle) * growth)
	canvas.draw_colored_polygon(grown, cue)
