class_name LightsOut
extends Node2D

# The care home's lights go out. A warning first: the room dims and "Lights out!" shows over
# Grandpa. Then everything goes dark but a soft circle around him. Warnings, marks and shots draw
# above this layer, so every attack still shows. It ends early if the boss who called it falls.
const Z := 50
const DARK := 0.85
const WARNING_DIM := 0.35
const FADE_OUT := 0.4
const LIGHT_RADIUS := 70.0
const CLEAR_RADIUS := 45.0
const EDGE_RADIUS := 90.0
const REACH := 4000.0
const TEXT := "Lights out!"
const TEXT_COLOR := Color("fff6d8")

var _source: Enemy
var _target: Node2D
var _warning := 1.0
var _dark := 4.0
var _darkness := DARK
var _age := 0.0
var _fading := -1.0
var _hole: GradientTexture2D
# How far the light around him reaches, and what shows over him as it starts. A smaller dark, such as
# a perfume cloud's, sets both before it enters the room.
var light_radius := LIGHT_RADIUS
var text := TEXT


# How dark the room is at a moment, from 0 to the darkness asked for.
static func shade_at(age: float, warning: float, dark: float, darkness: float) -> float:
	if age < warning:
		return darkness * WARNING_DIM * clampf(age / warning, 0.0, 1.0)
	if age < warning + dark:
		return darkness
	return darkness * clampf(1.0 - (age - warning - dark) / FADE_OUT, 0.0, 1.0)


# How far the light around him reaches, as a multiple, from his run's stats: twice as far with the
# Night Light. Anything without a run keeps the usual light.
static func light_scale(target: Node) -> float:
	var stats := _stats_of(target)
	return stats.dark_light_mult if stats != null else 1.0


# Whether his run keeps every room lit, so no dark falls at all (Night Shift).
static func kept_lit(target: Node) -> bool:
	var stats := _stats_of(target)
	return stats != null and stats.never_dark


static func _stats_of(target: Node) -> PlayerStats:
	if target == null or not is_instance_valid(target) or not "run" in target:
		return null
	var run = target.get("run")
	return run.stats if run is RunState else null


func setup(source: Enemy, target: Node2D, warning: float, dark: float, darkness := DARK) -> void:
	_source = source
	_target = target
	_warning = warning
	_dark = dark
	_darkness = darkness


func is_dark() -> bool:
	return _age >= _warning and _age < _warning + _dark and _fading < 0.0


func total_time() -> float:
	return _warning + _dark + FADE_OUT


func _ready() -> void:
	z_index = Z
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0, 0, 0, 1))
	gradient.add_point(CLEAR_RADIUS / EDGE_RADIUS, Color(0, 0, 0, 0))
	gradient.add_point(LIGHT_RADIUS / EDGE_RADIUS, Color(0, 0, 0, 0.55))
	_hole = GradientTexture2D.new()
	_hole.gradient = gradient
	_hole.width = 128
	_hole.height = 128
	_hole.fill = GradientTexture2D.FILL_RADIAL
	_hole.fill_from = Vector2(0.5, 0.5)
	_hole.fill_to = Vector2(1.0, 0.5)


func _process(delta: float) -> void:
	_age += delta
	if _fading < 0.0 and (not is_instance_valid(_source) or _source.is_dead()):
		# The boss is down: skip ahead to the fade.
		_age = maxf(_age, _warning + _dark)
		_fading = 0.0
	queue_redraw()
	if _age >= total_time():
		queue_free()


func current_shade() -> float:
	return shade_at(_age, _warning, _dark, _darkness)


func _draw() -> void:
	if not is_instance_valid(_target):
		return
	var shade := current_shade()
	if shade <= 0.0 or kept_lit(_target):
		return
	var feet: Vector2 = _target.feet().global_position if _target.has_method("feet") else _target.global_position
	var center := to_local(feet)
	var tint := Color(1, 1, 1, shade)
	# The light's edges scale with its radius, so a smaller dark keeps the same soft rim.
	var edge := EDGE_RADIUS * light_radius * light_scale(_target) / LIGHT_RADIUS
	var square := Rect2(center - Vector2(edge, edge), Vector2(edge, edge) * 2.0)
	draw_texture_rect(_hole, square, false, tint)
	var black := Color(0, 0, 0, shade)
	draw_rect(Rect2(square.position.x - REACH, square.position.y - REACH, REACH * 2.0 + square.size.x, REACH), black)
	draw_rect(Rect2(square.position.x - REACH, square.end.y, REACH * 2.0 + square.size.x, REACH), black)
	draw_rect(Rect2(square.position.x - REACH, square.position.y, REACH, square.size.y), black)
	draw_rect(Rect2(square.end.x, square.position.y, REACH, square.size.y), black)
	if _age < _warning + 0.4 and not text.is_empty():
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var at := center + Vector2(-width / 2.0, -46.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 5, Color.BLACK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT_COLOR)
