extends TestCase

const Counting := preload("res://tests/support/counting_effect.gd")


func _item(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id
	return item


func _combo(a: String, b: String) -> ComboDef:
	var combo := ComboDef.new()
	combo.id = "%s_%s" % [a, b]
	combo.display_name = "Pair of %s and %s" % [a, b]
	combo.item_a = a
	combo.item_b = b
	return combo


func _run_with_combos(combos: Array[ComboDef]) -> RunState:
	var none: Array[UpgradeDef] = []
	var run := RunState.new(none, {})
	run.effects.set_combos(combos)
	return run


func test_a_combo_forms_only_with_both_items_and_only_once() -> void:
	var combo := _combo("a", "b")
	var run := _run_with_combos([combo] as Array[ComboDef])
	var formed: Array = []
	run.effects.combo_formed.connect(formed.append)
	run.add_item(_item("a"))
	assert_false(run.effects.has_combo(combo.id))
	run.add_item(_item("b"))
	assert_true(run.effects.has_combo(combo.id))
	run.add_item(_item("c"))
	assert_eq(formed.size(), 1)
	assert_eq(run.effects.combo_names(), PackedStringArray([combo.display_name]))


func test_a_combos_stats_count() -> void:
	var combo := _combo("a", "b")
	combo.death_pension_bonus = 0.25
	combo.bonus_pills = 1
	var run := _run_with_combos([combo] as Array[ComboDef])
	var pills := run.stats.max_pills
	run.add_item(_item("a"))
	run.add_item(_item("b"))
	assert_eq(run.stats.max_pills, pills + 1)
	assert_near(run.stats.death_pension_bonus, 0.25)


func test_a_combos_effect_runs_after_the_items() -> void:
	var combo := _combo("a", "b")
	var effect: ItemEffect = Counting.new()
	effect.tag = "combo"
	combo.effect = effect
	var kit := ItemKit.new()
	var run := _run_with_combos([combo] as Array[ComboDef])
	kit.wire(run)
	var first := _item("a")
	var own: ItemEffect = Counting.new()
	own.tag = "item"
	first.effect = own
	run.add_item(first)
	run.add_item(_item("b"))
	kit.notices.clear()
	run.effects.dodge(Vector2.UP)
	assert_eq(kit.notices, ["item:dodge", "combo:dodge"] as Array[String])


func test_dropping_the_items_ends_the_combo() -> void:
	var combo := _combo("a", "b")
	var run := _run_with_combos([combo] as Array[ComboDef])
	run.add_item(_item("a"))
	run.add_item(_item("b"))
	run.clear_items()
	assert_true(run.effects.active_combos().is_empty())


func test_the_banner_names_the_combo() -> void:
	assert_eq(Hud.banner_text("Full Set"), "COMBO: Full Set")
	# Combos are retired from the paused map, which lists the run's formed sets instead.
	assert_eq(FloorMapView.sets_line(PackedStringArray(["Full Set", "Night Shift"])), "Sets: Full Set, Night Shift")
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("combo_formed.connect(") and scene.contains("_hud.show_combo("))


func test_every_shipped_combo_names_two_shipped_items() -> void:
	var ids := {}
	for item in Content.items():
		ids[item.id] = true
	var uses := {}
	for combo in Content.combos():
		assert_false(combo.display_name.is_empty(), combo.id)
		assert_true(ids.has(combo.item_a) and ids.has(combo.item_b), combo.id)
		assert_true(combo.item_a != combo.item_b, combo.id)
		for id in [combo.item_a, combo.item_b]:
			uses[id] = int(uses.get(id, 0)) + 1
	for id in uses:
		assert_true(uses[id] <= 2, "%s is in %d combos" % [id, uses[id]])


func test_runs_made_by_progress_know_the_shipped_combos() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/autoload/progress.gd")
	assert_true(source.contains("run.effects.set_combos(Content.combos())"))
