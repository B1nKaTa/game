class_name Chest
extends Pickup

# A chest rolled from a layout's C cell. ChestRules says what each kind costs and holds, and this is
# how it looks and opens. Lunchboxes, locked chests and urns open like any pickup that asks for the
# interact key. A Safe Deposit Box ignores the key and opens only to the player's Thermos. A mimic
# passes for a Locked Chest, except that it breathes slowly, and wakes when Grandpa touches it.
signal woke(at: Vector2)
signal blasted_open(at: Vector2)

const TOUCH_RADIUS := Pickup.COLLECT_RADIUS
# How far past its middle a blast must reach to count as touching the box.
const BODY_REACH := 9.0
# Where the box stands on its cell, so every kind sits on the same floor line.
const BASE := Vector2(0, 6)
const BREATH_PERIOD := 2.6
const BREATH_SWELL := 0.07
const OUTLINE := Color.BLACK
const HINT_COLOR := Color("ffd24a")
const LUNCHBOX_COLOR := Color("c8463c")
const LUNCHBOX_TRIM := Color("e9d8a6")
const CHEST_COLOR := Color("a8692f")
const CHEST_BAND := Color("5e3a1a")
const LOCK_COLOR := Color("e2b33c")
const SAFE_COLOR := Color("7c8794")
const SAFE_EDGE := Color("39404a")
const SAFE_DIAL := Color("d8dde3")
const URN_COLOR := Color("e2b33c")
const URN_SHINE := Color("fff1b8")
const URN_EDGE := Color("7a5a12")

var kind := ChestRules.LOCKED
var _time := 0.0
var _opened := false
var _near := false


# Every chest near a player's Thermos blast that answers one: a safe opens, and a mimic wakes.
# An Auditor's blast or a boss never calls this, so they open nothing.
static func blast_among(nodes: Array, center: Vector2, radius: float) -> int:
	var answered := 0
	for node in nodes:
		var chest := node as Chest
		if chest == null or chest.is_queued_for_deletion() or chest.is_open():
			continue
		if center.distance_to(chest.global_position) > radius + BODY_REACH:
			continue
		if chest.kind == ChestRules.SAFE and chest.blast_open():
			answered += 1
		elif chest.kind == ChestRules.MIMIC and chest.wake():
			answered += 1
	return answered


static func blast(tree: SceneTree, center: Vector2, radius: float) -> int:
	return blast_among(tree.get_nodes_in_group("pickups"), center, radius)


func is_open() -> bool:
	return _opened


func _process(delta: float) -> void:
	_time += delta
	match kind:
		ChestRules.MIMIC:
			queue_redraw()
			if _touched():
				wake()
		ChestRules.SAFE:
			var near := _touched()
			if near != _near:
				_near = near
				queue_redraw()
		_:
			super._process(delta)


func _touched() -> bool:
	return is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= TOUCH_RADIUS


# A safe never answers the key, and a mimic answers anything that reaches for it by waking.
func collect() -> void:
	match kind:
		ChestRules.MIMIC:
			wake()
		ChestRules.SAFE:
			pass
		_:
			if can_take.is_valid() and not can_take.call():
				return
			super.collect()


func wake() -> bool:
	if _opened or kind != ChestRules.MIMIC or is_queued_for_deletion():
		return false
	_opened = true
	woke.emit(position)
	queue_free()
	return true


func blast_open() -> bool:
	if _opened or kind != ChestRules.SAFE or is_queued_for_deletion():
		return false
	_opened = true
	blasted_open.emit(position)
	queue_free()
	return true


func _draw() -> void:
	super._draw()
	if kind == ChestRules.SAFE and _near:
		draw_string(ThemeDB.fallback_font, Vector2(-18, 22), ChestRules.SAFE_HINT, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, HINT_COLOR)


func _draw_body() -> void:
	match kind:
		ChestRules.LUNCHBOX:
			_draw_lunchbox()
		ChestRules.SAFE:
			_draw_safe()
		ChestRules.URN:
			_draw_urn()
		ChestRules.MIMIC:
			# Its one tell: the lid rises and falls as it breathes, slowly enough to miss.
			_draw_locked_chest((0.5 - 0.5 * cos(_time * TAU / BREATH_PERIOD)) * BREATH_SWELL)
		_:
			_draw_locked_chest(0.0)


# A red tin with a domed lid, a pale stripe and a wire handle.
func _draw_lunchbox() -> void:
	draw_set_transform(BASE)
	var body := Rect2(-8, -7, 16, 7)
	var lid := PackedVector2Array()
	for i in 9:
		var angle := PI + PI * i / 8.0
		lid.append(Vector2(cos(angle) * 8.0, -7.0 + sin(angle) * 4.0))
	draw_arc(Vector2(0, -12), 3.0, PI, TAU, 8, LUNCHBOX_TRIM, 1.5)
	draw_colored_polygon(lid, LUNCHBOX_COLOR.lightened(0.15))
	draw_polyline(lid, OUTLINE, 1.0)
	draw_rect(body, LUNCHBOX_COLOR)
	draw_rect(Rect2(-8, -5, 16, 1.5), LUNCHBOX_TRIM)
	draw_rect(Rect2(-1, -8, 2, 3), LUNCHBOX_TRIM)
	draw_rect(body, OUTLINE, false, 1.0)
	draw_set_transform(Vector2.ZERO)


# A wooden chest with two dark bands and a gold padlock. A mimic swells it a little as it breathes.
func _draw_locked_chest(swell: float) -> void:
	draw_set_transform(BASE, 0.0, Vector2(1.0 + swell * 0.5, 1.0 + swell))
	var whole := Rect2(-9, -13, 18, 13)
	draw_rect(Rect2(-9, -8, 18, 8), CHEST_COLOR)
	draw_rect(Rect2(-9, -13, 18, 5), CHEST_COLOR.lightened(0.12))
	for band_x in [-6.0, 4.0]:
		draw_rect(Rect2(band_x, -13, 2, 13), CHEST_BAND)
	draw_line(Vector2(-9, -8), Vector2(9, -8), OUTLINE, 1.0)
	draw_rect(whole, OUTLINE, false, 1.0)
	draw_arc(Vector2(0, -10), 1.5, PI, TAU, 6, LOCK_COLOR, 1.0)
	draw_rect(Rect2(-2, -10, 4, 4), LOCK_COLOR)
	draw_set_transform(Vector2.ZERO)


# A squat steel box with a round dial and two hinges.
func _draw_safe() -> void:
	draw_set_transform(BASE)
	var body := Rect2(-8, -15, 16, 15)
	draw_rect(body, SAFE_COLOR)
	draw_rect(body.grow(-2.0), SAFE_EDGE, false, 1.0)
	for hinge_y in [-13.0, -4.0]:
		draw_rect(Rect2(-8, hinge_y, 2, 3), SAFE_EDGE)
	draw_circle(Vector2(1, -8), 3.0, SAFE_DIAL)
	draw_line(Vector2(1, -8), Vector2(1, -10.5), SAFE_EDGE, 1.0)
	draw_rect(body, OUTLINE, false, 1.0)
	draw_set_transform(Vector2.ZERO)


# A tall gold urn: a wide body, a narrow neck, a lip and a knob on its lid.
func _draw_urn() -> void:
	draw_set_transform(BASE)
	var shape := PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(7, -6), Vector2(4, -11), Vector2(2.5, -13),
		Vector2(4, -15), Vector2(-4, -15), Vector2(-2.5, -13), Vector2(-4, -11), Vector2(-7, -6),
	])
	draw_colored_polygon(shape, URN_COLOR)
	var edge := shape.duplicate()
	edge.append(shape[0])
	draw_polyline(edge, URN_EDGE, 1.0)
	draw_line(Vector2(-4, -9), Vector2(-4, -3), URN_SHINE, 1.0)
	draw_circle(Vector2(0, -16.5), 1.5, URN_COLOR)
	draw_set_transform(Vector2.ZERO)
