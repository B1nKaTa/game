class_name ItemFx
extends RefCounted

# Shared visuals the items draw with: shockwaves, clouds, puddles, sparks, a word that pops up, a
# blast, and the HUD's off-screen arrows. Each make_ function returns a node for ctx.add_fx to place.
# They are looks only; whatever an effect does to enemies it does itself, at once or in its tick.
# Every room node joins GROUP and fades and frees itself, so RoomView.is_passing_effect clears any
# still showing when Grandpa leaves a room.

const GROUP := "item_fx"
# Above the floor and props, below the warnings layer (Enemy.WARNING_Z).
const Z := 40
const SHOCKWAVE_TIME := 0.35
const SPARKS_TIME := 0.3
const POP_TIME := 0.9
const POP_RISE := 18.0
const BLAST_TIME := 0.3
const BINGO_COLOR := Color("ffd24a")
const BLAST_COLOR := Color("ff7b2e")
const CLOUD_COLOR := Color(0.75, 0.78, 0.7, 0.55)
const PUDDLE_COLOR := Color(0.95, 0.5, 0.2, 0.5)


static func is_passing_effect(node: Node) -> bool:
	return node.is_in_group(GROUP)


static func make_shockwave(radius: float, color: Color) -> Fx:
	return FxShockwave.new(radius, color, SHOCKWAVE_TIME)


static func make_cloud(radius: float, seconds: float, color := CLOUD_COLOR) -> Fx:
	return FxCloud.new(radius, color, seconds)


static func make_puddle(radius: float, seconds: float, color := PUDDLE_COLOR) -> Fx:
	return FxPuddle.new(radius, color, seconds)


static func make_sparks(color: Color, radius := 12.0) -> Fx:
	return FxSparks.new(radius, color, SPARKS_TIME)


static func make_pop(text: String, color := BINGO_COLOR) -> Fx:
	var pop := FxPop.new(0.0, color, POP_TIME)
	pop.text = text
	return pop


static func make_blast(radius: float, color := BLAST_COLOR) -> Fx:
	return FxBlast.new(radius, color, BLAST_TIME)


# The base of every room effect: a radius, a colour and a life, after which it frees itself.
class Fx:
	extends Node2D

	var radius := 0.0
	var color := Color.WHITE
	var life := 0.3
	var age := 0.0

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		radius = at_radius
		color = at_color
		life = maxf(seconds, 0.01)
		z_index = Z
		# It finishes its fade even under a room stopped at the run's end.
		process_mode = Node.PROCESS_MODE_ALWAYS
		add_to_group(GROUP)

	# How far through its life it is, from 0 to 1.
	func progress() -> float:
		return clampf(age / life, 0.0, 1.0)

	# Whether a point lies inside it, for effects that act on what stands in a cloud or puddle.
	func covers(point: Vector2) -> bool:
		return is_inside_tree() and global_position.distance_to(point) <= radius

	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
			return
		queue_redraw()


class FxShockwave:
	extends Fx

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)

	func _draw() -> void:
		var t := progress()
		var r := radius * (0.25 + 0.75 * t)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(Color.BLACK, 0.6 * (1.0 - t)), 5.0)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(color, 1.0 - t), 3.0)


class FxCloud:
	extends Fx

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)

	func _draw() -> void:
		var fade := 1.0 - maxf(progress() - 0.7, 0.0) / 0.3
		for i in 6:
			var angle := TAU * i / 6.0 + age * 0.6
			var at := Vector2.from_angle(angle) * radius * 0.45
			draw_circle(at, radius * 0.45, Color(color, color.a * fade))
		draw_circle(Vector2.ZERO, radius * 0.5, Color(color, color.a * fade))


class FxPuddle:
	extends Fx

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		# Flat on the floor, under bodies.
		z_index = 0

	func _draw() -> void:
		var fade := 1.0 - maxf(progress() - 0.8, 0.0) / 0.2
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, radius, Color(color, color.a * fade))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(color.lightened(0.3), fade), 1.5)
		draw_set_transform(Vector2.ZERO)


class FxSparks:
	extends Fx

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)

	func _draw() -> void:
		var t := progress()
		for i in 8:
			var direction := Vector2.from_angle(TAU * i / 8.0 + 0.4)
			var from := direction * radius * t
			draw_line(from, from + direction * 5.0 * (1.0 - t), Color(color, 1.0 - t), 2.0)


# A word that rises and fades over where it was placed, outlined so it reads on any floor.
class FxPop:
	extends Fx

	const FONT_SIZE := 16

	var text := ""

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Enemy.WARNING_Z + 1

	func _draw() -> void:
		var t := progress()
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var at := Vector2(-width / 2.0, -30.0 - POP_RISE * t)
		var alpha := 1.0 - maxf(t - 0.6, 0.0) / 0.4
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 5, Color(Color.BLACK, alpha))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(color, alpha))


# A burst of fire round a point: a filled flash that swells and a hot ring at its reach.
class FxBlast:
	extends Fx

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)

	func _draw() -> void:
		var t := progress()
		draw_circle(Vector2.ZERO, radius * minf(0.5 + t, 1.0), Color(color, 0.6 * (1.0 - t)))
		draw_circle(Vector2.ZERO, radius * 0.35 * (1.0 - t), Color(1.0, 0.95, 0.7, 0.8 * (1.0 - t)))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(Color.BLACK, 0.7 * (1.0 - t)), 4.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(color.lightened(0.3), 1.0 - t), 2.0)


# Arrows at the screen's edge pointing to enemies off screen, while the run's stats ask for them. It
# lives on the HUD's layer and reads where enemies are through the view's own canvas transform, so it
# agrees with whatever the camera shows.
class OffscreenArrows:
	extends Control

	const MARGIN := 10.0
	const SIZE := 7.0
	const COLOR := Color("e4524f")
	const TOP_ROW := 24.0

	var _run: RunState

	func setup(run: RunState) -> void:
		_run = run

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = RoomBackdrop.VIEW_SIZE

	# Where on the edge of view an arrow to target stands, or Vector2.INF when target is in view. The
	# top edge sits below the HUD's top row.
	static func edge_point(view: Rect2, target: Vector2) -> Vector2:
		if view.has_point(target):
			return Vector2.INF
		var inner := Rect2(view.position + Vector2(MARGIN, MARGIN + TOP_ROW), view.size - Vector2(MARGIN * 2.0, MARGIN * 2.0 + TOP_ROW))
		var center := inner.get_center()
		var offset := target - center
		var scale_x := (inner.size.x / 2.0) / absf(offset.x) if absf(offset.x) > 0.001 else INF
		var scale_y := (inner.size.y / 2.0) / absf(offset.y) if absf(offset.y) > 0.001 else INF
		return center + offset * minf(minf(scale_x, scale_y), 1.0)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if _run == null or not _run.stats.shows_offscreen_enemies or not is_inside_tree():
			return
		var view := Rect2(Vector2.ZERO, get_viewport_rect().size)
		var to_screen := get_viewport().get_canvas_transform()
		for node in get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy == null or enemy.is_dead() or enemy.submerged or not enemy.is_inside_tree():
				continue
			var at: Vector2 = to_screen * enemy.global_position
			var tip := edge_point(view, at)
			if tip == Vector2.INF:
				continue
			var direction := (at - tip).normalized()
			var side := direction.orthogonal() * SIZE * 0.6
			var points := PackedVector2Array([tip + direction * SIZE, tip - direction * SIZE * 0.5 + side, tip - direction * SIZE * 0.5 - side])
			draw_colored_polygon(points, COLOR)
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color.BLACK, 1.0)
