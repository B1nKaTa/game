class_name ProjectionistBehavior
extends EnemyBehavior

# The Projectionist, the Cinema's floor boss in the Mall Santa's old slot. His reel change cuts the
# screen to black with a chime and a flash, then laces up a new reel that sets the room's hazard for
# eight seconds: a rain reel wets the whole floor, a silent comedy throws custard pies down warned
# lanes, a western rolls tumbleweeds along warned rows, and never the same reel twice running. His lens
# beam is the one attack that costs three pills: the projector's light thrown from where he stands,
# sweeping through a 100 degree arc like a searchlight, the whole arc tinted and the line it starts on
# outlined twice for its whole 1.2 s windup. His splice marks two or three lanes across the room with
# film, which snaps shut on them after a warning. Below half health the film catches fire: a burn ring
# grows slowly from the screen (BurnRing), and his reel changes and splices come faster.
#
# His attacks overlap the reel's lanes, each other's tails and the burn, so every beam, splice and
# thrown lane is planned with OverlapRoute over everything already under way: he picks the first that
# leaves Grandpa a way out, marks a spot that stays safe (SafeSpotMark), and waits when none does.
const BEAM_WINDUP := 1.2
const BEAM_DAMAGE := Enemy.HEAVIEST_DAMAGE
# The beam's warning shows for all of its windup, whatever the player's warning stat.
const BEAM_SHOWN_WHOLE := true
# The arcs he tries, as turns of their middle away from Grandpa, in degrees.
const BEAM_SHIFTS: Array[float] = [0.0, 30.0, -30.0, 60.0, -60.0, 95.0, -95.0]
const SPLICE_WINDUP := 0.5
const SPLICE_WARNING := 1.0
const PHASE_TWO_SPLICE_WARNING := 0.85
# How far apart the middles of neighbouring splice lanes lie, and how far a pattern may be moved off him.
const SPLICE_PITCH := 96.0
const SPLICE_SHIFTS: Array[float] = [0.0, 0.5, -0.5, 1.0, -1.0, 1.5, -1.5]
const REEL_WINDUP := 0.7
const FIRST_REEL := 3.0
const REEL_EVERY := 14.0
const PHASE_TWO_REEL_EVERY := 10.0
const PIE_EVERY := 1.0
const TUMBLEWEED_EVERY := 1.3
# Below half health the reel's lanes come this much sooner.
const PHASE_TWO_LANE_PACE := 0.8
const FIRST_LANE := 0.4
# How many lanes off his own row or column a thrown lane may lie, and how many it tries.
const LANE_REACH := 3
const LANE_TRIES := 7
const WARNING_RADIUS := 40.0
# The Mall Santa's rests: as short as Mortimer's, shorter than Old Smokey's and Matron Mercy's.
const BASE_COOLDOWN := 0.65
const PHASE_TWO_COOLDOWN := 0.45
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const KEEP_NEAR := 110.0
# When nothing he would start leaves a way out, he waits this long and tries again.
const RETRY := 0.25
const SAY_TIME := 1.0

enum Attack { NONE, BEAM, SPLICE, REEL }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.2
var _since_reel := REEL_EVERY - FIRST_REEL
var _last_reel := -1
var _reel_kind := 0
var _reel: ReelChange
var _lane_timer := 0.0
var _beam_left := 0.0
var _phase_two_seen := false
var _burn: BurnRing
var _mark: SafeSpotMark
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


# The second phase quickens his windups, but never the beam's extra-clear warning.
static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := SPLICE_WINDUP
	match attack:
		Attack.BEAM:
			return BEAM_WINDUP
		Attack.REEL:
			windup = REEL_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


static func splice_warning(phase_two: bool) -> float:
	return PHASE_TWO_SPLICE_WARNING if phase_two else SPLICE_WARNING


# Two or three lanes as rolled, and always three in the second phase.
static func splice_count(phase_two: bool, roll: float) -> int:
	if phase_two:
		return 3
	return 2 if roll < 0.5 else 3


static func reel_every(phase_two: bool) -> float:
	return PHASE_TWO_REEL_EVERY if phase_two else REEL_EVERY


static func lane_every(kind: int, phase_two: bool) -> float:
	var every := TUMBLEWEED_EVERY if kind == ReelChange.Genre.WESTERN else PIE_EVERY
	return every * (PHASE_TWO_LANE_PACE if phase_two else 1.0)


# A reel change when one is due, and never two running; otherwise the beam and the splice, never the
# same twice in a row.
static func choose_attack(last: int, reel_due: bool, roll: float) -> int:
	if reel_due and last != Attack.REEL:
		return Attack.REEL
	var options: Array[int] = [Attack.BEAM, Attack.SPLICE]
	options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# The splice's lanes: count strips across the whole room, rows when across_rows, columns otherwise,
# their middles SPLICE_PITCH apart round center and moved to lie inside the room.
static func splice_lanes(room: Rect2, across_rows: bool, center: Vector2, count: int) -> Array[Rect2]:
	var lanes: Array[Rect2] = []
	var band := SPLICE_PITCH * (count - 1) + SpliceLane.WIDTH
	var low := room.position.y if across_rows else room.position.x
	var high := room.end.y if across_rows else room.end.x
	var middle := center.y if across_rows else center.x
	var first := clampf(middle - band / 2.0, low, maxf(high - band, low)) + SpliceLane.WIDTH / 2.0
	for i in count:
		var at := first + i * SPLICE_PITCH
		if across_rows:
			lanes.append(Rect2(room.position.x, at - SpliceLane.WIDTH / 2.0, room.size.x, SpliceLane.WIDTH))
		else:
			lanes.append(Rect2(at - SpliceLane.WIDTH / 2.0, room.position.y, SpliceLane.WIDTH, room.size.y))
	return lanes


# Everything under way, as OverlapRoute shapes: {"rects": [[Rect2, Vector2]], "circles": [[Vector3,
# Vector2]]}, from every node that answers route_rects or route_circles.
static func live_shapes(nodes: Array) -> Dictionary:
	var shapes := {"rects": [], "circles": []}
	for node in nodes:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if node.has_method("route_rects"):
			shapes["rects"].append_array(node.route_rects())
		if node.has_method("route_circles"):
			shapes["circles"].append_array(node.route_circles())
	return shapes


# A route over the room with these shapes, his body in the way and closed cells; it shares the floor
# worked out by floor_route when one is given.
static func route_with(room: Rect2, shapes: Dictionary, body: Rect2, is_open: Callable, floor_route: OverlapRoute = null) -> OverlapRoute:
	var route := OverlapRoute.new(room)
	for shape: Array in shapes.get("rects", []):
		var window: Vector2 = shape[1]
		if window.y >= 0.0:
			route.add_rect(shape[0], window.x, window.y)
	for shape: Array in shapes.get("circles", []):
		var circle: Vector3 = shape[0]
		var window: Vector2 = shape[1]
		if window.y >= 0.0:
			route.add_circle(Vector2(circle.x, circle.y), circle.z, window.x, window.y)
	if body.has_area():
		route.add_block(body)
	route.set_open(is_open)
	if floor_route != null:
		route.share_floor(floor_route)
	return route


static func _with(base: Dictionary, rects: Array, circles: Array) -> Dictionary:
	var shapes := {"rects": base.get("rects", []).duplicate(), "circles": base.get("circles", []).duplicate()}
	shapes["rects"].append_array(rects)
	shapes["circles"].append_array(circles)
	return shapes


# The lens beam to throw from origin: its arc's middle on Grandpa first, then turned ever further off
# him, each way round, until one leaves him a way out over everything under way. Returns {start, turn,
# mark}, with start INF when none does.
static func beam_plan(room: Rect2, origin: Vector2, feet: Vector2, base: Dictionary, body := Rect2(), is_open := Callable(), clockwise_first := true) -> Dictionary:
	var keep_off := HeadOfDeparturesBehavior.keep_off_body(body)
	var aim := (feet - origin).angle()
	var arc := deg_to_rad(LensBeam.ARC_DEG)
	var floor_route: OverlapRoute = null
	for shift: float in BEAM_SHIFTS:
		for clockwise: bool in [clockwise_first, not clockwise_first]:
			var turn := arc if clockwise else -arc
			var start := aim + deg_to_rad(shift) - turn / 2.0
			var shapes := _with(base, [], LensBeam.plan_circles(origin, start, turn, BEAM_WINDUP))
			var route := route_with(room, shapes, body, is_open, floor_route)
			if floor_route == null:
				floor_route = route
			var out := route.escape(feet, keep_off)
			if out["safe"]:
				var mark: Vector2 = out["pure"] if out["pure"] != Vector2.INF else out["haven"]
				return {"start": start, "turn": turn, "mark": mark}
	return {"start": INF, "turn": 0.0, "mark": Vector2.INF}


# The splice to mark: rows or columns as preferred first, round his feet first, then moved off him half
# a pitch at a time, until one leaves him a way out over everything under way. Returns {lanes, mark},
# lanes empty when none does.
static func splice_plan(room: Rect2, feet: Vector2, count: int, warning: float, across_rows_first: bool, base: Dictionary, body := Rect2(), is_open := Callable()) -> Dictionary:
	var keep_off := HeadOfDeparturesBehavior.keep_off_body(body)
	var floor_route: OverlapRoute = null
	for across_rows: bool in [across_rows_first, not across_rows_first]:
		var axis := Vector2(0, 1) if across_rows else Vector2(1, 0)
		for shift: float in SPLICE_SHIFTS:
			var lanes := splice_lanes(room, across_rows, feet + axis * shift * SPLICE_PITCH, count)
			var rects: Array = []
			for lane in lanes:
				rects.append([lane, Vector2(warning, warning + SpliceLane.SNAP_TIME)])
			var route := route_with(room, _with(base, rects, []), body, is_open, floor_route)
			if floor_route == null:
				floor_route = route
			var out := route.escape(feet, keep_off)
			if out["safe"]:
				var mark: Vector2 = out["pure"] if out["pure"] != Vector2.INF else out["haven"]
				return {"lanes": lanes, "mark": mark}
	var none: Array[Rect2] = []
	return {"lanes": none, "mark": Vector2.INF}


# Where a thrown lane runs: {origin, direction, length}, across the room along a row (or a column, for
# a pie that may fly either way), on Grandpa's own line or a few lanes off it, the first that leaves him
# a way out over everything under way. Empty when none does.
static func lane_plan(room: Rect2, feet: Vector2, look: String, base: Dictionary, rng: RandomNumberGenerator, body := Rect2(), is_open := Callable()) -> Dictionary:
	var floor_route: OverlapRoute = null
	var keep_off := HeadOfDeparturesBehavior.keep_off_body(body)
	var offsets: Array[int] = [0]
	for k in range(1, LANE_REACH + 1):
		offsets.append(k)
		offsets.append(-k)
	# Not always on him: a lane on his own line comes first only half the time.
	if rng.randf() < 0.5:
		offsets.shuffle()
	var tries := 0
	for offset in offsets:
		if tries >= LANE_TRIES:
			break
		tries += 1
		var along_row := look == ReelLane.LOOK_TUMBLEWEED or rng.randf() < 0.5
		var forward := rng.randf() < 0.5
		var direction := (Vector2.RIGHT if forward else Vector2.LEFT) if along_row else (Vector2.DOWN if forward else Vector2.UP)
		var line := lane_line(room, feet, along_row, offset)
		var length := room.size.x if along_row else room.size.y
		var origin := line - direction * length / 2.0
		var rects := ReelLane.plan_rects(origin, direction, length, ReelLane.WIDTH, ReelLane.WARNING, ReelLane.speed_of(look))
		var route := route_with(room, _with(base, rects, []), body, is_open, floor_route)
		if floor_route == null:
			floor_route = route
		if route.escape(feet, keep_off)["safe"]:
			return {"origin": origin, "direction": direction, "length": length}
	return {}


# The middle of a lane offset lanes off Grandpa's own row (or column), kept inside the room.
static func lane_line(room: Rect2, feet: Vector2, along_row: bool, offset: int) -> Vector2:
	var step := ReelLane.WIDTH * 1.5
	var half := ReelLane.WIDTH / 2.0
	if along_row:
		return Vector2(room.get_center().x, clampf(feet.y + offset * step, room.position.y + half, room.end.y - half))
	return Vector2(clampf(feet.x + offset * step, room.position.x + half, room.end.x - half), room.get_center().y)


# Where the film starts burning: at the foot of the screen, or the middle of the north wall's foot.
static func burn_center(room: Rect2, picture := Rect2()) -> Vector2:
	if picture.has_area():
		return Vector2(picture.get_center().x, picture.end.y + 4.0)
	return Vector2(room.get_center().x, room.position.y)


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	if phase_two and not _phase_two_seen:
		_enter_phase_two(enemy)
	_since_reel += delta
	_beam_left = maxf(_beam_left - delta, 0.0)
	_run_reel(enemy, delta, phase_two)
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	# He holds still while his beam sweeps, so it turns about where he stands.
	if _beam_left > 0.0:
		return
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	if _cooldown <= 0.0:
		var reel_due := _since_reel >= reel_every(phase_two) and not _reel_running()
		_begin(enemy, choose_attack(_last, reel_due, _rng.randf()), phase_two)
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _reel_running() -> bool:
	return is_instance_valid(_reel) and _reel.is_running()


func _enter_phase_two(enemy: Enemy) -> void:
	_phase_two_seen = true
	enemy.say("The film's caught fire!", SAY_TIME * 1.5)
	if not enemy.is_inside_tree():
		return
	var room := _room(enemy)
	var screen := _screen(enemy)
	_burn = BurnRing.new()
	_burn.setup(enemy, BurnRing.cap_for(room.size.y))
	enemy.get_parent().add_child(_burn)
	_burn.global_position = burn_center(room, screen.picture_rect() if screen != null else Rect2())


# While a comedy or a western runs, he throws its pies or tumbleweeds in, one lane at a time.
func _run_reel(enemy: Enemy, delta: float, phase_two: bool) -> void:
	if not _reel_running() or _reel.genre == ReelChange.Genre.RAIN:
		return
	_lane_timer -= delta
	if _lane_timer > 0.0:
		return
	_lane_timer = lane_every(_reel.genre, phase_two)
	var look := ReelLane.LOOK_TUMBLEWEED if _reel.genre == ReelChange.Genre.WESTERN else ReelLane.LOOK_PIE
	var plan := lane_plan(_room(enemy), enemy.target_ground(), look, _live(enemy), _rng, enemy.body_rect(), _open_cells(enemy))
	if plan.is_empty():
		_lane_timer = RETRY
		return
	var lane := ReelLane.new()
	lane.setup(enemy, plan["direction"], plan["length"], look)
	enemy.get_parent().add_child(lane)
	lane.global_position = plan["origin"]


func _room(enemy: Enemy) -> Rect2:
	return ForemanBehavior.room_rect(enemy.room_cells)


func _live(enemy: Enemy) -> Dictionary:
	if not enemy.is_inside_tree():
		return {"rects": [], "circles": []}
	return live_shapes(enemy.get_parent().get_children())


func _open_cells(enemy: Enemy) -> Callable:
	var grid := enemy.walk_grid
	if grid == null:
		return Callable()
	return func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))


func _screen(enemy: Enemy) -> CinemaScreen:
	return CinemaScreen.in_room(enemy.get_parent()) if enemy.is_inside_tree() else null


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	match attack:
		Attack.BEAM:
			if not _start_beam(enemy) and not _start_splice(enemy, phase_two):
				_cooldown = RETRY
				return
			attack = _attack
		Attack.SPLICE:
			if not _start_splice(enemy, phase_two) and not _start_beam(enemy):
				_cooldown = RETRY
				return
			attack = _attack
		Attack.REEL:
			_attack = Attack.REEL
			_reel_kind = ReelChange.next_genre(_last_reel, _rng.randf())
			var screen := _screen(enemy)
			if screen != null:
				screen.cut_to_black(windup_for(Attack.REEL, phase_two) + 0.25)
			Sfx.play("barrier_chime")
			enemy.say("Reel change!", SAY_TIME)
	_telegraph.start(windup_for(attack, phase_two))
	enemy.set_warning(_telegraph, WARNING_RADIUS, attack == Attack.BEAM and BEAM_SHOWN_WHOLE)


func _start_beam(enemy: Enemy) -> bool:
	if not enemy.is_inside_tree():
		return false
	var plan := beam_plan(_room(enemy), enemy.global_position, enemy.target_ground(), _live(enemy), enemy.body_rect(), _open_cells(enemy), _rng.randf() < 0.5)
	if plan["start"] == INF:
		return false
	_attack = Attack.BEAM
	var beam := LensBeam.new()
	beam.setup(enemy, plan["start"], plan["turn"], BEAM_WINDUP, BEAM_DAMAGE)
	enemy.get_parent().add_child(beam)
	beam.global_position = enemy.global_position
	_beam_left = BEAM_WINDUP + LensBeam.SWEEP_TIME
	_place_mark(enemy, plan["mark"], _beam_left)
	enemy.say("Lights, lens, action!", SAY_TIME)
	enemy.play_anim("crank", BEAM_WINDUP)
	return true


func _start_splice(enemy: Enemy, phase_two: bool) -> bool:
	if not enemy.is_inside_tree():
		return false
	var warning := splice_warning(phase_two)
	var plan := splice_plan(_room(enemy), enemy.target_ground(), splice_count(phase_two, _rng.randf()), warning, _rng.randf() < 0.5, _live(enemy), enemy.body_rect(), _open_cells(enemy))
	var lanes: Array = plan["lanes"]
	if lanes.is_empty():
		return false
	_attack = Attack.SPLICE
	for strip: Rect2 in lanes:
		var lane := SpliceLane.new()
		lane.setup(enemy, strip, warning)
		enemy.get_parent().add_child(lane)
		lane.global_position = Vector2.ZERO
	_place_mark(enemy, plan["mark"], warning + 0.2)
	enemy.say("Splice!", SAY_TIME)
	return true


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.BEAM:
			# He may start his next attack over the beam's tail, planned round it.
			busy = LensBeam.SWEEP_TIME * 0.5
		Attack.REEL:
			_lace_reel(enemy)
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack


func _lace_reel(enemy: Enemy) -> void:
	_since_reel = 0.0
	_last_reel = _reel_kind
	var screen := _screen(enemy)
	if screen != null:
		screen.flash(1.0)
	if not enemy.is_inside_tree():
		return
	_reel = ReelChange.new()
	_reel.setup(enemy, _reel_kind, _room(enemy))
	enemy.get_parent().add_child(_reel)
	_reel.global_position = Vector2.ZERO
	_lane_timer = FIRST_LANE
	enemy.say(ReelChange.title(_reel_kind), SAY_TIME)
	if _reel_kind == ReelChange.Genre.RAIN:
		var parent := enemy.get_parent()
		var splash := WetSplash.new()
		var palette: RoomPalette = parent.room_palette() if parent.has_method("room_palette") else null
		splash.setup(SplashJets.wet_room(enemy.room_cells, _open_cells(enemy)), ReelChange.TIME, palette)
		parent.add_child(splash)


func _place_mark(enemy: Enemy, spot: Vector2, seconds: float) -> void:
	if spot == Vector2.INF:
		return
	if not is_instance_valid(_mark):
		_mark = SafeSpotMark.new()
		_mark.setup(seconds)
		enemy.get_parent().add_child(_mark)
	else:
		_mark.setup(maxf(_mark.time_left(), seconds))
	_mark.global_position = spot


# For a look probe: the reel running now, or null, and the burn.
func reel() -> ReelChange:
	return _reel if _reel_running() else null


func burn() -> BurnRing:
	return _burn
