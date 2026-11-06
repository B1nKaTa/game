class_name StarFall
extends Node2D

# The Star, Sister Celestine's last card: spots of light rain down round Grandpa. Every spot shows at
# once, a red ring that fills for its own warning, the first on his feet and each of the others landing
# STEP after the one before, so they come down in a short stagger. A falling star streaks onto each
# spot as it fills, and feet in a spot as it lands cost a pill. It lies at the room's origin with its
# spots in room coordinates, and comes to nothing if she falls first.
const RADIUS := 16.0
const STEP := 0.15
const FLASH := 0.3
const COLOR := Color("e4524f")
const LIGHT := Color(1.0, 0.95, 0.7)
const LIGHT_EDGE := Color("8a6a1c")
# The falling star is the critic's star picture (art/props/star.png), drawn 1:1 at the head of its
# streak; the drawing stays for when it is missing.
const ART := "star"
# The spots as a plan sees them: each this much wider, hurting this long after it lands.
const ROUTE_SPARE := 3.0
const ROUTE_HIT_TIME := 0.05

var _source: Enemy
var _spots: Array[Vector2] = []
# How long until each spot lands, and how long since, once it has.
var _left: Array[float] = []
var _warnings: Array[float] = []
var _landed: Array[bool] = []
var _since: Array[float] = []
var _damage := -1


func setup(source: Enemy, spots: Array[Vector2], warning: float, damage := -1) -> void:
	_source = source
	_spots = spots.duplicate()
	_left.clear()
	_warnings.clear()
	_landed.clear()
	_since.clear()
	for i in _spots.size():
		_left.append(warning + i * STEP)
		_warnings.append(warning + i * STEP)
		_landed.append(false)
		_since.append(0.0)
	_damage = damage
	z_index = Projectile.SHOT_Z


func spots() -> Array[Vector2]:
	return _spots


func damage() -> int:
	return _damage


# How long until a spot lands, from now.
func lands_in(index: int) -> float:
	return maxf(_left[index], 0.0)


func fill(index: int) -> float:
	return clampf(1.0 - _left[index] / maxf(_warnings[index], 0.01), 0.0, 1.0)


func has_landed(index: int) -> bool:
	return _landed[index]


func is_spent() -> bool:
	return not _landed.has(false)


func _spot(index: int) -> Vector2:
	return global_position + _spots[index]


# Moves it on; returns how many spots landed on the point in this step.
func advance(delta: float, point: Vector2) -> int:
	var hits := 0
	for i in _spots.size():
		if _landed[i]:
			_since[i] += delta
			continue
		_left[i] -= delta
		if _left[i] <= 0.0:
			_landed[i] = true
			if _spot(i).distance_to(point) <= RADIUS:
				hits += 1
	return hits


# What it means for a point, for a simulated player: 2 in a spot still to land, 1 just beside one.
func threat_at(p: Vector2, strict: bool) -> int:
	var worst := 0
	for i in _spots.size():
		if _landed[i]:
			continue
		var distance := _spot(i).distance_to(p)
		if distance <= RADIUS + (8.0 if strict else 3.0):
			return 2
		if distance <= RADIUS + 18.0:
			worst = 1
	return worst


func threat_imminent(p: Vector2) -> bool:
	for i in _spots.size():
		if not _landed[i] and _left[i] < 0.12 and _spot(i).distance_to(p) <= RADIUS + 3.0:
			return true
	return false


# Its shapes for a plan made now: each spot still to land, hurting the moment it does.
func route_circles() -> Array:
	var shapes: Array = []
	for i in _spots.size():
		if _landed[i]:
			continue
		var at := _spot(i)
		shapes.append([Vector3(at.x, at.y, RADIUS + ROUTE_SPARE), Vector2(_left[i], _left[i] + ROUTE_HIT_TIME)])
	return shapes


func _process(delta: float) -> void:
	queue_redraw()
	if is_spent():
		var done := true
		for since in _since:
			if since < FLASH:
				done = false
		for i in _since.size():
			_since[i] += delta
		if done:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	var feet := _source.target_ground() if is_instance_valid(_source.target) else Vector2.INF
	# One spot at a time can hit him; a second in the same step would only meet his grace.
	if advance(delta, feet) > 0:
		_source.hit_target(_source.attack_damage(_damage))


func _star(center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var reach := size if i % 2 == 0 else size * 0.42
		points.append(center + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * reach)
	draw_colored_polygon(points, color)


func _draw() -> void:
	for i in _spots.size():
		var at := _spots[i]
		if _landed[i]:
			# A burst of light where it came down, fading.
			var fade := clampf(1.0 - _since[i] / FLASH, 0.0, 1.0)
			if fade <= 0.0:
				continue
			draw_circle(at, RADIUS * (1.0 + 0.3 * (1.0 - fade)), Color(LIGHT, 0.45 * fade))
			_star(at, 9.0, Color(LIGHT, fade))
			continue
		var filled := fill(i)
		draw_circle(at, RADIUS, Color(COLOR, 0.1 + 0.15 * filled))
		draw_circle(at, RADIUS * filled, Color(COLOR, 0.3))
		draw_arc(at, RADIUS, 0.0, TAU, 24, COLOR, 2.0)
		# The star streaks down onto its spot as it fills, from high above.
		if filled > 0.4:
			var drop := (1.0 - filled) / 0.6 * 70.0
			var star_at := at - Vector2(drop * 0.35, drop)
			draw_line(star_at, star_at - Vector2(7.0, 20.0), Color(LIGHT, 0.5), 2.0)
			var art := PropArt.texture(ART)
			if art != null:
				draw_texture(art, PropArt.centred(art, star_at))
				continue
			_star(star_at, 6.0, LIGHT)
			_star(star_at, 3.0, LIGHT_EDGE)
