class_name TakeoverTether
extends Node2D

# The Chairman's hostile takeover: a red tether from him to Grandpa's feet, shown for its whole
# warning, tightening as it fills. When it ends he is pulled a short way in; a dodge before then snaps
# it, and it is gone. It lies in the room and follows them both. It comes to nothing if he falls.
const COLOR := Color("e4524f")
const CORD := Color("c8202c")
const SNAP_TIME := 0.25
const DASH := 10.0

var _source: Enemy
var _warning := 0.9
var _left := 0.9
var _snapped := false
var _snap_left := 0.0


func setup(source: Enemy, warning: float) -> void:
	_source = source
	_warning = warning
	_left = warning
	z_index = Projectile.SHOT_Z


func snap() -> void:
	if _snapped:
		return
	_snapped = true
	_snap_left = SNAP_TIME


func is_snapped() -> bool:
	return _snapped


func fill() -> float:
	return clampf(1.0 - _left / maxf(_warning, 0.01), 0.0, 1.0)


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead() or not is_instance_valid(_source.target):
		queue_free()
		return
	global_position = _source.global_position
	if _snapped:
		_snap_left -= delta
		if _snap_left <= 0.0:
			queue_free()
		return
	_left -= delta
	if _left <= 0.0:
		queue_free()


func _draw() -> void:
	if not is_instance_valid(_source) or not is_instance_valid(_source.target):
		return
	var to := _source.target_ground() - global_position
	if _snapped:
		# Two loose ends recoil toward each side.
		var fade := clampf(_snap_left / SNAP_TIME, 0.0, 1.0)
		draw_line(Vector2.ZERO, to * 0.25, Color(CORD, fade), 2.0)
		draw_line(to, to * 0.75, Color(CORD, fade), 2.0)
		return
	var filled := fill()
	var length := to.length()
	var way := to / maxf(length, 0.01)
	var along := 0.0
	# With Attack warnings off (AttackWarnings) the dashes are the cord's own colour, faint, and the ring
	# round him is the dark cue; the cord filling in is the tell.
	var red := AttackWarnings.drawn_by(_source)
	var dash := Color(COLOR, 0.5) if red else Color(CORD, 0.5)
	# A dashed cord that fills in solid as the pull comes.
	while along < length:
		var stop := minf(along + DASH, length)
		var solid := along / maxf(length, 0.01) <= filled
		draw_line(way * along, way * stop, CORD if solid else dash, 2.0 if solid else 1.0)
		along += DASH * (1.0 if solid else 1.6)
	if red:
		draw_arc(to, 9.0, 0.0, TAU, 16, COLOR, 2.0)
	else:
		draw_arc(to, 9.0, 0.0, TAU, 16, AttackWarnings.cue_color(filled), 2.0)
