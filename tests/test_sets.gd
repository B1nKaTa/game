extends TestCase

const Counting := preload("res://tests/support/counting_effect.gd")


func _item(id: String, build: String, kind := ItemDef.KIND_PASSIVE) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id.capitalize()
	item.build = build
	item.kind = kind
	return item


func _set_def(id: String, build: String) -> SetDef:
	var def := SetDef.new()
	def.id = id
	def.display_name = id.capitalize()
	def.build = build
	return def


func _run_with_sets(defs: Array[SetDef]) -> RunState:
	var run := ItemKit.new().make_run()
	run.effects.set_sets(defs)
	return run


func test_a_set_forms_at_three_of_its_build_and_only_once() -> void:
	var run := _run_with_sets([_set_def("tea", "thermos")] as Array[SetDef])
	var formed: Array = []
	run.effects.set_formed.connect(func(def: SetDef): formed.append(def.id))
	run.add_item(_item("a", "thermos"))
	run.add_item(_item("b", "thermos"))
	run.add_item(_item("c", "slip"))
	assert_false(run.effects.has_set("tea"))
	run.add_item(_item("d", "thermos"))
	assert_true(run.effects.has_set("tea"))
	run.add_item(_item("e", "thermos"))
	assert_eq(formed, ["tea"])


func test_the_held_active_counts_for_its_build() -> void:
	var run := _run_with_sets([_set_def("clerk", "slip")] as Array[SetDef])
	run.add_item(_item("a", "slip"))
	run.add_item(_item("b", "slip"))
	run.add_item(_item("desk", "slip", ItemDef.KIND_ACTIVE))
	assert_true(run.effects.has_set("clerk"))


func test_the_pets_set_counts_pet_items_only() -> void:
	var run := _run_with_sets([_set_def("lover", "pets")] as Array[SetDef])
	run.add_item(_item("treats", "pets"))
	run.add_item(_item("p1", "pets", ItemDef.KIND_PET))
	run.add_item(_item("p2", "pets", ItemDef.KIND_PET))
	assert_false(run.effects.has_set("lover"), "a pets-build passive is no pet")
	run.add_item(_item("p3", "pets", ItemDef.KIND_PET))
	assert_true(run.effects.has_set("lover"))


func test_a_sets_stats_count_and_its_effect_runs_after_the_items() -> void:
	var spry := _set_def("spry", "dodge")
	spry.bonus_dodge_charges = 1
	spry.effect = Counting.new()
	var run := _run_with_sets([spry] as Array[SetDef])
	for id in ["a", "b", "c"]:
		run.add_item(_item(id, "dodge"))
	assert_eq(run.stats.dodge_charges, 2)
	run.effects.tick(0.1)
	var copy = run.effects.effect_of("spry")
	assert_eq(int(copy.counts.get("tick", 0)), 1)
	assert_eq(int(copy.counts.get("gain", 0)), 1)


func test_a_formed_set_stays_after_a_swap_and_comes_back_on_a_resume() -> void:
	var clerk := _set_def("clerk", "slip")
	var run := _run_with_sets([clerk] as Array[SetDef])
	run.add_item(_item("a", "slip"))
	run.add_item(_item("b", "slip"))
	var desk := _item("desk", "slip", ItemDef.KIND_ACTIVE)
	run.add_item(desk)
	var bell := _item("bell", "pets", ItemDef.KIND_ACTIVE)
	run.add_item(bell)
	assert_true(run.effects.has_set("clerk"), "a swap never unforms it")
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	back.effects.set_sets([clerk] as Array[SetDef])
	var shipped: Array[ItemDef] = [run.items[0], run.items[1], desk, bell]
	RunCheckpoint.apply_run(back, raw, shipped)
	assert_true(back.effects.has_set("clerk"))


func test_the_banner_names_the_set_and_the_summary_lists_it() -> void:
	assert_eq(Hud.set_banner_text("Tea Lady"), "SET: Tea Lady")
	var run := _run_with_sets([_set_def("tea", "thermos")] as Array[SetDef])
	for id in ["a", "b", "c"]:
		run.add_item(_item(id, "thermos"))
	assert_true(run.effects.bonus_names().has("Tea"))


func test_the_old_pair_combos_are_retired_and_runs_know_the_sets() -> void:
	assert_true(Content.combos().is_empty())
	assert_eq(RetiredContent.RETIRED_COMBOS.size(), 12)
	assert_true(FileAccess.get_file_as_string("res://scripts/autoload/progress.gd").contains("run.effects.set_sets(Content.sets())"))
	assert_true(FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd").contains("_run.effects.set_formed.connect(_on_set_formed)"))
