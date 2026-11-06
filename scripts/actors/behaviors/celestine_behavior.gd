class_name CelestineBehavior
extends EnemyBehavior

# Sister Celestine, Tarot Reader, the Seance Hotline's mini boss in Chip's old slot. She deals three
# cards face down on the floor in front of her, between her and Grandpa, and turns them over one at a
# time. Each turned card shows its symbol, with its name, for TURN_WINDUP before it acts:
# - The Tower: ceiling tiles fall on marked squares round him (TowerTiles).
# - Death: a scythe sweeps through a marked arc from her toward him (ScytheSweep), two pills.
# - The Wheel: a ring of blades spins round her, with gaps, a clear inside and a clear outside (WheelRing).
# - The Star: spots of light rain down round him in a short stagger (StarFall).
# She never deals three of a kind, though two alike may come. She holds still from the deal to her last
# card, and turns the next card only once the last one's attack can hurt no more, so no two cards' hits
# are ever under way together and every attack comes alone, fully warned. She calls no one.
enum Card { TOWER, DEATH, WHEEL, STAR }
const CARD_COUNT := 4
const HAND := 3
const NAMES: Array[String] = ["The Tower", "Death", "The Wheel", "The Star"]
# The deal: the cards land one after another while she deals, then the first is turned.
const DEAL_WINDUP := 0.6
const DEAL_STEP := 0.15
# How long a turned card shows its symbol before its attack begins.
const TURN_WINDUP := 0.6
# The attacks' warnings, each shown whole by its own mark.
const TOWER_WINDUP := 0.9
const DEATH_WINDUP := 1.0
const WHEEL_WINDUP := 1.0
const STAR_WINDUP := 0.8
const TOWER_DAMAGE := 1
const DEATH_DAMAGE := Enemy.HEAVY_DAMAGE
const WHEEL_DAMAGE := 1
const STAR_DAMAGE := 1
# The Tower: this many tiles, his own cell's and others at most TOWER_REACH cells from it.
const TOWER_TILES := 5
const TOWER_REACH := 2
# The Star: this many spots, the first on his feet, the rest within STAR_REACH and apart.
const STARS := 5
const STAR_REACH := 90.0
const STAR_TRIES := 40
# A pause after one card's attack is done, before the next card turns.
const CARD_GAP := 0.25
# Her rest between hands: Chip's slot, as short as the Reverend's and shorter than Crabtree's.
const COOLDOWN := 0.5
const FIRST_HAND := 1.0
const KEEP_NEAR := 110.0
const SAY_TIME := 1.0
# Where the cards lie: a row of three in front of her, above or below, or a column of three beside her,
# each clear of her body (32x40) and of each other (the cards are TarotCard.SIZE, 32x48).
const ROW_AHEAD := 52.0
const ROW_STEP := 40.0
const COLUMN_AHEAD := 40.0
const COLUMN_STEP := 56.0
const ROW_SLIDES: Array[float] = [0.0, 24.0, -24.0, 48.0, -48.0]
const DEAL_TEXT := "Let us see your cards..."
# Her body, which no card may lie on.
const BODY := Vector2(32, 40)

enum Step { REST, DEAL, TURN, ACT, GAP }

var _step := Step.REST
var _step_left := 0.0
var _cooldown := FIRST_HAND
var _hand: Array[int] = []
var _cards: Array[TarotCard] = []
var _index := 0
# The attack under way: a TowerTiles, ScytheSweep, WheelRing or StarFall, each of which says is_spent.
var _effect = null
# A look probe's pick for her next hand (three cards, by Card); empty, or a hand she may not deal,
# lets her choose.
var forced_hand: Array = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# --- the deal ---

static func card_for(roll: float) -> int:
	return clampi(int(roll * CARD_COUNT), 0, CARD_COUNT - 1)


# Three cards from three rolls in [0, 1). The first two are drawn freely; when they match, the third
# is drawn from the other three cards, so three of a kind never comes.
static func deal(rolls: Array) -> Array[int]:
	var hand: Array[int] = []
	for i in HAND:
		var roll: float = rolls[i] if i < rolls.size() else 0.0
		if i == HAND - 1 and hand[0] == hand[1]:
			var others: Array[int] = []
			for card in CARD_COUNT:
				if card != hand[0]:
					others.append(card)
			hand.append(others[clampi(int(roll * others.size()), 0, others.size() - 1)])
		else:
			hand.append(card_for(roll))
	return hand


static func deal_with(rng: RandomNumberGenerator) -> Array[int]:
	return deal([rng.randf(), rng.randf(), rng.randf()])


static func is_valid_hand(hand: Array) -> bool:
	if hand.size() != HAND:
		return false
	for card in hand:
		if typeof(card) != TYPE_INT or card < 0 or card >= CARD_COUNT:
			return false
	return not (hand[0] == hand[1] and hand[1] == hand[2])


static func windup_of(card: int) -> float:
	match card:
		Card.TOWER:
			return TOWER_WINDUP
		Card.DEATH:
			return DEATH_WINDUP
		Card.WHEEL:
			return WHEEL_WINDUP
	return STAR_WINDUP


# How long a card's attack runs from its start until it can hurt no more.
static func act_time(card: int) -> float:
	match card:
		Card.TOWER:
			return TOWER_WINDUP
		Card.DEATH:
			return DEATH_WINDUP + ScytheSweep.SWEEP_TIME
		Card.WHEEL:
			return WHEEL_WINDUP + WheelRing.SPIN_TIME
	return STAR_WINDUP + (STARS - 1) * StarFall.STEP


# --- where things go ---

# The three cards' spots, in front of her toward Grandpa's feet: the side facing him first, then the
# others by how much they face him, each slid a little along its line when it must be, the first
# whose three spots lie wholly inside the room on open floor. When none does, the side facing him
# with each spot moved to the nearest open floor clear of her body and the other cards.
static func card_spots(origin: Vector2, toward: Vector2, room: Rect2, is_open := Callable()) -> Array[Vector2]:
	var way := origin.direction_to(toward)
	if way.is_zero_approx():
		way = Vector2.DOWN
	var sides: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	sides.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.dot(way) > b.dot(way))
	for side in sides:
		# Slid along its own line a little either way when the middle will not do, before the next side.
		for slide: float in ROW_SLIDES:
			var spots := _spots_on(origin, side)
			var along := Vector2(slide, 0.0) if side.x == 0.0 else Vector2(0.0, slide)
			var fits := true
			for i in spots.size():
				spots[i] += along
				if not _card_fits(spots[i], room, is_open):
					fits = false
			if fits:
				return spots
	var chosen: Array[Vector2] = []
	var body := Rect2(origin - BODY / 2.0, BODY)
	for spot in _spots_on(origin, sides[0]):
		chosen.append(_nearest_card_spot(spot, room, is_open, chosen, body))
	return chosen


static func _spots_on(origin: Vector2, side: Vector2) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	if side.x == 0.0:
		var middle := origin + side * ROW_AHEAD
		for i in [-1, 0, 1]:
			spots.append(middle + Vector2(i * ROW_STEP, 0.0))
	else:
		var middle := origin + side * COLUMN_AHEAD
		for i in [-1, 0, 1]:
			spots.append(middle + Vector2(0.0, i * COLUMN_STEP))
	return spots


# A card fits where its whole face lies inside the room and its middle and both ends are on open floor.
static func _card_fits(spot: Vector2, room: Rect2, is_open: Callable) -> bool:
	var card := Rect2(spot - TarotCard.SIZE / 2.0, TarotCard.SIZE)
	if room.has_area() and not room.encloses(card):
		return false
	if not is_open.is_valid():
		return true
	var reach := TarotCard.SIZE.y / 2.0 - 4.0
	for point in [spot, spot + Vector2(0.0, -reach), spot + Vector2(0.0, reach)]:
		if not is_open.call(point):
			return false
	return true


# The nearest cell middle to a spot where a card fits, clear of the cards already placed.
static func _nearest_card_spot(spot: Vector2, room: Rect2, is_open: Callable, placed: Array[Vector2], body: Rect2) -> Vector2:
	var tile := float(RoomBackdrop.TILE)
	var best := Vector2.INF
	var cell := WalkGrid.cell_of(spot)
	for reach in range(0, 12):
		for y in range(cell.y - reach, cell.y + reach + 1):
			for x in range(cell.x - reach, cell.x + reach + 1):
				if maxi(absi(x - cell.x), absi(y - cell.y)) != reach:
					continue
				var at := (Vector2(x, y) + Vector2(0.5, 0.5)) * tile
				if not _card_fits(at, room, is_open) or not _clear_of(at, placed):
					continue
				if body.intersects(Rect2(at - TarotCard.SIZE / 2.0, TarotCard.SIZE)):
					continue
				if best == Vector2.INF or at.distance_to(spot) < best.distance_to(spot):
					best = at
		if best != Vector2.INF:
			return best
	return room.get_center() if room.has_area() else spot


static func _clear_of(at: Vector2, placed: Array[Vector2]) -> bool:
	for other in placed:
		if absf(at.x - other.x) < TarotCard.SIZE.x + 4.0 and absf(at.y - other.y) < TarotCard.SIZE.y + 4.0:
			return false
	return true


# The Tower's cells: his own, then others at most TOWER_REACH cells from it, all on open floor inside
# the room, never every open cell beside his own, so a step out always lands clear.
static func tower_cells(feet: Vector2, cells: Vector2i, rng: RandomNumberGenerator, is_open := Callable()) -> Array[Vector2i]:
	var center := WalkGrid.cell_of(feet)
	var usable := func(cell: Vector2i) -> bool:
		if cell.x < 1 or cell.y < 1 or cell.x > cells.x - 2 or cell.y > cells.y - 2:
			return false
		return not is_open.is_valid() or is_open.call(RoomBackdrop.cell_center(cell))
	var chosen: Array[Vector2i] = []
	if usable.call(center):
		chosen.append(center)
	var options: Array[Vector2i] = []
	for y in range(-TOWER_REACH, TOWER_REACH + 1):
		for x in range(-TOWER_REACH, TOWER_REACH + 1):
			var cell := center + Vector2i(x, y)
			if cell != center and usable.call(cell):
				options.append(cell)
	# Shuffled by the given rng, so a seed always gives the same tiles.
	for i in range(options.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := options[i]
		options[i] = options[j]
		options[j] = swap
	var beside: Array[Vector2i] = []
	for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if usable.call(center + side):
			beside.append(center + side)
	for cell in options:
		if chosen.size() >= TOWER_TILES:
			break
		if beside.has(cell):
			var free := 0
			for other in beside:
				if other != cell and not chosen.has(other):
					free += 1
			if free == 0:
				continue
		chosen.append(cell)
	return chosen


# The Tower's cells as she drops them: tower_cells, checked with OverlapRoute against the room's walls
# and props and her body, dropping the last tile picked (never his own) until he has a way out.
static func tower_plan(feet: Vector2, cells: Vector2i, rng: RandomNumberGenerator, is_open := Callable(), body := Rect2()) -> Array[Vector2i]:
	var chosen := tower_cells(feet, cells, rng, is_open)
	var room := ForemanBehavior.room_rect(cells)
	var floor_route: OverlapRoute = null
	while chosen.size() > 1:
		var rects: Array = []
		for cell in chosen:
			rects.append([TowerTiles.square_of(cell).grow(TowerTiles.ROUTE_SPARE), Vector2(TOWER_WINDUP, TOWER_WINDUP + TowerTiles.ROUTE_HIT_TIME)])
		var route := ProjectionistBehavior.route_with(room, {"rects": rects, "circles": []}, body, is_open, floor_route)
		if floor_route == null:
			floor_route = route
		if route.escape(feet)["safe"]:
			return chosen
		chosen.pop_back()
	return chosen


# The Star's spots: one on his feet, the rest near him, apart from each other, on open floor inside the
# room.
static func star_spots(feet: Vector2, rng: RandomNumberGenerator, room := Rect2(), is_open := Callable()) -> Array[Vector2]:
	var inner := room.grow(-StarFall.RADIUS) if room.has_area() else Rect2()
	var fits := func(point: Vector2) -> bool:
		if inner.has_area() and not inner.has_point(point):
			return false
		return not is_open.is_valid() or is_open.call(point)
	var spots: Array[Vector2] = []
	var first: Vector2 = feet.clamp(inner.position, inner.end) if inner.has_area() else feet
	spots.append(first)
	var tries := 0
	while spots.size() < STARS and tries < STAR_TRIES:
		tries += 1
		var spot := feet + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(StarFall.RADIUS * 2.0 + 6.0, STAR_REACH)
		if fits.call(spot) and _apart(spot, spots):
			spots.append(spot)
	# A cramped corner: walk round him at set distances until every star has a spot.
	for reach: float in [STAR_REACH, STAR_REACH * 0.75, STAR_REACH * 0.5]:
		for step in 24:
			if spots.size() >= STARS:
				return spots
			var spot := feet + Vector2.from_angle(TAU * step / 24.0) * reach
			if fits.call(spot) and _apart(spot, spots):
				spots.append(spot)
	return spots


static func _apart(spot: Vector2, others: Array[Vector2]) -> bool:
	for other in others:
		if spot.distance_to(other) < StarFall.RADIUS * 2.0 + 6.0:
			return false
	return true


# --- her turn ---

func tick(enemy: Enemy, delta: float) -> void:
	match _step:
		Step.REST:
			_rest(enemy, delta)
		Step.DEAL:
			_step_left -= delta
			if _step_left <= 0.0:
				_index = 0
				_turn(enemy)
		Step.TURN:
			_step_left -= delta
			if _step_left <= 0.0:
				_act(enemy)
		Step.ACT:
			if not _effect_running():
				if _index < _cards.size() and is_instance_valid(_cards[_index]):
					_cards[_index].mark_spent()
				_step = Step.GAP
				_step_left = CARD_GAP
		Step.GAP:
			_step_left -= delta
			if _step_left <= 0.0:
				_index += 1
				if _index < _hand.size():
					_turn(enemy)
				else:
					_end_hand()


func _rest(enemy: Enemy, delta: float) -> void:
	_cooldown -= delta
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * BossMoves.CATCH_UP_SPEED
		return
	if _cooldown <= 0.0:
		_deal(enemy)
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _deal(enemy: Enemy) -> void:
	_hand.clear()
	if is_valid_hand(forced_hand):
		_hand.assign(forced_hand)
	else:
		_hand = deal_with(_rng)
	_cards.clear()
	_step = Step.DEAL
	_step_left = DEAL_WINDUP
	enemy.say(DEAL_TEXT, SAY_TIME)
	enemy.play_anim("deal_cards", DEAL_WINDUP)
	var parent := enemy.get_parent()
	if parent == null:
		return
	var spots := card_spots(enemy.global_position, enemy.target_ground(), _room(enemy), _open_spots(enemy))
	for i in HAND:
		var card := TarotCard.new()
		card.setup(_hand[i], enemy, i * DEAL_STEP)
		parent.add_child(card)
		card.global_position = spots[i]
		card.slide_from(enemy.global_position)
		_cards.append(card)


func _turn(enemy: Enemy) -> void:
	_step = Step.TURN
	_step_left = TURN_WINDUP
	if _index < _cards.size() and is_instance_valid(_cards[_index]):
		_cards[_index].turn()
	enemy.say(NAMES[_hand[_index]], TURN_WINDUP + 0.4)
	enemy.play_anim("attack", TURN_WINDUP)


func _act(enemy: Enemy) -> void:
	_step = Step.ACT
	_effect = null
	var parent := enemy.get_parent()
	if parent == null:
		return
	var feet := enemy.target_ground()
	match _hand[_index]:
		Card.TOWER:
			var tiles := TowerTiles.new()
			tiles.setup(enemy, tower_plan(feet, enemy.room_cells, _rng, _open_spots(enemy), enemy.body_rect()), TOWER_WINDUP, TOWER_DAMAGE)
			parent.add_child(tiles)
			tiles.global_position = Vector2.ZERO
			_effect = tiles
		Card.DEATH:
			var scythe := ScytheSweep.new()
			scythe.setup(enemy, (feet - enemy.global_position).angle(), DEATH_WINDUP, DEATH_DAMAGE, _rng.randf() < 0.5)
			parent.add_child(scythe)
			scythe.global_position = enemy.global_position
			_effect = scythe
		Card.WHEEL:
			var wheel := WheelRing.new()
			wheel.setup(enemy, WHEEL_WINDUP, _rng.randf() * TAU, _rng.randf() < 0.5, WHEEL_DAMAGE)
			parent.add_child(wheel)
			wheel.global_position = enemy.global_position
			_effect = wheel
		_:
			var stars := StarFall.new()
			stars.setup(enemy, star_spots(feet, _rng, _room(enemy), _open_spots(enemy)), STAR_WINDUP, STAR_DAMAGE)
			parent.add_child(stars)
			stars.global_position = Vector2.ZERO
			_effect = stars
	Sfx.play("attack_warning")


func _effect_running() -> bool:
	return is_instance_valid(_effect) and not _effect.is_queued_for_deletion() and not _effect.is_spent()


func _end_hand() -> void:
	for card in _cards:
		if is_instance_valid(card):
			card.vanish()
	_cards.clear()
	_effect = null
	_step = Step.REST
	_cooldown = COOLDOWN


func on_killed(_enemy: Enemy) -> void:
	for card in _cards:
		if is_instance_valid(card):
			card.queue_free()
	_cards.clear()


func _room(enemy: Enemy) -> Rect2:
	return ForemanBehavior.room_rect(enemy.room_cells)


func _open_spots(enemy: Enemy) -> Callable:
	var grid := enemy.walk_grid
	if grid == null:
		return Callable()
	return func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))


# For tests and a look probe: what she is doing, her hand, her cards and the attack under way.
func is_dealing() -> bool:
	return _step != Step.REST


func step() -> int:
	return _step


func hand() -> Array[int]:
	return _hand


func cards() -> Array[TarotCard]:
	return _cards


func effect() -> Node:
	return _effect if is_instance_valid(_effect) else null
