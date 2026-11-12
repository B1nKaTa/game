extends TestCase

const Scale := preload("res://tests/support/scale_effect.gd")


func _pet_item(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id.capitalize()
	item.kind = ItemDef.KIND_PET
	item.build = "pets"
	var effect := PetEffect.new()
	effect.look = id
	item.effect = effect
	return item


func _stat_item(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	return item


func test_pets_count_and_extra_pets_count_too() -> void:
	var run := ItemKit.new().make_run()
	assert_eq(run.pet_count(), 0)
	run.add_item(_pet_item("rex_test"))
	run.add_item(_pet_item("mittens_test"))
	assert_eq(run.pet_count(), 2)
	var cat := _stat_item("cat_bonus")
	cat.extra_pets = 1
	run.add_item(cat)
	assert_eq(run.pet_count(), 3)


func test_the_pet_multiplier_adds_bonuses_and_multiplies_scales() -> void:
	var run := ItemKit.new().make_run()
	assert_near(run.pet_damage_mult(), 1.0)
	var treats := _stat_item("treats")
	treats.pet_damage_bonus = 0.5
	run.add_item(treats)
	assert_near(run.pet_damage_mult(), 1.5)
	var bell := _stat_item("bell")
	bell.effect = Scale.new()
	run.add_item(bell)
	assert_near(run.pet_damage_mult(), 3.0)


func test_a_pet_hit_lands_as_a_pet_hit_scaled_by_the_multiplier() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_pet_item("rex_test"))
	var treats := _stat_item("treats")
	treats.pet_damage_bonus = 0.5
	run.add_item(treats)
	var effect: PetEffect = run.effects.effect_of("rex_test")
	var enemy := kit.enemy()
	var before := enemy.hp
	assert_true(effect.strike(run.effects.ctx, enemy, 6.0))
	assert_near(before - enemy.hp, 9.0)
	run.effects.ctx.counting_exact = true
	assert_false(effect.strike(run.effects.ctx, enemy, 6.0), "the full loop counts damage exactly")
	kit.free_enemies()


func test_a_pet_finds_the_nearest_enemy_in_reach() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_pet_item("rex_test"))
	var effect: PetEffect = run.effects.effect_of("rex_test")
	var far := kit.enemy()
	far.position = Vector2(100, 0)
	var near := kit.enemy()
	near.position = Vector2(50, 0)
	var boss := kit.enemy("regional_reaper")
	boss.position = Vector2(10, 0)
	assert_eq(effect.nearest(run.effects.ctx, 160.0), boss)
	assert_eq(effect.nearest(run.effects.ctx, 160.0, true), near, "regular only skips the boss")
	assert_true(effect.nearest(run.effects.ctx, 5.0) == null)
	assert_eq(effect.nearest_where(run.effects.ctx, 160.0, func(enemy: Enemy) -> bool: return enemy == far), far)
	kit.free_enemies()


func test_each_pet_places_its_body_in_every_room_on_its_own_slot() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_pet_item("rex_test"))
	run.add_item(_pet_item("mittens_test"))
	run.effects.room_enter(null)
	assert_eq(kit.fx.filter(func(entry): return entry["script"] == Pet).size(), 2)
	assert_eq(run.effects.effect_of("rex_test").slot, 0)
	assert_eq(run.effects.effect_of("mittens_test").slot, 1)
	var seen := {}
	for i in 6:
		var offset := Pet.slot_offset(i)
		assert_false(seen.has(offset), "slot %d has its own spot" % i)
		seen[offset] = true


# Nothing in a test is in a started tree, so a context that says Harold and a room are there, as in play. Its
# add_fx hands the body to the on_fx listener and frees it, as the real one does with no room.
class StagedContext extends EffectContext:
	func has_player() -> bool:
		return true


	func has_room() -> bool:
		return true


	func feet() -> Vector2:
		return Vector2.ZERO


	func add_fx(node: Node2D, _at: Vector2) -> Node2D:
		if on_fx.is_valid():
			on_fx.call(node)
		node.free()
		return null


# Puts the staged context in the run, wired to the kit.
func _stage(kit: ItemKit, run: RunState) -> void:
	run.effects.ctx = StagedContext.new(run)
	kit.wire(run)


func _bodies(kit: ItemKit) -> int:
	return kit.fx.filter(func(entry): return entry["script"] == Pet).size()


func test_a_pet_gained_in_a_room_places_its_body_at_once() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	_stage(kit, run)
	run.add_item(_pet_item("rex_test"))
	assert_eq(_bodies(kit), 1, "the body stands by him the moment the pet is taken")
	run.effects.room_enter(null)
	assert_eq(_bodies(kit), 2, "the next room places exactly one more")


func test_a_pet_gained_with_no_room_places_nothing_until_a_room() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_pet_item("rex_test"))
	assert_eq(_bodies(kit), 0)
	run.effects.room_enter(null)
	assert_eq(_bodies(kit), 1)


func test_a_resumed_pet_places_nothing_until_a_room() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	_stage(kit, run)
	run.effects.add(_pet_item("rex_test"), false)
	assert_eq(_bodies(kit), 0, "a resumed run gets no body on restoring")


func test_every_shipped_pet_places_its_body_when_taken() -> void:
	var ids: Array[String] = []
	for item in Content.all_items():
		if item.effect is PetEffect:
			ids.append(item.id)
	assert_true(ids.size() >= 10, "the shipped pets were found")
	for id in ids:
		var kit := ItemKit.new()
		var run := kit.make_run()
		_stage(kit, run)
		run.add_item(kit.item(id))
		var expected := 2 if id == "moths" else 1
		assert_eq(_bodies(kit), expected, "%s shows at once" % id)
		run.effects.room_enter(null)
		assert_eq(_bodies(kit), expected * 2, "%s places the same count in the next room" % id)
	

# The run-tests root is not in a started tree, so the guards are asked through try_block_in with the
# nodes the group would hold (the repo's way for group-wide helpers).
func test_a_pet_body_is_a_passing_effect_and_never_blocks_by_itself() -> void:
	var pet := Pet.make("rex", Color("8a5a2b"), 0)
	assert_true(RoomView.is_passing_effect(pet))
	pet.global_position = Vector2(200, 200)
	assert_false(ShotGuards.try_block_in([pet], Vector2(200, 200)), "a pet with no guard rule blocks nothing")
	pet.free()


func test_a_guard_blocks_a_shot_in_reach_only_when_ready_and_spends() -> void:
	var guard := ShotGuard.new()
	guard.radius = 10.0
	var state := {"ready": true, "spent": 0}
	guard.check = func() -> bool: return state["ready"]
	guard.spend = func() -> void:
		state["spent"] += 1
		state["ready"] = false
	guard.global_position = Vector2(300, 300)
	assert_false(ShotGuards.try_block_in([guard], Vector2(340, 300)), "out of reach")
	assert_true(ShotGuards.try_block_in([guard], Vector2(305, 300)))
	assert_eq(state["spent"], 1)
	assert_false(ShotGuards.try_block_in([guard], Vector2(305, 300)), "spent until ready again")
	guard.free()


func test_no_guard_blocks_or_spends_while_pills_are_counted() -> void:
	var guard := ShotGuard.new()
	guard.radius = 10.0
	var state := {"spent": 0}
	guard.check = func() -> bool: return true
	guard.spend = func() -> void: state["spent"] += 1
	guard.global_position = Vector2(300, 300)
	assert_true(ShotGuards.try_block_in([guard], Vector2(305, 300), false), "ready and in reach: blocked")
	assert_eq(state["spent"], 1)
	assert_false(ShotGuards.try_block_in([guard], Vector2(305, 300), true), "pills are being counted")
	assert_eq(state["spent"], 1, "nothing spent while counting")
	guard.free()


func test_a_shot_reads_the_counting_switch_from_the_run_it_aims_at() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var target := PillTarget.new()
	target.run = run
	var shot := Projectile.new()
	shot.setup(Vector2.RIGHT, 100.0, target, 1)
	assert_false(shot._counting_pills())
	run.effects.ctx.counting_pills = true
	assert_true(shot._counting_pills())
	shot.free()
	target.free()
	var decoy := Node2D.new()
	var other := Projectile.new()
	other.setup(Vector2.RIGHT, 100.0, decoy, 1)
	assert_false(other._counting_pills(), "a decoy has no run")
	other.free()
	decoy.free()


class PillTarget extends Node2D:
	var run: RunState


func test_projectiles_ask_the_guards_before_their_target() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/projectile.gd")
	var guard_at := source.find("ShotGuards.try_block(get_tree(), global_position, _counting_pills())")
	assert_true(guard_at > 0)
	assert_true(guard_at < source.find("_target.take_hit("), "a guard stops the shot before it reaches him")
