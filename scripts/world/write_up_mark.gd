class_name WriteUpMark
extends Node2D

# A memo thrown by an HR Representative onto a warned spot. A red circle fills for its warning while
# the memo flies in, then it lands: it breaks props and hurts Grandpa if his feet are inside, as any
# warned spot does. It leaves a write-up lying there for a while, a pink form with a red stamp, which
# stings him if he stands in it for a moment, and again each time he stays that long. It comes to
# nothing if the thrower falls before it lands, and a lying write-up is filed away early if she falls.
const WARNING := 0.9
const RADIUS := 22.0
const LINGER := 3.5
# Standing in a write-up this long stings, once, and the count starts again.
const STING_AFTER := 0.6
const STING_DAMAGE := 1
const FADE := 0.4
const THROW_ARC := 24.0
const COLOR := Color("e4524f")
const FORM := Color("f6d3dc")
const FORM_EDGE := Color("9a3a52")
const STAMP := Color("c8202c")
const MEMO := Color("f4efe0")

var _source: Enemy
var _target: Node2D
var _warning := WARNING
var _left := WARNING
var _linger := LINGER
var _landed := false
var _stood := 0.0
var _thrown_from := Vector2.INF


# Whether standing in a write-up for stood seconds stings now.
static func stings(stood: float) -> bool:
	return stood >= STING_AFTER


func setup(source: Enemy, warning := WARNING, linger := LINGER) -> void:
	_source = source
	_target = source.target if source != null else null
	_warning = warning
	_left = warning
	_linger = linger
	# The warning shows above the room, as every mark does.
	z_index = Projectile.SHOT_Z


func throw_from(point: Vector2) -> void:
	_thrown_from = point


func has_landed() -> bool:
	return _landed


func covers(point: Vector2) -> bool:
	return _landed and _linger > 0.0 and global_position.distance_to(point) <= RADIUS


func is_finished() -> bool:
	return _landed and _linger <= 0.0


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)


# Runs the warning, then the write-up's time. True once, on the moment it lands.
func advance(delta: float) -> bool:
	if not _landed:
		_left -= delta
		if _left <= 0.0:
			_landed = true
			return true
		return false
	_linger -= delta
	return false


# Counts how long someone has stood in it. True when that stings, and the count starts again.
func stand(delta: float, inside: bool) -> bool:
	if not inside:
		_stood = 0.0
		return false
	_stood += delta
	if not stings(_stood):
		return false
	_stood = 0.0
	return true


func _process(delta: float) -> void:
	queue_redraw()
	var source_gone := not is_instance_valid(_source) or _source.is_dead()
	if not _landed and source_gone:
		queue_free()
		return
	if _landed and source_gone:
		_linger = minf(_linger, FADE)
	if advance(delta):
		_source.land_ground_strike(global_position, RADIUS)
		# The write-up settles once the landing is over, under everyone, as a mark on the floor.
		z_index = -8
		return
	if not _landed:
		return
	if is_instance_valid(_target):
		var feet: Vector2 = _target.feet().global_position if _target.has_method("feet") else _target.global_position
		if stand(delta, covers(feet)) and _target.has_method("take_hit"):
			_target.take_hit(STING_DAMAGE)
	if is_finished():
		queue_free()


func _draw() -> void:
	if not _landed:
		var filled := fill()
		draw_circle(Vector2.ZERO, RADIUS * filled, Color(COLOR, 0.15 + 0.3 * filled))
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, COLOR, 2.0)
		if _thrown_from != Vector2.INF:
			var start := _thrown_from - global_position
			var at := start.lerp(Vector2.ZERO, filled) + Vector2(0.0, -sin(filled * PI) * THROW_ARC)
			draw_set_transform(at, filled * TAU)
			draw_rect(Rect2(-4, -5, 8, 10), MEMO)
			draw_rect(Rect2(-4, -5, 8, 10), Color.BLACK, false, 1.0)
			draw_set_transform(Vector2.ZERO)
		return
	var fade := clampf(_linger / FADE, 0.0, 1.0)
	# A pink form, a ring round the reach of its sting, and a red stamp across it.
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, Color(FORM_EDGE, 0.8 * fade), 2.0)
	draw_rect(Rect2(-8, -10, 16, 20), Color(FORM, 0.9 * fade))
	draw_rect(Rect2(-8, -10, 16, 20), Color(FORM_EDGE, fade), false, 1.0)
	for row in 3:
		draw_line(Vector2(-5, -6 + row * 4), Vector2(5, -6 + row * 4), Color(FORM_EDGE, 0.6 * fade), 1.0)
	draw_rect(Rect2(-7, 3, 14, 5), Color(STAMP, 0.85 * fade), false, 2.0)
	var warmth := clampf(_stood / STING_AFTER, 0.0, 1.0)
	if warmth > 0.0:
		draw_arc(Vector2.ZERO, RADIUS - 3.0, -PI / 2.0, -PI / 2.0 + TAU * warmth, 20, Color(STAMP, fade), 2.0)
