extends TestCase

# The active slot: one held at a time, charged by fight rooms (or once a floor), used with its own key,
# swapped by taking another.

const TestActive := preload("res://tests/support/test_active_effect.gd")
const Counting := preload("res://tests/support/counting_effect.gd")


func _active(id: String, rooms := 2, per_floor := false) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id.capitalize()
	item.kind = ItemDef.KIND_ACTIVE
	item.charge_rooms = rooms
	item.charge_per_floor = per_floor
	item.effect = TestActive.new()
	return item


func test_a_new_active_arrives_charged_and_is_held_apart_from_items() -> void:
	var run := ItemKit.new().make_run()
	var bell := _active("bell", 2)
	run.add_item(bell)
	assert_eq(run.active, bell)
	assert_true(run.items.is_empty(), "actives are not in the item list")
	assert_true(run.has_item("bell"), "but the pools see it as held")
	assert_true(run.active_ready())
	assert_eq(run.found, ["bell"] as Array[String], "the case file counts it as found")


func test_using_spends_the_charge_and_fight_rooms_fill_it_again() -> void:
	var run := ItemKit.new().make_run()
	run.add_item(_active("bell", 2))
	assert_true(run.use_active())
	assert_eq(run.effects.active_effect().uses, 1)
	assert_false(run.active_ready())
	assert_false(run.use_active(), "empty")
	run.effects.room_clear(null)
	assert_false(run.active_ready())
	run.effects.room_clear(null)
	assert_true(run.active_ready())
	run.effects.room_clear(null)
	assert_eq(run.active_charge, 2, "never past full")


func test_a_refused_or_idle_use_keeps_the_charge() -> void:
	var run := ItemKit.new().make_run()
	run.add_item(_active("bell", 2))
	run.effects.active_effect().allow = false
	assert_false(run.use_active())
	assert_true(run.active_ready())
	run.effects.active_effect().allow = true
	run.effects.active_effect().does = false
	assert_false(run.use_active())
	assert_true(run.active_ready())


func test_a_once_a_floor_active_fills_at_each_floor_start() -> void:
	var run := ItemKit.new().make_run()
	run.add_item(_active("ticket", 0, true))
	assert_eq(run.active_needed(), 1)
	assert_true(run.use_active())
	run.effects.room_clear(null)
	assert_false(run.active_ready(), "rooms do not fill it")
	run.effects.floor_start()
	assert_true(run.active_ready())


func test_taking_another_swaps_and_the_old_one_keeps_its_charge() -> void:
	var run := ItemKit.new().make_run()
	var seen: Array = []
	run.active_swapped.connect(func(old: ItemDef, charge: int): seen.append([old.id, charge]))
	run.add_item(_active("bell", 3))
	run.use_active()
	run.effects.room_clear(null)
	run.add_item(_active("frame", 2))
	assert_eq(run.active.id, "frame")
	assert_true(run.active_ready(), "the new one arrives charged")
	assert_eq(seen, [["bell", 1]])
	assert_false(run.has_item("bell"))
	run.add_item(_active("bell", 3), 1)
	assert_eq(run.active_charge, 1, "taking a dropped one back brings back its charge")


func test_the_active_survives_the_checkpoint_with_its_charge_and_state() -> void:
	var run := ItemKit.new().make_run()
	var bell := _active("bell", 3)
	run.add_item(bell)
	run.use_active()
	run.effects.room_clear(null)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	var shipped: Array[ItemDef] = [bell]
	RunCheckpoint.apply_run(back, raw, shipped)
	assert_eq(back.active, bell)
	assert_eq(back.active_charge, 1)
	assert_eq(back.effects.active_effect().uses, 1, "its state came back")


func test_the_active_hears_the_usual_hooks_and_leaves_with_the_items() -> void:
	var run := ItemKit.new().make_run()
	var item := _active("counting", 2)
	item.effect = Counting.new()
	run.add_item(item)
	run.effects.tick(0.1)
	assert_eq(int(run.effects.active_effect().counts.get("tick", 0)), 1)
	assert_eq(run.effects.effect_of("counting"), run.effects.active_effect())
	run.clear_items()
	assert_true(run.active == null, "leaving the Training Yard drops the active too")
	assert_true(run.effects.active_effect() == null)


func test_new_hook_dispatchers_default_to_no_change() -> void:
	var run := ItemKit.new().make_run()
	assert_near(run.effects.pet_damage_scale(), 1.0)
	assert_false(run.effects.excuses_rule_break())
	assert_false(run.effects.sides_with_you())
	run.effects.blast_hits(Vector2.ZERO, 3)
	assert_true(RunEffects.is_his_hit(RunEffects.SWING))
	assert_true(RunEffects.is_his_hit("era"))
	assert_false(RunEffects.is_his_hit(RunEffects.PET))
	assert_false(RunEffects.is_his_hit(RunEffects.ALLY))
