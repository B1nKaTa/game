extends TestCase

const IDS := {"filing_cabinet": "legendary", "in_triplicate": "rare", "key_cutter": "common", "loose_paperwork": "rare",
	"rubber_stamp_collection": "common", "paper_cuts": "rare", "locksmiths_apron": "common", "desk_drawer": "rare"}


func _finisher() -> SwingAttack:
	return SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 18.0, 60.0, false, true)


func _plain_swing() -> SwingAttack:
	return SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false)


func test_the_slip_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "slip", id)
		assert_eq(item.rarity, IDS[id], id)
		assert_eq(Array(item.tags), ["slip"], id)
	assert_eq(ItemKit.item("rubber_stamp_collection").first_clear_path, "floor_1", "it takes the old stamps' source")
	assert_true(RetiredContent.is_retired("rubber_stamps"))


func test_filing_cabinet_adds_five_percent_per_slip_counted() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["filing_cabinet"])
	var enemy := kit.enemy()
	run.keys = 6
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 13.0)
	run.keys = 99
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.THERMOS), 20.0, "at most 20 count")
	kit.free_enemies()


func test_in_triplicate_makes_each_slip_two() -> void:
	var run := ItemKit.new().run_with(["in_triplicate"])
	assert_eq(run.effects.pickup(RunEffects.SLIP, 1), 2)
	assert_eq(run.effects.pickup(RunEffects.BOMB, 1), 1)


func test_key_cutter_gives_three_now_and_one_each_floor() -> void:
	var run := ItemKit.new().make_run()
	run.keys = 0
	run.add_item(ItemKit.item("key_cutter"))
	assert_eq(run.keys, 3)
	run.effects.floor_start()
	assert_eq(run.keys, 4)


func test_loose_paperwork_lays_one_sheet_per_slip_up_to_five_each_room() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["loose_paperwork"])
	var paper = run.effects.effect_of("loose_paperwork")
	run.keys = 7
	run.effects.room_enter(null)
	assert_eq(paper.sheets, 5)
	for i in 5:
		assert_true(paper.has_sheet())
		paper.use_sheet()
	assert_false(paper.has_sheet(), "gone until the next room")
	run.keys = 2
	run.effects.room_enter(null)
	assert_eq(paper.sheets, 2)


func test_the_stamp_collection_pays_fifteen_a_slip() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rubber_stamp_collection"])
	run.keys = 2
	run.use_key()
	run.use_key()
	assert_eq(kit.paid, 30)
	assert_eq(kit.sounds, ["form_filed", "form_filed"] as Array[String])


func test_paper_cuts_fling_a_slip_with_each_finisher_only() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["paper_cuts"])
	run.keys = 3
	run.effects.swing(_plain_swing())
	assert_eq(kit.fx_of(ItemFx.FxNeedle).size(), 0)
	run.effects.swing(_finisher())
	assert_eq(kit.fx_of(ItemFx.FxNeedle).size(), 1)
	assert_eq(run.keys, 3, "it costs no Slip")


func test_locksmiths_apron_takes_a_slip_off() -> void:
	assert_eq(ItemKit.new().run_with(["locksmiths_apron"]).stats.slip_cost_cut, 1)


func test_desk_drawer_links_the_first_slip_and_thermos_of_each_room() -> void:
	var run := ItemKit.new().run_with(["desk_drawer"])
	run.keys = 0
	run.bombs = 0
	run.effects.room_enter(null)
	run.effects.pickup(RunEffects.SLIP, 1)
	assert_eq(run.bombs, 1)
	run.effects.pickup(RunEffects.SLIP, 1)
	assert_eq(run.bombs, 1, "once a room")
	run.effects.pickup(RunEffects.BOMB, 1)
	assert_eq(run.keys, 1)
	run.effects.room_enter(null)
	run.effects.pickup(RunEffects.SLIP, 1)
	assert_eq(run.bombs, 2)
