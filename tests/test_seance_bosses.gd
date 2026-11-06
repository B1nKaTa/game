extends TestCase

# The Seance Hotline's bosses: Sister Celestine, Tarot Reader, and Madame Zara, the Medium.
const Reader := preload("res://scripts/actors/behaviors/celestine_behavior.gd")
const FRAME := 1.0 / 60.0
# The hotline scales health by this, and its bosses hold their final health divided by it.
const HOTLINE_HEALTH := 2.2
const FLOOR_TWO_HEALTH := 1.4
const FLOOR_THREE_HEALTH := 1.8
const MINI_ROOMS := ["mini_boss_01", "mini_boss_large_01"]
const SEEDS := 200


# A stand-in for Grandpa that counts the hits it takes and what they cost.
class Target extends Node2D:
	var hits := 0
	var pills := 0

	func take_hit(amount: int, _source = null) -> bool:
		hits += 1
		pills += amount
		return true


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _layout(room_name: String) -> RoomLayout:
	return load("res://data/rooms/seance_hotline/%s.tres" % room_name)


func _is_open(layout: RoomLayout) -> Callable:
	return func(spot: Vector2) -> bool: return not layout.is_solid_at(WalkGrid.cell_of(spot))


# A spot where his whole feet box stands on open floor.
func _open_spot(layout: RoomLayout, rng: RandomNumberGenerator, room: Rect2) -> Vector2:
	for i in 400:
		var spot := Vector2(rng.randf_range(room.position.x + 10.0, room.end.x - 10.0), rng.randf_range(room.position.y + 10.0, room.end.y - 10.0))
		var box := Rect2(spot - Player.FEET_BOX_SIZE / 2.0, Player.FEET_BOX_SIZE)
		var clear := true
		for corner in [box.position, box.end, Vector2(box.position.x, box.end.y), Vector2(box.end.x, box.position.y)]:
			if layout.is_solid_at(WalkGrid.cell_of(corner)):
				clear = false
		if clear:
			return spot
	return room.get_center()


# Her middle on open floor, with the cells under her whole body open, as she walks.
func _boss_spot(layout: RoomLayout, rng: RandomNumberGenerator, room: Rect2) -> Vector2:
	for i in 400:
		var spot := _open_spot(layout, rng, room.grow(-20.0))
		var body := Rect2(spot - Reader.BODY / 2.0, Reader.BODY)
		var clear := true
		for corner in [body.position, body.end, Vector2(body.position.x, body.end.y), Vector2(body.end.x, body.position.y)]:
			if layout.is_solid_at(WalkGrid.cell_of(corner)):
				clear = false
		if clear:
			return spot
	return room.get_center()


func _celestine(at: Vector2, grandpa: Node2D, cells := Vector2i(20, 11)) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(_load("celestine"), grandpa, 0.5)
	enemy.room_cells = cells
	enemy.position = at
	return enemy


# One frame of her and of everything she has laid in the room, out of the tree.
func _frame(behavior: CelestineBehavior, enemy: Enemy, room: Node2D) -> void:
	enemy.desired_velocity = Vector2.ZERO
	enemy._holding_lane = false
	behavior.tick(enemy, FRAME)
	for child in room.get_children():
		if child != enemy and not child.is_queued_for_deletion() and child.has_method("_process"):
			child._process(FRAME)


func _is_attack(node: Node) -> bool:
	return node is TowerTiles or node is ScytheSweep or node is WheelRing or node is StarFall


# --- the deal ---

func test_she_always_deals_three_cards_and_never_three_alike() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var seen := {}
	var pairs := 0
	for i in 4000:
		var hand := Reader.deal_with(rng)
		assert_eq(hand.size(), 3, "three cards")
		assert_true(Reader.is_valid_hand(hand), "hand %s" % str(hand))
		assert_false(hand[0] == hand[1] and hand[1] == hand[2], "never three alike: %s" % str(hand))
		for card in hand:
			seen[card] = true
		if hand[0] == hand[1] or hand[1] == hand[2] or hand[0] == hand[2]:
			pairs += 1
	assert_eq(seen.size(), Reader.CARD_COUNT, "every card comes up")
	assert_true(pairs > 400, "two alike may come (%d)" % pairs)
	# Every roll she could make, not only random ones.
	for a in 20:
		for b in 20:
			for c in 20:
				var hand := Reader.deal([a / 20.0, b / 20.0, c / 20.0])
				assert_true(Reader.is_valid_hand(hand), "%d %d %d: %s" % [a, b, c, str(hand)])
	assert_eq(Reader.deal([0.999, 0.999, 0.999]).size(), 3, "even at the top of every roll")


func test_a_hand_must_be_three_cards_of_the_deck_not_all_alike() -> void:
	assert_true(Reader.is_valid_hand([Reader.Card.TOWER, Reader.Card.TOWER, Reader.Card.STAR]), "two alike are allowed")
	assert_true(Reader.is_valid_hand([Reader.Card.DEATH, Reader.Card.WHEEL, Reader.Card.STAR]))
	assert_false(Reader.is_valid_hand([Reader.Card.WHEEL, Reader.Card.WHEEL, Reader.Card.WHEEL]), "three alike")
	assert_false(Reader.is_valid_hand([Reader.Card.WHEEL, Reader.Card.STAR]), "two cards")
	assert_false(Reader.is_valid_hand([0, 1, 2, 3]), "four cards")
	assert_false(Reader.is_valid_hand([0, 1, 9]), "a card not in the deck")
	assert_eq(Reader.NAMES.size(), Reader.CARD_COUNT)
	assert_eq(Reader.NAMES[Reader.Card.TOWER], "The Tower")
	assert_eq(Reader.NAMES[Reader.Card.DEATH], "Death")
	assert_eq(Reader.NAMES[Reader.Card.WHEEL], "The Wheel")
	assert_eq(Reader.NAMES[Reader.Card.STAR], "The Star")


# --- the cards ---

func test_the_cards_are_sized_and_named_for_the_tarot_art() -> void:
	assert_eq(TarotCard.SIZE, Vector2(32, 48), "the tarot PNGs are 32x48")
	assert_eq(TarotCard.BACK_ART_ID, "tarot_card_back")
	var stems := ["tarot_tower", "tarot_death", "tarot_wheel", "tarot_star"]
	for card in Reader.CARD_COUNT:
		assert_eq(TarotCard.art_id_of(card, true), stems[card])
		assert_eq(TarotCard.art_id_of(card, false), "tarot_card_back", "face down shows the back")
		assert_eq(TarotCard.name_of(card), Reader.NAMES[card])
	var tarot := TarotCard.new()
	tarot.setup(Reader.Card.DEATH, null)
	assert_eq(tarot.art_id(), "tarot_card_back")
	assert_false(tarot.shows_symbol())
	tarot.turn()
	assert_false(tarot.shows_symbol(), "it flips first")
	tarot.advance(TarotCard.FLIP_TIME * 0.6)
	assert_true(tarot.shows_symbol(), "then its face shows")
	assert_eq(tarot.art_id(), "tarot_death")
	assert_true(TarotCard.FLIP_TIME < Reader.TURN_WINDUP * 0.5, "the flip takes little of the time it shows")
	tarot.free()


func test_the_cards_lie_on_open_floor_in_front_of_her() -> void:
	# In an open room, a row toward him, between them.
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	var origin := Vector2(320, 140)
	for toward in [Vector2(320, 300), Vector2(320, 40), Vector2(520, 150), Vector2(100, 130)]:
		var way := origin.direction_to(toward)
		var spots := Reader.card_spots(origin, toward, room)
		assert_eq(spots.size(), 3)
		for spot in spots:
			assert_true((spot - origin).dot(way) > 20.0, "in front of her toward %s" % str(toward))
			assert_true(spot.distance_to(toward) < origin.distance_to(toward), "between her and him")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var facing := 0
	for seed_value in SEEDS:
		var layout := _layout(MINI_ROOMS[seed_value % 2])
		var bounds := ForemanBehavior.room_rect(layout.size_in_cells())
		var is_open := _is_open(layout)
		var at := _boss_spot(layout, rng, bounds)
		var feet := _open_spot(layout, rng, bounds)
		var spots := Reader.card_spots(at, feet, bounds, is_open)
		assert_eq(spots.size(), 3, "seed %d" % seed_value)
		var body := Rect2(at - Reader.BODY / 2.0, Reader.BODY)
		var middle := Vector2.ZERO
		for i in spots.size():
			middle += spots[i] / 3.0
			var card := Rect2(spots[i] - TarotCard.SIZE / 2.0, TarotCard.SIZE)
			assert_true(bounds.encloses(card), "seed %d: inside the room" % seed_value)
			assert_false(layout.is_solid_at(WalkGrid.cell_of(spots[i])), "seed %d: on open floor" % seed_value)
			assert_false(body.intersects(card), "seed %d: off her body" % seed_value)
			for j in range(i + 1, spots.size()):
				assert_false(card.intersects(Rect2(spots[j] - TarotCard.SIZE / 2.0, TarotCard.SIZE)), "seed %d: apart" % seed_value)
		if (middle - at).dot(feet - at) > 0.0:
			facing += 1
	assert_true(facing >= SEEDS * 0.9, "mostly on his side of her: %d of %d" % [facing, SEEDS])


func test_a_turned_card_shows_its_symbol_and_name_before_it_acts() -> void:
	var grandpa := Target.new()
	grandpa.position = Vector2(330, 250)
	var room := Node2D.new()
	var reader := _celestine(Vector2(320, 120), grandpa)
	room.add_child(reader)
	var behavior := CelestineBehavior.new()
	behavior.forced_hand = [Reader.Card.TOWER, Reader.Card.DEATH, Reader.Card.STAR]
	var shown_at := [-1.0, -1.0, -1.0]
	var acted_at := [-1.0, -1.0, -1.0]
	var said := ["", "", ""]
	var time := 0.0
	var dealt_checked := false
	var last_effect: Node = null
	while time < 12.0:
		_frame(behavior, reader, room)
		time += FRAME
		var cards := behavior.cards()
		if not dealt_checked and behavior.step() == Reader.Step.DEAL and cards.size() == 3:
			dealt_checked = true
			assert_eq(reader._say_text, Reader.DEAL_TEXT, "she says she deals")
			for card in cards:
				assert_false(card.is_face_up(), "dealt face down")
				assert_eq(card.art_id(), TarotCard.BACK_ART_ID)
		for i in cards.size():
			if shown_at[i] < 0.0 and cards[i].shows_symbol():
				shown_at[i] = time
				said[i] = reader._say_text
		var now := behavior.effect()
		if now != null and now != last_effect:
			last_effect = now
			acted_at[behavior._index] = time
		if behavior.step() == Reader.Step.REST and dealt_checked:
			break
	assert_true(dealt_checked, "she dealt")
	for i in 3:
		assert_true(shown_at[i] > 0.0, "card %d was turned" % i)
		assert_true(acted_at[i] > 0.0, "card %d acted" % i)
		assert_true(acted_at[i] - shown_at[i] >= 0.45, "card %d shows its symbol %.2f s first" % [i, acted_at[i] - shown_at[i]])
		assert_true(acted_at[i] - shown_at[i] <= 0.75, "and only briefly, %.2f s" % (acted_at[i] - shown_at[i]))
		assert_eq(said[i], Reader.NAMES[behavior.forced_hand[i]], "she names card %d" % i)
		if i > 0:
			assert_true(shown_at[i] > acted_at[i - 1], "one at a time, in turn")
	assert_eq(behavior.step(), Reader.Step.REST, "the hand ends")
	room.free()
	grandpa.free()


# Every hand she can deal, played out: she holds still, only one card's attack is ever under way, so
# no two cards' hits overlap, and her cards go when the hand is done.
func test_her_cards_act_one_at_a_time_and_never_overlap() -> void:
	var hands: Array = []
	for a in Reader.CARD_COUNT:
		for b in Reader.CARD_COUNT:
			hands.append([a, b, (a + b + 1) % Reader.CARD_COUNT])
	for hand: Array in hands:
		if not Reader.is_valid_hand(hand):
			continue
		var grandpa := Target.new()
		grandpa.position = Vector2(400, 260)
		var room := Node2D.new()
		var reader := _celestine(Vector2(300, 150), grandpa)
		room.add_child(reader)
		var behavior := CelestineBehavior.new()
		behavior.forced_hand = hand
		var time := 0.0
		var began := false
		var attacks_seen := 0
		var last_attack: Node = null
		while time < 15.0:
			_frame(behavior, reader, room)
			time += FRAME
			if behavior.is_dealing():
				began = true
				assert_true(reader.desired_velocity.is_zero_approx(), "%s: she holds still through her hand" % str(hand))
			var live := 0
			for child in room.get_children():
				if _is_attack(child) and not child.is_queued_for_deletion() and not child.is_spent():
					live += 1
			assert_true(live <= 1, "%s: one attack at a time, %d at %.2f" % [str(hand), live, time])
			var now := behavior.effect()
			if now != null and now != last_attack:
				attacks_seen += 1
				last_attack = now
			if began and not behavior.is_dealing():
				break
		assert_eq(attacks_seen, 3, "%s: every card acts" % str(hand))
		assert_eq(behavior.cards().size(), 0, "%s: the hand's cards are let go" % str(hand))
		for child in room.get_children():
			if child is TarotCard:
				assert_true(child._vanishing or child.is_queued_for_deletion(), "%s: its cards fade away" % str(hand))
		room.free()
		grandpa.free()


func test_she_deals_only_with_her_body_in_view_and_chases_until_it_is() -> void:
	var grandpa := Target.new()
	grandpa.position = Vector2(60, 60)
	var room := Node2D.new()
	# A wide room with her far across it, out of what the camera shows round him.
	var reader := _celestine(Vector2(900, 480), grandpa, Vector2i(30, 17))
	room.add_child(reader)
	var behavior := CelestineBehavior.new()
	var time := 0.0
	while time < Reader.FIRST_HAND + 0.5:
		_frame(behavior, reader, room)
		time += FRAME
	assert_false(reader.target_in_view())
	assert_false(behavior.is_dealing(), "no hand off screen")
	assert_true(reader.desired_velocity.length() > reader.def.speed, "she hurries to him")
	room.free()
	grandpa.free()


# --- the Tower ---

func test_the_tower_marks_his_cell_and_others_near_and_leaves_a_step_out() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var cells := Vector2i(20, 11)
	for i in 300:
		var feet := Vector2(rng.randf_range(40.0, 600.0), rng.randf_range(40.0, 310.0))
		var center := WalkGrid.cell_of(feet)
		var chosen := Reader.tower_cells(feet, cells, rng)
		assert_eq(chosen.size(), Reader.TOWER_TILES, "at %s" % str(feet))
		assert_true(chosen.has(center), "his own cell")
		var free_beside := 0
		for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var cell: Vector2i = center + side
			if cell.x >= 1 and cell.y >= 1 and cell.x <= cells.x - 2 and cell.y <= cells.y - 2 and not chosen.has(cell):
				free_beside += 1
		assert_true(free_beside >= 1, "a cell beside his stays clear")
		for k in chosen.size():
			var cell := chosen[k]
			assert_true(maxi(absi(cell.x - center.x), absi(cell.y - center.y)) <= Reader.TOWER_REACH, "near him")
			assert_true(cell.x >= 1 and cell.y >= 1 and cell.x <= cells.x - 2 and cell.y <= cells.y - 2, "inside the walls")
			assert_eq(chosen.find(cell), k, "no cell twice")
	# A step from anywhere in his cell to the next one fits in the warning, after reacting.
	var walk := PlayerStats.BASE_SPEED * (Reader.TOWER_WINDUP - OverlapRoute.REACT)
	assert_true(walk > RoomBackdrop.TILE + Player.FEET_BOX_SIZE.x / 2.0 + TowerTiles.HIT_SPARE, "%f" % walk)
	assert_true(Reader.TOWER_WINDUP * PlayerStats.BASE_WARNING >= 0.2)


func test_tower_tiles_fall_once_on_feet_in_their_squares() -> void:
	var grandpa := Target.new()
	var room := Node2D.new()
	var reader := _celestine(Vector2(100, 100), grandpa)
	room.add_child(reader)
	var cells: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5)]
	for case in [[Vector2(176, 176), 1], [Vector2(208, 170), 1], [Vector2(176, 220), 0], [Vector2(250, 176), 0]]:
		grandpa.position = case[0]
		var tiles := TowerTiles.new()
		tiles.setup(reader, cells, Reader.TOWER_WINDUP, Reader.TOWER_DAMAGE)
		room.add_child(tiles)
		grandpa.hits = 0
		if case[1] == 1:
			assert_eq(tiles.threat_at(case[0], false), 2, "a simulated player reads the coming fall")
		var time := 0.0
		while time < Reader.TOWER_WINDUP + 0.3:
			tiles._process(FRAME)
			time += FRAME
			if time < Reader.TOWER_WINDUP - 0.05:
				assert_eq(grandpa.hits, 0, "nothing before the fall")
		assert_eq(grandpa.hits, case[1], "standing at %s" % str(case[0]))
		assert_true(tiles.is_spent())
		room.remove_child(tiles)
		tiles.free()
	room.free()
	grandpa.free()


# --- Death ---

func test_death_sweeps_its_marked_arc_and_costs_two_pills() -> void:
	assert_eq(Reader.DEATH_DAMAGE, Enemy.HEAVY_DAMAGE)
	assert_eq(Reader.DEATH_DAMAGE, 2)
	var grandpa := Target.new()
	var room := Node2D.new()
	var reader := _celestine(Vector2(200, 200), grandpa)
	room.add_child(reader)
	var inside := Vector2(200, 200) + Vector2.from_angle(0.3) * 80.0
	for case in [[inside, 1], [Vector2(200, 200) + Vector2.from_angle(1.2) * 80.0, 0], [Vector2(200, 200) + Vector2(ScytheSweep.RADIUS + 12.0, 0.0), 0], [Vector2(150, 200), 0]]:
		grandpa.position = case[0]
		grandpa.hits = 0
		grandpa.pills = 0
		for clockwise in [true, false]:
			var before := grandpa.hits
			var scythe := ScytheSweep.new()
			scythe.setup(reader, 0.0, Reader.DEATH_WINDUP, Reader.DEATH_DAMAGE, clockwise)
			room.add_child(scythe)
			scythe.global_position = Vector2(200, 200)
			var time := 0.0
			while time < Reader.DEATH_WINDUP + ScytheSweep.SWEEP_TIME + 0.2:
				scythe._process(FRAME)
				time += FRAME
				if time < Reader.DEATH_WINDUP - 0.02:
					assert_eq(grandpa.hits, before, "nothing while it is warned")
			assert_true(scythe.is_spent())
			room.remove_child(scythe)
			scythe.free()
		assert_eq(grandpa.hits, case[1] * 2, "at %s, either way round" % str(case[0]))
		assert_eq(grandpa.pills, case[1] * 4)
	room.free()
	grandpa.free()


func test_the_scythe_leaves_time_to_step_out_of_its_arc() -> void:
	# From the worst spot in the arc, the shorter way out (sideways or outward) fits in the warning.
	var worst := 0.0
	var distance := 1.0
	while distance <= ScytheSweep.RADIUS:
		worst = maxf(worst, minf(distance * sin(ScytheSweep.HALF_ARC), ScytheSweep.RADIUS - distance))
		distance += 1.0
	var walk := PlayerStats.BASE_SPEED * (Reader.DEATH_WINDUP - OverlapRoute.REACT)
	assert_true(walk > worst + Player.FEET_BOX_SIZE.x, "%f against %f" % [walk, worst])
	assert_true(Reader.DEATH_WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	# Its blade passes over feet however long a frame takes.
	assert_true(ScytheSweep.swept_over(Vector2.ZERO, 0.0, true, 0.0, ScytheSweep.HALF_ARC * 2.0, Vector2(60, 0)))
	assert_false(ScytheSweep.swept_over(Vector2.ZERO, 0.0, true, 0.0, 0.2, Vector2(60, 0)), "not before the blade comes")


# --- the Wheel ---

func test_the_wheel_spins_round_her_with_gaps_and_clear_ground_inside_and_out() -> void:
	var gap := TAU / WheelRing.BLADES - WheelRing.BLADE_ARC
	assert_true(gap >= deg_to_rad(30.0), "gaps between the blades")
	assert_true(WheelRing.INNER > (Reader.BODY / 2.0).length(), "a clear ring round her body")
	assert_false(WheelRing.in_band(Vector2.ZERO, Vector2(WheelRing.OUTER + 2.0, 0.0)), "clear outside")
	assert_false(WheelRing.in_band(Vector2.ZERO, Vector2(WheelRing.INNER - 2.0, 0.0)), "clear inside")
	var middle := (WheelRing.INNER + WheelRing.OUTER) / 2.0
	assert_true(WheelRing.under_blade(Vector2.ZERO, 0.0, Vector2.from_angle(WheelRing.BLADE_ARC * 0.5) * middle))
	assert_false(WheelRing.under_blade(Vector2.ZERO, 0.0, Vector2.from_angle(WheelRing.BLADE_ARC + gap * 0.5) * middle), "a gap")
	# Half the band's width out of it, after reacting, fits in the warning before it turns.
	var walk := PlayerStats.BASE_SPEED * (Reader.WHEEL_WINDUP - OverlapRoute.REACT)
	assert_true(walk > (WheelRing.OUTER - WheelRing.INNER) / 2.0 + Player.FEET_BOX_SIZE.x, "%f" % walk)
	assert_true(Reader.WHEEL_WINDUP * PlayerStats.BASE_WARNING >= 0.2)


func test_the_wheel_waits_its_warning_then_a_blade_costs_a_pill_once() -> void:
	var grandpa := Target.new()
	var room := Node2D.new()
	var reader := _celestine(Vector2(200, 200), grandpa)
	room.add_child(reader)
	var middle := (WheelRing.INNER + WheelRing.OUTER) / 2.0
	for case in [[Vector2(200, 200) + Vector2(middle, 0.0), 1], [Vector2(200, 200) + Vector2(WheelRing.OUTER + 10.0, 0.0), 0], [Vector2(200, 200) + Vector2(0.0, WheelRing.INNER - 8.0), 0]]:
		grandpa.position = case[0]
		grandpa.hits = 0
		var wheel := WheelRing.new()
		wheel.setup(reader, Reader.WHEEL_WINDUP, 0.5, true, Reader.WHEEL_DAMAGE)
		room.add_child(wheel)
		wheel.global_position = Vector2(200, 200)
		var start := wheel.angle()
		var time := 0.0
		while time < Reader.WHEEL_WINDUP + WheelRing.SPIN_TIME + 0.2:
			wheel._process(FRAME)
			time += FRAME
			if time < Reader.WHEEL_WINDUP - 0.02:
				assert_eq(grandpa.hits, 0, "nothing while it is warned")
				assert_near(wheel.angle(), start, "and it does not turn yet")
		assert_eq(grandpa.hits, case[1], "at %s" % str(case[0]))
		assert_true(wheel.is_spent())
		room.remove_child(wheel)
		wheel.free()
	room.free()
	grandpa.free()


# --- the Star ---

func test_the_stars_land_on_him_near_him_apart_and_in_a_stagger() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	for i in 200:
		var inside := room.grow(-Player.FEET_BOX_SIZE.x / 2.0)
		var feet := Vector2(rng.randf_range(inside.position.x, inside.end.x), rng.randf_range(inside.position.y, inside.end.y))
		var spots := Reader.star_spots(feet, rng, room)
		assert_eq(spots.size(), Reader.STARS, "every star has a spot")
		assert_true(spots[0].distance_to(feet) <= StarFall.RADIUS, "the first on him")
		for a in spots.size():
			assert_true(spots[a].distance_to(feet) <= Reader.STAR_REACH + 0.01, "near him")
			assert_true(room.grow(-StarFall.RADIUS + 0.01).has_point(spots[a]), "inside the room")
			for b in range(a + 1, spots.size()):
				assert_true(spots[a].distance_to(spots[b]) >= StarFall.RADIUS * 2.0, "apart")
	var stars := StarFall.new()
	var spots: Array[Vector2] = [Vector2(100, 100), Vector2(160, 100), Vector2(100, 160)]
	stars.setup(null, spots, Reader.STAR_WINDUP)
	assert_near(stars.lands_in(0), Reader.STAR_WINDUP)
	assert_near(stars.lands_in(2) - stars.lands_in(1), StarFall.STEP, "a short stagger")
	assert_eq(stars.advance(Reader.STAR_WINDUP + 0.01, Vector2(100, 100)), 1, "his spot lands on him")
	assert_eq(stars.advance(StarFall.STEP * 2.0, Vector2(100, 100)), 0, "the others miss him there")
	assert_true(stars.is_spent())
	stars.free()
	var walk := PlayerStats.BASE_SPEED * (Reader.STAR_WINDUP - OverlapRoute.REACT)
	assert_true(walk > StarFall.RADIUS + Player.FEET_BOX_SIZE.x, "%f" % walk)
	assert_true(Reader.STAR_WINDUP * PlayerStats.BASE_WARNING >= 0.2)


# --- every card leaves a way out, in her own rooms ---

func _attack_for(card: int, reader: Enemy, at: Vector2, feet: Vector2, layout: RoomLayout, rng: RandomNumberGenerator) -> Node2D:
	var bounds := ForemanBehavior.room_rect(layout.size_in_cells())
	var is_open := _is_open(layout)
	match card:
		Reader.Card.TOWER:
			var tiles := TowerTiles.new()
			var body := Rect2(at - Reader.BODY / 2.0, Reader.BODY)
			var chosen := Reader.tower_plan(feet, layout.size_in_cells(), rng, is_open, body)
			assert_true(chosen.has(WalkGrid.cell_of(feet)), "a tile always falls on his own cell")
			tiles.setup(reader, chosen, Reader.TOWER_WINDUP)
			return tiles
		Reader.Card.DEATH:
			var scythe := ScytheSweep.new()
			scythe.setup(reader, (feet - at).angle(), Reader.DEATH_WINDUP, Reader.DEATH_DAMAGE)
			scythe.position = at
			return scythe
		Reader.Card.WHEEL:
			var wheel := WheelRing.new()
			wheel.setup(reader, Reader.WHEEL_WINDUP)
			wheel.position = at
			return wheel
	var stars := StarFall.new()
	stars.setup(reader, Reader.star_spots(feet, rng, bounds, is_open), Reader.STAR_WINDUP)
	return stars


func test_every_card_leaves_a_way_out_in_her_rooms() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for card in Reader.CARD_COUNT:
		var safe := 0
		for seed_value in SEEDS:
			var layout := _layout(MINI_ROOMS[seed_value % 2])
			var bounds := ForemanBehavior.room_rect(layout.size_in_cells())
			var at := _boss_spot(layout, rng, bounds)
			var feet := _open_spot(layout, rng, bounds)
			if feet.distance_to(at) < 50.0:
				feet = _open_spot(layout, rng, bounds)
			var body := Rect2(at - Reader.BODY / 2.0, Reader.BODY)
			if body.grow(Player.FEET_BOX_SIZE.x).has_point(feet):
				safe += 1
				continue
			var node := _attack_for(card, null, at, feet, layout, rng)
			var shapes := ProjectionistBehavior.live_shapes([node])
			var route := ProjectionistBehavior.route_with(bounds, shapes, body, _is_open(layout))
			if route.escape(feet)["safe"]:
				safe += 1
			else:
				print("%s: no way out, her at %s, him at %s" % [Reader.NAMES[card], str(at), str(feet)])
			node.free()
		print("%s: %d of %d leave a way out" % [Reader.NAMES[card], safe, SEEDS])
		assert_true(safe >= SEEDS - 2, "%s leaves a way out: %d of %d" % [Reader.NAMES[card], safe, SEEDS])


# The shapes each attack shows a planner hold its hit, and end when it can hurt no more, which is when
# she turns the next card, so each later card's hit always comes after the last one's.
func test_each_attack_shows_a_planner_its_hit_and_ends_before_the_next_card() -> void:
	var tiles := TowerTiles.new()
	var tower_cells: Array[Vector2i] = [Vector2i(5, 5)]
	tiles.setup(null, tower_cells, Reader.TOWER_WINDUP)
	var scythe := ScytheSweep.new()
	scythe.setup(null, 0.0, Reader.DEATH_WINDUP)
	scythe.position = Vector2(200, 200)
	var wheel := WheelRing.new()
	wheel.setup(null, Reader.WHEEL_WINDUP)
	wheel.position = Vector2(200, 200)
	var stars := StarFall.new()
	var star_spots: Array[Vector2] = [Vector2(100, 100), Vector2(150, 100), Vector2(100, 150), Vector2(150, 150), Vector2(200, 100)]
	stars.setup(null, star_spots, Reader.STAR_WINDUP)
	var nodes := {Reader.Card.TOWER: tiles, Reader.Card.DEATH: scythe, Reader.Card.WHEEL: wheel, Reader.Card.STAR: stars}
	var points := {Reader.Card.TOWER: Vector2(176, 176), Reader.Card.DEATH: Vector2(260, 200), Reader.Card.WHEEL: Vector2(260, 200), Reader.Card.STAR: Vector2(150, 150)}
	for card: int in nodes:
		var node: Node2D = nodes[card]
		var shapes := ProjectionistBehavior.live_shapes([node])
		var last_end := 0.0
		var covered := false
		var point: Vector2 = points[card]
		for shape: Array in shapes["rects"]:
			last_end = maxf(last_end, (shape[1] as Vector2).y)
			if (shape[0] as Rect2).has_point(point):
				covered = true
		for shape: Array in shapes["circles"]:
			last_end = maxf(last_end, (shape[1] as Vector2).y)
			var circle: Vector3 = shape[0]
			if Vector2(circle.x, circle.y).distance_to(point) <= circle.z:
				covered = true
		assert_true(covered, "%s shows a planner where it hits" % Reader.NAMES[card])
		assert_true(last_end >= Reader.act_time(card) - 0.01, "%s holds its whole hit" % Reader.NAMES[card])
		assert_true(last_end <= Reader.act_time(card) + 0.1, "%s ends when it is spent" % Reader.NAMES[card])
		assert_eq(node.threat_at(point, false), 2, "%s tells a simulated player its coming hit" % Reader.NAMES[card])
		assert_eq(node.threat_at(Vector2(2000, 2000), false), 0, "and nothing far away")
		# The next card's hit comes no sooner than its turn and its warning after this one is spent.
		for next in Reader.CARD_COUNT:
			assert_true(Reader.CARD_GAP + Reader.TURN_WINDUP + Reader.windup_of(next) >= 1.5, "a breath between cards")
		node.free()


func test_every_hazard_she_leaves_answers_a_simulated_players_questions() -> void:
	var nodes: Array[Node] = [TowerTiles.new(), ScytheSweep.new(), WheelRing.new(), StarFall.new()]
	for node in nodes:
		var name: String = node.get_script().get_global_name()
		assert_true(node.has_method("threat_at") and node.has_method("threat_imminent"), name)
		assert_true(node.has_method("route_rects") or node.has_method("route_circles"), "%s shows a planner its shapes" % name)
		assert_true(node.has_method("is_spent"), "%s says when it is done" % name)
		node.free()


func test_her_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [TarotCard.new(), TowerTiles.new(), ScytheSweep.new(), WheelRing.new(), StarFall.new()]
	for effect in effects:
		assert_true(SeanceProps.is_passing_effect(effect), "the hotline knows %s lingers" % effect.get_script().get_global_name())
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()


# --- her numbers ---

func test_celestine_is_at_least_as_hard_as_barbara_klaus_the_reverend_and_crabtree() -> void:
	var def := _load("celestine")
	assert_true(def.is_boss)
	assert_eq(def.id, "celestine")
	assert_eq(def.display_name, "Sister Celestine, Tarot Reader")
	assert_eq(def.body_size, Vector2(32, 40))
	assert_eq(def.body_size, Reader.BODY)
	assert_eq(def.art(), "celestine")
	assert_true(absf(def.max_hp * HOTLINE_HEALTH - 760.0) < 0.5, str(def.max_hp * HOTLINE_HEALTH))
	assert_near(def.speed, 75.0)
	assert_eq(def.pension_drop, 8)
	assert_eq(def.summon, null, "she calls no one")
	assert_true(def.behavior_script.new() is CelestineBehavior)
	for id in ["activities_coordinator", "foreman_klaus"]:
		assert_true(def.max_hp * HOTLINE_HEALTH >= _load(id).max_hp * FLOOR_TWO_HEALTH, id)
	for id in ["reverend", "crabtree"]:
		assert_true(def.max_hp * HOTLINE_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH, id)
	assert_true(def.speed >= _load("crabtree").speed, "as quick as Crabtree")
	assert_true(Reader.COOLDOWN <= ReverendBehavior.COOLDOWN, "rests no longer than the Reverend")
	assert_true(Reader.COOLDOWN <= CrabtreeBehavior.COOLDOWN, "or Crabtree")
	assert_true(Reader.COOLDOWN <= ActivitiesCoordinatorBehavior.COOLDOWN)
	assert_true(Reader.COOLDOWN <= ForemanBehavior.COOLDOWN)
	assert_eq(Reader.HAND, 3, "three attacks to a hand")
	assert_true(Reader.DEATH_DAMAGE >= Enemy.HEAVY_DAMAGE, "Death hits harder than the rest")
	assert_true(Reader.DEATH_DAMAGE < Enemy.HEAVIEST_DAMAGE, "but a mini boss keeps the heaviest hit for the floor bosses")


func test_she_holds_the_hotlines_mini_boss_room_with_her_poster() -> void:
	var floor_def: FloorDef = load("res://data/floors/seance_hotline.tres")
	assert_eq(floor_def.mini_boss.id, "celestine")
	assert_true(ResourceLoader.exists("res://data/bounties/celestine.tres"), "she has a poster")
	for gone in ["chip", "gopher"]:
		assert_false(ResourceLoader.exists("res://data/enemies/%s.tres" % gone), "%s is retired" % gone)


# Her ochre is her own: apart from every body of the floor, and from the warning red, the mint and the
# violet carpet.
func test_her_colour_and_mark_are_her_own() -> void:
	var def := _load("celestine")
	assert_true(SeanceMarks.draws(def.mark), "her headscarf, shawl and cards")
	var floor_def: FloorDef = load("res://data/floors/seance_hotline.tres")
	var body := SpriteVisual.readable(def.color)
	var others: Array[EnemyDef] = []
	others.assign(floor_def.enemies)
	others.append(_load("ectoplasm"))
	for other in others:
		assert_true(_difference(body, SpriteVisual.readable(other.color)) >= 0.25, "apart from %s" % other.id)
	assert_true(_difference(body, Enemy.WARNING_COLOR) >= 0.4, "far from the warning red")
	assert_true(_difference(body, SafeSpotMark.COLOR) >= 0.3, "and the mint")
	var carpet := floor_def.room_palette().floor_a
	var gap := absf(body.h - carpet.h)
	assert_true(minf(gap, 1.0 - gap) >= 0.1, "and the carpet's violet")


# --- Madame Zara, the Medium ---

const Medium := preload("res://scripts/actors/behaviors/madame_zara_behavior.gd")
const BOSS_ROOMS := ["floor_boss_01", "floor_boss_large_01"]
const ZARA_BODY := Vector2(44, 52)


# A stand-in for Grandpa that a line can hold, counting its hits and holds.
class LeashTarget extends Node2D:
	var hits := 0
	var pills := 0
	var held_at := Vector2.INF
	var held_reach := 0.0
	var held_left := 0.0
	var let_go := 0

	func take_hit(amount: int, _source = null) -> bool:
		hits += 1
		pills += amount
		return true

	func leash_to(center: Vector2, radius: float, seconds: float) -> void:
		held_at = center
		held_reach = radius
		held_left = seconds

	func end_leash() -> void:
		held_left = 0.0
		let_go += 1

	func is_leashed() -> bool:
		return held_left > 0.0

	func leash_center() -> Vector2:
		return held_at


func _zara(at: Vector2, grandpa: Node2D, cells := Vector2i(20, 11)) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(_load("madame_zara"), grandpa, 0.5)
	enemy.room_cells = cells
	enemy.position = at
	return enemy


func _medium_frame(behavior: MadameZaraBehavior, enemy: Enemy, room: Node2D) -> void:
	enemy.desired_velocity = Vector2.ZERO
	enemy._holding_lane = false
	behavior.tick(enemy, FRAME)
	for child in room.get_children():
		if child != enemy and not child.is_queued_for_deletion() and child.has_method("_process"):
			child._process(FRAME)


# Her middle on open floor with her whole body over open cells.
func _zara_spot(layout: RoomLayout, rng: RandomNumberGenerator, room: Rect2) -> Vector2:
	for i in 400:
		var spot := _open_spot(layout, rng, room.grow(-26.0))
		var body := Rect2(spot - ZARA_BODY / 2.0, ZARA_BODY)
		var clear := true
		for corner in [body.position, body.end, Vector2(body.position.x, body.end.y), Vector2(body.end.x, body.position.y)]:
			if layout.is_solid_at(WalkGrid.cell_of(corner)):
				clear = false
		if clear:
			return spot
	return room.get_center()


# A walk of his last two seconds ending at his feet, at his pace or slower, turning now and then.
func _trail_near(feet: Vector2, rng: RandomNumberGenerator, bounds: Rect2) -> PackedVector2Array:
	var points: Array[Vector2] = [feet]
	var way := Vector2.from_angle(rng.randf() * TAU)
	var pace := rng.randf_range(0.0, PlayerStats.BASE_SPEED)
	var steps := roundi(FeetTrail.LENGTH / Medium.TRAIL_STEP)
	for k in steps:
		if rng.randf() < 0.1:
			way = Vector2.from_angle(rng.randf() * TAU)
		var last := points[points.size() - 1]
		points.append((last - way * pace * Medium.TRAIL_STEP).clamp(bounds.position + Vector2(8, 8), bounds.end - Vector2(8, 8)))
	points.reverse()
	return PackedVector2Array(points)


# Whether a planner's mark is a fair one: well off her body, on floor he may stand on, and either never
# covered by anything under way or clear of it by the time he can walk there. Returns whether one was
# given.
func _check_mark(mark: Vector2, route: OverlapRoute, body: Rect2, feet: Vector2, label: String) -> bool:
	if mark == Vector2.INF:
		return false
	assert_false(body.grow(SafeSpotMark.RADIUS + ProjectionistBehavior.MARK_CLEARANCE).has_point(mark), "%s: well off her body" % label)
	assert_false(route.is_blocked_at(mark), "%s: on open floor" % label)
	var walk := OverlapRoute.REACT + (absf(mark.x - feet.x) + absf(mark.y - feet.y)) / PlayerStats.BASE_SPEED + OverlapRoute.STEP_TIME * 2.0
	assert_true(route.danger_end_at(mark) <= walk, "%s: clear once he gets there (%f against %f)" % [label, route.danger_end_at(mark), walk])
	return true


# --- her numbers ---

func test_madame_zara_is_clearly_harder_than_mortimer_and_the_projectionist_and_in_line_with_the_commodore() -> void:
	var def := _load("madame_zara")
	assert_true(def.is_boss)
	assert_eq(def.id, "madame_zara")
	assert_eq(def.display_name, "Madame Zara, the Medium")
	assert_eq(def.body_size, ZARA_BODY)
	assert_eq(def.art(), "madame_zara")
	assert_true(absf(def.max_hp * HOTLINE_HEALTH - 1950.0) < 0.5, str(def.max_hp * HOTLINE_HEALTH))
	assert_near(def.speed, 80.0)
	assert_eq(def.pension_drop, 16)
	assert_eq(def.summon.id, "ectoplasm", "she manifests the hotline's own summon")
	assert_true(def.behavior_script.new() is MadameZaraBehavior)
	for id in ["mortimer_grimsby", "projectionist"]:
		assert_true(def.max_hp * HOTLINE_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH * 1.1, id)
	var commodore := _load("commodore_wellington")
	assert_true(absf(def.max_hp - commodore.max_hp) < 0.5, "as tough as the other fourth-floor boss")
	assert_true(def.body_size.x >= _load("mortimer_grimsby").body_size.x)
	assert_true(Medium.BASE_COOLDOWN < FuneralDirectorBehavior.BASE_COOLDOWN)
	assert_true(Medium.BASE_COOLDOWN < ProjectionistBehavior.BASE_COOLDOWN)
	assert_true(Medium.PHASE_TWO_COOLDOWN < ProjectionistBehavior.PHASE_TWO_COOLDOWN)
	assert_true(Medium.BASE_COOLDOWN <= CommodoreBehavior.BASE_COOLDOWN)
	assert_true(Medium.PHASE_TWO_COOLDOWN <= CommodoreBehavior.PHASE_TWO_COOLDOWN)
	assert_eq(Medium.OUIJA_DAMAGE, Enemy.HEAVIEST_DAMAGE)
	assert_true(Medium.OUIJA_DAMAGE > Enemy.HEAVY_DAMAGE)
	assert_eq(Medium.POSSESSION_DAMAGE, 1)
	assert_eq(SpiritSwoop.DAMAGE, 1)


func test_she_holds_the_hotlines_boss_room_with_her_poster_and_memento() -> void:
	var floor_def: FloorDef = load("res://data/floors/seance_hotline.tres")
	assert_eq(floor_def.floor_boss.id, "madame_zara")
	assert_true(ResourceLoader.exists("res://data/bounties/madame_zara.tres"), "she has a poster")
	var found := false
	for entry: Dictionary in Mementos.ALL:
		if entry["boss"] == "madame_zara":
			found = true
			assert_eq(entry["path"], "seance_hotline")
	assert_true(found, "her memento")
	for gone in ["thaddeus_fairweather", "caddie"]:
		assert_false(ResourceLoader.exists("res://data/enemies/%s.tres" % gone), "%s is retired" % gone)
	for gone in ["club_president_behavior", "caddie_behavior"]:
		assert_false(ResourceLoader.exists("res://scripts/actors/behaviors/%s.gd" % gone), "%s is retired" % gone)
	assert_false(ResourceLoader.exists("res://tests/support/pending_bosses.gd"), "no stand-in bosses are left")


func test_madame_zaras_colour_and_mark_are_her_own() -> void:
	var def := _load("madame_zara")
	assert_true(SeanceMarks.draws(def.mark), "her turban, beads and receiver")
	var floor_def: FloorDef = load("res://data/floors/seance_hotline.tres")
	var body := SpriteVisual.readable(def.color)
	var others: Array[EnemyDef] = []
	others.assign(floor_def.enemies)
	others.append(floor_def.mini_boss)
	others.append(_load("ectoplasm"))
	for other in others:
		assert_true(_difference(body, SpriteVisual.readable(other.color)) >= 0.25, "apart from %s" % other.id)
	assert_true(_difference(body, Enemy.WARNING_COLOR) >= 0.4, "far from the warning red")
	assert_true(_difference(body, SafeSpotMark.COLOR) >= 0.3, "and the mint")
	var carpet := floor_def.room_palette().floor_a
	var gap := absf(body.h - carpet.h)
	assert_true(minf(gap, 1.0 - gap) >= 0.1, "and the carpet's violet")


func test_she_has_no_hold_music() -> void:
	for path in ["res://scripts/actors/behaviors/madame_zara_behavior.gd", "res://scripts/world/line_tether.gd", "res://scripts/world/ouija_board.gd",
			"res://scripts/world/ouija_planchette.gd", "res://scripts/world/possession_ghost.gd", "res://scripts/world/seance_circle.gd",
			"res://scripts/world/spirit_swoop.gd"]:
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.is_empty(), path)
		assert_false(source.contains("HoldMusic"), "%s plays no hold music" % path)
		assert_false(source.contains("hold_music"), path)


func test_she_plays_her_own_anims() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/behaviors/madame_zara_behavior.gd")
	assert_true(source.contains("_anim(enemy, \"tether_call\""), "On the Line plays tether_call")
	assert_true(source.contains("_anim(enemy, \"possession\""), "Possession plays possession")
	assert_true(source.contains("enemy.play_anim(anim, seconds)"))


func test_she_never_does_the_same_twice_running() -> void:
	for last in [MadameZaraBehavior.Attack.NONE, MadameZaraBehavior.Attack.LINE, MadameZaraBehavior.Attack.OUIJA, MadameZaraBehavior.Attack.POSSESSION]:
		var seen := {}
		for i in 30:
			var attack := Medium.choose_attack(last, i / 30.0)
			assert_true(attack != last, "not %d twice" % last)
			seen[attack] = true
		assert_eq(seen.size(), 3 if last == MadameZaraBehavior.Attack.NONE else 2)
	for i in 30:
		assert_true(Medium.choose_attack(MadameZaraBehavior.Attack.NONE, i / 30.0, false) != MadameZaraBehavior.Attack.POSSESSION, "no possession without his last two seconds")
		assert_true(Medium.choose_attack(MadameZaraBehavior.Attack.NONE, i / 30.0, true, true) != MadameZaraBehavior.Attack.LINE, "no call while a line holds")


# --- every warning leaves time ---

func test_every_attack_of_hers_warns_long_enough_to_step_out() -> void:
	var react := OverlapRoute.REACT
	for phase_two in [false, true]:
		for attack in [MadameZaraBehavior.Attack.LINE, MadameZaraBehavior.Attack.OUIJA, MadameZaraBehavior.Attack.POSSESSION]:
			assert_true(Medium.windup_for(attack, phase_two) * PlayerStats.BASE_WARNING >= 0.2 - 0.001, "%d in phase two %s" % [attack, str(phase_two)])
		# Off the planchette's band from its middle, after reacting.
		var walk := PlayerStats.BASE_SPEED * (Medium.windup_for(MadameZaraBehavior.Attack.OUIJA, phase_two) - react)
		assert_true(walk > OuijaPlanchette.RADIUS + Player.FEET_BOX_SIZE.x, "the board: %f" % walk)
		# Clear of where the copy rises, after reacting.
		walk = PlayerStats.BASE_SPEED * (Medium.windup_for(MadameZaraBehavior.Attack.POSSESSION, phase_two) - react)
		assert_true(walk > PossessionGhost.REACH + Player.FEET_BOX_SIZE.x / 2.0, "the copy: %f" % walk)
	# A spirit's ring, or a step into the light beside it.
	var spirit_walk := PlayerStats.BASE_SPEED * (SpiritSwoop.WARNING - react)
	assert_true(spirit_walk > SpiritSwoop.RADIUS + Player.FEET_BOX_SIZE.x, "%f" % spirit_walk)
	assert_true(SpiritSwoop.WARNING * PlayerStats.BASE_WARNING >= 0.2)
	# The line shows its circle round him and hurts nothing, so staying inside costs nothing to read.
	assert_true(LineTether.RADIUS >= 72.0 and LineTether.RADIUS <= 90.0)
	assert_near(LineTether.HOLD, 3.0)


# --- the Ouija board ---

func test_the_board_lays_a_letter_grid_of_a_to_z_yes_and_no() -> void:
	assert_eq(OuijaBoard.LABELS.size(), OuijaBoard.COLUMNS * OuijaBoard.ROWS)
	for code in range(65, 91):
		assert_true(OuijaBoard.LABELS.has(String.chr(code)), String.chr(code))
	assert_true(OuijaBoard.LABELS.has("YES") and OuijaBoard.LABELS.has("NO"))
	for cells in [Vector2i(20, 11), Vector2i(30, 17)]:
		var room := ForemanBehavior.room_rect(cells)
		var slots := OuijaBoard.slots(room)
		assert_eq(slots.size(), OuijaBoard.LABELS.size())
		for i in slots.size():
			assert_true(room.grow(-OuijaBoard.INSET + 0.01).has_point(slots[i]), "inside the room")
			for j in range(i + 1, slots.size()):
				assert_true(slots[i].distance_to(slots[j]) >= 60.0, "letters apart")
		var path := OuijaBoard.word_path("HELLO", room)
		assert_eq(path.size(), 5)
		assert_eq(path[0], slots[OuijaBoard.slot_of("H")])
		assert_eq(path[2], path[3], "it rests twice on a doubled letter")
	for word in Medium.WORDS:
		assert_eq(OuijaBoard.word_path(word, ForemanBehavior.room_rect(Vector2i(20, 11))).size(), word.length(), "%s is spelt on the board" % word)
	var board := OuijaBoard.new()
	board.setup(null, ForemanBehavior.room_rect(Vector2i(20, 11)))
	assert_eq(board.z_index, OuijaBoard.BOARD_Z, "under the bodies")
	assert_true(OuijaBoard.BOARD_Z < 0 and OuijaBoard.BOARD_Z > -10, "flat on the floor, over the carpet")
	board.free()
	# The carpet's pattern is scattered stars and moons; the board is one framed grid of letters.
	assert_true(OuijaBoard.LABELS.size() >= 28)


func test_the_planchette_costs_three_pills_and_shows_its_whole_path_outlined_twice() -> void:
	assert_true(Medium.OUIJA_SHOWN_WHOLE)
	assert_near(Medium.OUIJA_WINDUP, 1.2)
	for phase_two in [false, true]:
		assert_near(Medium.windup_for(MadameZaraBehavior.Attack.OUIJA, phase_two), 1.2, "never shortened")
	assert_eq(OuijaPlanchette.ART_SIZE, Vector2(32, 32), "sized to planchette.png")
	assert_near(OuijaPlanchette.RADIUS, OuijaPlanchette.ART_SIZE.x / 2.0)
	var source := FileAccess.get_file_as_string("res://scripts/world/ouija_planchette.gd")
	assert_true(source.contains("grow(Enemy.HEAVIEST_LANE_GAP)") and source.contains("RADIUS + Enemy.HEAVIEST_LANE_GAP"), "the second outline")
	var grandpa := Target.new()
	var room := Node2D.new()
	var zara := _zara(Vector2(500, 260), grandpa)
	room.add_child(zara)
	var telegraph := Telegraph.new()
	telegraph.start(Medium.OUIJA_WINDUP)
	zara.set_warning(telegraph, Medium.WARNING_RADIUS, Medium.OUIJA_SHOWN_WHOLE)
	assert_near(zara._warning_share(), 1.0, "whatever his warning stat")
	var path: Array[Vector2] = [Vector2(100, 100), Vector2(300, 100), Vector2(300, 200)]
	for case in [[Vector2(200, 104), 1], [Vector2(305, 160), 1], [Vector2(200, 140), 0], [Vector2(320, 260), 0]]:
		grandpa.position = case[0]
		grandpa.hits = 0
		grandpa.pills = 0
		var planchette := OuijaPlanchette.new()
		planchette.setup(zara, path, Medium.OUIJA_WINDUP, Medium.OUIJA_DAMAGE)
		room.add_child(planchette)
		if case[1] == 1:
			assert_eq(planchette.threat_at(case[0], false), 2, "a simulated player reads the coming slide")
		var time := 0.0
		while time < planchette.total_time() + 0.1:
			planchette._process(FRAME)
			time += FRAME
			if time < Medium.OUIJA_WINDUP - 0.02:
				assert_eq(grandpa.hits, 0, "nothing in the windup")
				assert_true(planchette.is_warning())
		assert_eq(grandpa.hits, case[1], "at %s" % str(case[0]))
		assert_eq(grandpa.pills, case[1] * 3)
		if is_instance_valid(planchette):
			room.remove_child(planchette)
			planchette.free()
	room.free()
	grandpa.free()


func test_the_slide_sampled_for_a_plan_covers_the_planchette_at_every_moment() -> void:
	for cells in [Vector2i(20, 11), Vector2i(30, 17)]:
		var fits := Medium.words_by_nearness(ForemanBehavior.room_rect(cells), Vector2(200, 200)).size()
		assert_true(fits >= 10, "most words are quick enough to spell in a %s room: %d" % [str(cells), fits])
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	var path := OuijaBoard.word_path("HELLO", room)
	var total := OuijaPlanchette.slide_time(path)
	assert_true(total > 1.0 and total <= Medium.OUIJA_LONGEST, "%f" % total)
	var shapes := OuijaPlanchette.plan_circles(path, 0.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in 300:
		var t := rng.randf_range(0.0, total)
		var point := OuijaPlanchette.position_at(path, t) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, OuijaPlanchette.RADIUS)
		var found := false
		for shape: Array in shapes:
			var circle: Vector3 = shape[0]
			var window: Vector2 = shape[1]
			if t + 0.4 >= window.x - 0.001 and t + 0.4 <= window.y + 0.001 and point.distance_to(Vector2(circle.x, circle.y)) <= circle.z:
				found = true
				break
		assert_true(found, "t %f at %s" % [t, str(point)])
	# A plan made part way through holds only what is left, counted from now.
	var later := OuijaPlanchette.plan_circles(path, 0.0, total * 0.5)
	for shape: Array in later:
		assert_true((shape[1] as Vector2).y >= 0.0)
		assert_true((shape[1] as Vector2).y <= total * 0.5 + 0.2)


# Over 200 plans in her two rooms, with her and Grandpa anywhere, over a possession under way, inside a
# line's circle or inside the seance circle's light: whenever he still has a way out of what is under
# way, she finds a word whose slide leaves him one, and a mark nothing ever covers.
func test_every_ouija_path_leaves_a_way_out_and_a_marked_spot_in_her_rooms() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	var planned := 0
	var lost := 0
	var near_him := 0
	var marked := 0
	var slowest := [0, 0]
	for seed_value in SEEDS:
		var large := seed_value % 2
		var layout := _layout(BOSS_ROOMS[large])
		var bounds := ForemanBehavior.room_rect(layout.size_in_cells())
		var at := _zara_spot(layout, rng, bounds)
		var feet := _open_spot(layout, rng, bounds)
		if feet.distance_to(at) < 60.0:
			feet = _open_spot(layout, rng, bounds)
		var body := Rect2(at - ZARA_BODY / 2.0, ZARA_BODY)
		var base := {"rects": [], "circles": []}
		var is_open := _is_open(layout)
		var held := false
		match seed_value % 4:
			1:
				base["circles"] = PossessionGhost.plan_circles(_trail_near(feet, rng, bounds), Medium.TRAIL_STEP, rng.randf_range(0.0, 0.7), rng.randf_range(0.0, 2.0))
			2:
				held = true
				is_open = LineTether.open_within(feet, LineTether.RADIUS, _is_open(layout))
			3:
				var light := feet + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 50.0)
				is_open = SeanceCircle.open_within(light, Medium.LIGHT_HORIZON, _is_open(layout))
		if not Medium.hold_plan(bounds, feet, base, body, is_open)["safe"]:
			lost += 1
			continue
		var began := Time.get_ticks_usec()
		var plan := Medium.ouija_plan(bounds, feet, base, body, is_open, rng.randi_range(0, Medium.OUIJA_START_PICK - 1))
		slowest[large] = maxi(slowest[large], Time.get_ticks_usec() - began)
		var path: Array = plan["path"]
		assert_false(path.is_empty(), "seed %d: a word is found" % seed_value)
		if path.is_empty():
			print("ouija: none for seed %d, her at %s, him at %s" % [seed_value, str(at), str(feet)])
			continue
		planned += 1
		var typed: Array[Vector2] = []
		typed.assign(path)
		var shapes := ProjectionistBehavior._with(base, [], OuijaPlanchette.plan_circles(typed, Medium.OUIJA_WINDUP))
		var route := ProjectionistBehavior.route_with(bounds, shapes, body, is_open)
		assert_true(route.escape(feet)["safe"], "seed %d: it leaves a way out" % seed_value)
		var mark: Vector2 = plan["mark"]
		if _check_mark(mark, route, body, feet, "seed %d" % seed_value):
			marked += 1
		if held and mark != Vector2.INF:
			assert_true(mark.distance_to(feet) <= LineTether.RADIUS, "seed %d: the mark is inside the circle" % seed_value)
		if OuijaPlanchette.distance_to_path(typed, feet) <= OuijaPlanchette.RADIUS + 40.0:
			near_him += 1
	print("ouija: %d planned, %d marked, %d near him, %d lost before it, slowest %d us (medium room) and %d us (large room)" % [planned, marked, near_him, lost, slowest[0], slowest[1]])
	assert_true(marked >= planned * 0.9, "a safe spot is marked where one exists: %d of %d" % [marked, planned])
	assert_eq(planned + lost, SEEDS)
	assert_true(lost <= 30, "most states are not lost already: %d" % lost)
	assert_true(near_him >= planned * 0.6, "most slides pass near him: %d of %d" % [near_him, planned])
	assert_true(slowest[1] < 200000, "a plan takes %d us at worst in the large room" % slowest[1])


# --- On the Line ---

func test_the_line_warns_then_holds_him_three_seconds_and_lets_him_go() -> void:
	var grandpa := LeashTarget.new()
	grandpa.position = Vector2(300, 200)
	var room := Node2D.new()
	var zara := _zara(Vector2(450, 200), grandpa)
	room.add_child(zara)
	var tether := LineTether.new()
	tether.setup(zara, Medium.LINE_WINDUP)
	room.add_child(tether)
	tether.position = Vector2(300, 200)
	var inside := Vector2(300 + LineTether.RADIUS - 20.0, 200)
	var outside := Vector2(300 + LineTether.RADIUS + 20.0, 200)
	assert_true(tether.is_warning())
	assert_eq(tether.threat_at(inside, false), 0)
	assert_eq(tether.threat_at(outside, false), 1, "outside is better avoided while it warns")
	assert_eq(tether.threat_at(Vector2(300 + LineTether.RADIUS - 8.0, 200), true), 1, "a strict reading keeps a margin")
	assert_false(tether.threat_imminent(outside), "the circle never hurts")
	tether.advance(Medium.LINE_WINDUP)
	assert_eq(grandpa.held_left, 0.0, "nothing holds him until it locks")
	tether.lock()
	assert_true(tether.is_held())
	assert_eq(grandpa.held_at, Vector2(300, 200))
	assert_near(grandpa.held_reach, LineTether.RADIUS)
	assert_near(grandpa.held_left, LineTether.HOLD)
	assert_eq(tether.threat_at(outside, false), 2, "held, outside is a coming hit")
	assert_eq(tether.threat_at(inside, false), 0)
	assert_false(tether.threat_imminent(outside))
	var time := 0.0
	while time < LineTether.HOLD - 0.05:
		tether.advance(FRAME)
		time += FRAME
	assert_true(tether.is_held(), "three seconds")
	assert_eq(grandpa.let_go, 0)
	while time < LineTether.HOLD + 0.1:
		tether.advance(FRAME)
		time += FRAME
	assert_true(tether.is_over())
	assert_eq(grandpa.let_go, 1, "then it lets him go")
	assert_eq(tether.threat_at(outside, false), 0)
	# Her fall lets him go at once.
	var second := LineTether.new()
	second.setup(zara, Medium.LINE_WINDUP)
	room.add_child(second)
	second.position = Vector2(300, 200)
	second.lock()
	var behavior := MadameZaraBehavior.new()
	behavior._tether = second
	behavior.on_killed(zara)
	assert_true(second.is_over(), "the line drops")
	assert_eq(grandpa.let_go, 3, "and he is let go")
	assert_eq(grandpa.held_left, 0.0)
	room.free()
	grandpa.free()


func test_the_leash_holds_his_feet_in_and_ends_on_a_room_change() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var center := Vector2(300, 200)
	var radius := LineTether.RADIUS
	for trial in 200:
		var feet := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, radius)
		for frame in 90:
			# Walks, dodges and shoves, any way.
			var velocity := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 420.0)
			feet += LeashRule.held_velocity(feet, velocity, center, radius, FRAME) * FRAME
			assert_true(feet.distance_to(center) <= radius + 0.01, "trial %d: his feet stay in (%f)" % [trial, feet.distance_to(center)])
	# Along the edge he still moves, only never out.
	var on_edge := center + Vector2(radius, 0)
	var along := LeashRule.held_velocity(on_edge, Vector2(0, 120), center, radius, FRAME)
	assert_true(along.length() > 60.0, "he can walk round the edge")
	# Caught outside as it locks, he is drawn in, never further out, whatever he presses.
	var feet := center + Vector2(radius + 60.0, 0)
	var last := feet.distance_to(center)
	for frame in 90:
		feet += LeashRule.held_velocity(feet, Vector2(400, 50), center, radius, FRAME) * FRAME
		assert_true(feet.distance_to(center) <= maxf(last, radius) + 0.001, "never further out")
		last = feet.distance_to(center)
	assert_true(last <= radius + 0.01, "back inside (%f)" % last)
	assert_true(LeashRule.DRIFT_SPEED > PlayerStats.BASE_SPEED, "he cannot walk away from the pull")
	# The player's own hold.
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	assert_false(player.is_leashed())
	player.leash_to(center, radius, LineTether.HOLD)
	assert_true(player.is_leashed())
	assert_eq(player.leash_center(), center)
	assert_near(player.leash_radius(), radius)
	player.end_leash()
	assert_false(player.is_leashed(), "let go")
	player.free()
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	var move := source.substr(source.find("func _handle_movement("))
	move = move.substr(0, move.find("\nfunc ", 1))
	assert_true(move.contains("LeashRule.held_velocity("), "his walk, dodge and pushes go through the hold")
	assert_true(move.find("LeashRule.held_velocity(") > move.find("velocity += _push"), "after every push")
	assert_true(move.find("LeashRule.held_velocity(") < move.find("move_and_slide()"), "before he moves")
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var enter := scene.substr(scene.find("func _enter_room("))
	enter = enter.substr(0, enter.find("\nfunc ", 1))
	assert_true(enter.contains("player.end_leash()"), "entering a room ends any hold")
	var line := LineTether.new()
	assert_true(SeanceProps.is_passing_effect(line), "and a stored room clears the line")
	line.free()


# The circle a plan may use answers for whole cells, and only cells wholly inside it, so anywhere it
# lets his feet stand is inside the circle.
func test_the_circle_a_plan_uses_is_cautious() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	for i in 400:
		var center := Vector2(rng.randf_range(100.0, 800.0), rng.randf_range(100.0, 400.0))
		var open := LineTether.open_within(center, LineTether.RADIUS)
		var spot := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, LineTether.RADIUS + 40.0)
		if open.call(spot):
			var cell := WalkGrid.cell_of(spot)
			for corner in [Vector2(cell) * 32.0, Vector2(cell + Vector2i(1, 1)) * 32.0, Vector2(cell + Vector2i(1, 0)) * 32.0, Vector2(cell + Vector2i(0, 1)) * 32.0]:
				assert_true(corner.distance_to(center) <= LineTether.RADIUS + 0.01, "the whole cell is inside")
		# The cell under his feet as she calls always counts.
		assert_true(open.call(center), "his own cell")
	var walled := LineTether.open_within(Vector2(100, 100), LineTether.RADIUS, func(_p: Vector2) -> bool: return false)
	assert_false(walled.call(Vector2(100, 100)), "and never a cell the floor shuts")


# Over 200 calls in her two rooms, over a slide or a possession under way: she calls only when he has
# a safe spot inside the circle; when the line locks (after he has moved within it) it holds only if he
# still has one, and whatever she runs alongside is planned to leave him one, marked inside the circle.
func test_on_the_line_always_leaves_a_safe_spot_inside_the_circle_with_what_runs_alongside() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 43
	var called := 0
	var refused := 0
	var dropped := 0
	var alongside := 0
	var marked := 0
	var held_alone := 0
	var slowest := [0, 0]
	for seed_value in SEEDS:
		var large := seed_value % 2
		var layout := _layout(BOSS_ROOMS[large])
		var bounds := ForemanBehavior.room_rect(layout.size_in_cells())
		var at := _zara_spot(layout, rng, bounds)
		var feet := _open_spot(layout, rng, bounds)
		if feet.distance_to(at) < 70.0:
			feet = _open_spot(layout, rng, bounds)
		var body := Rect2(at - ZARA_BODY / 2.0, ZARA_BODY)
		var base := {"rects": [], "circles": []}
		match seed_value % 3:
			1:
				var earlier := OuijaBoard.word_path(Medium.WORDS[rng.randi_range(0, Medium.WORDS.size() - 1)], bounds)
				base["circles"] = OuijaPlanchette.plan_circles(earlier, 0.0, OuijaPlanchette.slide_time(earlier) * rng.randf_range(0.3, 0.7))
			2:
				base["circles"] = PossessionGhost.plan_circles(_trail_near(feet + Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60)), rng, bounds), Medium.TRAIL_STEP, 0.0, rng.randf_range(0.0, 2.5))
		var is_open := LineTether.open_within(feet, LineTether.RADIUS, _is_open(layout))
		var began := Time.get_ticks_usec()
		var call := Medium.hold_plan(bounds, feet, base, body, is_open)
		if not call["safe"]:
			refused += 1
			continue
		called += 1
		# He walks a little inside the circle while it warns; the base moves on by the warning.
		var moved := feet + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, LineTether.RADIUS * 0.6)
		if not is_open.call(moved) or body.grow(8.0).has_point(moved):
			moved = feet
		var later := {"rects": [], "circles": []}
		for shape: Array in base["circles"]:
			later["circles"].append([shape[0], (shape[1] as Vector2) - Vector2(Medium.LINE_WINDUP, Medium.LINE_WINDUP)])
		var lock := Medium.hold_plan(bounds, moved, later, body, is_open)
		if not lock["safe"]:
			dropped += 1
			continue
		var lock_route := ProjectionistBehavior.route_with(bounds, later, body, is_open)
		if _check_mark(lock["mark"], lock_route, body, moved, "seed %d: the lock" % seed_value):
			assert_true((lock["mark"] as Vector2).distance_to(feet) <= LineTether.RADIUS, "seed %d: its mark is inside the circle" % seed_value)
		var ouija := Medium.ouija_plan(bounds, moved, later, body, is_open, rng.randi_range(0, Medium.OUIJA_START_PICK - 1))
		var path: Array = ouija["path"]
		var found := false
		var shapes := {}
		var mark := Vector2.INF
		if not path.is_empty():
			var typed: Array[Vector2] = []
			typed.assign(path)
			shapes = ProjectionistBehavior._with(later, [], OuijaPlanchette.plan_circles(typed, Medium.OUIJA_WINDUP))
			mark = ouija["mark"]
			found = true
		else:
			var trail := _trail_near(moved, rng, bounds)
			var possession := Medium.possession_plan(bounds, trail, Medium.TRAIL_STEP, Medium.POSSESSION_WINDUP, moved, later, body, is_open)
			if possession["safe"]:
				shapes = ProjectionistBehavior._with(later, [], PossessionGhost.plan_circles(trail, Medium.TRAIL_STEP, Medium.POSSESSION_WINDUP))
				mark = possession["mark"]
				found = true
		slowest[large] = maxi(slowest[large], Time.get_ticks_usec() - began)
		if not found:
			held_alone += 1
			continue
		alongside += 1
		var route := ProjectionistBehavior.route_with(bounds, shapes, body, is_open)
		assert_true(route.escape(moved)["safe"], "seed %d: what runs alongside leaves a way out inside the circle" % seed_value)
		if _check_mark(mark, route, body, moved, "seed %d: alongside" % seed_value):
			marked += 1
		if mark != Vector2.INF:
			assert_true(mark.distance_to(feet) <= LineTether.RADIUS, "seed %d: marked inside the circle" % seed_value)
	print("on the line: %d called, %d refused, %d dropped at the lock, %d with an attack alongside (%d marked), %d held alone, slowest %d us (medium room) and %d us (large room)" % [called, refused, dropped, alongside, marked, held_alone, slowest[0], slowest[1]])
	assert_true(marked >= alongside * 0.85, "a safe spot inside the circle is marked: %d of %d" % [marked, alongside])
	assert_eq(called + refused, SEEDS)
	assert_true(refused <= 30, "she can nearly always call: %d refused" % refused)
	assert_true(alongside >= (called - dropped) * 0.9, "nearly always with an attack alongside: %d of %d" % [alongside, called - dropped])
	assert_true(slowest[1] < 200000, "a call and its plans take %d us at worst in the large room" % slowest[1])


# Played out: she calls, the circle shows round his feet, the line locks and holds him while the board
# spells alongside, and then he is let go.
func test_she_calls_holds_him_and_runs_the_board_alongside() -> void:
	var grandpa := LeashTarget.new()
	grandpa.position = Vector2(300, 210)
	var room := Node2D.new()
	var zara := _zara(Vector2(480, 150), grandpa)
	room.add_child(zara)
	var behavior := MadameZaraBehavior.new()
	behavior.forced_attack = MadameZaraBehavior.Attack.LINE
	behavior._cooldown = 0.0
	_medium_frame(behavior, zara, room)
	assert_eq(behavior.last_anim, "tether_call", "she plays tether_call")
	var tether := behavior.tether()
	assert_true(tether != null, "the line")
	if tether == null:
		room.free()
		grandpa.free()
		return
	assert_eq(tether.center(), Vector2(300, 210), "round where his feet stood")
	assert_true(tether.is_warning())
	assert_true(behavior.board() != null, "her board lies on the floor")
	var time := 0.0
	while time < Medium.LINE_WINDUP + 0.05:
		_medium_frame(behavior, zara, room)
		time += FRAME
	assert_true(tether.is_held(), "the line locks")
	assert_eq(grandpa.held_at, Vector2(300, 210))
	assert_true(behavior.planchette() != null or behavior.ghost() != null, "an attack runs alongside")
	assert_true(zara.desired_velocity.is_zero_approx(), "she holds still while it holds")
	while time < Medium.LINE_WINDUP + LineTether.HOLD + 0.1:
		_medium_frame(behavior, zara, room)
		time += FRAME
	assert_true(grandpa.let_go >= 1, "he is let go")
	room.free()
	grandpa.free()


# --- Possession ---

func test_the_copy_replays_his_last_two_seconds_where_and_when_he_walked_them() -> void:
	var walk := func(t: float) -> Vector2: return Vector2(120.0 + 50.0 * t, 200.0 + 30.0 * sin(t * 2.0))
	var grandpa := LeashTarget.new()
	grandpa.position = walk.call(0.0)
	var room := Node2D.new()
	var zara := _zara(Vector2(520, 120), grandpa)
	room.add_child(zara)
	var behavior := MadameZaraBehavior.new()
	behavior._cooldown = 99.0
	behavior._summon_timer = 99.0
	var time := 0.0
	while time < 2.5:
		grandpa.position = walk.call(time + FRAME)
		_medium_frame(behavior, zara, room)
		time += FRAME
	assert_true(behavior.trail().covers(behavior._clock), "she has his last two seconds")
	behavior.forced_attack = MadameZaraBehavior.Attack.POSSESSION
	behavior._cooldown = 0.0
	grandpa.position = walk.call(time + FRAME)
	_medium_frame(behavior, zara, room)
	time += FRAME
	var called_at := time
	assert_eq(behavior.last_anim, "possession", "she plays possession")
	var ghost := behavior.ghost()
	assert_true(ghost != null, "the copy")
	if ghost == null:
		room.free()
		grandpa.free()
		return
	var called := behavior._clock
	var trail := ghost.trail()
	for k in trail.size():
		var when := called - FeetTrail.LENGTH + k * Medium.TRAIL_STEP
		assert_true(trail[k].distance_to(walk.call(when)) < 1.0, "step %d is where he stood at %f" % [k, when])
	# He stands still now, well off the way it walks.
	grandpa.position = Vector2(300, 320)
	var windup := Medium.windup_for(MadameZaraBehavior.Attack.POSSESSION, false)
	var checked := 0
	var walking_from := -1.0
	var over_at := -1.0
	while time < called_at + windup + PossessionGhost.LIFE + 0.2:
		# Only the copy: nothing else of hers starts meanwhile.
		behavior._cooldown = 99.0
		_medium_frame(behavior, zara, room)
		time += FRAME
		if not is_instance_valid(ghost):
			break
		if ghost.is_walking() and walking_from < 0.0:
			walking_from = time
		if ghost.is_over() and over_at < 0.0:
			over_at = time
		if ghost.is_walking():
			var into := ghost.walked()
			var expected: Vector2 = walk.call(called - FeetTrail.LENGTH + into) if into <= FeetTrail.LENGTH else walk.call(called - FeetTrail.LENGTH + (2.0 * FeetTrail.LENGTH - into))
			assert_true(ghost.now_at().distance_to(expected) < 1.5, "at %f into its walk it stands where he stood" % into)
			checked += 1
	assert_true(checked > 200, "checked %d moments" % checked)
	assert_true(walking_from > 0.0 and absf(walking_from - called_at - windup) < 0.04, "it walks once its way has shown: %f" % (walking_from - called_at))
	assert_true(over_at > 0.0 and absf(over_at - walking_from - PossessionGhost.LIFE) < 0.05, "for four seconds: %f" % (over_at - walking_from))
	assert_eq(grandpa.hits, 0, "it never came near him")
	room.free()
	grandpa.free()


func test_the_trail_keeps_only_his_last_two_seconds() -> void:
	var trail := FeetTrail.new()
	assert_false(trail.covers(0.0))
	for i in 300:
		trail.record(i * FRAME, Vector2(i, 0))
	assert_true(trail.covers(299 * FRAME))
	assert_true(trail.at(299 * FRAME - 1.0).distance_to(Vector2(299 - 60, 0)) < 0.01, "a second ago")
	assert_true(trail._times.size() <= int((FeetTrail.LENGTH + FeetTrail.SPARE) / FRAME) + 3, "nothing older is kept")
	var path := trail.path(299 * FRAME, Medium.TRAIL_STEP)
	assert_eq(path.size(), roundi(FeetTrail.LENGTH / Medium.TRAIL_STEP) + 1)
	assert_true(path[path.size() - 1].distance_to(Vector2(299, 0)) < 0.01, "ending where he is")
	assert_true(path[0].distance_to(Vector2(299 - 120, 0)) < 0.01, "from two seconds ago")


func test_the_copy_warns_first_lasts_four_seconds_and_hurts_once_a_touch() -> void:
	assert_near(PossessionGhost.LIFE, 4.0)
	var trail := PackedVector2Array()
	for k in 41:
		trail.append(Vector2(100 + k * 3.0, 100))
	assert_true(PossessionGhost.ghost_at(trail, Medium.TRAIL_STEP, 0.0).distance_to(trail[0]) < 0.01)
	assert_true(PossessionGhost.ghost_at(trail, Medium.TRAIL_STEP, 2.0).distance_to(trail[40]) < 0.01, "the end of his walk at two seconds")
	assert_true(PossessionGhost.ghost_at(trail, Medium.TRAIL_STEP, 4.0).distance_to(trail[0]) < 0.01, "and back where it rose at four")
	assert_true(PossessionGhost.ghost_at(trail, Medium.TRAIL_STEP, 3.0).distance_to(trail[20]) < 0.01, "walking it back at his pace")
	var still := PackedVector2Array()
	for k in 41:
		still.append(Vector2(200, 200))
	var ghost := PossessionGhost.new()
	ghost.setup(null, still, Medium.TRAIL_STEP, Medium.POSSESSION_WINDUP)
	assert_true(ghost.is_warning())
	assert_eq(ghost.threat_at(Vector2(200, 200), false), 2, "its way reads as a coming hit")
	assert_false(ghost.advance(Medium.POSSESSION_WINDUP - 0.05, Vector2(200, 200)), "nothing while it warns")
	assert_true(ghost.advance(0.1, Vector2(200, 200)), "then a touch hurts")
	assert_false(ghost.advance(0.1, Vector2(200, 205)), "once a touch")
	assert_false(ghost.advance(0.1, Vector2(260, 200)))
	assert_true(ghost.advance(0.1, Vector2(200, 200)), "and again only after he left it")
	assert_eq(ghost.hits(), 2)
	ghost.advance(PossessionGhost.LIFE, Vector2(400, 400))
	assert_true(ghost.is_over(), "gone after its four seconds")
	assert_eq(ghost.threat_at(Vector2(200, 200), false), 0)
	ghost.free()
	# Sampled for a plan, the copy's walk is covered at every moment.
	var walk := PackedVector2Array()
	for k in 41:
		walk.append(Vector2(100 + k * 6.0, 100 + (k % 7) * 4.0))
	var shapes := PossessionGhost.plan_circles(walk, Medium.TRAIL_STEP, 0.5)
	for i in 200:
		var t := i * PossessionGhost.LIFE / 200.0
		var point := PossessionGhost.ghost_at(walk, Medium.TRAIL_STEP, t)
		var found := false
		for shape: Array in shapes:
			var circle: Vector3 = shape[0]
			var window: Vector2 = shape[1]
			if t + 0.5 >= window.x and t + 0.5 <= window.y and point.distance_to(Vector2(circle.x, circle.y)) + PossessionGhost.REACH <= circle.z + 0.01:
				found = true
				break
		assert_true(found, "t %f" % t)


# Over 200 states in her rooms, a copy of his last two seconds is cast only when it leaves him a way
# out over what is under way, inside a line's circle too, and it nearly always does.
func test_every_possession_she_casts_leaves_a_way_out() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	var cast := 0
	var held_back := 0
	var lost := 0
	var slowest := [0, 0]
	for seed_value in SEEDS:
		var large := seed_value % 2
		var layout := _layout(BOSS_ROOMS[large])
		var bounds := ForemanBehavior.room_rect(layout.size_in_cells())
		var at := _zara_spot(layout, rng, bounds)
		var feet := _open_spot(layout, rng, bounds)
		if feet.distance_to(at) < 60.0:
			feet = _open_spot(layout, rng, bounds)
		var body := Rect2(at - ZARA_BODY / 2.0, ZARA_BODY)
		var base := {"rects": [], "circles": []}
		var is_open := _is_open(layout)
		match seed_value % 3:
			1:
				var earlier := OuijaBoard.word_path(Medium.WORDS[rng.randi_range(0, Medium.WORDS.size() - 1)], bounds)
				base["circles"] = OuijaPlanchette.plan_circles(earlier, rng.randf_range(0.0, 1.0))
			2:
				is_open = LineTether.open_within(feet, LineTether.RADIUS, _is_open(layout))
		if not Medium.hold_plan(bounds, feet, base, body, is_open)["safe"]:
			lost += 1
			continue
		var trail := _trail_near(feet, rng, bounds)
		var began := Time.get_ticks_usec()
		var plan := Medium.possession_plan(bounds, trail, Medium.TRAIL_STEP, Medium.POSSESSION_WINDUP, feet, base, body, is_open)
		slowest[large] = maxi(slowest[large], Time.get_ticks_usec() - began)
		if not plan["safe"]:
			held_back += 1
			continue
		cast += 1
		var shapes := ProjectionistBehavior._with(base, [], PossessionGhost.plan_circles(trail, Medium.TRAIL_STEP, Medium.POSSESSION_WINDUP))
		var route := ProjectionistBehavior.route_with(bounds, shapes, body, is_open)
		assert_true(route.escape(feet)["safe"], "seed %d: a way out" % seed_value)
		_check_mark(plan["mark"], route, body, feet, "seed %d" % seed_value)
	print("possession: %d cast, %d held back, %d lost before it, slowest %d us (medium room) and %d us (large room)" % [cast, held_back, lost, slowest[0], slowest[1]])
	assert_eq(cast + held_back + lost, SEEDS)
	assert_true(cast >= (SEEDS - lost) * 0.85, "nearly always cast: %d of %d" % [cast, SEEDS - lost])
	assert_true(slowest[1] < 200000, "%d us at worst in the large room" % slowest[1])


# --- the seance circle ---

func test_the_seance_circle_drifts_is_wider_and_dimmer_than_lights_out() -> void:
	assert_true(SeanceCircle.LIGHT_RADIUS >= LightsOut.LIGHT_RADIUS * 1.6, "wider")
	assert_true(SeanceCircle.LIGHT_RADIUS >= 120.0 and SeanceCircle.LIGHT_RADIUS <= 140.0)
	assert_true(SeanceCircle.DIM <= LightsOut.DARK - 0.25, "dim, not black")
	assert_near(SeanceCircle.shade_at(SeanceCircle.FADE_IN + 1.0), SeanceCircle.DIM)
	assert_true(SeanceCircle.shade_at(0.2) < SeanceCircle.DIM, "the candles go out over a moment")
	assert_true(SeanceCircle.DRIFT_SPEED >= 10.0 and SeanceCircle.DRIFT_SPEED <= 16.0, "slowly")
	assert_true(SeanceCircle.Z < Projectile.SHOT_Z and SeanceCircle.Z < Enemy.WARNING_Z, "warnings stay above it")
	var room := ForemanBehavior.room_rect(Vector2i(30, 17))
	var circle := SeanceCircle.new()
	circle.setup(null, room, room.get_center(), 7)
	var start := circle.center()
	var area := SeanceCircle.drift_area(room)
	var travelled := 0.0
	var last := start
	var seconds := 30.0
	var time := 0.0
	while time < seconds:
		# Wherever he stands, the light keeps its own way.
		circle.advance(FRAME, Vector2(100, 100))
		time += FRAME
		travelled += last.distance_to(circle.center())
		last = circle.center()
		assert_true(area.grow(0.01).has_point(last), "it stays in the room")
	assert_true(travelled >= seconds * SeanceCircle.DRIFT_SPEED * 0.9 and travelled <= seconds * SeanceCircle.DRIFT_SPEED + 1.0, "it drifts: %f" % travelled)
	assert_true(start.distance_to(last) > 1.0, "it moves")
	circle.free()
	# Lights Out's light rides on him; this one never does.
	var source := FileAccess.get_file_as_string("res://scripts/world/seance_circle.gd")
	assert_false(source.contains("feet().global_position"), "it never follows his feet")


func test_the_spirits_strike_only_outside_the_light() -> void:
	var room := ForemanBehavior.room_rect(Vector2i(30, 17))
	var circle := SeanceCircle.new()
	circle.setup(null, room, room.get_center(), 3)
	var inside := circle.center() + Vector2(SeanceCircle.LIGHT_RADIUS - 20.0, 0)
	var time := 0.0
	var swoops := 0
	while time < 6.0:
		if circle.advance(FRAME, circle.center() + Vector2(SeanceCircle.LIGHT_RADIUS - 20.0, 0)):
			swoops += 1
		time += FRAME
	assert_eq(swoops, 0, "never while he stands in the light")
	assert_eq(circle.threat_at(circle.center(), false), 0)
	assert_eq(circle.threat_at(circle.center() + Vector2(SeanceCircle.LIGHT_RADIUS + 10.0, 0), false), 2, "outside reads as a coming hit")
	assert_eq(circle.threat_at(circle.center() + Vector2(SeanceCircle.LIGHT_RADIUS - 8.0, 0), true), 2, "with a strict margin")
	assert_false(circle.threat_imminent(circle.center() + Vector2(400, 0)))
	var first := -1.0
	time = 0.0
	while time < 6.0:
		if circle.advance(FRAME, circle.center() + Vector2(SeanceCircle.LIGHT_RADIUS + 60.0, 0)):
			swoops += 1
			if first < 0.0:
				first = time
		time += FRAME
	assert_true(swoops >= 3, "outside, they come: %d" % swoops)
	assert_true(first >= SeanceCircle.FIRST_SWOOP - 0.05, "not at once")
	# A swoop lands on his spot and hurts only outside the light.
	var grandpa := Target.new()
	var parent := Node2D.new()
	var zara := _zara(Vector2(200, 200), grandpa, Vector2i(30, 17))
	parent.add_child(zara)
	var edge := circle.center() + Vector2(SeanceCircle.LIGHT_RADIUS + 10.0, 0)
	for case in [[edge, 1], [edge - Vector2(16.0, 0), 0], [edge + Vector2(SpiritSwoop.RADIUS + 6.0, 0), 0]]:
		grandpa.position = case[0]
		grandpa.hits = 0
		var swoop := SpiritSwoop.new()
		swoop.setup(zara, circle, edge, edge + Vector2(30, 0))
		parent.add_child(swoop)
		if case[1] == 1:
			assert_eq(swoop.threat_at(case[0], false), 2, "outside the light its ring reads as a coming hit")
		else:
			assert_true(swoop.threat_at(case[0], false) == 0 or not swoop.strikes(case[0]), "in the light or off the ring it hurts nothing")
		var elapsed := 0.0
		while elapsed < SpiritSwoop.WARNING + 0.1:
			swoop._process(FRAME)
			elapsed += FRAME
			if elapsed < SpiritSwoop.WARNING - 0.02:
				assert_eq(grandpa.hits, 0, "nothing while it warns")
		assert_eq(grandpa.hits, case[1], "at %s" % str(case[0]))
		if is_instance_valid(swoop):
			parent.remove_child(swoop)
			swoop.free()
	var stray := SpiritSwoop.new()
	assert_false(stray.strikes(Vector2(9999, 9999)), "far off nothing")
	stray.free()
	assert_eq(SpiritSwoop.DAMAGE, 1)
	parent.free()
	grandpa.free()
	circle.free()


func test_phase_two_starts_below_half_and_lays_the_seance_circle() -> void:
	assert_true(Medium.is_phase_two(900.0, 1950.0))
	assert_false(Medium.is_phase_two(1000.0, 1950.0))
	for attack in [MadameZaraBehavior.Attack.LINE, MadameZaraBehavior.Attack.POSSESSION]:
		assert_true(Medium.windup_for(attack, true) < Medium.windup_for(attack, false))
	assert_near(Medium.windup_for(MadameZaraBehavior.Attack.OUIJA, true), Medium.windup_for(MadameZaraBehavior.Attack.OUIJA, false))
	assert_true(Medium.cooldown_for(true) < Medium.cooldown_for(false))
	assert_true(Medium.PHASE_TWO_SPEED > 1.0)
	var grandpa := Target.new()
	grandpa.position = Vector2(300, 200)
	var room := Node2D.new()
	var zara := _zara(Vector2(450, 200), grandpa)
	room.add_child(zara)
	var behavior := MadameZaraBehavior.new()
	behavior._cooldown = 99.0
	zara.hp = zara.max_hp() * 0.51
	_medium_frame(behavior, zara, room)
	assert_true(behavior.circle() == null, "not above half")
	zara.hp = zara.max_hp() * 0.49
	_medium_frame(behavior, zara, room)
	assert_true(behavior.circle() != null, "below half the circle comes")
	behavior.on_killed(zara)
	assert_true(behavior.circle().is_out(), "and goes out when she falls")
	var forced := MadameZaraBehavior.new()
	forced._cooldown = 99.0
	forced.forced_phase_two = true
	zara.hp = zara.max_hp()
	_medium_frame(forced, zara, room)
	assert_true(forced.circle() != null, "a look probe can force it")
	room.free()
	grandpa.free()


# Her plans in the second phase keep him in the light: the floor they lead him over is only where the
# light will be however it drifts while they run.
func test_in_the_seance_circle_her_plans_keep_him_in_the_light() -> void:
	var open := SeanceCircle.open_within(Vector2(400, 300), Medium.LIGHT_HORIZON)
	var reach := SeanceCircle.LIGHT_RADIUS - SeanceCircle.DRIFT_SPEED * Medium.LIGHT_HORIZON
	assert_true(reach >= 80.0, "room enough to move: %f" % reach)
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	for i in 300:
		var spot := Vector2(400, 300) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, SeanceCircle.LIGHT_RADIUS + 30.0)
		if open.call(spot):
			assert_true(spot.distance_to(Vector2(400, 300)) <= reach, "only well inside the light")
	var source := FileAccess.get_file_as_string("res://scripts/actors/behaviors/madame_zara_behavior.gd")
	assert_true(source.contains("_circle.open_test(LIGHT_HORIZON, open)"), "her plans read the light")


# --- her summons ---

func test_she_manifests_two_ectoplasm_never_past_five_and_they_pay_nothing() -> void:
	assert_eq(Medium.ectoplasm_count(1), 2)
	assert_eq(Medium.ectoplasm_count(4), 1)
	assert_eq(Medium.ectoplasm_count(5), 0)
	assert_eq(Medium.ectoplasm_count(9), 0)
	assert_eq(Medium.MAX_ENEMIES, 5)
	assert_near(Medium.ECTOPLASM_EVERY, 12.0)
	assert_false(BossMoves.can_summon(5, Medium.MAX_ENEMIES))
	var source := FileAccess.get_file_as_string("res://scripts/actors/behaviors/madame_zara_behavior.gd")
	assert_true(source.contains("enemy.request_summon_at("), "on marked spots")
	assert_true(source.contains("BossMoves.can_summon(alive, MAX_ENEMIES)"))
	assert_eq(_load("madame_zara").summon.id, "ectoplasm")


func test_she_starts_only_with_her_body_in_view_and_hurries_to_him() -> void:
	var grandpa := Target.new()
	grandpa.position = Vector2(60, 60)
	var room := Node2D.new()
	var zara := _zara(Vector2(900, 480), grandpa, Vector2i(30, 17))
	room.add_child(zara)
	var behavior := MadameZaraBehavior.new()
	behavior._cooldown = 0.0
	_medium_frame(behavior, zara, room)
	assert_false(zara.target_in_view())
	assert_eq(behavior.attack(), MadameZaraBehavior.Attack.NONE, "no attack off screen")
	assert_true(zara.desired_velocity.length() > zara.def.speed, "she hurries to him")
	room.free()
	grandpa.free()


# --- her hazards ---

func test_every_hazard_madame_zara_leaves_answers_a_simulated_players_questions() -> void:
	var nodes: Array[Node] = [LineTether.new(), OuijaPlanchette.new(), PossessionGhost.new(), SeanceCircle.new(), SpiritSwoop.new()]
	for node in nodes:
		var name: String = node.get_script().get_global_name()
		assert_true(node.has_method("threat_at") and node.has_method("threat_imminent"), name)
		node.free()
	for node: Node in [OuijaPlanchette.new(), PossessionGhost.new(), SpiritSwoop.new()]:
		assert_true(node.has_method("route_circles"), "%s shows a planner its timed shapes" % node.get_script().get_global_name())
		node.free()
	var path: Array[Vector2] = [Vector2(100, 100), Vector2(300, 100)]
	var planchette := OuijaPlanchette.new()
	planchette.setup(null, path, Medium.OUIJA_WINDUP)
	assert_eq(planchette.threat_at(Vector2(200, 100), false), 2)
	assert_eq(planchette.threat_at(Vector2(200, 160), false), 0)
	assert_false(planchette.threat_imminent(Vector2(200, 100)), "not while the windup is young")
	planchette.free()


func test_madame_zaras_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [LineTether.new(), OuijaBoard.new(), OuijaPlanchette.new(), PossessionGhost.new(), SeanceCircle.new(), SpiritSwoop.new(), SafeSpotMark.new()]
	for effect in effects:
		if not (effect is SafeSpotMark):
			assert_true(SeanceProps.is_passing_effect(effect), "the hotline knows %s lingers" % effect.get_script().get_global_name())
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()
