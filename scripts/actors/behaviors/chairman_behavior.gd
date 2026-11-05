class_name ChairmanBehavior
extends EnemyBehavior

# The Chairman of the Board, the last boss of all, and the hardest fight in the game, because his
# attacks overlap. His quarterly projections raise the bars of a bar chart out of the floor in turn,
# down warned columns with open gaps between, and the chart keeps rising and falling in the background
# while he stands at it and brings his gavel down: the one attack that costs three pills, its warning
# always shown whole for its 1.2 s with a second ring. So the safe gap and the gavel's spot must be
# found together. Before each gavel he works out where Grandpa can still walk to in time (OverlapRoute),
# and the gavel never takes the last way out: a green mark shows a spot that stays safe to the end.
# Between charts, his hostile takeover shows a warned tether to Grandpa far away and pulls him a short
# way in, then charges down a fresh warned lane; a dodge before the pull snaps the tether. Up close he
# slams his desk: a warned ring round him, shown whole, that costs a pill and shoves Grandpa out.
# Below half health he is quicker, the charts come closer together, red tape spreads across warned rows
# of the room for ten seconds as a chart starts, and the gavel follows the chart without a rest.
# While a chart runs he may also restructure: rows of filing cabinets slide their drawers out across
# the room in turn, crossing the bars, so the open floor is only where a gap and a row's gap meet, and
# it moves. The rows are laid out with OverlapRoute against the chart as it stands, so a way out is
# always left, and the green mark moves to a spot that stays safe.
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
# How long after one chart has sunk the next one rises, and below half health.
const FIRST_CHART := 1.5
const CHART_BREAK := 1.6
const PHASE_TWO_CHART_BREAK := 1.0
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
# The desk slam, his answer when Grandpa's feet are this close. It starts right beside him, so its
# warning shows whole, and the second phase never shortens it.
const SLAM_START := 80.0
const SLAM_RADIUS := 72.0
const SLAM_WINDUP := 0.8
const SLAM_SHOWN_WHOLE := true
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
# When no spot for the gavel leaves a way out, he waits this long and tries again.
const GAVEL_RETRY := 0.15
# How many ways to lay out a chart are tried before settling for one with no checked spot.
const CHART_TRIES := 8
# Restructuring: rows across the room, as tall as a bar is wide, with gaps as wide as a bar's.
const ROW_HEIGHT := BAR_WIDTH
const ROW_GAP := BAR_GAP
const ROW_WARNING := 0.9
const ROW_STAGGER := 0.4
const ROW_STAND := 0.4
# The rows start this long after he calls them, at one of a few delays.
const ROW_DELAYS: Array[float] = [0.0, 0.25, 0.5]
const ROW_TRIES := 12
# The share of charts he restructures during, before and below half health. Never twice in one chart.
const RESTRUCTURE_SHARE := 0.42
const PHASE_TWO_RESTRUCTURE_SHARE := 0.7
const RESTRUCTURE_WINDUP := 0.35

enum Attack { NONE, GAVEL, PROJECTIONS, TAKEOVER, CHARGE, TAPE, SLAM, RESTRUCTURE }

var _telegraph := Telegraph.new()
var _dash := BossDash.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
# Starts full, so the first spread comes with the first chart of the second phase.
var _since_tape := TAPE_EVERY
var _aim := Vector2.RIGHT
var _tether: TakeoverTether
var _bar_count := 0
# The chart standing now: its bars, how long until the last has sunk, and its green mark.
var _bars: Array = []
var _chart_left := 0.0
var _chart_wait := FIRST_CHART
var _mark: GapMark
# The restructuring's rows standing now, and whether this chart has had them.
var _rows: Array = []
var _restructured := false
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


static func chart_break(phase_two: bool) -> float:
	return PHASE_TWO_CHART_BREAK if phase_two else CHART_BREAK


# The second phase quickens his windups, but never the gavel's extra-clear warning or the slam's.
static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := PROJECTION_WINDUP
	match attack:
		Attack.GAVEL:
			return GAVEL_WINDUP
		Attack.SLAM:
			return SLAM_WINDUP
		Attack.TAKEOVER:
			windup = TETHER_WINDUP
		Attack.CHARGE:
			windup = CHARGE_WINDUP
		Attack.TAPE:
			windup = TAPE_WINDUP
		Attack.RESTRUCTURE:
			return RESTRUCTURE_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# A chart is always followed by the gavel, which falls while its bars run, and so is a restructuring.
static func followup(attack: int, _phase_two: bool) -> int:
	if attack == Attack.PROJECTIONS or attack == Attack.RESTRUCTURE:
		return Attack.GAVEL
	return Attack.NONE


# Whether he restructures in this chart: once at most, for a share of charts (roll in [0, 1)).
static func restructures(phase_two: bool, already: bool, roll: float) -> bool:
	return not already and roll < (PHASE_TWO_RESTRUCTURE_SHARE if phase_two else RESTRUCTURE_SHARE)


# The rows across the room: a chart's bars laid on their side, each the room's whole width. A strip
# by a wall too narrow to stand in is widened into a whole gap, as the bars' are.
static func restructure_rows(room: Rect2, offset: float) -> Array[Rect2]:
	var turned := Rect2(room.position.y, room.position.x, room.size.y, room.size.x)
	var rows: Array[Rect2] = []
	for bar in projection_bars(turned, offset):
		rows.append(Rect2(bar.position.y, bar.position.x, bar.size.y, bar.size.x))
	return rows


# When each row hurts, counted from now: in turn from the top or the bottom, after delay.
static func row_windows(count: int, top_first: bool, delay: float) -> Array[Vector2]:
	var windows: Array[Vector2] = []
	for i in count:
		var order := i if top_first else count - 1 - i
		var rises := delay + order * ROW_STAGGER + ROW_WARNING
		windows.append(Vector2(rises, rises + ROW_STAND))
	return windows


# Rows to lay over the chart as it stands (route), that still leave Grandpa a way to a spot nothing
# will hurt. Each roll is an offset along the room (x), top first (y < 0.5) and a delay (z, a share
# into ROW_DELAYS), tried in turn. {rows, top_first, delay, mark, route}, empty when none works.
static func restructure_plan(route: OverlapRoute, room: Rect2, rolls: Array[Vector3], feet: Vector2, body := Rect2()) -> Dictionary:
	for roll in rolls:
		var rows := restructure_rows(room, roll.x)
		if rows.is_empty():
			continue
		var top_first := roll.y < 0.5
		var delay: float = ROW_DELAYS[mini(int(roll.z * ROW_DELAYS.size()), ROW_DELAYS.size() - 1)]
		var windows := row_windows(rows.size(), top_first, delay)
		var trial := route.with_rects(rows, windows)
		var out := trial.escape(feet, keep_off_body(body))
		if out["safe"] and out["pure"] != Vector2.INF:
			return {"rows": rows, "top_first": top_first, "delay": delay, "mark": out["pure"], "route": trial}
	return {}


# How long a restructuring lasts from its call to its last row sinking.
static func restructure_time(row_count: int, delay: float) -> float:
	return delay + maxi(row_count - 1, 0) * ROW_STAGGER + ROW_WARNING + ROW_STAND + LaneDrop.SHOW_TIME


# In the second phase the gavel follows the chart without a rest.
static func rest_after_chart(phase_two: bool) -> float:
	return 0.0 if phase_two else BASE_COOLDOWN


# While a chart runs he only gavels (a restructuring is chosen apart, in tick). Between charts the gavel takes turns with the desk slam when
# Grandpa's feet are close, and with the takeover when they are far.
static func choose_attack(last: int, distance: float, charting: bool, roll: float) -> int:
	if charting:
		return Attack.GAVEL
	var options: Array[int] = [Attack.GAVEL]
	if distance <= SLAM_START:
		options.append(Attack.SLAM)
	elif distance >= TAKEOVER_START:
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
# offset slides the chart along, so the gaps are somewhere new each time. A strip left by a wall too
# narrow to stand in is widened into a whole gap, by trimming the bar beside it, so every gap can be
# stood in and every bar has a gap at its side.
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
	if not bars.is_empty():
		var first := bars[0]
		var edge := first.position.x - room.position.x
		if edge > 0.01 and edge < BAR_GAP:
			var trimmed := first.end.x - (room.position.x + BAR_GAP)
			if trimmed >= BAR_MIN:
				bars[0] = Rect2(room.position.x + BAR_GAP, first.position.y, trimmed, first.size.y)
			else:
				bars.remove_at(0)
	if not bars.is_empty():
		var last := bars[bars.size() - 1]
		var edge_end := room.end.x - last.end.x
		if edge_end > 0.01 and edge_end < BAR_GAP:
			var kept := (room.end.x - BAR_GAP) - last.position.x
			if kept >= BAR_MIN:
				bars[bars.size() - 1] = Rect2(last.position.x, last.position.y, kept, last.size.y)
			else:
				bars.remove_at(bars.size() - 1)
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


# The middle of the gap nearest his feet, at his height, kept off the Chairman's own body. Only a gap
# wide enough to stand in counts. Used when nothing else is known about the room.
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


# When each bar of a chart hurts, counted from elapsed seconds after it was raised: x when it rises
# and y when it sinks. Bars rise in turn from the left, or from the right.
static func bar_windows(count: int, left_first: bool, elapsed := 0.0) -> Array[Vector2]:
	var windows: Array[Vector2] = []
	for i in count:
		var order := i if left_first else count - 1 - i
		var rises := order * BAR_STAGGER + BAR_WARNING - elapsed
		windows.append(Vector2(rises, rises + BAR_STAND))
	return windows


# The floor of a chart for working out a way out: each bar hurting in its window (one that is over
# has a negative end), his body in the way, closed cells, and red tape by the time it is strung.
static func chart_route(room: Rect2, bars: Array[Rect2], windows: Array[Vector2], body := Rect2(), is_open := Callable(), tape := {}) -> OverlapRoute:
	var route := OverlapRoute.new(room)
	for i in bars.size():
		if windows[i].y >= 0.0:
			route.add_rect(bars[i], windows[i].x, windows[i].y)
	if body.has_area():
		route.add_block(body)
	route.set_open(is_open)
	for cell in tape:
		route.add_sticky(cell, tape[cell])
	return route


# A mark may not go on his body or just beside it.
static func keep_off_body(body: Rect2) -> Callable:
	var avoid := body.grow(SafeSpotMark.RADIUS)
	return func(spot: Vector2) -> bool: return avoid.has_area() and avoid.has_point(spot)


# Where the green mark of a new chart goes: the nearest spot he can reach that no bar ever covers.
# Vector2.INF if there is none, which the tests rule out.
static func chart_mark(route: OverlapRoute, feet: Vector2, body := Rect2()) -> Vector2:
	var out := route.escape(feet, keep_off_body(body))
	return out["pure"] if out["safe"] else Vector2.INF


# Bars for a new chart that leave him a spot to reach. Each roll is an offset along the room (x) and
# whether the bars rise from the left (y < 0.5), tried in turn; the first chart with a reachable mark
# wins. Tape spread with the chart can box him in under the first bar, so one roll is not enough.
# {bars, left_first, mark, route}; mark is Vector2.INF only when no roll works, and the last is kept.
static func choose_chart(room: Rect2, rolls: Array[Vector2], feet: Vector2, body := Rect2(), is_open := Callable(), tape := {}) -> Dictionary:
	var choice := {}
	var floor_route: OverlapRoute = null
	for roll in rolls:
		var bars := projection_bars(room, roll.x)
		var left_first := roll.y < 0.5
		var route := chart_route(room, bars, bar_windows(bars.size(), left_first), body, is_open, tape)
		if floor_route == null:
			floor_route = route
		else:
			route.share_floor(floor_route)
		choice = {"bars": bars, "left_first": left_first, "mark": chart_mark(route, feet, body), "route": route}
		if choice["mark"] != Vector2.INF:
			return choice
	return choice


# Where the gavel falls while a chart runs, and where the mark moves: on his feet when that still
# leaves him a way to a spot nothing will hurt, otherwise a little off. {spot, mark}, both INF when
# no spot works, and then he holds the gavel back.
static func gavel_plan(route: OverlapRoute, feet: Vector2, body := Rect2(), open_at := Callable()) -> Dictionary:
	return route.strike_plan(feet, GAVEL_RADIUS, GAVEL_WINDUP, open_at, keep_off_body(body))


# A mark that lies in a gap sits in its middle, where it reads best, when the middle is as safe.
static func centered_in_gap(route: OverlapRoute, spot: Vector2, gaps: Array[Rect2], strike := Vector2.INF) -> Vector2:
	for gap in gaps:
		if spot.x < gap.position.x or spot.x >= gap.end.x:
			continue
		var middle := Vector2(gap.get_center().x, spot.y)
		if route.danger_end_at(middle) > 0.0 or route.is_blocked_at(middle):
			return spot
		if strike != Vector2.INF and middle.distance_to(strike) <= GAVEL_RADIUS + OverlapRoute.MARGIN:
			return spot
		return middle
	return spot


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
	_chart_left = maxf(_chart_left - delta, 0.0)
	if _chart_left <= 0.0:
		_chart_wait -= delta
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
		# Right after a chart rises he may restructure first; the gavel follows the rows.
		if chained == Attack.GAVEL and _last == Attack.PROJECTIONS and _charting() and restructures(phase_two, _restructured, _rng.randf()):
			_restructured = true
			chained = Attack.RESTRUCTURE
		_begin(enemy, chained, phase_two)
		return
	if _cooldown <= 0.0:
		if not _charting() and _chart_wait <= 0.0:
			_begin(enemy, Attack.PROJECTIONS, phase_two)
		else:
			_begin(enemy, choose_attack(_last, _feet_distance(enemy), _charting(), _rng.randf()), phase_two)
		return
	# He stands at his chart while it runs, so its mark is never under him.
	if not _charting() and enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _charting() -> bool:
	return _chart_left > 0.0


func _feet_distance(enemy: Enemy) -> float:
	return enemy.global_position.distance_to(enemy.target_ground())


func _target_dodging(enemy: Enemy) -> bool:
	return is_instance_valid(enemy.target) and enemy.target.has_method("is_dodging") and enemy.target.is_dodging()


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	var gavel_at := enemy.target_ground()
	if attack == Attack.GAVEL and _charting():
		var plan := gavel_plan(_live_route(enemy), enemy.target_ground(), enemy.body_rect(), enemy.open_ground)
		if plan["spot"] == Vector2.INF:
			# No spot leaves him a way out while the bars run, so the gavel waits.
			_cooldown = GAVEL_RETRY
			return
		gavel_at = plan["spot"]
		_move_mark(enemy, plan["mark"], plan["spot"])
	if attack == Attack.RESTRUCTURE and not _lay_rows(enemy):
		# No rows leave a way out over this chart, so he gavels instead.
		attack = Attack.GAVEL
		var plan := gavel_plan(_live_route(enemy), enemy.target_ground(), enemy.body_rect(), enemy.open_ground)
		if plan["spot"] == Vector2.INF:
			_cooldown = GAVEL_RETRY
			return
		gavel_at = plan["spot"]
		_move_mark(enemy, plan["mark"], plan["spot"])
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.RESTRUCTURE:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Restructuring!", SAY_TIME)
		Attack.GAVEL:
			enemy.set_warning(_telegraph, WARNING_RADIUS, GAVEL_SHOWN_WHOLE)
			enemy.say("Order! Order!", SAY_TIME)
			drop_gavel(enemy, gavel_at, GAVEL_WINDUP)
		Attack.PROJECTIONS:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Quarterly projections!", SAY_TIME)
			# Below half health the tape goes up as the chart does.
			if spreads_tape(phase_two, _since_tape):
				_since_tape = 0.0
				_spread_tape(enemy)
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
		Attack.SLAM:
			enemy.set_warning(_telegraph, WARNING_RADIUS, SLAM_SHOWN_WHOLE)
			enemy.say("Meeting adjourned!", SAY_TIME)
			var slam := DeskSlam.new()
			slam.setup(enemy, SLAM_RADIUS, SLAM_WINDUP)
			enemy.get_parent().add_child(slam)
			slam.global_position = enemy.global_position
		Attack.TAPE:
			_since_tape = 0.0
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Let's add some process.", SAY_TIME)
			_spread_tape(enemy)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	match _attack:
		Attack.RESTRUCTURE:
			# The rows are already warning; the gavel follows as it does a chart.
			_last = Attack.RESTRUCTURE
			_next = followup(Attack.RESTRUCTURE, phase_two)
			_cooldown = rest_after_chart(phase_two)
			_attack = Attack.NONE
			return
		Attack.PROJECTIONS:
			_raise_projections(enemy)
			_chart_wait = chart_break(phase_two)
			_cooldown = rest_after_chart(phase_two)
			_last = Attack.PROJECTIONS
			_next = followup(Attack.PROJECTIONS, phase_two)
			return
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
	_cooldown = cooldown_for(phase_two)
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


func _open_cells(enemy: Enemy) -> Callable:
	var grid := enemy.walk_grid
	if grid == null:
		return Callable()
	return func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))


# Every cell of red tape in the room, by when it is strung: now for strung tape, after its warning for
# a spread still warning, after the cut heals for tape a dodge has cut.
func _tape_now(enemy: Enemy) -> Dictionary:
	var tape := {}
	if not enemy.is_inside_tree():
		return tape
	for node in enemy.get_tree().get_nodes_in_group(RedTape.GROUP):
		if not is_instance_valid(node):
			continue
		var from := 0.0
		var spread = node.get_parent()
		if spread is TapeSpread and not spread.is_strung():
			from = spread.warning_left()
		elif node.is_cut():
			from = node._cut_left
		tape[WalkGrid.cell_of(node.global_position)] = from
	return tape


# The chart as it stands this moment, with each bar's and row's own time left.
func _live_route(enemy: Enemy) -> OverlapRoute:
	var bars: Array[Rect2] = []
	var windows: Array[Vector2] = []
	for drop in _bars + _rows:
		if is_instance_valid(drop):
			bars.append(drop.strip())
			windows.append(drop.danger_window())
	return chart_route(ForemanBehavior.room_rect(enemy.room_cells), bars, windows, enemy.body_rect(), _open_cells(enemy), _tape_now(enemy))


func _move_mark(enemy: Enemy, spot: Vector2, strike: Vector2) -> void:
	if spot == Vector2.INF:
		return
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var gaps := projection_gaps(room, _bar_rects())
	var at := centered_in_gap(_live_route(enemy), spot, gaps, strike)
	var lasts := maxf(_chart_left, GAVEL_WINDUP + 0.3)
	if not is_instance_valid(_mark):
		_mark = GapMark.new()
		_mark.setup(lasts)
		enemy.get_parent().add_child(_mark)
	else:
		_mark.setup(maxf(_mark.time_left(), lasts))
	_mark.global_position = at


func _bar_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for drop in _bars:
		if is_instance_valid(drop):
			rects.append(drop.strip())
	return rects


# Lays the restructuring's rows over the chart as it stands, if any layout leaves a way out, moves the
# mark, and keeps the chart running until the last row sinks. False when nothing works.
func _lay_rows(enemy: Enemy) -> bool:
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var rolls: Array[Vector3] = []
	for i in ROW_TRIES:
		rolls.append(Vector3(_rng.randf() * (ROW_HEIGHT + ROW_GAP), _rng.randf(), _rng.randf()))
	var plan := restructure_plan(_live_route(enemy), room, rolls, enemy.target_ground(), enemy.body_rect())
	if plan.is_empty():
		return false
	var rows: Array[Rect2] = plan["rows"]
	var top_first: bool = plan["top_first"]
	var delay: float = plan["delay"]
	_rows.clear()
	for i in rows.size():
		var order := i if top_first else rows.size() - 1 - i
		var drop := LaneDrop.new()
		drop.setup(enemy, rows[i], ROW_WARNING, delay + order * ROW_STAGGER, ROW_STAND, -1, LaneDrop.LOOK_DRAWERS)
		enemy.get_parent().add_child(drop)
		_rows.append(drop)
	_chart_left = maxf(_chart_left, restructure_time(rows.size(), delay))
	_move_mark(enemy, plan["mark"], Vector2.INF)
	return true


func _raise_projections(enemy: Enemy) -> void:
	_restructured = false
	_rows.clear()
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var rolls: Array[Vector2] = []
	for i in CHART_TRIES:
		rolls.append(Vector2(_rng.randf() * (BAR_WIDTH + BAR_GAP), _rng.randf()))
	var choice := choose_chart(room, rolls, enemy.target_ground(), enemy.body_rect(), _open_cells(enemy), _tape_now(enemy))
	var bars: Array[Rect2] = choice["bars"]
	var left_first: bool = choice["left_first"]
	_bar_count = bars.size()
	_bars.clear()
	for i in bars.size():
		var order := i if left_first else bars.size() - 1 - i
		var drop := LaneDrop.new()
		drop.setup(enemy, bars[i], BAR_WARNING, order * BAR_STAGGER, BAR_STAND, -1, LaneDrop.LOOK_BAR)
		enemy.get_parent().add_child(drop)
		_bars.append(drop)
	_chart_left = projection_time(bars.size())
	var route: OverlapRoute = choice["route"]
	var spot: Vector2 = choice["mark"]
	if spot == Vector2.INF:
		spot = safe_gap_point(projection_gaps(room, bars), enemy.target_ground(), enemy.body_rect())
	else:
		spot = centered_in_gap(route, spot, projection_gaps(room, bars))
	if spot != Vector2.INF:
		_mark = GapMark.new()
		_mark.setup(_chart_left)
		enemy.get_parent().add_child(_mark)
		_mark.global_position = spot


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
