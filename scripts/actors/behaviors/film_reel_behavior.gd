class_name FilmReelBehavior
extends EnemyBehavior

# A Runaway Film Reel, an object and no one at all. It rolls in a straight line along a row or a column
# until it hits a wall or a seat, then rattles a moment and turns 90 degrees toward Grandpa, its next
# leg warned as a lane while it rattles. Touching it costs a pill, as any body does, and it unspools a
# strip of film behind it (FilmTrail) that slows him while he stands on it and fades after 4 s.
const ROLL_SPEED := 130.0
# It rattles this long before each leg, the leg's lane warned.
const WINDUP := 0.45
const LANE_LENGTH := 200.0
const LANE_WIDTH := 18.0
const WARNING_RADIUS := 12.0
const WALL_GRACE := 0.05
# A piece of film every this many pixels rolled.
const LAY_EVERY := 12.0
# How far ahead a new way must be open for the reel to roll it.
const LOOK_AHEAD := 20.0

var _telegraph := Telegraph.new()
var _way := Vector2.ZERO
var _rolling := false
var _rolled_for := 0.0
var _since_piece := 0.0
var _trail: FilmTrail


# The row or column way that points most toward Grandpa, for the first leg.
static func axis_toward(to_target: Vector2) -> Vector2:
	if absf(to_target.x) >= absf(to_target.y):
		return Vector2.RIGHT if to_target.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if to_target.y >= 0.0 else Vector2.UP


# Where it turns after hitting something while rolling way: 90 degrees, to the side Grandpa is on
# (to_target), or to the other side when that is blocked, or back the way it came when both are.
# is_clear, when valid, takes a way and says whether the reel can roll it.
static func bounce_turn(way: Vector2, to_target: Vector2, is_clear := Callable()) -> Vector2:
	var left := Vector2(way.y, -way.x)
	var right := -left
	var first := left if left.dot(to_target) >= right.dot(to_target) else right
	var second := right if first == left else left
	for option: Vector2 in [first, second, -way]:
		if not is_clear.is_valid() or is_clear.call(option):
			return option
	return first


func tick(enemy: Enemy, delta: float) -> void:
	if _rolling:
		_roll(enemy, delta)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_rolling = true
			_rolled_for = 0.0
		return
	# A new leg: the first toward him, then turned at each bounce.
	if _way == Vector2.ZERO:
		_way = axis_toward(enemy.target_ground() - enemy.global_position)
	else:
		_way = bounce_turn(_way, enemy.target_ground() - enemy.global_position, _clear_way(enemy))
	_telegraph.start(WINDUP)
	enemy.set_warning(_telegraph, WARNING_RADIUS)
	enemy.set_warning_lane(_way, LANE_LENGTH, LANE_WIDTH, false)


func _roll(enemy: Enemy, delta: float) -> void:
	if _rolled_for > WALL_GRACE and enemy.get_slide_collision_count() > 0:
		_rolling = false
		return
	_rolled_for += delta
	enemy.hold_lane()
	enemy.desired_velocity = _way * ROLL_SPEED
	_since_piece += ROLL_SPEED * delta
	if _since_piece >= LAY_EVERY:
		_since_piece = 0.0
		_lay(enemy)


func _lay(enemy: Enemy) -> void:
	if not enemy.is_inside_tree():
		return
	if not is_instance_valid(_trail):
		_trail = FilmTrail.new()
		_trail.setup(enemy.target, enemy)
		enemy.get_parent().add_child(_trail)
	_trail.add_piece(enemy.global_position - _way * enemy.def.body_size.x * 0.5, _way)


# Whether the reel could roll a way from where it stands: open floor just ahead.
func _clear_way(enemy: Enemy) -> Callable:
	var at := enemy.global_position
	var grid := enemy.walk_grid
	var ground := enemy.open_ground
	return func(way: Vector2) -> bool:
		var ahead := at + way * LOOK_AHEAD
		if grid != null and not grid.is_open(WalkGrid.cell_of(ahead)):
			return false
		return not ground.is_valid() or ground.call(ahead)
