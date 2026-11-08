class_name PhoneCordLash
extends Node2D

# A Phone Psychic's "I sense you": a red ring marks the spot where Grandpa's feet stood, and the band
# the cord will sweep shows with it, an arc round the psychic through that spot. The ring and the band
# fill for the whole WARNING, then the coiled phone cord lashes along the arc, and feet in the band at
# that moment cost a pill, once. It lies where the psychic stood (it holds still while it senses), and
# comes to nothing if the psychic falls first.
const WARNING := 0.7
# The ring round his marked spot.
const MARK_RADIUS := 14.0
# The band is this wide across (out from the psychic) and spans this far either side of the spot.
const BAND := 22.0
const HALF_ARC := PI * 40.0 / 180.0
# The cord reaches no nearer or farther than these from the psychic.
const NEAREST := 40.0
const REACH := 170.0
const LASH_SHOW := 0.25
const COLOR := Color("e4524f")
const CORD := Color("f1e6c8")
const CORD_SHADE := Color("8a7a5c")
# The band as a plan sees it: circles this far apart along the arc, each this much wider than half
# the band, hurting for this long after the lash.
const ROUTE_STEP := 10.0
const ROUTE_SPARE := 3.0
const ROUTE_HIT_TIME := 0.05

var _source: Enemy
var _spot := Vector2.ZERO
var _warning := WARNING
var _left := WARNING
var _lashed := false
var _show_left := LASH_SHOW


# Whether a point lies in the band an arc from origin through spot sweeps.
static func in_band(origin: Vector2, spot: Vector2, point: Vector2, margin := 0.0) -> bool:
	var radius := origin.distance_to(spot)
	var distance := origin.distance_to(point)
	if absf(distance - radius) > BAND / 2.0 + margin:
		return false
	var off := absf((spot - origin).angle_to(point - origin))
	# A margin along the arc, turned into an angle at the band's radius.
	return off <= HALF_ARC + margin / maxf(radius, 1.0)


# The band's radius for a marked spot this far away, kept inside the cord's reach.
static func reaches(distance: float) -> bool:
	return distance >= NEAREST and distance <= REACH


# Puts one down for a psychic: anchored where it stands, through the spot his feet hold now.
static func sense(enemy: Enemy, spot: Vector2) -> PhoneCordLash:
	var lash := PhoneCordLash.new()
	lash.setup(enemy, spot - enemy.global_position, WARNING)
	enemy.get_parent().add_child(lash)
	lash.global_position = enemy.global_position
	return lash


# spot_offset is the marked spot from the lash's own position (the psychic's).
func setup(source: Enemy, spot_offset: Vector2, warning: float) -> void:
	_source = source
	_spot = spot_offset
	_warning = warning
	_left = warning
	z_index = Projectile.SHOT_Z


func spot() -> Vector2:
	return global_position + _spot


func has_lashed() -> bool:
	return _lashed


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)


func covers(point: Vector2, margin := 0.0) -> bool:
	return in_band(global_position, spot(), point, margin)


# True once, on the moment it lashes.
func advance(delta: float) -> bool:
	if _lashed:
		_show_left -= delta
		return false
	_left -= delta
	if _left <= 0.0:
		_lashed = true
		return true
	return false


# What it means for a point, for a simulated player: 2 in the band, 1 just beside it.
func threat_at(p: Vector2, strict: bool) -> int:
	if _lashed:
		return 0
	if covers(p, 8.0 if strict else 4.0):
		return 2
	return 1 if covers(p, 20.0) else 0


func threat_imminent(p: Vector2) -> bool:
	return not _lashed and _left < 0.12 and covers(p, 4.0)


# Its shapes for a plan made now: circles along the band, hurting the moment it lashes.
func route_circles() -> Array:
	if _lashed:
		return []
	var shapes: Array = []
	var origin := global_position
	var radius := _spot.length()
	var middle := _spot.angle()
	var steps := maxi(ceili(radius * HALF_ARC * 2.0 / ROUTE_STEP), 1)
	for i in steps + 1:
		var angle := middle - HALF_ARC + HALF_ARC * 2.0 * i / steps
		var at := origin + Vector2.from_angle(angle) * radius
		shapes.append([Vector3(at.x, at.y, BAND / 2.0 + ROUTE_SPARE), Vector2(_left, _left + ROUTE_HIT_TIME)])
	return shapes


func _process(delta: float) -> void:
	queue_redraw()
	if _lashed:
		_show_left -= delta
		if _show_left <= 0.0:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if advance(delta) and is_instance_valid(_source.target) and covers(_source.target_ground()):
		_source.hit_target(_source.attack_damage())


func _band_points(inner: float, outer: float, from_angle: float, to_angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 16
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(from_angle, to_angle, float(i) / steps)) * outer)
	for i in steps + 1:
		points.append(Vector2.from_angle(lerpf(to_angle, from_angle, float(i) / steps)) * inner)
	return points


func _draw() -> void:
	var radius := _spot.length()
	var middle := _spot.angle()
	var inner := maxf(radius - BAND / 2.0, 1.0)
	var outer := radius + BAND / 2.0
	if _lashed:
		# The coiled cord whips along the arc and fades.
		var fade := clampf(_show_left / LASH_SHOW, 0.0, 1.0)
		var coil := PackedVector2Array()
		var steps := 40
		for i in steps + 1:
			var angle := lerpf(middle - HALF_ARC, middle + HALF_ARC, float(i) / steps)
			coil.append(Vector2.from_angle(angle) * (radius + sin(i * 1.6) * 4.0))
		draw_polyline(coil, Color(CORD_SHADE, fade), 4.0)
		draw_polyline(coil, Color(CORD, fade), 2.0)
		return
	# The red band only with Attack warnings on (AttackWarnings); otherwise the caller's windup and a
	# faint cue on the band, which thickens as the lash nears.
	if not AttackWarnings.drawn_by(_source):
		var cue := AttackWarnings.cue_color(fill())
		var outline := _band_points(inner, outer, middle - HALF_ARC, middle + HALF_ARC)
		outline.append(outline[0])
		draw_polyline(outline, cue, 1.0)
		var half := BAND / 2.0 * AttackWarnings.cue_growth(fill())
		if half > 0.5:
			draw_colored_polygon(_band_points(maxf(radius - half, 1.0), radius + half, middle - HALF_ARC, middle + HALF_ARC), cue)
		return
	var filled := fill()
	var band := _band_points(inner, outer, middle - HALF_ARC, middle + HALF_ARC)
	draw_colored_polygon(band, Color(COLOR, 0.1 + 0.3 * filled))
	var edge := band.duplicate()
	edge.append(band[0])
	draw_polyline(edge, COLOR, 2.0)
	# The band fills along the arc from both ends toward the spot as the lash nears.
	var reach := HALF_ARC * filled
	if reach > 0.01:
		draw_colored_polygon(_band_points(inner, outer, middle - HALF_ARC, middle - HALF_ARC + reach), Color(COLOR, 0.2))
		draw_colored_polygon(_band_points(inner, outer, middle + HALF_ARC - reach, middle + HALF_ARC), Color(COLOR, 0.2))
	# The ring on his marked spot.
	draw_circle(_spot, MARK_RADIUS * filled, Color(COLOR, 0.15 + 0.3 * filled))
	draw_arc(_spot, MARK_RADIUS, 0.0, TAU, 24, COLOR, 2.0)
