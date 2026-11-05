class_name ChairmanBehavior
extends EnemyBehavior

# The Chairman of the Board, the last boss of all. His gavel comes down on a warned spot, the one attack
# that costs three pills, so its warning always shows whole, with a second ring round the spot. His
# quarterly projections raise the bars of a bar chart out of the floor in turn, down warned columns
# with open gaps between, the nearest gap marked green. His hostile takeover shows a warned tether to
# Grandpa and then pulls him a short way in, never through anything solid, and charges down a fresh
# warned lane; a dodge before the pull snaps the tether. Below half health he is quicker, red tape
# spreads across warned rows of the room every so often for ten seconds, and every projection chains
# straight into one gavel.
const GAVEL_WINDUP := 1.2
const GAVEL_DAMAGE := Enemy.HEAVIEST_DAMAGE
# The gavel's warning shows for all of its windup, whatever the player's warning stat.
const GAVEL_SHOWN_WHOLE := true
const GAVEL_RADIUS := 44.0
const PROJECTION_WINDUP := 0.45
const BAR_WIDTH := 64.0
# The open floor between two bars, wide enough to stand in.
const BAR_GAP := 40.0
const BAR_WARNING := 0.75
const BAR_STAGGER := 0.3
const BAR_STAND := 0.35
# A bar cut down to less than this by a wall is left out.
const BAR_MIN := 12.0
const TETHER_WINDUP := 0.9
const TETHER_SHOWN_WHOLE := true
const TETHER_LANE_WIDTH := 20.0
# Only worth it when Grandpa is some way off.
const TAKEOVER_START := 130.0
const PULL_SPEED := 240.0
const PULL_TIME := 0.3
# The pull never brings him nearer than this to the Chairman.
const PULL_KEEP := 60.0
const CHARGE_WINDUP := 0.75
const CHARGE_LENGTH := 320.0
const CHARGE_SPEED := 400.0
const CHARGE_HIT_RANGE := 28.0
const CHARGE_LANE_WIDTH := 52.0
const CHARGE_DAMAGE := Enemy.HEAVY_DAMAGE
const TAPE_WINDUP := 0.6
const TAPE_EVERY := 10.0
const TAPE_ROWS := 3
const TAPE_ROW_GAP := 3
const WARNING_RADIUS := 40.0
# Shorter than Mortimer's and the Mall Santa's 0.65 and 0.45.
const BASE_COOLDOWN := 0.35
const PHASE_TWO_COOLDOWN := 0.25
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const KEEP_NEAR := 90.0
const SAY_TIME := 1.0

enum Attack { NONE, GAVEL, PROJECTIONS, TAKEOVER, CHARGE, TAPE }

var _telegraph := Telegraph.new()
var _dash := BossDash.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
# Starts full, so the first spread comes as soon as he reaches the second phase.
var _since_tape := TAPE_EVERY
var _aim := Vector2.RIGHT
var _tether: TakeoverTether
var _bar_count := 0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


# The second phase quickens his windups, but never the gavel's extra-clear warning.
static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := PROJECTION_WINDUP
	match attack:
		Attack.GAVEL:
			return GAVEL_WINDUP
		Attack.TAKEOVER:
			windup = TETHER_WINDUP
		Attack.CHARGE:
			windup = CHARGE_WINDUP
		Attack.TAPE:
			windup = TAPE_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# In the second phase every projection chains straight into one gavel, and nothing else chains.
static func followup(attack: int, phase_two: bool) -> int:
	if phase_two and attack == Attack.PROJECTIONS:
		return Attack.GAVEL
	return Attack.NONE


# The takeover is only for when Grandpa is far, and the gavel stands in for it up close.
static func choose_attack(last: int, far: bool, roll: float) -> int:
	var options: Array[int] = [Attack.GAVEL, Attack.PROJECTIONS]
	if far:
		options.append(Attack.TAKEOVER)
	if options.size() > 1:
		options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# Only the second phase spreads tape, and not more often than TAPE_EVERY.
static func spreads_tape(phase_two: bool, since_tape: float) -> bool:
	return phase_two and since_tape >= TAPE_EVERY


# A dodge before the pull snaps the tether.
static func tether_holds(dodged: bool) -> bool:
	return not dodged


# How long the pull lasts for a distance between them: at most PULL_TIME, and never so long that it
# brings him nearer than PULL_KEEP.
static func pull_time(distance: float) -> float:
	return clampf((distance - PULL_KEEP) / PULL_SPEED, 0.0, PULL_TIME)


# The shove that pulls him in, from where his feet are toward the Chairman.
static func pull_shove(feet: Vector2, chairman: Vector2) -> Vector2:
	var way := feet.direction_to(chairman)
	return way * PULL_SPEED if not way.is_zero_approx() else Vector2.ZERO


# The bars of the chart, across the room's floor from wall to wall, each running its whole height.
# offset slides the chart along, so the gaps are somewhere new each time.
static func projection_bars(room: Rect2, offset: float) -> Array[Rect2]:
	var bars: Array[Rect2] = []
	var pitch := BAR_WIDTH + BAR_GAP
	var x := room.position.x - pitch + fposmod(offset, pitch)
	while x < room.end.x:
		var left := maxf(x, room.position.x)
		var right := minf(x + BAR_WIDTH, room.end.x)
		if right - left >= BAR_MIN:
			bars.append(Rect2(left, room.position.y, right - left, room.size.y))
		x += pitch
	return bars


# The open floor between and beside the bars, each the room's whole height.
static func projection_gaps(room: Rect2, bars: Array[Rect2]) -> Array[Rect2]:
	var gaps: Array[Rect2] = []
	var x := room.position.x
	for bar in bars:
		if bar.position.x - x > 0.01:
			gaps.append(Rect2(x, room.position.y, bar.position.x - x, room.size.y))
		x = bar.end.x
	if room.end.x - x > 0.01:
		gaps.append(Rect2(x, room.position.y, room.end.x - x, room.size.y))
	return gaps


# Where the green mark goes: the middle of the gap nearest his feet, at his height, kept off the
# Chairman's own body. Only a gap wide enough to stand in counts.
static func safe_gap_point(gaps: Array[Rect2], feet: Vector2, avoid := Rect2()) -> Vector2:
	var best := Vector2.INF
	var best_distance := INF
	for gap in gaps:
		if gap.size.x < BAR_GAP - 0.01:
			continue
		var spot := Vector2(gap.get_center().x, clampf(feet.y, gap.position.y + 16.0, gap.end.y - 16.0))
		if avoid.has_area() and avoid.grow(SafeSpotMark.RADIUS).has_point(spot):
			continue
		var distance := spot.distance_to(feet)
		if distance < best_distance:
			best_distance = distance
			best = spot
	return best


# Whether a cell may be taped: inside the walls, on open floor, and well clear of every doorway.
static func can_be_taped(cell: Vector2i, room_cells: Vector2i, is_open := Callable()) -> bool:
	if cell.x < 1 or cell.y < 1 or cell.x > room_cells.x - 2 or cell.y > room_cells.y - 2:
		return false
	for door in FountainDivaBehavior.door_cells(room_cells):
		if absi(cell.x - door.x) <= RoomLayout.RED_TAPE_DOOR_CLEARANCE and absi(cell.y - door.y) <= RoomLayout.RED_TAPE_DOOR_CLEARANCE:
			return false
	return not is_open.is_valid() or is_open.call(RoomBackdrop.cell_center(cell))


# The rows the tape spreads along: his own and one each side, TAPE_ROW_GAP rows away, kept inside
# the room. Each row is taped from wall to wall wherever a cell may be.
static func tape_cells(room_cells: Vector2i, target_cell: Vector2i, is_open := Callable()) -> Array[Vector2i]:
	var rows: Array[int] = []
	for i in TAPE_ROWS:
		var row := clampi(target_cell.y + (i - int(TAPE_ROWS / 2.0)) * TAPE_ROW_GAP, 1, room_cells.y - 2)
		if not rows.has(row):
			rows.append(row)
	var cells: Array[Vector2i] = []
	for y in rows:
		for x in range(1, room_cells.x - 1):
			var cell := Vector2i(x, y)
			if can_be_taped(cell, room_cells, is_open):
				cells.append(cell)
	return cells


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	_since_tape += delta
	if _dash.is_active():
		_dash.tick(enemy, delta)
		if not _dash.is_active():
			_cooldown = cooldown_for(phase_two)
		return
	if _telegraph.is_active():
		if _attack == Attack.TAKEOVER and not tether_holds(_target_dodging(enemy)):
			_snap_tether(enemy, phase_two)
			return
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	if _next != Attack.NONE and _cooldown <= cooldown_for(phase_two) * 0.5:
		var chained := _next
		_next = Attack.NONE
		_begin(enemy, chained, phase_two)
		return
	if _cooldown <= 0.0:
		if spreads_tape(phase_two, _since_tape):
			_begin(enemy, Attack.TAPE, phase_two)
		else:
			_begin(enemy, choose_attack(_last, enemy.distance_to_target() >= TAKEOVER_START, _rng.randf()), phase_two)
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _target_dodging(enemy: Enemy) -> bool:
	return is_instance_valid(enemy.target) and enemy.target.has_method("is_dodging") and enemy.target.is_dodging()


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.GAVEL:
			enemy.set_warning(_telegraph, WARNING_RADIUS, GAVEL_SHOWN_WHOLE)
			enemy.say("Order! Order!", SAY_TIME)
			drop_gavel(enemy, enemy.target_ground(), GAVEL_WINDUP)
		Attack.PROJECTIONS:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Quarterly projections!", SAY_TIME)
			_raise_projections(enemy)
		Attack.TAKEOVER:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS, TETHER_SHOWN_WHOLE)
			enemy.set_warning_lane(_aim, enemy.global_position.distance_to(enemy.target_ground()), TETHER_LANE_WIDTH)
			enemy.say("Let's discuss a merger.", SAY_TIME)
			_tether = TakeoverTether.new()
			_tether.setup(enemy, windup_for(attack, phase_two))
			enemy.get_parent().add_child(_tether)
			_tether.global_position = enemy.global_position
		Attack.CHARGE:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, CHARGE_HIT_RANGE)
			enemy.set_warning_lane(_aim, enemy.global_position.distance_to(_charge_end(enemy)), CHARGE_LANE_WIDTH)
			enemy.say("Acquired!", SAY_TIME)
		Attack.TAPE:
			_since_tape = 0.0
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Let's add some process.", SAY_TIME)
			_spread_tape(enemy)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.PROJECTIONS:
			busy = maxf(projection_time(_bar_count) - windup_for(Attack.PROJECTIONS, phase_two), 0.0)
		Attack.TAKEOVER:
			# The tether held: he pulls, then winds up a charge down a fresh lane.
			_pull(enemy)
			_last = Attack.TAKEOVER
			_begin(enemy, Attack.CHARGE, phase_two)
			return
		Attack.CHARGE:
			_dash.start(_aim, enemy.global_position.distance_to(_charge_end(enemy)), CHARGE_SPEED, CHARGE_HIT_RANGE, CHARGE_DAMAGE)
			_attack = Attack.NONE
			return
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two)


func _snap_tether(enemy: Enemy, phase_two: bool) -> void:
	if is_instance_valid(_tether):
		_tether.snap()
	_tether = null
	enemy.clear_warning()
	_telegraph.start(0.0)
	enemy.say("Hmph. Noted.", SAY_TIME)
	_attack = Attack.NONE
	_last = Attack.TAKEOVER
	_cooldown = cooldown_for(phase_two)


func _pull(enemy: Enemy) -> void:
	_tether = null
	if not is_instance_valid(enemy.target) or not enemy.target.has_method("push"):
		return
	var feet := enemy.target_ground()
	var seconds := pull_time(feet.distance_to(enemy.global_position))
	if seconds > 0.0:
		enemy.target.push(pull_shove(feet, enemy.global_position), seconds)


func _charge_end(enemy: Enemy) -> Vector2:
	if enemy.open_ground.is_valid():
		return MatronBehavior.charge_end(enemy.global_position, _aim, CHARGE_LENGTH, enemy.open_ground)
	return enemy.global_position + _aim * CHARGE_LENGTH


static func drop_gavel(enemy: Enemy, at: Vector2, warning: float) -> GavelStrike:
	if enemy.open_ground.is_valid() and not enemy.open_ground.call(at):
		return null
	var strike := GavelStrike.new()
	strike.setup(enemy, GAVEL_RADIUS, warning, 0.0, 0.0, GAVEL_DAMAGE)
	enemy.get_parent().add_child(strike)
	strike.global_position = at
	return strike


# How long a whole chart takes, from the first bar's warning to the last bar sinking.
static func projection_time(bar_count: int) -> float:
	return maxi(bar_count - 1, 0) * BAR_STAGGER + BAR_WARNING + BAR_STAND + LaneDrop.SHOW_TIME


func _raise_projections(enemy: Enemy) -> void:
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var bars := projection_bars(room, _rng.randf() * (BAR_WIDTH + BAR_GAP))
	var left_first := _rng.randf() < 0.5
	_bar_count = bars.size()
	for i in bars.size():
		var order := i if left_first else bars.size() - 1 - i
		var drop := LaneDrop.new()
		drop.setup(enemy, bars[i], BAR_WARNING, order * BAR_STAGGER, BAR_STAND, -1, LaneDrop.LOOK_BAR)
		enemy.get_parent().add_child(drop)
	var spot := safe_gap_point(projection_gaps(room, bars), enemy.target_ground(), enemy.body_rect())
	if spot != Vector2.INF:
		var mark := GapMark.new()
		mark.setup(projection_time(bars.size()))
		enemy.get_parent().add_child(mark)
		mark.global_position = spot


func _spread_tape(enemy: Enemy) -> void:
	var grid := enemy.walk_grid
	var is_open := Callable()
	if grid != null:
		is_open = func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))
	var cells := tape_cells(enemy.room_cells, WalkGrid.cell_of(enemy.target_ground()), is_open)
	if cells.is_empty():
		return
	var spread := TapeSpread.new()
	spread.setup(cells, true, TapeSpread.WARNING, TapeSpread.LAST, enemy)
	enemy.get_parent().add_child(spread)
