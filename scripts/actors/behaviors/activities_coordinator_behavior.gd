class_name ActivitiesCoordinatorBehavior
extends EnemyBehavior

# Runs the day room: a bingo grid lit across the floor around Grandpa, row by row with one column
# always left safe, a spin of the ball cage that fires a fan of balls down a warned lane, and
# residents woken on marked spots.
const GRID := 4
const GRID_GAP := 32.0
const TILE_RADIUS := 20.0
const TILE_WARNING := 0.8
const ROW_STEP := 0.25
const BINGO_WINDUP := 0.6
const CAGE_WINDUP := 0.7
const BALLS := 5
const BALL_SPREAD := deg_to_rad(50.0)
const BALL_SPEED := 150.0
const LANE_LENGTH := 160.0
const LANE_WIDTH := 44.0
const WARNING_RADIUS := 34.0
const COOLDOWN := 1.1
const KEEP_NEAR := 100.0
const FIRST_SUMMON := 6.0
const SUMMON_EVERY := 12.0
const SUMMON_COUNT := 2
const SUMMON_DISTANCE := 100.0
const MAX_ENEMIES := 5
const SAY_TIME := 1.0

enum Attack { NONE, BINGO, CAGE }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON
var _safe_column := -1
var _aim := Vector2.RIGHT
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func choose_attack(last: int, roll: float) -> int:
	if last == Attack.BINGO:
		return Attack.CAGE
	if last == Attack.CAGE:
		return Attack.BINGO
	return Attack.BINGO if roll < 0.5 else Attack.CAGE


static func column_x(center: Vector2, column: int) -> float:
	return center.x + (column - (GRID - 1) / 2.0) * GRID_GAP


static func row_y(center: Vector2, row: int) -> float:
	return center.y + (row - (GRID - 1) / 2.0) * GRID_GAP


# Every tile of the grid but the safe column, row by row from the top.
static func bingo_grid(center: Vector2, safe_column: int) -> Array[Vector2]:
	var tiles: Array[Vector2] = []
	for row in GRID:
		for column in GRID:
			if column != safe_column:
				tiles.append(Vector2(column_x(center, column), row_y(center, row)))
	return tiles


# Any column but the last one, so standing still where it was safe never works twice.
static func next_safe_column(last: int, rng: RandomNumberGenerator) -> int:
	if last < 0 or last >= GRID:
		return rng.randi_range(0, GRID - 1)
	var column := rng.randi_range(0, GRID - 2)
	return column + 1 if column >= last else column


func tick(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy)
		return
	_cooldown -= delta
	var offset := enemy.target.global_position - enemy.global_position
	if not BossMoves.in_view(offset):
		enemy.desired_velocity = offset.normalized() * enemy.def.speed * BossMoves.CATCH_UP_SPEED
		return
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_EVERY
		if BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES):
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, SUMMON_COUNT, SUMMON_DISTANCE, 1.2), BossMoves.SUMMON_WARNING)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(_last, _rng.randf()))
		return
	if offset.length() > KEEP_NEAR:
		enemy.desired_velocity = offset.normalized() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	match attack:
		Attack.BINGO:
			_telegraph.start(BINGO_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Eyes down for bingo!", SAY_TIME)
		Attack.CAGE:
			_telegraph.start(CAGE_WINDUP)
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.set_warning_lane(_aim, LANE_LENGTH, LANE_WIDTH, false)


func _finish_attack(enemy: Enemy) -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.BINGO:
			_safe_column = next_safe_column(_safe_column, _rng)
			var tiles := bingo_grid(enemy.target_ground(), _safe_column)
			var per_row := GRID - 1
			for i in tiles.size():
				enemy.strike_ground(tiles[i], TILE_RADIUS, TILE_WARNING, floori(i / float(per_row)) * ROW_STEP)
			_cooldown += ROW_STEP * GRID
		Attack.CAGE:
			for direction in BossMoves.fan_directions(_aim, BALLS, BALL_SPREAD):
				enemy.shoot(direction, BALL_SPEED)
