extends TestCase

const Director := preload("res://scripts/actors/behaviors/cruise_director_behavior.gd")
const Commodore := preload("res://scripts/actors/behaviors/commodore_behavior.gd")
# The cruise scales health by this, and its bosses hold their final health divided by it.
const CRUISE_HEALTH := 2.2
# The third floors scale by this, so their bosses' final health is their .tres health times it.
const FLOOR_THREE_HEALTH := 1.8
const CONGA := CruiseDirectorBehavior.Attack.CONGA
const KARAOKE := CruiseDirectorBehavior.Attack.KARAOKE
const QUOITS := CruiseDirectorBehavior.Attack.QUOITS
const ANCHOR := CommodoreBehavior.Attack.ANCHOR
const FOGHORN := CommodoreBehavior.Attack.FOGHORN
const PORT := CommodoreBehavior.Attack.PORT
const BUOYS := CommodoreBehavior.Attack.BUOYS
const ROOMS: Array[Vector2i] = [Vector2i(14, 9), Vector2i(20, 11), Vector2i(30, 17)]


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- Lorraine ---

func test_the_conga_line_leaves_its_gap_inside_the_room_and_marks_it() -> void:
	for cells in ROOMS:
		var room := ForemanBehavior.room_rect(cells)
		for direction in [Vector2.RIGHT, Vector2.DOWN]:
			for gap in FuneralDirectorBehavior.SLOTS:
				for feet in [room.get_center(), room.position + Vector2(5, 5), room.end - Vector2(5, 5)]:
					var lanes := FuneralDirectorBehavior.procession_lanes(room, direction, gap, feet)
					assert_eq(lanes.size(), FuneralDirectorBehavior.SLOTS - 1, "every slot but one dances")
					var clear := FuneralDirectorBehavior.procession_slot(room, direction, gap, feet)
					var spot := Director.gap_spot(clear, feet)
					assert_true(clear.has_point(spot), "the mark %s lies in the gap %s" % [str(spot), str(clear)])
					assert_true(room.grow(0.5).has_point(spot))
					for lane in lanes:
						assert_true(room.grow(0.5).encloses(lane))
						assert_false(lane.has_point(spot), "no dancer crosses the mark")


func test_a_conga_row_hits_only_where_it_has_danced() -> void:
	var row := DeckLane.row_for(DeckLane.LOOK_CONGA)
	assert_true(DeckLane.row_hits(Vector2.ZERO, Vector2.RIGHT, 40.0, 100.0, row, Vector2(80, 10)))
	assert_false(DeckLane.row_hits(Vector2.ZERO, Vector2.RIGHT, 40.0, 100.0, row, Vector2(140, 0)), "not reached yet")
	assert_false(DeckLane.row_hits(Vector2.ZERO, Vector2.RIGHT, 40.0, 100.0, row, Vector2(100.0 - row - 5.0, 0)), "already passed")
	assert_false(DeckLane.row_hits(Vector2.ZERO, Vector2.RIGHT, 40.0, 100.0, row, Vector2(80, 30)), "beside the lane")
	var lane := DeckLane.new()
	lane.setup(null, Vector2.DOWN, 200.0, 40.0, Director.CONGA_WARNING)
	assert_eq(lane.look(), DeckLane.LOOK_CONGA)
	assert_false(lane.is_moving(), "it warns first")
	lane.free()


func test_the_conga_leaves_time_to_reach_the_gap() -> void:
	var walk := PlayerStats.BASE_SPEED * (Director.CONGA_WINDUP + Director.CONGA_WARNING - 0.3)
	assert_true(walk > FuneralDirectorBehavior.LANE_WIDTH * 2.0, "%f" % walk)


func test_she_never_calls_the_same_number_twice_running() -> void:
	for last in [CONGA, KARAOKE, QUOITS]:
		for i in 20:
			var next := Director.choose_attack(60.0, last, i / 20.0)
			assert_true(next != last, "after %d came %d" % [last, next])
	for i in 20:
		assert_true(Director.choose_attack(Director.KARAOKE_START + 50.0, QUOITS, i / 20.0) != KARAOKE, "the cone only when he is near")
	var seen := {}
	for i in 100:
		seen[Director.choose_attack(60.0, CruiseDirectorBehavior.Attack.NONE, i / 100.0)] = true
	assert_eq(seen.size(), 3)


func test_the_karaoke_cone_follows_the_plan() -> void:
	assert_near(Director.KARAOKE_ANGLE, 60.0)
	assert_near(Director.KARAOKE_LENGTH, 150.0)
	assert_true(Director.KARAOKE_WINDUP >= 0.7, "a cone that starts beside him warns long enough")
	assert_true(ChiefStokerBehavior.in_cone(Vector2.ZERO, Vector2.RIGHT, Director.KARAOKE_ANGLE, Director.KARAOKE_LENGTH, Vector2(100, 20)))
	assert_false(ChiefStokerBehavior.in_cone(Vector2.ZERO, Vector2.RIGHT, Director.KARAOKE_ANGLE, Director.KARAOKE_LENGTH, Vector2(20, 100)))


func test_quoits_land_on_him_and_around_him_inside_the_room() -> void:
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var room := ForemanBehavior.room_rect(ROOMS[seed_value % 3])
		var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
		var spots := Director.quoit_spots(feet, Director.QUOIT_COUNT, rng, room)
		assert_true(spots.size() >= 2, "seed %d: %d quoits" % [seed_value, spots.size()])
		assert_true(spots[0].distance_to(feet) <= QuoitRing.RADIUS * 1.5, "seed %d: the first lands on him" % seed_value)
		for i in spots.size():
			assert_true(room.grow(0.01).has_point(spots[i]), "seed %d: inside the room" % seed_value)
			for j in range(i + 1, spots.size()):
				assert_true(spots[i].distance_to(spots[j]) >= Director.QUOIT_APART - 0.01, "seed %d: apart" % seed_value)
	var middle := ForemanBehavior.room_rect(Vector2i(20, 11))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	assert_eq(Director.quoit_spots(middle.get_center(), Director.QUOIT_COUNT, rng, middle).size(), Director.QUOIT_COUNT, "in the open all three land")


func test_a_quoit_lands_once_then_lies_a_while_and_slows() -> void:
	var quoit := QuoitRing.new()
	quoit.setup(null, QuoitRing.WARNING)
	assert_false(quoit.advance(QuoitRing.WARNING - 0.1))
	assert_near(quoit.fill(), (QuoitRing.WARNING - 0.1) / QuoitRing.WARNING)
	assert_true(quoit.advance(0.2), "it lands")
	assert_false(quoit.advance(0.2), "once")
	assert_true(quoit.is_lying())
	assert_false(quoit.lie(QuoitRing.LIE_TIME - 0.1))
	assert_true(quoit.lie(0.2), "and is gone")
	assert_true(QuoitRing.inside(Vector2(100, 100), QuoitRing.RADIUS, Vector2(110, 110)))
	assert_false(QuoitRing.inside(Vector2(100, 100), QuoitRing.RADIUS, Vector2(130, 100)))
	assert_near(QuoitRing.SLOW, 0.5)
	assert_true(QuoitRing.LIE_TIME >= 2.0, "a few seconds")
	quoit.free()
	var walk := PlayerStats.BASE_SPEED * (QuoitRing.WARNING + Director.QUOIT_WINDUP - 0.3)
	assert_true(walk > QuoitRing.RADIUS * 2.0, "%f" % walk)


func test_she_never_summons_over_the_cap_and_her_diners_pay_nothing() -> void:
	for alive in 9:
		var count := Director.summon_count(alive, Director.MAX_ENEMIES)
		assert_true(count >= 0 and count <= Director.SUMMON_COUNT)
		assert_true(alive + count <= maxi(Director.MAX_ENEMIES, alive), "%d alive, %d called" % [alive, count])
	assert_eq(Director.MAX_ENEMIES, 5)
	var def := _load("lorraine")
	assert_eq(def.summon.id, "early_bird_diner")
	var diner := Enemy.new()
	diner.setup(def.summon, null, 0.5)
	diner.is_summon = true
	diner.apply_floor(CRUISE_HEALTH, 2.5)
	assert_eq(diner.coin_value(), 0)
	diner.free()


func test_lorraine_is_at_least_as_hard_as_the_reverend_and_gloria() -> void:
	var def := _load("lorraine")
	assert_true(def.is_boss)
	assert_eq(def.id, "lorraine")
	assert_eq(def.display_name, "Lorraine, Cruise Director")
	assert_true(absf(def.max_hp * CRUISE_HEALTH - 760.0) < 0.5, str(def.max_hp * CRUISE_HEALTH))
	assert_eq(def.pension_drop, 8)
	for id in ["reverend", "gloria"]:
		assert_true(def.max_hp * CRUISE_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH, id)
	assert_true(Director.COOLDOWN <= ReverendBehavior.COOLDOWN)
	assert_true(Director.COOLDOWN <= FountainDivaBehavior.COOLDOWN)
	assert_true(Director.SUMMON_COUNT >= ReverendBehavior.SUMMON_COUNT)
	assert_true(Director.SUMMON_COUNT >= FountainDivaBehavior.SUMMON_COUNT)


# --- Commodore Wellington ---

func test_the_anchor_costs_three_pills_and_its_warning_shows_whole() -> void:
	assert_eq(Commodore.ANCHOR_DAMAGE, Enemy.HEAVIEST_DAMAGE)
	assert_eq(Commodore.ANCHOR_DAMAGE, 3)
	assert_true(Commodore.ANCHOR_SHOWN_WHOLE)
	assert_near(Commodore.ANCHOR_WINDUP, 1.2)
	for phase_two in [false, true]:
		assert_near(Commodore.windup_for(ANCHOR, phase_two), 1.2, "the second phase never shortens it")
	var commodore := Enemy.new()
	commodore.setup(_load("commodore_wellington"), null, 0.25)
	var telegraph := Telegraph.new()
	telegraph.start(Commodore.ANCHOR_WINDUP)
	commodore.set_warning(telegraph, Commodore.WARNING_RADIUS, Commodore.ANCHOR_SHOWN_WHOLE)
	assert_near(commodore._warning_share(), 1.0, "whatever his warning stat")
	assert_true(telegraph.shows_warning(commodore._warning_share()), "it shows from the first instant")
	commodore.free()


func test_the_anchor_mark_fills_over_its_whole_windup_and_lands_for_three() -> void:
	var anchor := AnchorDrop.new()
	anchor.setup(null, Commodore.ANCHOR_WINDUP, Commodore.ANCHOR_DAMAGE)
	assert_eq(anchor.damage(), 3)
	assert_false(anchor.advance(0.6))
	assert_near(anchor.fill(), 0.5, "half filled at half the windup")
	assert_true(anchor.advance(0.61))
	assert_false(anchor.advance(0.1), "it lands once")
	assert_true(AnchorDrop.RING_GAP > 0.0, "with a second ring")
	anchor.free()
	var walk := PlayerStats.BASE_SPEED * (Commodore.ANCHOR_WINDUP - 0.3)
	assert_true(walk > AnchorDrop.RADIUS * 2.0, "he can step out in time, %f" % walk)


func test_phase_two_drops_the_anchor_twice_in_a_row() -> void:
	assert_eq(Commodore.followup(ANCHOR, true, 1), ANCHOR, "a second drop")
	assert_eq(Commodore.followup(ANCHOR, true, 2), CommodoreBehavior.Attack.NONE, "never a third")
	assert_eq(Commodore.followup(ANCHOR, false, 1), CommodoreBehavior.Attack.NONE, "only below half health")
	for attack in [FOGHORN, PORT, BUOYS]:
		assert_eq(Commodore.followup(attack, true, 0), CommodoreBehavior.Attack.NONE)
	assert_eq(Commodore.ANCHORS_IN_A_ROW, 2)
	assert_true(Commodore.windup_for(FOGHORN, true) < Commodore.FOGHORN_WINDUP, "his other windups quicken")
	assert_true(Commodore.is_phase_two(900.0, 1950.0))
	assert_false(Commodore.is_phase_two(1000.0, 1950.0))


func test_the_foghorn_blasts_a_wide_lane() -> void:
	assert_true(Commodore.FOGHORN_WIDTH >= 80.0, "wide")
	assert_eq(Commodore.FOGHORN_DAMAGE, Enemy.HEAVY_DAMAGE)
	assert_true(FoghornBlast.in_blast(Vector2.ZERO, Vector2.RIGHT, 300.0, 84.0, Vector2(200, 40)))
	assert_false(FoghornBlast.in_blast(Vector2.ZERO, Vector2.RIGHT, 300.0, 84.0, Vector2(200, 50)), "beside it")
	assert_false(FoghornBlast.in_blast(Vector2.ZERO, Vector2.RIGHT, 300.0, 84.0, Vector2(-20, 0)), "behind him")
	assert_false(FoghornBlast.in_blast(Vector2.ZERO, Vector2.RIGHT, 300.0, 84.0, Vector2(320, 0)), "past its end")
	var walk := PlayerStats.BASE_SPEED * (Commodore.FOGHORN_WINDUP * Commodore.PHASE_TWO_WINDUP_SCALE - 0.3)
	assert_true(walk > Commodore.FOGHORN_WIDTH / 2.0, "even in the second phase he can step out sideways, %f" % walk)


func test_hard_to_port_comes_only_on_a_rolling_deck_and_rolls_harder() -> void:
	for i in 50:
		assert_true(Commodore.choose_attack(CommodoreBehavior.Attack.NONE, false, 99.0, i / 50.0) != PORT, "no deck, no roll")
		assert_true(Commodore.choose_attack(CommodoreBehavior.Attack.NONE, true, 0.0, i / 50.0) != PORT, "not too often")
	var seen := {}
	for i in 100:
		seen[Commodore.choose_attack(CommodoreBehavior.Attack.NONE, true, 99.0, i / 100.0)] = true
	assert_true(seen.has(PORT), "on a deck it comes")
	assert_eq(seen.size(), 4)
	for last in [ANCHOR, FOGHORN, PORT, BUOYS]:
		for i in 20:
			assert_true(Commodore.choose_attack(last, true, 99.0, i / 20.0) != last, "never twice running")
	assert_near(Commodore.PORT_HORN, ShipRoll.HORN_TIME, "warned as the ship's own roll is")
	assert_true(Commodore.PORT_SPEED >= ShipRoll.SPEED * 2.0, "a strong roll")
	assert_true(Commodore.PORT_SPEED > PlayerStats.BASE_SPEED, "too strong to walk against, so he must brace for it")
	assert_eq(Commodore.port_side(0.1), Vector2.LEFT)
	assert_eq(Commodore.port_side(0.9), Vector2.RIGHT)


func test_every_lifebuoy_lane_stays_inside_the_room() -> void:
	for cells in ROOMS:
		var room := ForemanBehavior.room_rect(cells)
		for feet_y in [room.position.y, room.get_center().y, room.end.y, room.position.y + 20.0]:
			var rows := Commodore.buoy_rows(room, feet_y, Commodore.BUOY_COUNT)
			assert_true(rows.size() >= 2, "%s: %d rows" % [str(cells), rows.size()])
			for i in rows.size():
				assert_true(rows[i] - Commodore.BUOY_WIDTH / 2.0 >= room.position.y - 0.01, "%s row %d" % [str(cells), i])
				assert_true(rows[i] + Commodore.BUOY_WIDTH / 2.0 <= room.end.y + 0.01, "%s row %d" % [str(cells), i])
				if i > 0:
					assert_near(rows[i] - rows[i - 1], Commodore.BUOY_SPACING)
	var big := ForemanBehavior.room_rect(Vector2i(30, 17))
	var rows := Commodore.buoy_rows(big, big.get_center().y, Commodore.BUOY_COUNT)
	assert_eq(rows.size(), 3)
	assert_near(rows[1], big.get_center().y, "the middle one runs level with him")
	assert_true(Commodore.BUOY_SPACING - Commodore.BUOY_WIDTH >= Player.FEET_BOX_SIZE.y * 2.0, "room to stand between them")


func test_the_swabbed_decks_follow_the_plan() -> void:
	assert_near(Commodore.WET_TIME, 5.0)
	assert_eq(Commodore.WET_JETS, 2)
	var walk := PlayerStats.BASE_SPEED * (Commodore.WET_WARNING - 0.2)
	assert_true(walk > Commodore.WET_RADIUS * 2.0, "%f" % walk)


func test_the_commodore_is_clearly_harder_than_mortimer_and_the_mall_santa() -> void:
	var def := _load("commodore_wellington")
	assert_true(def.is_boss)
	assert_eq(def.id, "commodore_wellington")
	assert_eq(def.display_name, "Commodore Wellington")
	assert_true(absf(def.max_hp * CRUISE_HEALTH - 1950.0) < 0.5, str(def.max_hp * CRUISE_HEALTH))
	assert_eq(def.pension_drop, 16)
	for id in ["mortimer_grimsby", "mall_santa"]:
		assert_true(def.max_hp * CRUISE_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH * 1.1, id)
	assert_true(Commodore.BASE_COOLDOWN < FuneralDirectorBehavior.BASE_COOLDOWN)
	assert_true(Commodore.PHASE_TWO_COOLDOWN < FuneralDirectorBehavior.PHASE_TWO_COOLDOWN)
	assert_true(Commodore.BASE_COOLDOWN < MallSantaBehavior.BASE_COOLDOWN)
	assert_true(Commodore.PHASE_TWO_COOLDOWN < MallSantaBehavior.PHASE_TWO_COOLDOWN)
	assert_true(Commodore.ANCHOR_DAMAGE > Enemy.HEAVY_DAMAGE)
	assert_true(def.summon == null, "he calls nobody")


# --- both ---

func test_the_cruises_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [ShuffleboardPuck.new(), DeckLane.new(), QuoitRing.new(), AnchorDrop.new(), FoghornBlast.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()
	for kept: Node in [Pickup.new(), ShipDeck.new()]:
		assert_false(RoomView.is_passing_effect(kept), "%s is kept" % kept.get_script().get_global_name())
		kept.free()
