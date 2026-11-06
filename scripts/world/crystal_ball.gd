class_name CrystalBall
extends Node2D

# A Crystal Gazer's glowing ball. It glides low over the carpet after Grandpa's feet for HOME_TIME,
# turning no faster than TURN_RATE, so a step aside leaves it curving after him. Then it stops, a red
# ring round it fills for BURST_WARNING, and it bursts: feet inside the ring cost a pill, unless a wall
# stands between, as with a blast. Meeting cover (a wall, a desk, a partition) ends its flight there at once, and it
# bursts the same way, warned. Touching his feet on the way costs a pill and pops it with no burst. It
# comes to nothing if the gazer falls first.
#
# Drawn for crystal_ball.png, a 32x32 canvas whose ball fills about 21x24 of it, shown at 1:1.
const SPEED := 75.0
const TURN_RATE := PI * 110.0 / 180.0
const HOME_TIME := 3.0
const BURST_WARNING := 0.6
const BURST_RADIUS := 28.0
# How near his feet it must come to strike him on the way.
const HIT_RADIUS := 10.0
const BALL_RADIUS := 10.0
const BURST_SHOW := 0.3
const COLOR := Color("e4524f")
const GLASS := Color("ad9bf3")
const GLASS_LIGHT := Color("d7cdff")
const SHINE := Color("faf9fb")
const GLASS_DEEP := Color("7e71cd")
const GLOW := Color(0.78, 0.72, 1.0, 0.35)
const STAND := Color("292125")
# How near its spot a point counts as better avoided for a simulated player while it flies.
const AVOID_REACH := 44.0

enum State { HOMING, WARNING, BURST, GONE }

var _source: Enemy
var _target: Node2D
var _way := Vector2.RIGHT
var _state := State.HOMING
var _home_left := HOME_TIME
var _warn_left := BURST_WARNING
var _show_left := BURST_SHOW
# Takes a step's start and end and says whether cover stands across it. Unset, it asks the physics
# space for walls and props, as a shot does.
var blocked: Callable


# One step of homing: the way turned toward the wanted way by no more than TURN_RATE x delta.
static func steer(way: Vector2, wanted: Vector2, delta: float) -> Vector2:
	if wanted.is_zero_approx():
		return way
	var turn := way.angle_to(wanted)
	var most := TURN_RATE * delta
	return way.rotated(clampf(turn, -most, most))


static func burst_hits(center: Vector2, feet: Vector2) -> bool:
	return center.distance_to(feet) <= BURST_RADIUS


# Lets one go from where a gazer stands, first headed at his feet.
static func release(enemy: Enemy) -> CrystalBall:
	var ball := CrystalBall.new()
	ball.setup(enemy, enemy.target, enemy.global_position.direction_to(enemy.target_ground()))
	enemy.get_parent().add_child(ball)
	ball.global_position = enemy.global_position
	return ball


func setup(source: Enemy, target: Node2D, way: Vector2) -> void:
	_source = source
	_target = target
	_way = way.normalized() if not way.is_zero_approx() else Vector2.RIGHT
	z_index = Projectile.SHOT_Z


func state() -> State:
	return _state


func is_homing() -> bool:
	return _state == State.HOMING


func way() -> Vector2:
	return _way


func home_left() -> float:
	return _home_left


# How far the burst's ring has filled, 0 while it still flies.
func fill() -> float:
	if _state != State.WARNING:
		return 1.0 if _state == State.BURST else 0.0
	return clampf(1.0 - _warn_left / BURST_WARNING, 0.0, 1.0)


func _feet() -> Vector2:
	if not is_instance_valid(_target):
		return Vector2.INF
	return _target.feet().global_position if _target.has_method("feet") else _target.global_position


func _is_blocked(from: Vector2, to: Vector2) -> bool:
	if blocked.is_valid():
		return blocked.call(from, to)
	if not is_inside_tree():
		return false
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


# Moves it on by delta. Returns what happened to Grandpa's feet: "hit" when it struck him on the way,
# "burst" when it burst over them, "" otherwise.
func advance(delta: float, feet: Vector2) -> String:
	match _state:
		State.HOMING:
			_home_left -= delta
			if feet != Vector2.INF:
				_way = steer(_way, feet - global_position, delta)
			var next := global_position + _way * SPEED * delta
			if _is_blocked(global_position, next):
				_state = State.WARNING
				return ""
			global_position = next
			if feet != Vector2.INF and global_position.distance_to(feet) <= HIT_RADIUS:
				_state = State.GONE
				return "hit"
			if _home_left <= 0.0:
				_state = State.WARNING
		State.WARNING:
			_warn_left -= delta
			if _warn_left <= 0.0:
				_state = State.BURST
				if feet != Vector2.INF and burst_hits(global_position, feet) and _line_clear(feet):
					return "burst"
		State.BURST:
			_show_left -= delta
			if _show_left <= 0.0:
				_state = State.GONE
	return ""


func _line_clear(feet: Vector2) -> bool:
	if blocked.is_valid():
		return not blocked.call(global_position, feet)
	if not is_inside_tree():
		return true
	return EnemyBlast.line_is_clear(get_world_2d().direct_space_state, global_position, feet)


# What it means for a point, for a simulated player: 2 inside a warned ring or right at the ball,
# 1 near the ball while it flies.
func threat_at(p: Vector2, strict: bool) -> int:
	var distance := p.distance_to(global_position)
	match _state:
		State.HOMING:
			if distance <= HIT_RADIUS + (10.0 if strict else 4.0):
				return 2
			return 1 if distance <= AVOID_REACH else 0
		State.WARNING:
			return 2 if distance <= BURST_RADIUS + (8.0 if strict else 3.0) else 0
	return 0


func threat_imminent(p: Vector2) -> bool:
	return _state == State.WARNING and _warn_left < 0.12 and p.distance_to(global_position) <= BURST_RADIUS + 3.0


# Its shapes for a plan made now. Warned, the ring at its burst. Flying, the ball's reach until it
# stops, and the ring wherever it could stop.
func route_circles() -> Array:
	var at := global_position
	match _state:
		State.WARNING:
			return [[Vector3(at.x, at.y, BURST_RADIUS + 3.0), Vector2(_warn_left, _warn_left + 0.05)]]
		State.HOMING:
			var reach := SPEED * maxf(_home_left, 0.0)
			return [
				[Vector3(at.x, at.y, HIT_RADIUS + reach), Vector2(0.0, _home_left)],
				[Vector3(at.x, at.y, BURST_RADIUS + reach), Vector2(_home_left + BURST_WARNING, _home_left + BURST_WARNING + 0.05)],
			]
	return []


func _process(delta: float) -> void:
	queue_redraw()
	if _state == State.GONE:
		queue_free()
		return
	if _state != State.BURST and (not is_instance_valid(_source) or _source.is_dead()):
		queue_free()
		return
	var outcome := advance(delta, _feet())
	if not outcome.is_empty() and is_instance_valid(_source):
		_source.hit_target(_source.attack_damage())


func _draw() -> void:
	if _state == State.BURST:
		var progress := 1.0 - maxf(_show_left, 0.0) / BURST_SHOW
		draw_circle(Vector2.ZERO, BURST_RADIUS * progress, Color(GLASS_LIGHT, 0.5 * (1.0 - progress)))
		for i in 8:
			var shard := Vector2.from_angle(TAU * i / 8.0 + 0.2) * BURST_RADIUS * progress
			draw_line(shard * 0.6, shard, Color(SHINE, 1.0 - progress), 2.0)
		return
	if _state == State.WARNING:
		var filled := fill()
		draw_circle(Vector2.ZERO, BURST_RADIUS * filled, Color(COLOR, 0.15 + 0.3 * filled))
		draw_arc(Vector2.ZERO, BURST_RADIUS, 0.0, TAU, 32, COLOR, 2.0)
	# A soft glow, the glass with a deeper rim and a bright shine, and a little dark stand.
	draw_circle(Vector2.ZERO, BALL_RADIUS + 4.0, GLOW)
	draw_rect(Rect2(-6.0, BALL_RADIUS - 3.0, 12.0, 4.0), STAND)
	draw_circle(Vector2.ZERO, BALL_RADIUS, GLASS_DEEP)
	draw_circle(Vector2(-1.0, -1.0), BALL_RADIUS - 2.0, GLASS)
	draw_circle(Vector2(-3.0, -3.0), 3.5, GLASS_LIGHT)
	draw_circle(Vector2(-4.0, -4.5), 1.5, SHINE)
	draw_arc(Vector2.ZERO, BALL_RADIUS, 0.0, TAU, 20, Color.BLACK, 1.0)
