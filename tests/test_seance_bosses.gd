extends TestCase

# The Seance Hotline's bosses: Sister Celestine, Tarot Reader (Madame Zara follows in her own phase).
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
	assert_false(PendingBosses.BY_OLD.values().has("celestine"), "she needs no stand-in")
	assert_false(PendingBosses.BY_OLD.has("chip"))
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
