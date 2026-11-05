class_name ItemFx
extends RefCounted

# Shared visuals the items draw with: shockwaves, clouds, puddles, sparks, a word that pops up, a
# blast, marks that ride on an enemy, and the HUD's off-screen arrows. Each make_ function returns a
# node for ctx.add_fx to place. Most are looks only, and whatever an effect does to enemies it does
# itself, at once or in its tick. The few that act (a fizz that slows, a wave or needle that flies and
# hits) act on exactly what they draw, for as long as they are drawn, and pause with the game.
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
# The Bingo Dabber's ink, the Shark Tooth's blood and the Fizzy Cleaning Tablet's fizz.
const DAB_COLOR := Color("e0307a")
const BLOOD_COLOR := Color("d01c34")
const FIZZ_COLOR := Color("8fe6f2")
const STEEL_COLOR := Color("dfe6ee")
# Marks that ride on an enemy last until it dies or the room is left, unless told otherwise.
const RIDE_TIME := 3600.0


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


# Ink dots on an enemy's body, one per mark, that ride on it. Set count to change them.
static func make_dabs(enemy: Enemy, count: int) -> FxDabs:
	var dabs := FxDabs.new(0.0, DAB_COLOR, RIDE_TIME)
	dabs.count = count
	dabs.ride(enemy)
	return dabs


# Drops of blood running off an enemy while it bleeds. Its life can be stretched with keep_until.
static func make_bleed(enemy: Enemy, seconds: float) -> Fx:
	var bleed := FxBleed.new(0.0, BLOOD_COLOR, seconds)
	bleed.ride(enemy)
	return bleed


# A fizzing patch on the floor that slows every enemy whose body it touches, while it lasts.
static func make_fizz(radius: float, seconds: float, slow_share: float) -> FxFizz:
	var fizz := FxFizz.new(radius, FIZZ_COLOR, seconds)
	fizz.slow_share = slow_share
	return fizz


# A crescent that flies forward from where it is placed and hits each enemy it passes once.
static func make_wave(ctx: EffectContext, direction: Vector2, damage: float, distance: float) -> FxStrike:
	var wave := FxWave.new(26.0, STEEL_COLOR, 2.0)
	wave.aim(ctx, direction, damage, distance, FxWave.SPEED)
	return wave


# A knitting needle that flies forward and pokes the first enemy it reaches.
static func make_needle(ctx: EffectContext, direction: Vector2, damage: float, distance: float) -> FxStrike:
	var needle := FxNeedle.new(0.0, Color("c9ccd6"), 2.0)
	needle.aim(ctx, direction, damage, distance, FxNeedle.SPEED)
	return needle


# The base of every room effect: a radius, a colour and a life, after which it frees itself.
class Fx:
	extends Node2D

	var radius := 0.0
	var color := Color.WHITE
	var life := 0.3
	var age := 0.0
	# An enemy it rides on, if any: it stands where the enemy stands and goes when the enemy does.
	var _rider: WeakRef

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

	func ride(enemy: Enemy) -> void:
		_rider = weakref(enemy)

	# Lives on until this many seconds from now, if that is later than its end.
	func keep_for(seconds: float) -> void:
		life = maxf(life, age + seconds)

	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
			return
		if _rider != null:
			var enemy := _rider.get_ref() as Enemy
			if enemy == null or enemy.is_dead() or not enemy.is_inside_tree():
				queue_free()
				return
			global_position = enemy.global_position
			visible = not enemy.submerged
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


# The Bingo Dabber's marks: ink dots across the body, each with a dark rim so it reads on any enemy.
class FxDabs:
	extends Fx

	const SPACING := 6.0

	var count := 0

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)

	func _draw() -> void:
		var left := -SPACING * (count - 1) / 2.0
		for i in count:
			var at := Vector2(left + SPACING * i, -2.0 + (i % 2) * 3.0)
			draw_circle(at, 3.2, Color.BLACK)
			draw_circle(at, 2.3, color)


# The Shark Tooth's bleeding: drops that run off the body and fall.
class FxBleed:
	extends Fx

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)

	func _draw() -> void:
		for i in 3:
			var fall := fmod(age * 1.6 + i / 3.0, 1.0)
			var at := Vector2(-6.0 + i * 6.0, -4.0 + fall * 16.0)
			var alpha := 1.0 - fall * 0.6
			draw_circle(at, 2.6, Color(Color.BLACK, alpha))
			draw_circle(at, 1.8, Color(color, alpha))
		draw_line(Vector2(-7, -6), Vector2(7, -6), Color(Color.BLACK, 0.8), 3.0)
		draw_line(Vector2(-7, -6), Vector2(7, -6), color, 1.5)


# The Fizzy Cleaning Tablet's fizz: bubbles rising off a pale patch, slowing what stands in it.
class FxFizz:
	extends Fx

	var slow_share := 0.5

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = 0
		# It acts on enemies, so it waits while the game is paused.
		process_mode = Node.PROCESS_MODE_INHERIT

	func _physics_process(_delta: float) -> void:
		if is_inside_tree():
			slow_touching(get_tree().get_nodes_in_group("enemies"))

	# Slows each of these enemies whose body it touches. Returns how many.
	func slow_touching(enemies: Array) -> int:
		var count := 0
		for node in enemies:
			var enemy := node as Enemy
			if enemy == null or not is_instance_valid(enemy) or enemy.is_dead() or enemy.submerged:
				continue
			var body := enemy.body_rect()
			if global_position.distance_to(MeleeArc.closest_point(body, global_position)) <= radius:
				enemy.slow(slow_share, 0.15)
				count += 1
		return count

	func _draw() -> void:
		var fade := 1.0 - maxf(progress() - 0.75, 0.0) / 0.25
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, radius, Color(color, 0.35 * fade))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(Color.BLACK, 0.5 * fade), 2.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(color, fade), 1.0)
		draw_set_transform(Vector2.ZERO)
		for i in 7:
			var rise := fmod(age * 1.4 + i * 0.37, 1.0)
			var at := Vector2(cos(i * 2.3) * radius * 0.7, sin(i * 1.7) * radius * 0.35 - rise * 14.0)
			draw_arc(at, 1.5 + (i % 3) * 0.7, 0.0, TAU, 8, Color(Color.BLACK, 0.6 * fade), 1.8)
			draw_arc(at, 1.5 + (i % 3) * 0.7, 0.0, TAU, 8, Color(Color.WHITE, fade), 1.0)


# Something of his that flies forward and hits each enemy it reaches once, with damage through ctx, so
# the hit runs the hooks like any item hit. It stops at a wall and at the end of its distance. Its hit
# test is the shape it draws, at the spot it is drawn.
class FxStrike:
	extends Fx

	var ctx: EffectContext
	var direction := Vector2.RIGHT
	var damage := 0.0
	var push := 60.0
	var speed := 300.0
	var distance := 100.0
	# Whether it ends at the first enemy it hits.
	var stops_at_first := false
	var travelled := 0.0
	var _hit := {}

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		process_mode = Node.PROCESS_MODE_INHERIT

	func aim(context: EffectContext, way: Vector2, amount: float, reach: float, fly_speed: float) -> void:
		ctx = context
		direction = way.normalized()
		damage = amount
		distance = reach
		speed = fly_speed
		rotation = direction.angle()

	# Points along what it draws, in room space, that it hits with.
	func hit_points() -> PackedVector2Array:
		return PackedVector2Array([global_position])

	func hit_reach() -> float:
		return 3.0

	func _physics_process(delta: float) -> void:
		if not is_inside_tree():
			return
		var step := minf(speed * delta, distance - travelled)
		var from := global_position
		var to := from + direction * step
		var query := PhysicsRayQueryParameters2D.create(from, to, 1)
		var wall := get_world_2d().direct_space_state.intersect_ray(query)
		if not wall.is_empty():
			to = wall["position"]
		global_position = to
		travelled += step
		if _strike() and stops_at_first:
			queue_free()
			return
		if not wall.is_empty() or travelled >= distance - 0.01:
			queue_free()

	# Hits whatever its points touch this frame. Returns whether it hit anything.
	func _strike() -> bool:
		if ctx == null:
			return false
		var struck := false
		for enemy in ctx.enemies():
			var key := enemy.get_instance_id()
			if _hit.has(key) or enemy.submerged:
				continue
			var body := enemy.body_rect().grow(hit_reach())
			for point in hit_points():
				if body.has_point(point):
					_hit[key] = true
					struck = true
					ctx.hit_enemy(enemy, damage, RunEffects.ITEM, direction * push)
					ctx.add_fx(ItemFx.make_sparks(color), point)
					break
			if struck and stops_at_first:
				return true
		return struck


# The Cane Sword's shockwave: a steel crescent bulging forward.
class FxWave:
	extends FxStrike

	const SPEED := 330.0
	const HALF_ANGLE := 0.95
	const POINTS := 9

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		push = 140.0

	func _local_points() -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in POINTS:
			var angle := -HALF_ANGLE + 2.0 * HALF_ANGLE * i / float(POINTS - 1)
			points.append(Vector2(-radius, 0.0) + Vector2.from_angle(angle) * radius)
		return points

	func hit_points() -> PackedVector2Array:
		var points := PackedVector2Array()
		for point in _local_points():
			points.append(global_transform * point)
		return points

	func hit_reach() -> float:
		return 4.0

	func _draw() -> void:
		var fade := 1.0 - maxf(travelled / maxf(distance, 1.0) - 0.7, 0.0) / 0.3
		var points := _local_points()
		draw_polyline(points, Color(Color.BLACK, 0.7 * fade), 7.0)
		draw_polyline(points, Color(color, fade), 4.0)
		draw_polyline(points, Color(Color("7fb8ff"), fade), 1.5)


# A knitting needle: a thin grey line with a bead of yarn at the back.
class FxNeedle:
	extends FxStrike

	const SPEED := 380.0
	const LENGTH := 11.0

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		stops_at_first = true
		push = 30.0

	func hit_points() -> PackedVector2Array:
		return PackedVector2Array([global_position, global_position - direction * LENGTH / 2.0])

	func _draw() -> void:
		draw_line(Vector2(-LENGTH, 0), Vector2(0, 0), Color.BLACK, 4.0)
		draw_line(Vector2(-LENGTH, 0), Vector2(0, 0), color, 2.0)
		draw_circle(Vector2(-LENGTH, 0), 2.6, Color.BLACK)
		draw_circle(Vector2(-LENGTH, 0), 1.8, Color("e06a3a"))


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
