class_name PerfumeCloud
extends Node2D

# A cloud of perfume sprayed onto a warned spot. A red circle fills for its warning, then a pink haze
# hangs there for a while. It never hurts, but while Grandpa's feet are in it his view closes in, as
# in a small Lights Out (see PerfumeHaze). A warning that has not landed comes to nothing if the
# sprayer falls first; a cloud already hanging fades on its own.
const GROUP := "perfume_clouds"
const WARNING := 0.9
const LINGER := 4.0
const RADIUS := 40.0
const FADE := 0.5
const WARNING_COLOR := Color("e4524f")
const MIST := Color(0.9, 0.42, 0.76)
# A deep magenta edge, so a hanging cloud shows on the Mall's pale tile as well as on dark floors.
const MIST_EDGE := Color("b8358f")
const SPARKLE := Color("fff2fb")

var _source: Enemy
var _warning := WARNING
var _left := WARNING
var _linger := LINGER
var _radius := RADIUS
var _landed := false
var _age := 0.0


static func covers_point(center: Vector2, radius: float, point: Vector2) -> bool:
	return center.distance_to(point) <= radius


# Whether any landed cloud in a list covers a point, so tests need no scene tree.
static func any_covers(clouds: Array, point: Vector2) -> bool:
	for cloud in clouds:
		if is_instance_valid(cloud) and cloud.covers(point):
			return true
	return false


func setup(source: Enemy, warning: float, linger: float, radius: float) -> void:
	_source = source
	_warning = warning
	_left = warning
	_linger = linger
	_radius = radius
	# The warning shows above the room and any haze, as every mark does.
	z_index = Projectile.SHOT_Z


func _ready() -> void:
	add_to_group(GROUP)


func has_landed() -> bool:
	return _landed


func is_finished() -> bool:
	return _landed and _linger <= 0.0


func covers(point: Vector2) -> bool:
	return _landed and _linger > 0.0 and covers_point(global_position, _radius, point)


# Runs the warning, then the cloud's time. True once, on the moment it lands.
func advance(delta: float) -> bool:
	_age += delta
	if not _landed:
		_left -= delta
		if _left <= 0.0:
			_landed = true
			return true
		return false
	_linger -= delta
	return false


func _process(delta: float) -> void:
	queue_redraw()
	if not _landed and (not is_instance_valid(_source) or _source.is_dead()):
		queue_free()
		return
	if advance(delta) and is_instance_valid(_source) and is_instance_valid(_source.target):
		PerfumeHaze.ensure(get_parent(), _source.target)
		# The landed cloud hangs low, under the haze it makes, so it never hides a warning.
		z_index = 0
	if is_finished():
		queue_free()


func _draw() -> void:
	if not _landed:
		var filled := clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)
		draw_circle(Vector2.ZERO, _radius * filled, Color(WARNING_COLOR, 0.15 + 0.3 * filled))
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 32, WARNING_COLOR, 2.0)
		draw_circle(Vector2.ZERO, 4.0 + 6.0 * filled, Color(MIST, 0.5))
		return
	var fade := clampf(_linger / FADE, 0.0, 1.0)
	var swirl := _age * 1.3
	for i in 5:
		var at := Vector2.from_angle(swirl + TAU * i / 5.0) * _radius * 0.35
		draw_circle(at, _radius * 0.62, Color(MIST, 0.2 * fade))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 32, Color(MIST_EDGE, 0.85 * fade), 2.0)
	for i in 4:
		var lift := fposmod(_age * 0.6 + i * 0.27, 1.0)
		var at := Vector2.from_angle(TAU * i / 4.0 + 0.4) * _radius * 0.5 + Vector2(0.0, -lift * 10.0)
		draw_circle(at, 1.5, Color(SPARKLE, fade * (1.0 - lift)))
