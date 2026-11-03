class_name SteamValveBehavior
extends EnemyBehavior

# A valve bolted beside a wall. It never moves, and vents steam along one of four lanes at a time,
# going round them clockwise. Each lane is warned first, and a lane that would only blow into the
# wall it hangs on is passed over.
const WINDUP := 0.8
const LANE_LENGTH := 140.0
const LANE_WIDTH := 18.0
const WARNING_RADIUS := 16.0
const COOLDOWN := 1.8
const FIRST_VENT := 1.2
# A lane shorter than this ends in a wall right away, so it is not worth venting.
const MIN_LANE := 40.0
const LANES: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

var _telegraph := Telegraph.new()
var _cooldown := FIRST_VENT
var _lane := Vector2.LEFT


# The next lane clockwise, the way a hand turns the wheel.
static func next_lane(last: Vector2) -> Vector2:
	var at := LANES.find(last)
	return LANES[(at + 1) % LANES.size()] if at >= 0 else LANES[0]


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			var length := enemy.warning_lane_length()
			enemy.clear_warning()
			_cooldown = COOLDOWN
			var jet := SteamJet.new()
			jet.setup(enemy, _lane, length, LANE_WIDTH)
			enemy.get_parent().add_child(jet)
			jet.global_position = enemy.global_position
		return
	_cooldown -= delta
	if _cooldown <= 0.0 and enemy.target_in_view():
		_begin(enemy)


func _begin(enemy: Enemy) -> void:
	for i in LANES.size():
		_lane = next_lane(_lane)
		enemy.set_warning_lane(_lane, LANE_LENGTH, LANE_WIDTH, false)
		if enemy.warning_lane_length() >= MIN_LANE:
			_telegraph.start(WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			return
	enemy.clear_warning()
	_cooldown = COOLDOWN
