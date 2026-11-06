class_name MadameZaraBehavior
extends EnemyBehavior

# Madame Zara, the Medium, the Seance Hotline's floor boss in the Club President's old slot. A talking
# board lies on the floor of her room for the whole fight (OuijaBoard).
# - On the Line: she rings him. A marked circle round where his feet stand shows first, with a phone
#   cord from her to it (LineTether); then the line locks and for three seconds he cannot leave the
#   circle while she runs one of her other attacks alongside, planned to leave him a safe spot inside
#   it. When nothing would leave him one, she does not call, or the line goes dead before it locks.
# - The Ouija board, her heaviest attack: the planchette spells a word, sliding from letter to letter
#   along a path shown, outlined twice, for its whole 1.2 s windup; touching it costs three pills.
# - Possession: a ghostly copy of him walks his last two seconds of movement again, there and back, for
#   four seconds, its way shown first; touching it costs a pill.
# - Below half health, the seance circle: the room goes dim but for a wide ring of light drifting slowly
#   through it, and spirits outside the ring swoop at him whenever he stands outside it (SeanceCircle).
#   Her other attacks go on, planned to keep him in the light; she moves quicker and winds up quicker,
#   but never the Ouija board's warning.
# - Every twelve seconds she manifests two Ectoplasm on marked spots, never past five in the room, and
#   they pay nothing.
# Every attack is planned with OverlapRoute over everything already under way (ProjectionistBehavior's
# planning): she picks the first that leaves him a way out, marks a spot that stays safe, and waits a
# moment when none does. She has no hold music; that stays Doreen's.
enum Attack { NONE, LINE, OUIJA, POSSESSION }

const LINE_WINDUP := 0.8
const OUIJA_WINDUP := 1.2
const OUIJA_DAMAGE := Enemy.HEAVIEST_DAMAGE
# The board's warning shows for all of its windup, whatever the player's warning stat.
const OUIJA_SHOWN_WHOLE := true
const POSSESSION_WINDUP := 0.7
const POSSESSION_DAMAGE := PossessionGhost.DAMAGE
# The words the spirits spell. The nearest to him are tried first, a few at most.
const WORDS: Array[String] = [
	"HELLO", "BOO", "GERALD", "HEDGE", "BEWARE", "SOON", "COLD", "LISTEN", "HOLD", "CALL", "RING",
	"WAKE", "JINX", "SPIRIT", "MOVE", "QUIET", "WHO", "FOG",
]
const OUIJA_TRIES := 8
# A word that would take longer than this to spell is left out.
const OUIJA_LONGEST := 4.0
# How many of the nearest words she may start from, so the same spot does not always spell the same.
const OUIJA_START_PICK := 3
# How far apart in time the copy's steps are kept.
const TRAIL_STEP := 0.05
# Her rests: the Club President's slot, as short as the Commodore's, shorter than the Projectionist's.
const BASE_COOLDOWN := 0.6
const PHASE_TWO_COOLDOWN := 0.42
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const KEEP_NEAR := 110.0
const WARNING_RADIUS := 40.0
# When nothing she would start leaves a way out, she waits this long and tries again.
const RETRY := 0.25
const SAY_TIME := 1.0
# How far ahead a plan in the seance circle allows for the light drifting meanwhile.
const LIGHT_HORIZON := 3.0
const MAX_ENEMIES := 5
const ECTOPLASM_COUNT := 2
const ECTOPLASM_EVERY := 12.0
const FIRST_ECTOPLASM := 5.0
const SUMMON_DISTANCE := 100.0
const SUMMON_SPREAD := 0.9

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _main := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.2
var _still_left := 0.0
var _clock := 0.0
var _trail := FeetTrail.new()
var _summon_timer := FIRST_ECTOPLASM
var _phase_two_seen := false
var _alongside_ouija_first := true
var _tether: LineTether
var _planchette: OuijaPlanchette
var _ghost: PossessionGhost
var _board: OuijaBoard
var _circle: SeanceCircle
var _mark: SafeSpotMark
# The last anim she played, for tests and a look probe.
var last_anim := ""
# A look probe's pick for her next attack, used once; NONE lets her choose.
var forced_attack := Attack.NONE
# A look probe's switch into her second phase whatever her health.
var forced_phase_two := false
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


# The second phase quickens her windups, but never the board's extra-clear warning.
static func windup_for(attack: int, phase_two: bool) -> float:
	if attack == Attack.OUIJA:
		return OUIJA_WINDUP
	var windup := POSSESSION_WINDUP if attack == Attack.POSSESSION else LINE_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# Never the same twice running; a possession only once she has his last two seconds, and no call while
# a line still holds.
static func choose_attack(last: int, roll: float, can_possess := true, line_busy := false) -> int:
	var options: Array[int] = [Attack.LINE, Attack.OUIJA, Attack.POSSESSION]
	options.erase(last)
	if not can_possess:
		options.erase(Attack.POSSESSION)
	if line_busy:
		options.erase(Attack.LINE)
	if options.is_empty():
		options.append(Attack.OUIJA)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# How many Ectoplasm come: two, but never past the room's cap.
static func ectoplasm_count(alive: int) -> int:
	return clampi(MAX_ENEMIES - alive, 0, ECTOPLASM_COUNT)


# --- the plans ---

# The words in the order she tries them: nearest to his feet first. Returns [[word, path]].
static func words_by_nearness(room: Rect2, feet: Vector2) -> Array:
	var scored: Array = []
	for word in WORDS:
		var path := OuijaBoard.word_path(word, room)
		if OuijaPlanchette.slide_time(path) > OUIJA_LONGEST:
			continue
		scored.append([OuijaPlanchette.distance_to_path(path, feet), word, path])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var ordered: Array = []
	for entry: Array in scored:
		ordered.append([entry[1], entry[2]])
	return ordered


# The word to spell: of the words nearest his feet, from the one start picks, the first whose slide
# leaves him a way out over everything under way and a spot nothing ever covers, or failing that the
# first that leaves him a way out at all. Returns {word, path, mark}; path empty when none does.
static func ouija_plan(room: Rect2, feet: Vector2, base: Dictionary, body := Rect2(), is_open := Callable(), start := 0) -> Dictionary:
	var keep_off := ProjectionistBehavior.keep_off_body(body)
	var ordered := words_by_nearness(room, feet)
	var floor_route: OverlapRoute = null
	var first := clampi(start, 0, maxi(ordered.size() - 1, 0))
	var fallback := {}
	for k in mini(OUIJA_TRIES, ordered.size()):
		var entry: Array = ordered[(first + k) % ordered.size()]
		var path: Array[Vector2] = entry[1]
		var shapes := ProjectionistBehavior._with(base, [], OuijaPlanchette.plan_circles(path, OUIJA_WINDUP))
		var route := ProjectionistBehavior.route_with(room, shapes, body, is_open, floor_route)
		if floor_route == null:
			floor_route = route
		var out := route.escape(feet, keep_off)
		if not out["safe"]:
			continue
		var plan := {"word": entry[0], "path": path, "mark": mark_of(out, keep_off)}
		if out["pure"] != Vector2.INF:
			return plan
		if fallback.is_empty():
			fallback = plan
	if not fallback.is_empty():
		return fallback
	var none: Array[Vector2] = []
	return {"word": "", "path": none, "mark": Vector2.INF}


# Whether the copy walking his trail after a windup leaves him a way out. Returns {safe, mark}.
static func possession_plan(room: Rect2, trail: PackedVector2Array, step: float, windup: float, feet: Vector2, base: Dictionary, body := Rect2(), is_open := Callable()) -> Dictionary:
	var keep_off := ProjectionistBehavior.keep_off_body(body)
	var shapes := ProjectionistBehavior._with(base, [], PossessionGhost.plan_circles(trail, step, windup))
	var out := ProjectionistBehavior.route_with(room, shapes, body, is_open).escape(feet, keep_off)
	return {"safe": out["safe"], "mark": mark_of(out, keep_off) if out["safe"] else Vector2.INF}


# Whether what is under way leaves him a way out without leaving the floor is_open allows (the circle,
# for a call). Returns {safe, mark}.
static func hold_plan(room: Rect2, feet: Vector2, base: Dictionary, body := Rect2(), is_open := Callable()) -> Dictionary:
	var keep_off := ProjectionistBehavior.keep_off_body(body)
	var out := ProjectionistBehavior.route_with(room, base, body, is_open).escape(feet, keep_off)
	return {"safe": out["safe"], "mark": mark_of(out, keep_off) if out["safe"] else Vector2.INF}


# The spot to mark from an escape: one nothing ever covers, else the nearest that stays safe once he
# is there, but never one by her body; INF when neither will do.
static func mark_of(out: Dictionary, keep_off: Callable) -> Vector2:
	if out["pure"] != Vector2.INF:
		return out["pure"]
	var haven: Vector2 = out["haven"]
	if haven != Vector2.INF and not keep_off.call(haven):
		return haven
	return Vector2.INF


# --- her turn ---

func on_ready(enemy: Enemy) -> void:
	_ensure_board(enemy)


func tick(enemy: Enemy, delta: float) -> void:
	_clock += delta
	var phase_two := forced_phase_two or is_phase_two(enemy.hp, enemy.max_hp())
	if phase_two and not _phase_two_seen:
		_enter_phase_two(enemy)
	elif _phase_two_seen and not is_instance_valid(_circle):
		_make_circle(enemy)
	if is_instance_valid(enemy.target):
		_trail.record(_clock, enemy.target_ground())
	_ensure_board(enemy)
	_summon(enemy, delta)
	_still_left = maxf(_still_left - delta, 0.0)
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	# She holds still while her line holds and her board's planchette slides, as a medium at her table.
	if _still_left > 0.0:
		return
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	if _cooldown <= 0.0:
		var attack := forced_attack
		forced_attack = Attack.NONE
		if attack == Attack.NONE:
			attack = choose_attack(_last, _rng.randf(), _trail.covers(_clock), _line_running())
		_begin(enemy, attack, phase_two)
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func on_killed(enemy: Enemy) -> void:
	if is_instance_valid(_tether):
		_tether.drop()
	# Her fall lets him go, whatever line held him.
	if is_instance_valid(enemy) and is_instance_valid(enemy.target) and enemy.target.has_method("end_leash"):
		enemy.target.end_leash()
	if is_instance_valid(_circle):
		_circle.put_out()


func _line_running() -> bool:
	return is_instance_valid(_tether) and not _tether.is_over()


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	var order: Array[int] = [attack]
	for other: int in [Attack.OUIJA, Attack.LINE, Attack.POSSESSION]:
		if other != attack:
			order.append(other)
	for option in order:
		var started := false
		match option:
			Attack.LINE:
				started = not _line_running() and _start_line(enemy, phase_two)
			Attack.OUIJA:
				started = _start_ouija(enemy)
			Attack.POSSESSION:
				started = _start_possession(enemy, phase_two)
		if started:
			_main = option
			return
	_cooldown = RETRY


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.LINE:
			_lock_line(enemy, phase_two)
			return
		Attack.OUIJA:
			# She may start her next attack over the slide's tail, planned round it.
			if is_instance_valid(_planchette):
				busy = OuijaPlanchette.slide_time(_planchette.path()) * 0.5
	_attack = Attack.NONE
	_cooldown = cooldown_for(phase_two) + busy
	_last = _main


# --- On the Line ---

func _start_line(enemy: Enemy, phase_two: bool) -> bool:
	if enemy.get_parent() == null:
		return false
	var feet := enemy.target_ground()
	var is_open := LineTether.open_within(feet, LineTether.RADIUS, _plan_open(enemy))
	if not hold_plan(_room(enemy), feet, _live(enemy), enemy.body_rect(), is_open)["safe"]:
		return false
	_attack = Attack.LINE
	var windup := windup_for(Attack.LINE, phase_two)
	_tether = LineTether.new()
	_tether.setup(enemy, windup)
	enemy.get_parent().add_child(_tether)
	_tether.global_position = feet
	_telegraph.start(windup)
	enemy.set_warning(_telegraph, WARNING_RADIUS)
	_anim(enemy, "tether_call", windup)
	enemy.say("You have a call...", SAY_TIME)
	_still_left = windup + LineTether.HOLD
	return true


# The line locks, unless what is under way now leaves him nowhere safe inside the circle; then the
# other attack she runs alongside, planned inside it.
func _lock_line(enemy: Enemy, phase_two: bool) -> void:
	_attack = Attack.NONE
	_last = Attack.LINE
	_cooldown = cooldown_for(phase_two)
	if not is_instance_valid(_tether) or _tether.is_over() or enemy.get_parent() == null:
		_still_left = 0.0
		return
	var is_open := _tether.open_test(_plan_open(enemy))
	var check := hold_plan(_room(enemy), enemy.target_ground(), _live(enemy), enemy.body_rect(), is_open)
	if not check["safe"]:
		_tether.drop()
		_still_left = 0.0
		enemy.say("The line's gone dead.", SAY_TIME)
		return
	_tether.lock()
	_place_mark(enemy, check["mark"], 0.6)
	var order: Array[int] = [Attack.OUIJA, Attack.POSSESSION]
	if not _alongside_ouija_first:
		order.reverse()
	_alongside_ouija_first = not _alongside_ouija_first
	for option in order:
		if option == Attack.OUIJA and _start_ouija(enemy, is_open):
			return
		if option == Attack.POSSESSION and _start_possession(enemy, phase_two, is_open):
			return
	# Nothing fits alongside: the hold alone, and her next attack after it.
	_cooldown = LineTether.HOLD + cooldown_for(phase_two)


# --- the Ouija board ---

func _start_ouija(enemy: Enemy, is_open := Callable()) -> bool:
	if enemy.get_parent() == null:
		return false
	var open := is_open if is_open.is_valid() else _plan_open(enemy)
	var plan := ouija_plan(_room(enemy), enemy.target_ground(), _live(enemy), enemy.body_rect(), open, _rng.randi_range(0, OUIJA_START_PICK - 1))
	var path: Array = plan["path"]
	if path.is_empty():
		return false
	_attack = Attack.OUIJA
	_planchette = OuijaPlanchette.new()
	_planchette.setup(enemy, plan["path"], OUIJA_WINDUP, OUIJA_DAMAGE, plan["word"])
	enemy.get_parent().add_child(_planchette)
	_planchette.global_position = Vector2.ZERO
	var slide := OuijaPlanchette.slide_time(plan["path"])
	_telegraph.start(OUIJA_WINDUP)
	enemy.set_warning(_telegraph, WARNING_RADIUS, OUIJA_SHOWN_WHOLE)
	_anim(enemy, "attack", OUIJA_WINDUP)
	enemy.say("The spirits will spell it out...", SAY_TIME)
	_still_left = maxf(_still_left, OUIJA_WINDUP + slide)
	_place_mark(enemy, plan["mark"], OUIJA_WINDUP + slide)
	return true


# --- Possession ---

func _start_possession(enemy: Enemy, phase_two: bool, is_open := Callable()) -> bool:
	if enemy.get_parent() == null or not _trail.covers(_clock):
		return false
	var windup := windup_for(Attack.POSSESSION, phase_two)
	var trail := _trail.path(_clock, TRAIL_STEP)
	var open := is_open if is_open.is_valid() else _plan_open(enemy)
	var plan := possession_plan(_room(enemy), trail, TRAIL_STEP, windup, enemy.target_ground(), _live(enemy), enemy.body_rect(), open)
	if not plan["safe"]:
		return false
	_attack = Attack.POSSESSION
	_ghost = PossessionGhost.new()
	_ghost.setup(enemy, trail, TRAIL_STEP, windup, POSSESSION_DAMAGE)
	enemy.get_parent().add_child(_ghost)
	_ghost.global_position = Vector2.ZERO
	_telegraph.start(windup)
	enemy.set_warning(_telegraph, WARNING_RADIUS)
	_anim(enemy, "possession", windup)
	enemy.say("Let me in...", SAY_TIME)
	_still_left = maxf(_still_left, windup)
	_place_mark(enemy, plan["mark"], windup + PossessionGhost.LIFE)
	return true


# --- the seance circle ---

func _enter_phase_two(enemy: Enemy) -> void:
	_phase_two_seen = true
	enemy.say("The spirits are here. Stay in the light...", SAY_TIME * 1.5)
	_make_circle(enemy)


func _make_circle(enemy: Enemy) -> void:
	if enemy.get_parent() == null:
		return
	_circle = SeanceCircle.new()
	var feet := enemy.target_ground() if is_instance_valid(enemy.target) else enemy.global_position
	_circle.setup(enemy, _room(enemy), feet, _rng.randi())
	enemy.get_parent().add_child(_circle)
	_circle.global_position = Vector2.ZERO


# --- summons ---

func _summon(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _summon_timer > 0.0 or not enemy.is_inside_tree() or not enemy.target_in_view():
		return
	_summon_timer = ECTOPLASM_EVERY
	var alive := enemy.enemies_alive()
	var count := ectoplasm_count(alive)
	if not BossMoves.can_summon(alive, MAX_ENEMIES) or count <= 0:
		return
	enemy.say("Manifest!", SAY_TIME)
	enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, SUMMON_SPREAD), BossMoves.SUMMON_WARNING)


# --- helpers ---

func _ensure_board(enemy: Enemy) -> void:
	if is_instance_valid(_board) or enemy.get_parent() == null:
		return
	_board = OuijaBoard.new()
	_board.setup(enemy, _room(enemy))
	enemy.get_parent().add_child(_board)
	_board.global_position = Vector2.ZERO


func _anim(enemy: Enemy, anim: String, seconds: float) -> void:
	last_anim = anim
	enemy.play_anim(anim, seconds)


func _room(enemy: Enemy) -> Rect2:
	return ForemanBehavior.room_rect(enemy.room_cells)


func _live(enemy: Enemy) -> Dictionary:
	if enemy.get_parent() == null:
		return {"rects": [], "circles": []}
	return ProjectionistBehavior.live_shapes(enemy.get_parent().get_children())


func _open_cells(enemy: Enemy) -> Callable:
	var grid := enemy.walk_grid
	if grid == null:
		return Callable()
	return func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))


# The floor a plan may lead him over: open floor, and in the seance circle only the light (as it may
# drift meanwhile), unless he stands outside it already, when she plans over the open floor.
func _plan_open(enemy: Enemy) -> Callable:
	var open := _open_cells(enemy)
	if is_instance_valid(_circle) and not _circle.is_out() and is_instance_valid(enemy.target):
		var lit := _circle.open_test(LIGHT_HORIZON, open)
		if lit.call(enemy.target_ground()):
			return lit
	return open


func _place_mark(enemy: Enemy, spot: Vector2, seconds: float) -> void:
	if spot == Vector2.INF or enemy.get_parent() == null:
		return
	if not is_instance_valid(_mark):
		_mark = SafeSpotMark.new()
		_mark.setup(seconds)
		enemy.get_parent().add_child(_mark)
	else:
		_mark.setup(maxf(_mark.time_left(), seconds))
	_mark.global_position = spot


# For tests and a look probe: what she has under way.
func attack() -> int:
	return _attack


func tether() -> LineTether:
	return _tether if is_instance_valid(_tether) else null


func planchette() -> OuijaPlanchette:
	return _planchette if is_instance_valid(_planchette) else null


func ghost() -> PossessionGhost:
	return _ghost if is_instance_valid(_ghost) else null


func board() -> OuijaBoard:
	return _board if is_instance_valid(_board) else null


func circle() -> SeanceCircle:
	return _circle if is_instance_valid(_circle) else null


func trail() -> FeetTrail:
	return _trail
