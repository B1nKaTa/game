extends TestCase

const FULL_CLEAR_PENSION := 125


func _run() -> RunState:
	var upgrades: Array[UpgradeDef] = []
	return RunState.new(upgrades, {})


func _potion(id: String) -> PotionDef:
	return Content.potion(id)


# --- the potions themselves ---

func test_the_potion_data_loads() -> void:
	assert_eq(Content.potions().size(), 11)
	assert_eq(_potion("healing_tonic").heal, 2)
	assert_eq(_potion("small_potion").heal, 1)
	assert_true(_potion("swift_tea").has_buff())
	assert_true(_potion("fury_liniment").has_buff())
	assert_false(_potion("healing_tonic").has_buff())
	assert_true(Content.potion("nothing_like_it") == null)


func test_a_small_potion_is_found_never_sold() -> void:
	assert_false(_potion("small_potion").is_for_sale())
	for def in Content.potions_for_sale():
		assert_true(def.id != "small_potion")
	assert_eq(Content.potions_for_sale().size(), 3)


func test_a_brew_never_costs_more_than_a_fifth_of_a_full_clear() -> void:
	# Income is about 125 Pension a clear and the permanent upgrades total 2055 plus the Thermos
	# fuel. A brew is bought every run it is wanted, so it has to stay cheap beside them.
	for def in Content.potions_for_sale():
		assert_true(def.price * 5 <= FULL_CLEAR_PENSION, "%s costs %d" % [def.id, def.price])
		assert_true(def.price >= 5, "%s is not free" % def.id)


func test_buffs_are_short() -> void:
	for def in Content.potions():
		if def.has_buff():
			assert_true(def.duration <= 20.0 and def.duration >= 5.0, def.id)


# --- the slot ---

func test_the_slot_holds_one_potion_and_refuses_a_second() -> void:
	var run := _run()
	assert_true(run.can_take_potion())
	assert_true(run.give_potion(_potion("swift_tea")))
	assert_false(run.can_take_potion())
	assert_false(run.give_potion(_potion("healing_tonic")), "a full slot takes nothing")
	assert_eq(run.potion.id, "swift_tea", "and keeps what it has")
	assert_false(run.give_potion(null))


func test_healing_waits_until_it_helps() -> void:
	var run := _run()
	run.give_potion(_potion("healing_tonic"))
	assert_false(run.can_drink_potion(), "full pills")
	assert_false(run.drink_potion())
	assert_eq(run.potion.id, "healing_tonic", "not wasted")
	run.health.hit(3)
	var before := run.health.pills
	assert_true(run.drink_potion())
	assert_eq(run.health.pills, before + 2)
	assert_true(run.potion == null)
	assert_false(run.drink_potion(), "an empty slot does nothing")


func test_a_small_potion_heals_one_pill() -> void:
	var run := _run()
	run.health.hit(2)
	run.give_potion(_potion("small_potion"))
	var before := run.health.pills
	assert_true(run.drink_potion())
	assert_eq(run.health.pills, before + 1)


func test_a_buff_can_be_drunk_at_full_pills() -> void:
	var run := _run()
	run.give_potion(_potion("swift_tea"))
	assert_true(run.can_drink_potion())
	assert_true(run.drink_potion())
	assert_true(run.buff != null)


func test_swift_tea_speeds_him_up_then_runs_out() -> void:
	var run := _run()
	var base := run.stats.move_speed
	assert_near(run.move_speed(), base)
	run.give_potion(_potion("swift_tea"))
	run.drink_potion()
	assert_near(run.move_speed(), base * 1.4)
	run.tick_buff(14.0)
	assert_near(run.move_speed(), base * 1.4)
	run.tick_buff(1.1)
	assert_near(run.move_speed(), base)
	assert_true(run.buff == null)


func test_fury_adds_cane_and_bite_damage_then_runs_out() -> void:
	var run := _run()
	assert_near(run.damage_mult(), 1.0)
	run.give_potion(_potion("fury_liniment"))
	run.drink_potion()
	assert_near(run.damage_mult(), 1.5)
	assert_near(run.bite_damage_mult(), 1.5, "the dentures hit harder too")
	run.tick_buff(16.0)
	assert_near(run.damage_mult(), 1.0)
	assert_near(run.bite_damage_mult(), 1.0)


func test_drinking_the_next_buff_replaces_the_running_one() -> void:
	var run := _run()
	run.give_potion(_potion("swift_tea"))
	run.drink_potion()
	run.give_potion(_potion("fury_liniment"))
	run.drink_potion()
	assert_near(run.move_speed(), run.stats.move_speed, "the old buff is gone")
	assert_near(run.damage_mult(), 1.5)


func test_potions_change_nothing_about_the_permanent_stats() -> void:
	var run := _run()
	run.give_potion(_potion("fury_liniment"))
	run.drink_potion()
	assert_near(run.stats.damage_mult, 1.0)
	assert_near(run.stats.thermos_damage_mult, 1.0, "a Thermos is not a cane")


func test_the_slot_tells_the_hud_when_it_changes() -> void:
	var run := _run()
	var changes := [0]
	run.changed.connect(func(): changes[0] += 1)
	run.give_potion(_potion("swift_tea"))
	run.drink_potion()
	run.tick_buff(20.0)
	assert_eq(changes[0], 3, "filled, drunk, buff over")


# --- the drink key and the HUD slot ---

func test_the_potion_key_is_a_rebindable_action_on_h() -> void:
	KeyBindings.reset_to_defaults()
	var found := false
	for entry in KeyBindings.ACTIONS:
		if entry["action"] == "potion":
			found = true
	assert_true(found)
	assert_eq(KeyBindings.label_for("potion"), "H")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_G
	KeyBindings.rebind("potion", key)
	assert_eq(KeyBindings.label_for("potion"), "G")
	KeyBindings.reset_to_defaults()


func test_taking_the_potion_key_swaps_with_its_owner() -> void:
	KeyBindings.reset_to_defaults()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	KeyBindings.rebind("potion", key)
	assert_eq(KeyBindings.label_for("potion"), "E")
	assert_eq(KeyBindings.label_for("interact"), "H")
	KeyBindings.reset_to_defaults()


func test_the_slot_text() -> void:
	assert_eq(PotionSlot.name_text("H", null), "[H] -")
	assert_eq(PotionSlot.name_text("H", _potion("swift_tea")), "[H] Swift")
	assert_eq(PotionSlot.buff_text(null, 5.0), "")
	assert_eq(PotionSlot.buff_text(_potion("fury_liniment"), 0.0), "")
	assert_eq(PotionSlot.buff_text(_potion("fury_liniment"), 11.2), "Fury 12s")


func test_short_names_fit_the_slot() -> void:
	for def in Content.potions():
		assert_true(def.short_name.length() > 0 and def.short_name.length() <= 8, def.id)


func test_the_panel_texts() -> void:
	assert_true(PotionPanel.status_text("").contains("One brew"))
	assert_true(PotionPanel.status_text("Swift Tea").contains("Swift Tea"))
	assert_eq(PotionPanel.button_text(_potion("swift_tea")), "Swift Tea   12 Pension")


# --- barrels no longer heal on the spot ---

func test_barrels_still_drop_small_potions() -> void:
	var seen := false
	for i in 1000:
		if RoomRules.barrel_drop(i / 1000.0) == RoomRules.DROP_POTION:
			seen = true
	assert_true(seen)
	assert_eq(RoomRules.SMALL_POTION_ID, "small_potion")
	assert_true(_potion(RoomRules.SMALL_POTION_ID) != null)


# --- saving ---

func test_floors_cleared_and_the_brew_survive_saving() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared()
	data.record_floor_cleared()
	data.pension = 50
	assert_true(data.brew("swift_tea", 12))
	var back := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(back.floors_cleared, 2)
	assert_eq(back.brewed_potion, "swift_tea")
	assert_eq(back.pension, 38)


func test_an_older_save_without_the_new_fields_still_loads() -> void:
	var old := {"version": 1, "pension": 77, "upgrades": {"better_knees": 2}, "opening_seen": true, "retirement_balance": 10, "run_count": 4}
	var data := ProgressData.from_dict(old)
	assert_true(data != null, "an older save must load")
	assert_eq(data.floors_cleared, 0)
	assert_eq(data.brewed_potion, "")
	assert_eq(data.pension, 77)
	assert_eq(data.level_of("better_knees"), 2)
	var oldest := ProgressData.from_dict({"version": 1, "pension": 0, "upgrades": {}, "opening_seen": false})
	assert_true(oldest != null)
	assert_eq(oldest.floors_cleared, 0)


func test_damaged_new_fields_fall_back_instead_of_breaking_the_save() -> void:
	var raw := {"version": 1, "pension": 5, "upgrades": {}, "opening_seen": true, "floors_cleared": -4, "brewed_potion": 12}
	var data := ProgressData.from_dict(raw)
	assert_true(data != null)
	assert_eq(data.floors_cleared, 0)
	assert_eq(data.brewed_potion, "")


func test_a_brew_costs_pension_and_only_one_waits() -> void:
	var data := ProgressData.new()
	data.pension = 30
	assert_false(data.can_brew(0), "a free price is not for sale")
	assert_true(data.brew("healing_tonic", 20))
	assert_eq(data.pension, 10)
	assert_false(data.can_brew(12), "one brew is already waiting")
	assert_false(data.brew("swift_tea", 12))
	assert_eq(data.brewed_potion, "healing_tonic")
	assert_eq(data.take_brewed_potion(), "healing_tonic")
	assert_eq(data.brewed_potion, "")
	assert_eq(data.take_brewed_potion(), "")
	assert_false(data.brew("swift_tea", 12), "not enough Pension left")
	assert_eq(data.pension, 10)


# --- merchants open on floors cleared ---

func test_merchants_open_on_floors_cleared() -> void:
	var entries := [{"id": "always"}, {"id": "potions", "clears": 1}, {"id": "bombs", "clears": 3}]
	var data := ProgressData.new()
	assert_eq(MerchantRules.open_ones(entries, data).size(), 1)
	data.record_floor_cleared(1, "floor_1")
	assert_eq(MerchantRules.open_ones(entries, data).size(), 2)
	data.record_floor_cleared(1, "cemetery")
	assert_eq(MerchantRules.open_ones(entries, data).size(), 2)
	data.record_floor_cleared(1, "floor_1")
	assert_eq(MerchantRules.open_ones(entries, data).size(), 3)
	assert_true(MerchantRules.is_open({"id": "x"}, ProgressData.new()), "no requirement means always there")
