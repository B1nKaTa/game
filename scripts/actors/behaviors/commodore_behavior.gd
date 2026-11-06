class_name CommodoreBehavior
extends EnemyBehavior

# Commodore Wellington, master of the Last Resort. He drops the anchor on a warned spot under Grandpa,
# the one attack that costs three pills, so its warning always shows whole, with a second ring and a
# growing shadow. He sounds the foghorn down a wide warned lane, orders the helm "hard to port", a far
# stronger roll of the ship that sounds the ship's own horn first, and sends lifebuoys rolling across
# the deck in warned lanes. Below half health he has the decks swabbed, so wet patches spread under
# warned jets, and the anchor drops twice in a row, each drop warned in full.
const ANCHOR_WINDUP := 1.2
const ANCHOR_DAMAGE := Enemy.HEAVIEST_DAMAGE
# The anchor's warning shows for all of its windup, whatever the player's warning stat.
const ANCHOR_SHOWN_WHOLE := true
# In the second phase the anchor drops this many times in a row.
const ANCHORS_IN_A_ROW := 2
const FOGHORN_WINDUP := 0.9
const FOGHORN_LENGTH := 340.0
const FOGHORN_WIDTH := 84.0
const FOGHORN_DAMAGE := Enemy.HEAVY_DAMAGE
const FOGHORN_SHOVE := 220.0
const FOGHORN_SHOVE_TIME := 0.3
const PORT_WINDUP := 0.5
# The ordered roll sounds the ship's horn for as long as the ship's own roll does, then slides harder.
const PORT_HORN := ShipRoll.HORN_TIME
const PORT_SLIDE := 2.5
const PORT_SPEED := ShipRoll.SPEED * 2.2
const PORT_EVERY := 11.0
const FIRST_PORT := 6.0
const BUOY_WINDUP := 0.6
const BUOY_WARNING := 1.0
const BUOY_COUNT := 3
const BUOY_WIDTH := 30.0
const BUOY_SPACING := 96.0
const WET_EVERY := 8.0
const WET_JETS := 2
const WET_RADIUS := 26.0
const WET_WARNING := 0.9
const WET_TIME := 5.0
const WARNING_RADIUS := 42.0
# Shorter than Mortimer's 0.65 and 0.45 and the Projectionist's, as he must be clearly harder than both.
const BASE_COOLDOWN := 0.6
const PHASE_TWO_COOLDOWN := 0.42
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const KEEP_NEAR := 96.0
const SAY_TIME := 1.0

enum Attack { NONE, ANCHOR, FOGHORN, PORT, BUOYS }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
var _since_port := PORT_EVERY - FIRST_PORT
var _wet_timer := 0.0
var _anchors_in_a_row := 0
var _aim := Vector2.RIGHT
# How far the foghorn's warned lane really runs, since it ends at the first wall.
var _foghorn_length := FOGHORN_LENGTH
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


# The second phase quickens his windups, but never the anchor's extra-clear warning.
static func windup_for(attack: int, phase_two: bool) -> float:
	if attack == Attack.ANCHOR:
		return ANCHOR_WINDUP
	var windup := FOGHORN_WINDUP
	match attack:
		Attack.PORT:
			windup = PORT_WINDUP
		Attack.BUOYS:
			windup = BUOY_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# In the second phase the anchor drops again straight after it lands, ANCHORS_IN_A_ROW times in all.
static func followup(attack: int, phase_two: bool, anchors_so_far: int) -> int:
	if phase_two and attack == Attack.ANCHOR and anchors_so_far < ANCHORS_IN_A_ROW:
		return Attack.ANCHOR
	return Attack.NONE


# Never the same order twice running. The helm only turns on a rolling deck, and not too often.
static func choose_attack(last: int, has_deck: bool, since_port: float, roll: float) -> int:
	var options: Array[int] = [Attack.ANCHOR, Attack.FOGHORN, Attack.BUOYS]
	if has_deck and since_port >= PORT_EVERY:
		options.append(Attack.PORT)
	if options.size() > 1:
		options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# The rows the lifebuoys roll along: one level with his feet and the rest either side, spaced apart,
# every lane wholly inside the room and no two the same.
static func buoy_rows(room: Rect2, feet_y: float, count: int) -> Array[float]:
	var low := room.position.y + BUOY_WIDTH / 2.0
	var high := room.end.y - BUOY_WIDTH / 2.0
	var first := clampf(feet_y - (count - 1) / 2.0 * BUOY_SPACING, low, maxf(high - (count - 1) * BUOY_SPACING, low))
	var rows: Array[float] = []
	for i in count:
		var row := first + i * BUOY_SPACING
		if row > high + 0.001:
			break
		rows.append(row)
	return rows


# Port or starboard, as the helm turns: left or right, picked by the roll.
static func port_side(roll: float) -> Vector2:
	return Vector2.LEFT if roll < 0.5 else Vector2.RIGHT


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	_since_port += delta
	if phase_two:
		_wet_timer -= delta
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	if phase_two and _wet_timer <= 0.0:
		_wet_timer = WET_EVERY
		_swab_the_decks(enemy)
	if _cooldown <= 0.0 or (_next != Attack.NONE and _cooldown <= cooldown_for(phase_two) * 0.5):
		var attack := _next
		if attack == Attack.NONE:
			attack = choose_attack(_last, not _decks(enemy).is_empty(), _since_port, _rng.randf())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _decks(enemy: Enemy) -> Array:
	return ShipDeck.decks_in(enemy.get_tree()) if enemy.is_inside_tree() else []


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	if attack == Attack.PORT and _decks(enemy).is_empty():
		attack = Attack.FOGHORN
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.ANCHOR:
			# The windup on him shows whole too, and the anchor's spot is locked under Grandpa at once.
			_anchors_in_a_row = _anchors_in_a_row + 1 if _last == Attack.ANCHOR else 1
			enemy.set_warning(_telegraph, WARNING_RADIUS, ANCHOR_SHOWN_WHOLE)
			enemy.say("Drop anchor!" if _anchors_in_a_row == 1 else "And again!", SAY_TIME)
			var feet := enemy.target_ground()
			if not enemy.open_ground.is_valid() or enemy.open_ground.call(feet):
				var anchor := AnchorDrop.new()
				anchor.setup(enemy, ANCHOR_WINDUP, ANCHOR_DAMAGE)
				enemy.get_parent().add_child(anchor)
				anchor.global_position = feet
		Attack.FOGHORN:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.set_warning_lane(_aim, FOGHORN_LENGTH, FOGHORN_WIDTH)
			_foghorn_length = enemy.warning_lane_length()
			enemy.say("BWAAAMP!", SAY_TIME)
			# Looks only: his own move plays over the windup and the moment it lands.
			enemy.play_anim("foghorn_blast", windup_for(attack, phase_two) + EnemyAnim.ATTACK_TIME)
		Attack.PORT:
			_aim = port_side(_rng.randf())
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Hard to port!" if _aim == Vector2.LEFT else "Hard to starboard!", SAY_TIME)
		Attack.BUOYS:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Man overboard!", SAY_TIME)
			enemy.play_anim("buoy_call", windup_for(attack, phase_two) + EnemyAnim.ATTACK_TIME)
			_roll_buoys(enemy)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.FOGHORN:
			var lane := _foghorn_length if _foghorn_length > 0.0 else FOGHORN_LENGTH
			var blast := FoghornBlast.new()
			blast.setup(_aim, lane, FOGHORN_WIDTH)
			enemy.get_parent().add_child(blast)
			blast.global_position = enemy.global_position
			if FoghornBlast.in_blast(enemy.global_position, _aim, lane, FOGHORN_WIDTH, enemy.target_ground()):
				if enemy.target.has_method("take_hit") and enemy.target.take_hit(FOGHORN_DAMAGE) and enemy.target.has_method("push"):
					enemy.target.push(_aim * FOGHORN_SHOVE, FOGHORN_SHOVE_TIME)
		Attack.PORT:
			for deck in _decks(enemy):
				deck.force_roll(_aim, PORT_HORN, PORT_SLIDE, PORT_SPEED)
			_since_port = 0.0
		Attack.BUOYS:
			busy = BUOY_WARNING - BUOY_WINDUP
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two, _anchors_in_a_row)
	if _attack != Attack.ANCHOR:
		_anchors_in_a_row = 0


# Lifebuoys roll from one side of the room to the other along rows around him, each lane warned first.
func _roll_buoys(enemy: Enemy) -> void:
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var way := Vector2.RIGHT if _rng.randf() < 0.5 else Vector2.LEFT
	var start_x := room.position.x if way == Vector2.RIGHT else room.end.x
	for row in buoy_rows(room, enemy.target_ground().y, BUOY_COUNT):
		var lane := DeckLane.new()
		lane.setup(enemy, way, room.size.x, BUOY_WIDTH, BUOY_WARNING + BUOY_WINDUP, DeckLane.LOOK_LIFEBUOY)
		enemy.get_parent().add_child(lane)
		lane.global_position = Vector2(start_x, row)


# Jets of seawater come up under and around him, each warned, and leave a patch of wet deck.
func _swab_the_decks(enemy: Enemy) -> void:
	enemy.say("Swab the decks!", SAY_TIME)
	var grid := enemy.walk_grid
	var is_open := func(spot: Vector2) -> bool:
		return grid == null or grid.is_open(WalkGrid.cell_of(spot))
	var target := WalkGrid.cell_of(enemy.target_ground())
	for cell in SplashJets.splash_cells(target, WET_JETS, _rng, enemy.room_cells, is_open):
		var strike := enemy.strike_ground(RoomBackdrop.cell_center(cell), WET_RADIUS, WET_WARNING)
		if strike == null:
			continue
		strike.set_look(GroundStrike.LOOK_SPLASH)
		strike.landed.connect(_wet.bind(enemy.get_parent(), SplashJets.splash_patch(cell, enemy.room_cells, is_open)))


static func _wet(_at: Vector2, room: Node, cells: Array[Vector2i]) -> void:
	if not is_instance_valid(room) or cells.is_empty():
		return
	var splash := WetSplash.new()
	var palette: RoomPalette = room.room_palette() if room.has_method("room_palette") else null
	splash.setup(cells, WET_TIME, palette)
	room.add_child(splash)
