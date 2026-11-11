extends TestCase


func _no_upgrades() -> Array[UpgradeDef]:
	var list: Array[UpgradeDef] = []
	return list


func _no_items() -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	return list


func _shipped_upgrade(id: String) -> UpgradeDef:
	for upgrade in Content.upgrades():
		if upgrade.id == id:
			return upgrade
	return null


func _shipped_item(id: String) -> ItemDef:
	for item in Content.items():
		if item.id == id:
			return item
	return null


# --- the throw's states ---

func test_starts_held() -> void:
	var teeth := DentureThrow.new()
	assert_true(teeth.is_held())
	assert_false(teeth.is_flying())
	assert_near(teeth.return_delay, DentureThrow.RETURN_DELAY)


func test_throw_makes_them_fly() -> void:
	var teeth := DentureThrow.new()
	assert_true(teeth.try_throw())
	assert_false(teeth.is_held())
	assert_true(teeth.is_flying())


func test_second_throw_is_refused_while_away() -> void:
	var teeth := DentureThrow.new()
	teeth.try_throw()
	assert_false(teeth.try_throw(), "flying")
	teeth.drop()
	assert_false(teeth.try_throw(), "dropped")
	teeth.tick(DentureThrow.RETURN_DELAY + 0.1)
	assert_false(teeth.try_throw(), "returning")


func test_drop_only_works_from_flying() -> void:
	var teeth := DentureThrow.new()
	teeth.drop()
	assert_true(teeth.is_held(), "held stays held")
	teeth.try_throw()
	teeth.drop()
	assert_true(teeth.is_dropped())
	assert_false(teeth.is_flying())


func test_dropped_teeth_return_after_the_timer() -> void:
	var teeth := DentureThrow.new()
	teeth.try_throw()
	teeth.drop()
	teeth.tick(DentureThrow.RETURN_DELAY - 0.1)
	assert_true(teeth.is_dropped())
	teeth.tick(0.2)
	assert_true(teeth.is_returning())
	assert_false(teeth.is_dropped())


func test_a_shorter_delay_brings_them_back_sooner() -> void:
	var teeth := DentureThrow.new(DentureThrow.QUICK_RETURN_DELAY)
	teeth.try_throw()
	teeth.drop()
	teeth.tick(DentureThrow.QUICK_RETURN_DELAY + 0.01)
	assert_true(teeth.is_returning())
	assert_near(DentureThrow.QUICK_RETURN_DELAY, 2.0)
	assert_near(DentureThrow.RETURN_DELAY, 3.0)


func test_timer_does_not_run_while_flying() -> void:
	var teeth := DentureThrow.new()
	teeth.try_throw()
	teeth.tick(DentureThrow.RETURN_DELAY + 1.0)
	assert_true(teeth.is_flying())


func test_catch_returns_them_from_any_state() -> void:
	var teeth := DentureThrow.new()
	teeth.try_throw()
	teeth.catch_teeth()
	assert_true(teeth.is_held(), "caught in flight")
	teeth.try_throw()
	teeth.drop()
	teeth.catch_teeth()
	assert_true(teeth.is_held(), "picked up by walking over them")
	teeth.try_throw()
	teeth.drop()
	teeth.tick(DentureThrow.RETURN_DELAY + 0.1)
	teeth.catch_teeth()
	assert_true(teeth.is_held(), "caught on arrival")
	assert_true(teeth.try_throw(), "can throw again")


func test_drop_restarts_the_timer_on_the_next_throw() -> void:
	var teeth := DentureThrow.new()
	teeth.try_throw()
	teeth.drop()
	teeth.tick(DentureThrow.RETURN_DELAY - 0.5)
	teeth.catch_teeth()
	teeth.try_throw()
	teeth.drop()
	teeth.tick(1.0)
	assert_true(teeth.is_dropped())


func test_a_bite_drops_them_once() -> void:
	var teeth := DentureThrow.new()
	teeth.try_throw()
	teeth.drop()
	teeth.drop()
	assert_true(teeth.is_dropped())
	assert_false(teeth.is_flying(), "dropped teeth can't bite again")


# --- the cane stays in his hand ---

func test_the_cane_swings_whatever_the_teeth_are_doing() -> void:
	var teeth := DentureThrow.new()
	assert_true(Player.can_swing(teeth), "held")
	teeth.try_throw()
	assert_true(Player.can_swing(teeth), "flying")
	teeth.drop()
	assert_true(Player.can_swing(teeth), "lying on the floor")
	teeth.tick(DentureThrow.RETURN_DELAY + 0.1)
	assert_true(Player.can_swing(teeth), "coming back")


func test_only_held_teeth_can_be_thrown() -> void:
	var teeth := DentureThrow.new()
	assert_true(Player.can_throw(teeth))
	teeth.try_throw()
	assert_false(Player.can_throw(teeth))
	teeth.drop()
	assert_false(Player.can_throw(teeth))


func test_combo_and_charge_still_work_while_the_teeth_fly() -> void:
	var player := Player.new()
	assert_true(player._teeth.try_throw())
	assert_false(player.has_teeth())
	assert_true(player._combo.try_attack() > 0, "a combo swing starts")
	player._charge.start()
	player._charge.tick(ChargeSwing.CHARGE_TIME + 0.01)
	assert_true(player._charge.release(), "a charged swing fires")
	player.free()


# --- damage, range and how many they bite ---

func test_bite_damage_is_the_old_throw_damage_scaled_by_its_multiplier() -> void:
	assert_near(ThrownDentures.DAMAGE, 14.0)
	assert_near(ThrownDentures.bite_damage(1.0), 14.0)
	assert_near(ThrownDentures.bite_damage(1.5), 21.0)


func test_base_range_is_170() -> void:
	assert_near(DentureThrow.BASE_RANGE, 170.0)
	var stats := PlayerStats.compute(_no_upgrades(), {}, _no_items())
	assert_near(stats.bite_range, 170.0)
	assert_near(stats.bite_damage_mult, 1.0)
	assert_eq(stats.bites_per_throw, 1)
	assert_near(stats.teeth_return_delay, 3.0)


func test_advance_travel_caps_at_the_range_it_is_given() -> void:
	var delta := 1.0 / 60.0
	for max_range: float in [170.0, 210.0, 290.0]:
		var travelled := 0.0
		var frames := 0
		while travelled < max_range and frames < 1000:
			travelled = ThrownDentures.advance_travel(travelled, delta, max_range)
			frames += 1
		assert_eq(frames, ceili(max_range / (ThrownDentures.FLY_SPEED * delta) - 0.0001), "range %d" % max_range)
		assert_eq(travelled, max_range, "exactly the range")
		assert_eq(ThrownDentures.advance_travel(travelled, delta, max_range), max_range, "stays capped")


func test_travel_completes_from_any_position_and_direction() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var delta := 1.0 / 60.0
	var max_range := DentureThrow.BASE_RANGE
	var most := ceili(max_range / (ThrownDentures.FLY_SPEED * delta))
	for i in 2000:
		var position := Vector2(rng.randf_range(-700.0, 700.0), rng.randf_range(-400.0, 400.0))
		var direction := Vector2.from_angle(rng.randf_range(0.0, TAU))
		var travelled := 0.0
		var frames := 0
		while travelled < max_range and frames < 100:
			var next := ThrownDentures.advance_travel(travelled, delta, max_range)
			position += direction * (next - travelled)
			travelled = next
			frames += 1
		assert_true(travelled >= max_range and frames <= most, "throw %d took %d frames" % [i, frames])
		if not failures.is_empty():
			return


func test_adhesive_levels_raise_bite_range_and_return() -> void:
	var adhesive := _shipped_upgrade("denture_adhesive")
	assert_true(adhesive != null, "Denture Adhesive ships")
	if adhesive == null:
		return
	assert_eq(adhesive.merchant, "black_market", "sold beside Reinforced Cane")
	assert_eq(adhesive.prices, PackedInt32Array([50, 120, 240]))
	var upgrades: Array[UpgradeDef] = [adhesive]
	# From level 2, the milestone, the default option A (Bite) adds 0.25 once.
	var bites := [1.0, 1.15, 1.55, 1.70]
	var ranges := [170.0, 210.0, 250.0, 290.0]
	var delays := [3.0, 3.0, 3.0, 2.0]
	for level in 4:
		var stats := PlayerStats.compute(upgrades, {adhesive.id: level}, _no_items())
		assert_near(stats.bite_damage_mult, bites[level], "bite at level %d" % level)
		assert_near(stats.bite_range, ranges[level], "range at level %d" % level)
		assert_near(stats.teeth_return_delay, delays[level], "return at level %d" % level)
		assert_near(stats.damage_mult, 1.0, "the cane is untouched at level %d" % level)


func test_extra_strong_dentures_bite_harder_and_through_two() -> void:
	var item := _shipped_item("strong_dentures")
	assert_true(item != null, "Extra Strong Dentures ship")
	if item == null:
		return
	var items: Array[ItemDef] = [item]
	var stats := PlayerStats.compute(_no_upgrades(), {}, items)
	assert_near(stats.bite_damage_mult, 1.5)
	assert_eq(stats.bites_per_throw, 2)
	assert_near(stats.damage_mult, 1.0, "the cane gets nothing from them any more")
	assert_true(item.description.contains("2 enemies"))


func test_the_item_and_adhesive_add_up() -> void:
	var adhesive := _shipped_upgrade("denture_adhesive")
	var item := _shipped_item("strong_dentures")
	if adhesive == null or item == null:
		assert_true(false, "both ship")
		return
	var upgrades: Array[UpgradeDef] = [adhesive]
	var items: Array[ItemDef] = [item]
	var stats := PlayerStats.compute(upgrades, {adhesive.id: 3}, items)
	assert_near(stats.bite_damage_mult, 2.20, "1.45 from the levels, 0.25 from option A and 0.5 from the item")
	assert_near(stats.bite_range, 290.0)
	assert_eq(stats.bites_per_throw, 2)


func test_one_bite_ends_a_flight_and_the_item_allows_a_second() -> void:
	assert_false(ThrownDentures.keeps_flying(1, 1))
	assert_true(ThrownDentures.keeps_flying(1, 2), "on through the first enemy")
	assert_false(ThrownDentures.keeps_flying(2, 2), "and stopped by the second")
	assert_false(ThrownDentures.keeps_flying(1, 0), "never fewer than one bite")


func test_fury_covers_the_teeth_and_the_cane() -> void:
	var run := RunState.new(_no_upgrades(), {})
	run.give_potion(Content.potion("fury_liniment"))
	run.drink_potion()
	assert_near(run.damage_mult(), 1.5)
	assert_near(run.bite_damage_mult(), 1.5)
	run.tick_buff(16.0)
	assert_near(run.bite_damage_mult(), 1.0)
	assert_true(Content.potion("fury_liniment").description.contains("dentures"))


func test_an_old_save_without_adhesive_loads_at_level_zero() -> void:
	var raw := {"version": ProgressData.VERSION, "pension": 10, "upgrades": {"reinforced_cane": 2}, "opening_seen": true}
	var data := ProgressData.from_dict(raw)
	assert_true(data != null)
	assert_eq(data.level_of("denture_adhesive"), 0)
	assert_eq(data.level_of("reinforced_cane"), 2)


# --- reach and the thrown actor ---

func test_flying_teeth_bite_the_outer_part_of_a_big_body() -> void:
	var boss := Rect2(-20, -24, 40, 48)
	assert_true(ThrownDentures.touches_body(Vector2(0, 22), boss), "22 from the center, inside the body")


func test_bite_reaches_just_past_the_body_edge() -> void:
	var body := Rect2(-10, -12, 20, 24)
	assert_true(ThrownDentures.touches_body(Vector2(10.0 + ThrownDentures.HIT_REACH, 0), body))
	assert_false(ThrownDentures.touches_body(Vector2(10.0 + ThrownDentures.HIT_REACH + 1.0, 0), body))


func test_bite_reach_is_no_worse_for_regular_enemies() -> void:
	var body := Rect2(-9, -11, 18, 22)
	for i in 36:
		var point := Vector2.from_angle(TAU * i / 36.0) * 16.0
		assert_true(ThrownDentures.touches_body(point, body), "16 from the center at step %d" % i)


func test_thrown_teeth_announce_the_catch() -> void:
	var state := DentureThrow.new()
	state.try_throw()
	state.drop()
	var teeth := ThrownDentures.new()
	teeth.setup(state, null, Vector2.RIGHT, 1.0)
	var caught := [0]
	teeth.caught.connect(func(): caught[0] += 1)
	teeth._catch()
	assert_eq(caught[0], 1)
	assert_true(state.is_held())
	teeth.free()
