extends TestCase


func test_a_blast_tells_the_items_how_many_it_hit() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/thermos.gd")
	assert_true(source.contains("effects.blast_hits(global_position, hits)"))


func test_a_thrown_thermos_lands_at_the_aim_point_within_its_reach() -> void:
	assert_eq(ThrownThermos.landing(Vector2.ZERO, Vector2(100, 0)), Vector2(100, 0))
	assert_eq(ThrownThermos.landing(Vector2.ZERO, Vector2(400, 0)), Vector2(ThrownThermos.REACH, 0))
	assert_eq(ThrownThermos.landing(Vector2(10, 10), Vector2(10, 10)), Vector2(10, 10))
	assert_near(ThrownThermos.height(0.0), 0.0)
	assert_near(ThrownThermos.height(1.0), 0.0)
	assert_true(ThrownThermos.height(0.5) > ThrownThermos.height(0.2), "it arcs")


func test_the_room_throws_when_the_stat_says_so() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var place := source.substr(source.find("func place_bomb"), 900)
	assert_true(place.contains("_run.stats.throws_thermos"))
	assert_true(place.contains("ThrownThermos.landing("))


func test_bomblets_fly_out_evenly_and_burst_on_enemies_only() -> void:
	var spots := Bomblet.spots(Vector2(100, 100), 0.0)
	assert_eq(spots.size(), Bomblet.COUNT)
	for spot in spots:
		assert_near(spot.distance_to(Vector2(100, 100)), Bomblet.SPREAD)
	assert_near(absf(wrapf(spots[1].angle_to_point(Vector2(100, 100)) - spots[0].angle_to_point(Vector2(100, 100)), -PI, PI)), deg_to_rad(120.0))
	var kit := ItemKit.new()
	var run := kit.make_run()
	var near := kit.enemy()
	near.position = Vector2(10, 0)
	var far := kit.enemy()
	far.position = Vector2(100, 0)
	var before := far.hp
	var near_before := near.hp
	assert_eq(Bomblet.burst(run.effects.ctx, Vector2.ZERO, 15.0), 1)
	assert_near(near_before - near.hp, 15.0)
	assert_near(far.hp, before)
	kit.free_enemies()


func test_bomblets_are_passing_effects() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var bomblet := Bomblet.make(run.effects.ctx, Vector2.ZERO, 15.0)
	assert_true(RoomView.is_passing_effect(bomblet))
	bomblet.free()


func test_the_walking_frame_stands_across_his_aim_and_guards() -> void:
	var root: Window = Engine.get_main_loop().root
	var frame := WalkingFrame.make(Vector2(300, 300), Vector2.RIGHT)
	root.add_child(frame)
	assert_eq(frame.global_position, Vector2(300 + WalkingFrame.AHEAD, 300))
	assert_true(frame.blocks_shot(Vector2(300 + WalkingFrame.AHEAD, 310)), "along the frame")
	assert_false(frame.blocks_shot(Vector2(300 + WalkingFrame.AHEAD + 20, 300)), "past its thickness")
	assert_true(frame.blocks_shot(Vector2(300 + WalkingFrame.AHEAD, 310)), "it never runs out")
	assert_true(ShotGuards.try_block_in([frame], Vector2(300 + WalkingFrame.AHEAD, 310)), "the framework asks it")
	assert_true(RoomView.is_passing_effect(frame))
	root.remove_child(frame)
	frame.free()
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.ctx.counting_pills = true
	var counted := WalkingFrame.make(Vector2(300, 300), Vector2.RIGHT, run.effects.ctx)
	root.add_child(counted)
	assert_false(counted.blocks_shot(Vector2(300 + WalkingFrame.AHEAD, 300)), "the full loop counts every shot")
	root.remove_child(counted)
	counted.free()
