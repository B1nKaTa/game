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
const BLOOD_COLOR := Color("ff3347")
const PIN_WOOD := Color("b8743a")
const FLOUR_COLOR := Color(0.97, 0.94, 0.86, 0.8)
const FIZZ_COLOR := Color("8fe6f2")
const STEEL_COLOR := Color("dfe6ee")
# The second batch: Bad Hip's cough, the Afterimage's pale copy, the wheels' steel, the Banana Peel's
# yellow and the Mobility Scooter's flames.
const COUGH_COLOR := Color("9ccf5a")
const GHOST_TINT := Color("6cc4ff")
const WHEEL_STEEL := Color("c9ced8")
const PEEL_YELLOW := Color("ffd84a")
const FLAME_COLOR := Color("ff8a2a")
const SOUP_COLOR := Color("d9772b")
# The fourth batch: the Magnifying Glass's glint, the Bureaucrat's Stamp's red ink, the Complaint Form's
# paper, the Wreath of Thorns' leaves, the Harmonica's notes and the Alarm Clock's bell.
const GLINT_COLOR := Color("ffcf3a")
const STAMP_RED := Color("e0262f")
const FORM_PAPER := Color("f2ecd8")
const WREATH_GREEN := Color("3f8a3a")
const NOTE_COLOR := Color("9fd8ff")
const ALARM_BRASS := Color("f2b84a")
const STAMP_TIME := 1.1
const ALARM_TIME := 1.0
const NOTE_TIME := 1.2
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
	var bleed := FxBleed.new(enemy.def.body_size.y / 2.0, BLOOD_COLOR, seconds)
	bleed.ride(enemy)
	return bleed


# Grandma's Rolling Pin coming down over a swing: a wooden pin that travels out along the swing for
# its time, drawn over bodies. A look only; the swing's own arcs are what hit. Place it at Grandpa.
static func make_pin(follow: Node2D, direction: Vector2, reach: float, seconds: float) -> Fx:
	var pin := FxPin.new(reach, PIN_WOOD, seconds)
	pin.rotation = direction.angle()
	if follow != null:
		pin.ride(follow)
	return pin


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


# Bad Hip's cough: a sickly cloud that slows every enemy whose body it touches, while it lasts.
static func make_cough(radius: float, seconds: float, slow_share: float) -> FxFizz:
	var cough := FxCough.new(radius, COUGH_COLOR, seconds)
	cough.slow_share = slow_share
	return cough


# The Afterimage: a pale copy of Grandpa that enemies go for instead of him. sprite is his look this
# frame (Player.afterimage_sprite), or null for a plain outline. player is who they turn back to.
static func make_afterimage(player: Node2D, sprite: Sprite2D, seconds: float) -> FxAfterimage:
	var ghost := FxAfterimage.new(0.0, GHOST_TINT, seconds)
	ghost.setup(player, sprite)
	return ghost


# Wheelchair Wheels: two wheels spinning at his sides for as long as the roll lasts. A look only.
static func make_wheels(follow: Node2D, direction: Vector2, seconds: float) -> Fx:
	var wheels := FxWheels.new(0.0, WHEEL_STEEL, seconds)
	wheels.direction = direction
	if follow != null:
		wheels.ride(follow)
	return wheels


# The Banana Peel: it lies where it is dropped until the first enemy walks onto it, which trips.
static func make_peel(ctx: EffectContext, trip_seconds: float) -> FxPeel:
	var peel := FxPeel.new(8.0, PEEL_YELLOW, RIDE_TIME)
	peel.ctx = ctx
	peel.trip_time = trip_seconds
	return peel


# The Mobility Scooter's trail: a small fire on the floor that burns what stands in it now and then.
static func make_burn(ctx: EffectContext, radius: float, seconds: float, damage: float) -> FxBurn:
	var burn := FxBurn.new(radius, FLAME_COLOR, seconds)
	burn.ctx = ctx
	burn.damage = damage
	return burn


# The Hot Soup Thermos's puddle: a pool of burning soup that hurts what stands in it now and then,
# as the scooter's flames do.
static func make_soup(ctx: EffectContext, radius: float, seconds: float, damage: float) -> FxSoup:
	var soup := FxSoup.new(radius, SOUP_COLOR, seconds)
	soup.ctx = ctx
	soup.damage = damage
	return soup


# The Magnifying Glass: a star that glints on a secret wall now and then, for as long as the wall stands.
static func make_glint(wall: Node2D) -> Fx:
	var glint := FxGlint.new(12.0, GLINT_COLOR, RIDE_TIME)
	if wall != null:
		glint.ride(wall)
	return glint


# The Bureaucrat's Stamp coming down: a red stamped box with a word in it, slammed on and left a moment.
static func make_stamp(text: String) -> FxStamp:
	var stamp := FxStamp.new(0.0, STAMP_RED, STAMP_TIME)
	stamp.text = text
	return stamp


# The Complaint Form's meter: a small form over a boss whose bar fills as he hits it. Set fill (0 to 1)
# as it fills and filed while the boss is held. above is how far over the boss's middle it sits.
static func make_meter(boss: Enemy, above: float) -> FxMeter:
	var meter := FxMeter.new(above, FORM_PAPER, RIDE_TIME)
	if boss != null:
		meter.ride(boss)
	return meter


# The Wreath of Thorns: a ring of thorny leaves round his feet, riding on him for the room.
static func make_wreath(follow: Node2D) -> Fx:
	var wreath := FxWreath.new(18.0, WREATH_GREEN, RIDE_TIME)
	if follow != null:
		wreath.ride(follow)
	return wreath


# A note from the Harmonica rising over his head. pitch (0, 1, 2) sets how high it starts and its colour.
static func make_note(pitch: int) -> FxNote:
	var note := FxNote.new(0.0, NOTE_COLOR, NOTE_TIME)
	note.pitch = pitch
	return note


# The Alarm Clock going off over his head: a brass bell clock shaking, with its ring.
static func make_alarm() -> Fx:
	return FxAlarm.new(0.0, ALARM_BRASS, ALARM_TIME)


# The base of every room effect: a radius, a colour and a life, after which it frees itself.
class Fx:
	extends Node2D

	var radius := 0.0
	var color := Color.WHITE
	var life := 0.3
	var age := 0.0
	# What it rides on, if anything: it stands where that stands, and goes when it does (or an enemy dies).
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

	func ride(target: Node2D) -> void:
		_rider = weakref(target)

	# Lives on until this many seconds from now, if that is later than its end.
	func keep_for(seconds: float) -> void:
		life = maxf(life, age + seconds)

	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
			return
		if _rider != null:
			var target := _rider.get_ref() as Node2D
			var enemy := target as Enemy
			if target == null or not target.is_inside_tree() or (enemy != null and enemy.is_dead()):
				queue_free()
				return
			global_position = target.global_position
			visible = enemy == null or not enemy.submerged
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

	# radius is half the body's height, so drops run from the wound past its feet onto the floor.
	func _draw() -> void:
		draw_line(Vector2(-7, -5), Vector2(6, -2), Color.BLACK, 4.5)
		draw_line(Vector2(-7, -5), Vector2(6, -2), color, 2.5)
		for i in 4:
			var fall := fmod(age * 1.3 + i / 4.0, 1.0)
			var at := Vector2(-6.0 + i * 4.0, -3.0 + fall * (radius + 10.0))
			var alpha := 1.0 - maxf(fall - 0.7, 0.0) / 0.3
			draw_circle(at, 3.6, Color(Color.BLACK, alpha))
			draw_circle(at, 2.7, Color(color, alpha))
			draw_circle(at + Vector2(-0.8, -0.8), 0.9, Color(1.0, 0.85, 0.85, alpha))


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
		# Fainter copies trailing behind, so it reads as moving.
		for k in [2, 1]:
			var trail := PackedVector2Array()
			for point in points:
				trail.append(point - Vector2(8.0 * k, 0.0))
			draw_polyline(trail, Color(color, 0.25 * fade / k), 5.0)
		draw_polyline(points, Color(Color.BLACK, 0.75 * fade), 10.0)
		draw_polyline(points, Color(color, fade), 6.0)
		draw_polyline(points, Color(Color("7fb8ff"), fade), 2.0)


# Grandma's Rolling Pin: the pin, across the swing, travelling out from him over its time.
class FxPin:
	extends Fx

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Z

	func _draw() -> void:
		var out := lerpf(14.0, radius * 0.8, minf(progress() * 1.4, 1.0))
		var body := Rect2(out - 6.0, -16.0, 12.0, 32.0)
		for handle: Rect2 in [Rect2(out - 3.0, -25.0, 6.0, 10.0), Rect2(out - 3.0, 15.0, 6.0, 10.0)]:
			draw_rect(handle.grow(1.5), Color.BLACK)
			draw_rect(handle, color.darkened(0.35))
		draw_rect(body.grow(1.5), Color.BLACK)
		draw_rect(body, color)
		draw_line(Vector2(out - 3.0, -14.0), Vector2(out - 3.0, 14.0), color.lightened(0.35), 2.0)
		draw_line(Vector2(out + 3.5, -14.0), Vector2(out + 3.5, 14.0), FLOUR_COLOR, 2.0)


# A knitting needle: a thin grey line with a bead of yarn at the back.
class FxNeedle:
	extends FxStrike

	const SPEED := 380.0
	const LENGTH := 14.0

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


# Bad Hip's cough: puffs of a sickly cloud, each with a dark rim so it reads on the palest floors.
class FxCough:
	extends FxFizz

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Z

	func _draw() -> void:
		var t := progress()
		var fade := 1.0 - maxf(t - 0.7, 0.0) / 0.3
		var swell := 0.6 + 0.4 * minf(t * 4.0, 1.0)
		var puffs := [Vector2(0, 0), Vector2(-0.5, -0.25), Vector2(0.5, -0.2), Vector2(-0.3, 0.3), Vector2(0.35, 0.3)]
		for pass_index in 2:
			for i in puffs.size():
				var drift := Vector2(sin(age * 1.7 + i), -age * 4.0 * (i % 2))
				var at: Vector2 = puffs[i] * radius * swell + drift
				var size := radius * (0.5 if i == 0 else 0.38) * swell
				if pass_index == 0:
					draw_circle(at, size + 2.0, Color(Color.BLACK, 0.6 * fade))
				else:
					draw_circle(at, size, Color(color, 0.85 * fade))
		for i in 3:
			var at := Vector2(-radius * 0.35 + i * radius * 0.35, -2.0 + sin(age * 3.0 + i) * 2.0)
			draw_circle(at, 1.6, Color(color.darkened(0.45), fade))


# The Afterimage: a pale copy of Grandpa where a dodge began. Every enemy it lures walks and strikes at
# it instead of him while it stands, and it takes every blow for nothing. When it goes, whether it fades,
# the room is left or it is freed, each enemy still after it turns back to him. Bosses are never fooled.
class FxAfterimage:
	extends Fx

	const BODY := Vector2(20, 28)
	const FEET := Vector2(0, 17)

	var absorbed := 0
	var _player_ref: WeakRef
	var _lured: Array[WeakRef] = []
	var _feet: Marker2D
	var _sprite: Sprite2D

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		# Among the bodies, as he would be, and it pauses with the game since enemies follow it.
		z_index = 0
		process_mode = Node.PROCESS_MODE_INHERIT
		_feet = Marker2D.new()
		_feet.position = FEET
		add_child(_feet)

	func setup(player: Node2D, sprite: Sprite2D) -> void:
		_player_ref = weakref(player) if player != null else null
		_sprite = sprite
		if _sprite != null:
			_sprite.modulate = Color(color, 0.6)
			add_child(_sprite)

	# Where enemies aim ground attacks, as Player.feet.
	func feet() -> Node2D:
		return _feet

	# Turns an enemy after it. Returns whether it was fooled: a boss, or one already dead, is not.
	func lure(enemy: Enemy) -> bool:
		if enemy == null or not is_instance_valid(enemy) or enemy.is_dead() or enemy.def == null or enemy.def.is_boss:
			return false
		enemy.target = self
		_lured.append(weakref(enemy))
		return true

	func lure_all(enemies: Array) -> int:
		var count := 0
		for node in enemies:
			if node is Enemy and lure(node):
				count += 1
		return count

	func lured_count() -> int:
		var count := 0
		for ref in _lured:
			var enemy := ref.get_ref() as Enemy
			if enemy != null and enemy.target == self:
				count += 1
		return count

	# Every enemy still after it goes back to Grandpa.
	func release() -> void:
		var player: Node2D = _player_ref.get_ref() if _player_ref != null else null
		for ref in _lured:
			var enemy := ref.get_ref() as Enemy
			if enemy != null and is_instance_valid(enemy) and enemy.target == self:
				enemy.target = player
		_lured.clear()

	# What hits it does nothing: it is not there.
	func take_hit(_amount: int, _source := "") -> bool:
		absorbed += 1
		return false

	func take_fire_hit(_amount: int) -> bool:
		return take_hit(_amount)

	func push(_shove: Vector2, _seconds: float) -> void:
		pass

	func slow(_fraction: float, _seconds: float) -> void:
		pass

	func is_dodging() -> bool:
		return false

	func _exit_tree() -> void:
		release()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			release()

	func _process(delta: float) -> void:
		super(delta)
		if _sprite != null:
			var t := progress()
			_sprite.modulate = Color(color, (0.6 - 0.12 * sin(age * 18.0)) * (1.0 - maxf(t - 0.75, 0.0) / 0.25))

	func _draw() -> void:
		var t := progress()
		var fade := 1.0 - maxf(t - 0.75, 0.0) / 0.25
		# A ring at his feet with a dark rim, so the copy reads on pale floors too.
		draw_set_transform(FEET, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(Color.BLACK, 0.7 * fade), 4.0)
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(color, fade), 2.0)
		draw_set_transform(Vector2.ZERO)
		if _sprite == null:
			var body := Rect2(-BODY / 2.0, BODY)
			draw_rect(body.grow(1.0), Color(Color.BLACK, 0.6 * fade), false, 2.0)
			draw_rect(body, Color(color, 0.45 * fade))


# Wheelchair Wheels: rolling across, one big wheel seen side on over his legs, spokes turning, with a
# small caster ahead; rolling up or down, a wheel edge on at each side. Each has a dark rim.
class FxWheels:
	extends Fx

	const RADIUS := 13.0
	const SIDE := 12.0
	const HEIGHT := 12.0
	const WIDTH := 4.0
	const SPIN := 20.0

	var direction := Vector2.RIGHT

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Z

	func _draw() -> void:
		var fade := 1.0 - maxf(progress() - 0.85, 0.0) / 0.15
		if absf(direction.x) >= absf(direction.y):
			_draw_side_on(signf(direction.x), fade)
		else:
			_draw_edge_on(fade)
		# Dust kicked up behind the roll.
		for i in 3:
			var back := -direction * (16.0 + i * 7.0) + Vector2(0, 16 + (i - 1) * 3.0)
			draw_circle(back, 3.4 - i * 0.7, Color(Color.BLACK, 0.35 * fade))
			draw_circle(back, 2.6 - i * 0.6, Color(0.78, 0.72, 0.6, 0.7 * fade))

	func _draw_side_on(way: float, fade: float) -> void:
		var hub := Vector2(-3.0 * way, 7.0)
		draw_arc(hub, RADIUS, 0.0, TAU, 32, Color(Color.BLACK, 0.9 * fade), 6.0)
		draw_arc(hub, RADIUS, 0.0, TAU, 32, Color(0.22, 0.22, 0.25, fade), 3.5)
		draw_arc(hub, RADIUS - 3.0, 0.0, TAU, 28, Color(color, fade), 1.5)
		for k in 4:
			var spoke := Vector2.from_angle(age * SPIN * way + k * PI / 4.0) * (RADIUS - 3.0)
			draw_line(hub - spoke, hub + spoke, Color(Color.BLACK, 0.8 * fade), 2.5)
			draw_line(hub - spoke, hub + spoke, Color(color, fade), 1.2)
		draw_circle(hub, 2.6, Color(Color.BLACK, fade))
		draw_circle(hub, 1.6, Color(color, fade))
		var caster := hub + Vector2(15.0 * way, 9.0)
		draw_circle(caster, 3.6, Color(Color.BLACK, fade))
		draw_circle(caster, 2.4, Color(color, fade))

	func _draw_edge_on(fade: float) -> void:
		for side: float in [-1.0, 1.0]:
			var hub := Vector2(SIDE * side, 8.0)
			var rim := PackedVector2Array()
			for i in 17:
				var a := TAU * i / 16.0
				rim.append(hub + Vector2(cos(a) * WIDTH, sin(a) * HEIGHT))
			draw_polyline(rim, Color(Color.BLACK, 0.9 * fade), 5.0)
			draw_polyline(rim, Color(color, fade), 2.5)
			for k in 3:
				var turn := age * SPIN + k * TAU / 3.0
				if cos(turn) < 0.0:
					continue
				var y := sin(turn) * HEIGHT * 0.9
				draw_line(hub + Vector2(-WIDTH, y), hub + Vector2(WIDTH, y), Color(Color.BLACK, fade), 2.0)


# The Banana Peel: a yellow peel flat on the floor, flaps out, with a dark rim. The first enemy whose
# body walks onto it trips: it is stunned for trip_time and slides on a little. Then the peel is gone.
class FxPeel:
	extends Fx

	const SLIDE := 140.0
	const SLIDE_TIME := 0.25

	var ctx: EffectContext
	var trip_time := 1.2
	var tripped: Enemy

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = 0
		process_mode = Node.PROCESS_MODE_INHERIT

	func _physics_process(_delta: float) -> void:
		if is_inside_tree() and tripped == null:
			trip_first(get_tree().get_nodes_in_group("enemies"))

	# The first of these enemies standing on it trips. Returns it, or null when none is on it.
	func trip_first(enemies: Array) -> Enemy:
		if tripped != null:
			return null
		for node in enemies:
			var enemy := node as Enemy
			if enemy == null or not is_instance_valid(enemy) or enemy.is_dead() or enemy.submerged or enemy.def.ignores_walls:
				continue
			var at := global_position if is_inside_tree() else position
			if at.distance_to(MeleeArc.closest_point(enemy.body_rect(), at)) > radius:
				continue
			tripped = enemy
			var way := enemy.velocity.normalized() if not enemy.velocity.is_zero_approx() else Vector2.RIGHT
			if ctx != null:
				ctx.stun(enemy, trip_time)
				ctx.add_fx(ItemFx.make_pop("Whoops!", color), enemy.global_position)
			else:
				enemy.stun(trip_time)
			if enemy.is_inside_tree():
				enemy.apply_push(way * SLIDE, SLIDE_TIME)
			if is_inside_tree():
				queue_free()
			return enemy
		return null

	func _draw() -> void:
		var flaps := [Vector2(-1.0, -0.35), Vector2(1.0, -0.25), Vector2(-0.25, 0.9), Vector2(0.6, 0.75)]
		for flap: Vector2 in flaps:
			draw_line(Vector2.ZERO, flap * radius, Color.BLACK, 6.0)
		for flap: Vector2 in flaps:
			draw_line(Vector2.ZERO, flap * radius, color, 3.5)
			draw_circle(flap * radius, 1.6, color.darkened(0.25))
		draw_circle(Vector2.ZERO, 3.6, Color.BLACK)
		draw_circle(Vector2.ZERO, 2.6, color)
		draw_circle(Vector2(0.5, -2.5), 1.4, Color("5b3a1a"))


# The Mobility Scooter's flames: a small fire on the floor that burns each enemy touching it, at most
# once every BURN_EVERY seconds each, through ctx so its hits run the hooks.
class FxBurn:
	extends Fx

	const BURN_EVERY := 0.4

	var ctx: EffectContext
	var damage := 3.0
	var _next := {}

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = 0
		process_mode = Node.PROCESS_MODE_INHERIT

	func _physics_process(_delta: float) -> void:
		if is_inside_tree():
			burn_touching(get_tree().get_nodes_in_group("enemies"))

	# Burns each of these enemies touching it that is due. Returns how many it burned.
	func burn_touching(enemies: Array) -> int:
		if ctx == null:
			return 0
		var count := 0
		var at := global_position if is_inside_tree() else position
		for node in enemies:
			var enemy := node as Enemy
			if enemy == null or not is_instance_valid(enemy) or enemy.is_dead() or enemy.submerged:
				continue
			if at.distance_to(MeleeArc.closest_point(enemy.body_rect(), at)) > radius:
				continue
			var key := enemy.get_instance_id()
			if float(_next.get(key, -1.0)) > age:
				continue
			_next[key] = age + BURN_EVERY
			ctx.hit_enemy(enemy, damage)
			count += 1
		return count

	func _draw() -> void:
		var fade := 1.0 - maxf(progress() - 0.7, 0.0) / 0.3
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, radius, Color(0.25, 0.08, 0.02, 0.55 * fade))
		draw_set_transform(Vector2.ZERO)
		for i in 3:
			var flick := sin(age * 14.0 + i * 2.1) * 1.5
			var base := Vector2((i - 1) * radius * 0.5, 1.0)
			var tip := base + Vector2(flick, -radius * (1.1 - 0.25 * absf(i - 1)))
			var flame := PackedVector2Array([base + Vector2(-3.0, 0), tip, base + Vector2(3.0, 0)])
			draw_polyline(flame, Color(Color.BLACK, 0.8 * fade), 4.0)
			draw_colored_polygon(flame, Color(color, fade))
			draw_line(base, base.lerp(tip, 0.55), Color(1.0, 0.92, 0.5, fade), 1.5)


# The burning soup: a wide amber pool with a dark rim, so it reads on pale tile and dark stone alike,
# bubbling, with small flames licking its edge.
class FxSoup:
	extends FxBurn

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		# A wide pool, so it lies under the bodies standing in it, above the floor.
		z_index = -1

	func _draw() -> void:
		var fade := 1.0 - maxf(progress() - 0.8, 0.0) / 0.2
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, radius + 2.5, Color(0.22, 0.08, 0.02, 0.9 * fade))
		draw_circle(Vector2.ZERO, radius, Color(color, 0.85 * fade))
		draw_circle(Vector2(-radius * 0.2, -radius * 0.15), radius * 0.5, Color(color.lightened(0.2), 0.8 * fade))
		for i in 6:
			var angle := TAU * i / 6.0 + 0.4
			var at := Vector2.from_angle(angle) * radius * (0.35 + 0.25 * (i % 2))
			var size := 2.0 + 1.2 * (0.5 + 0.5 * sin(age * 7.0 + i * 1.7))
			draw_arc(at, size, 0.0, TAU, 10, Color(1.0, 0.93, 0.75, fade), 1.2)
		draw_set_transform(Vector2.ZERO)
		for i in 4:
			var angle := TAU * i / 4.0 + 0.8
			var base := Vector2(cos(angle) * radius * 0.85, sin(angle) * radius * 0.5)
			var flick := sin(age * 13.0 + i * 2.3) * 1.2
			var tip := base + Vector2(flick, -7.0)
			var flame := PackedVector2Array([base + Vector2(-2.5, 0), tip, base + Vector2(2.5, 0)])
			draw_polyline(flame, Color(Color.BLACK, 0.8 * fade), 3.5)
			draw_colored_polygon(flame, Color(FLAME_COLOR, fade))


# The Magnifying Glass's glint: a four-pointed star with a dark rim that flares and fades every
# PERIOD, so a secret wall catches the eye from across the room.
class FxGlint:
	extends Fx

	const PERIOD := 1.4

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Enemy.WARNING_Z - 1

	# How bright it is now, from 0 to 1: a quick flare at the start of each period, then nothing.
	func flare() -> float:
		var t := fmod(age, PERIOD) / PERIOD
		return maxf(0.0, sin(t * PI * 2.5)) if t < 0.4 else 0.0

	func _draw() -> void:
		var bright := flare()
		var size := radius * (0.55 + 0.45 * bright)
		# A faint mark stays between flares, so the wall never looks plain again once seen.
		draw_circle(Vector2.ZERO, 2.0, Color(color, 0.35 + 0.65 * bright))
		if bright <= 0.01:
			return
		var spokes := PackedVector2Array([Vector2(0, -size), Vector2(0, size), Vector2(-size, 0), Vector2(size, 0)])
		draw_multiline(spokes, Color(Color.BLACK, 0.8 * bright), 5.5)
		draw_multiline(spokes, Color(color, bright), 3.0)
		draw_arc(Vector2.ZERO, size * 0.7, 0.0, TAU, 20, Color(Color.BLACK, 0.6 * bright), 3.0)
		draw_arc(Vector2.ZERO, size * 0.7, 0.0, TAU, 20, Color(color, 0.8 * bright), 1.5)
		var small := size * 0.45
		var diagonal := PackedVector2Array([Vector2(-small, -small), Vector2(small, small), Vector2(-small, small), Vector2(small, -small)])
		draw_multiline(diagonal, Color(Color.WHITE, bright), 1.0)
		draw_circle(Vector2.ZERO, 2.5, Color(Color.WHITE, bright))


# The Bureaucrat's Stamp: a red box with a word in it, tilted, slammed down large and settling, then
# left a moment so the word is read.
class FxStamp:
	extends Fx

	const FONT_SIZE := 14
	const TILT := -0.2

	var text := "FILED"

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Enemy.WARNING_Z + 1

	func _draw() -> void:
		var t := progress()
		var slam := 1.0 + 0.8 * maxf(0.0, 1.0 - age / 0.12)
		var alpha := 1.0 - maxf(t - 0.75, 0.0) / 0.25
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var box := Rect2(-width / 2.0 - 5.0, -FONT_SIZE / 2.0 - 5.0, width + 10.0, FONT_SIZE + 8.0)
		draw_set_transform(Vector2.ZERO, TILT, Vector2(slam, slam))
		draw_rect(box, Color(FORM_PAPER, 0.85 * alpha))
		draw_rect(box.grow(1.5), Color(Color.BLACK, 0.8 * alpha), false, 2.0)
		draw_rect(box, Color(color, alpha), false, 2.5)
		draw_rect(box.grow(-3.0), Color(color, 0.8 * alpha), false, 1.0)
		var at := Vector2(-width / 2.0, FONT_SIZE / 2.0 - 2.0)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(color, alpha))
		draw_set_transform(Vector2.ZERO)


# The Complaint Form's meter over a boss: a paper form with a dark rim, the word COMPLAINT and a red
# bar that fills. While the boss is held it reads FILED. radius is how far over the boss's middle it sits.
class FxMeter:
	extends Fx

	const SIZE := Vector2(58, 14)
	const FONT_SIZE := 8

	var fill := 0.0
	var filed := false

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Enemy.WARNING_Z + 1

	func _draw() -> void:
		var top := Vector2(-SIZE.x / 2.0, -radius - SIZE.y)
		var form := Rect2(top, SIZE)
		draw_rect(form.grow(1.5), Color.BLACK)
		draw_rect(form, color)
		var font := ThemeDB.fallback_font
		var word := "FILED!" if filed else "COMPLAINT"
		var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		draw_string(font, top + Vector2((SIZE.x - width) / 2.0, 7.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, STAMP_RED if filed else Color("3a3346"))
		var bar := Rect2(top + Vector2(3.0, 9.0), Vector2(SIZE.x - 6.0, 3.0))
		draw_rect(bar, Color(0.3, 0.27, 0.32))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(1.0 if filed else fill, 0.0, 1.0), bar.size.y)), STAMP_RED)


# The Wreath of Thorns: a dark-rimmed green ring round his feet with thorns pointing out and a few red
# berries, turning slowly.
class FxWreath:
	extends Fx

	const FEET := Vector2(0, 17)
	const THORNS := 12

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = 0

	func _draw() -> void:
		draw_set_transform(FEET, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color.BLACK, 8.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 5.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color.lightened(0.35), 1.5)
		var turn := age * 0.6
		for i in THORNS:
			var way := Vector2.from_angle(turn + TAU * i / THORNS)
			var base := way * radius
			var tip := way * (radius + 5.0)
			draw_line(base, tip, Color.BLACK, 3.0)
			draw_line(base, tip, Color("c9d98a"), 1.5)
			if i % 4 == 0:
				draw_circle(way * (radius - 1.0), 2.4, Color.BLACK)
				draw_circle(way * (radius - 1.0), 1.6, Color("e0303a"))
		draw_set_transform(Vector2.ZERO)


# A Harmonica note: a note head with its stem and flag, dark rimmed, rising and swaying over his head.
class FxNote:
	extends Fx

	const COLORS := [Color("9fd8ff"), Color("b7f29a"), Color("ffd27a")]

	var pitch := 0

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Enemy.WARNING_Z + 1

	func _draw() -> void:
		var t := progress()
		var alpha := 1.0 - maxf(t - 0.6, 0.0) / 0.4
		var tint: Color = COLORS[clampi(pitch, 0, COLORS.size() - 1)]
		var head := Vector2(8.0 + pitch * 6.0 + sin(age * 6.0) * 3.0, -30.0 - pitch * 5.0 - 20.0 * t)
		for pass_index in 2:
			var ink := Color(Color.BLACK, alpha) if pass_index == 0 else Color(tint, alpha)
			var grow := 1.5 if pass_index == 0 else 0.0
			draw_set_transform(head, -0.4, Vector2(1.0, 0.75))
			draw_circle(Vector2.ZERO, 3.2 + grow, ink)
			draw_set_transform(Vector2.ZERO)
			draw_line(head + Vector2(2.6, 0), head + Vector2(2.6, -11.0), ink, 1.5 + grow * 1.5)
			draw_line(head + Vector2(2.6, -11.0), head + Vector2(7.0, -6.5), ink, 1.5 + grow * 1.5)


# The Alarm Clock: a brass bell clock over his head, shaking, with ringing arcs either side and RING!
class FxAlarm:
	extends Fx

	const FONT_SIZE := 12

	func _init(at_radius: float, at_color: Color, seconds: float) -> void:
		super(at_radius, at_color, seconds)
		z_index = Enemy.WARNING_Z + 1

	func _draw() -> void:
		var t := progress()
		var alpha := 1.0 - maxf(t - 0.7, 0.0) / 0.3
		var shake := sin(age * 60.0) * 2.0
		var at := Vector2(shake, -40.0)
		for side: float in [-1.0, 1.0]:
			draw_circle(at + Vector2(6.0 * side, -8.0), 4.4, Color(Color.BLACK, alpha))
			draw_circle(at + Vector2(6.0 * side, -8.0), 3.2, Color(color, alpha))
			for k in 2:
				var ring := 13.0 + k * 5.0 + fmod(age * 30.0, 4.0)
				var mid := 0.0 if side > 0.0 else PI
				draw_arc(at, ring, mid - 0.5, mid + 0.5, 8, Color(Color.BLACK, alpha), 3.0)
				draw_arc(at, ring, mid - 0.5, mid + 0.5, 8, Color(color, alpha), 1.5)
		draw_circle(at, 8.5, Color(Color.BLACK, alpha))
		draw_circle(at, 7.0, Color(color, alpha))
		draw_circle(at, 5.0, Color(1.0, 0.97, 0.88, alpha))
		draw_line(at, at + Vector2(0, -3.5), Color(Color.BLACK, alpha), 1.2)
		draw_line(at, at + Vector2(2.5, 1.0), Color(Color.BLACK, alpha), 1.2)
		var font := ThemeDB.fallback_font
		var width := font.get_string_size("RING!", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var word := Vector2(-width / 2.0, -54.0)
		draw_string_outline(font, word, "RING!", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 4, Color(Color.BLACK, alpha))
		draw_string(font, word, "RING!", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(color, alpha))


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
