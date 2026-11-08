class_name OuijaPlanchette
extends Node2D

# Madame Zara's Ouija board, the heaviest attack of her fight: the planchette slides from letter to
# letter across the board, spelling out what the spirits say, and touching it costs three pills, once.
# For its whole windup the path it will take is shown, a red band from letter to letter with a ring on
# every letter it stops on, outlined twice as the heaviest attack's are, and filling; as it slides, all it
# has still to cross stays shown. It is drawn about the size of its 32x32 art. It lies at the room's
# origin, holds its path in room space, and comes to nothing if she falls first.
const RADIUS := 16.0
const SPEED := 230.0
# How long it rests on each letter it reaches.
const PAUSE := 0.12
const CIRCLE_STEP := 12.0
const FADE := 0.3
const COLOR := Color("e4524f")
const WOOD := Color(0.86, 0.72, 0.52)
const WOOD_EDGE := Color(0.32, 0.2, 0.1)
const LENS := Color(0.85, 0.95, 1.0, 0.75)
# The size of its art, for when it is wired: planchette.png is 32x32.
const ART_SIZE := Vector2(32, 32)

var _source: Enemy
var _path: Array[Vector2] = []
var _word := ""
var _warning := 1.2
var _left := 1.2
var _time := 0.0
var _total := 0.0
var _damage := -1
var _has_hit := false
var _fade_left := FADE


# How long it takes to slide the whole path, resting on every letter after the first.
static func slide_time(path: Array[Vector2]) -> float:
	var time := 0.0
	for i in range(1, path.size()):
		time += path[i - 1].distance_to(path[i]) / SPEED + PAUSE
	return time


# Where it is a time into its slide.
static func position_at(path: Array[Vector2], time: float) -> Vector2:
	if path.is_empty():
		return Vector2.ZERO
	var left := maxf(time, 0.0)
	for i in range(1, path.size()):
		var travel := path[i - 1].distance_to(path[i]) / SPEED
		if left <= travel:
			return path[i - 1].lerp(path[i], 0.0 if travel <= 0.0 else left / travel)
		left -= travel
		if left <= PAUSE:
			return path[i]
		left -= PAUSE
	return path[path.size() - 1]


# The slide sampled for OverlapRoute: circles every CIRCLE_STEP along the path, each hurting for the
# moment the planchette passes it, and one on every letter for its rest. delay counts from now to the
# slide's start; from starts that many seconds into the slide. Returns [Vector3, Vector2] pairs.
static func plan_circles(path: Array[Vector2], delay: float, from := 0.0) -> Array:
	var shapes: Array = []
	var radius := RADIUS + CIRCLE_STEP / 2.0
	var at := 0.0
	for i in range(1, path.size()):
		var a := path[i - 1]
		var b := path[i]
		var length := a.distance_to(b)
		var travel := length / SPEED
		var pieces := maxi(ceili(length / CIRCLE_STEP), 1)
		var half := travel / pieces / 2.0
		for k in pieces + 1:
			var when := at + travel * k / float(pieces)
			if when + half < from:
				continue
			var spot := a.lerp(b, k / float(pieces))
			shapes.append([Vector3(spot.x, spot.y, radius), Vector2(delay + maxf(when - half, from) - from, delay + when + half - from)])
		at += travel
		if at + PAUSE >= from:
			shapes.append([Vector3(b.x, b.y, radius), Vector2(delay + maxf(at, from) - from, delay + at + PAUSE - from)])
		at += PAUSE
	return shapes


# The shortest distance from a point to the path, from a time into the slide on.
static func distance_to_path(path: Array[Vector2], point: Vector2, from := 0.0) -> float:
	if path.is_empty():
		return INF
	var best := point.distance_to(position_at(path, from))
	var at := 0.0
	for i in range(1, path.size()):
		var travel := path[i - 1].distance_to(path[i]) / SPEED
		if at + travel >= from:
			var start := position_at(path, maxf(at, from))
			best = minf(best, _to_segment(point, start, path[i]))
		at += travel + PAUSE
	return best


# Whether its whole path shows clear of the HUD (a BossMoves.clear_view), sampled every CIRCLE_STEP, with
# at least half its band on screen.
static func path_shown(path: Array[Vector2], clear: Dictionary) -> bool:
	if path.is_empty():
		return false
	var margin := RADIUS / 2.0
	if not BossMoves.shown_clear(clear, path[0], margin):
		return false
	for i in range(1, path.size()):
		var pieces := maxi(ceili(path[i - 1].distance_to(path[i]) / CIRCLE_STEP), 1)
		for k in range(1, pieces + 1):
			if not BossMoves.shown_clear(clear, path[i - 1].lerp(path[i], k / float(pieces)), margin):
				return false
	return true


static func _to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length := ab.length_squared()
	if length <= 0.0001:
		return point.distance_to(a)
	var share := clampf((point - a).dot(ab) / length, 0.0, 1.0)
	return point.distance_to(a + ab * share)


func setup(source: Enemy, path: Array[Vector2], warning: float, damage := -1, word := "") -> void:
	_source = source
	_path = path.duplicate()
	_word = word
	_warning = warning
	_left = warning
	_damage = damage
	_total = slide_time(_path)
	z_index = Projectile.SHOT_Z


func path() -> Array[Vector2]:
	return _path


func word() -> String:
	return _word


func is_warning() -> bool:
	return _left > 0.0


func is_sliding() -> bool:
	return _left <= 0.0 and _time < _total


func is_over() -> bool:
	return _left <= 0.0 and _time >= _total


func is_spent() -> bool:
	return is_over() or _has_hit


func has_hit() -> bool:
	return _has_hit


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)


func now_at() -> Vector2:
	return position_at(_path, _time)


func total_time() -> float:
	return _warning + _total


# Its shapes for a plan made now: the rest of its slide, from where it is.
func route_circles() -> Array:
	if is_over() or _has_hit:
		return []
	return plan_circles(_path, maxf(_left, 0.0), _time)


# Moves it on. Returns where it was and where it is now, or an empty array while it waits.
func advance(delta: float) -> Array:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0:
			return []
		delta = -_left
		_left = 0.0
	if _time >= _total:
		return []
	var before := position_at(_path, _time)
	_time = minf(_time + delta, _total)
	return [before, position_at(_path, _time)]


# For a simulated player: 2 anywhere along what it has still to cross.
func threat_at(p: Vector2, strict: bool) -> int:
	if is_over() or _has_hit:
		return 0
	var margin := 12.0 if strict else 4.0
	return 2 if distance_to_path(_path, p, _time) <= RADIUS + margin else 0


func threat_imminent(p: Vector2) -> bool:
	if is_over() or _has_hit:
		return false
	if is_warning():
		return _left < 0.12 and p.distance_to(now_at()) < RADIUS + 30.0
	var ahead := position_at(_path, _time + 0.15)
	return _to_segment(p, now_at(), ahead) < RADIUS + 10.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if is_over():
		_fade_left -= delta
		if _fade_left <= 0.0:
			queue_free()
		return
	var moved := advance(delta)
	if moved.is_empty() or _has_hit or not is_instance_valid(_source.target):
		return
	if _to_segment(_source.target_ground(), moved[0], moved[1]) <= RADIUS:
		if _source.target.take_hit(_source.attack_damage(_damage)):
			_has_hit = true


func _draw() -> void:
	var alpha := clampf(_fade_left / FADE, 0.0, 1.0) if is_over() else 1.0
	if not is_over() and not _has_hit:
		_draw_path()
	_draw_planchette(now_at() - global_position, alpha)


# Every piece still to cross, filling through the windup, with the heaviest attack's second outline.
func _draw_path() -> void:
	var progress := fill()
	var tint := Color(COLOR, 0.14 + (0.26 * progress if is_warning() else 0.12))
	# With Attack warnings off (AttackWarnings) the path is the faint dark cue; the board and the
	# planchette always show.
	var red := AttackWarnings.drawn_by(_source)
	var stops: Array[Vector2] = []
	var from := now_at() - global_position
	var at := 0.0
	for i in range(1, _path.size()):
		var travel := _path[i - 1].distance_to(_path[i]) / SPEED
		var b := _path[i] - global_position
		if at + travel + PAUSE >= _time:
			var a := from if at <= _time else _path[i - 1] - global_position
			_draw_band(a, b, tint, red, progress)
			stops.append(b)
		at += travel + PAUSE
	if is_warning():
		stops.push_front(_path[0] - global_position)
	for stop in stops:
		if not red:
			AttackWarnings.draw_cue_circle(self, stop, RADIUS, progress)
			continue
		draw_circle(stop, RADIUS, tint)
		draw_arc(stop, RADIUS, 0.0, TAU, 20, COLOR, 2.0)
		draw_arc(stop, RADIUS + Enemy.HEAVIEST_LANE_GAP, 0.0, TAU, 20, COLOR, 2.0)


func _draw_band(a: Vector2, b: Vector2, tint: Color, red := true, progress := 0.0) -> void:
	var length := a.distance_to(b)
	if length < 1.0:
		return
	draw_set_transform(a, (b - a).angle())
	var band := Rect2(0.0, -RADIUS, length, RADIUS * 2.0)
	if not red:
		AttackWarnings.draw_cue_lane(self, band, progress)
		draw_set_transform(Vector2.ZERO)
		return
	draw_rect(band, tint)
	draw_rect(band, COLOR, false, 2.0)
	draw_rect(band.grow(Enemy.HEAVIEST_LANE_GAP), COLOR, false, 2.0)
	draw_set_transform(Vector2.ZERO)


# A heart-shaped wooden planchette with a round glass window, about its art's 32x32
# (res://art/props/planchette.png, drawn at 1:1 when it is there).
const ART_ID := "planchette"


func _draw_planchette(at: Vector2, alpha: float) -> void:
	var art := PropArt.texture(ART_ID)
	if art != null:
		draw_texture_rect(art, Rect2((at - art.get_size() / 2.0).round(), art.get_size()), false, Color(1, 1, 1, alpha))
		return
	var points := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		# A heart, point down, about 28 px across.
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(at + Vector2(x, y) * 0.85 + Vector2(0.0, -1.0))
	draw_colored_polygon(points, Color(WOOD, alpha))
	points.append(points[0])
	draw_polyline(points, Color(WOOD_EDGE, alpha), 1.5)
	draw_circle(at + Vector2(0.0, -2.0), 5.0, Color(LENS, LENS.a * alpha))
	draw_arc(at + Vector2(0.0, -2.0), 5.0, 0.0, TAU, 12, Color(WOOD_EDGE, alpha), 1.0)
