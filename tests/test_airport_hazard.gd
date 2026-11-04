extends TestCase

# Departures, Terminal Zero's hazard: queue barrier lines that rise on a timer after a chime and a
# flash, and while up block Grandpa and his dentures only.


func _room_with(changes: Dictionary) -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	rows[4] = rows[4].substr(0, 9) + "H" + rows[4].substr(10)
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray(rows)
	return layout


func _line(row: int, from: int, to: int) -> Dictionary:
	var changes := {}
	for x in range(from, to + 1):
		changes[Vector2i(x, row)] = RoomLayout.SYMBOL_BARRIER
	return changes


func _barrier(across := true) -> QueueBarrier:
	var barrier := QueueBarrier.new()
	barrier.setup(Vector2i(5, 5), across)
	barrier.position = RoomBackdrop.cell_center(Vector2i(5, 5))
	barrier._ready()
	return barrier


# --- the timer ---

func test_a_barrier_chimes_then_rises_then_drops() -> void:
	var cycle := BarrierCycle.new(10.0, 3.0, 1.0)
	assert_false(cycle.is_up_at(0.5), "it starts down")
	assert_false(cycle.is_chiming(0.5))
	assert_true(cycle.is_chiming(6.5), "the chime comes just before it rises")
	assert_false(cycle.is_up_at(6.5))
	assert_true(cycle.is_up_at(7.5), "then the rope is up")
	assert_false(cycle.is_chiming(7.5), "and the chime is over")
	assert_true(cycle.is_up_at(9.9))
	assert_false(cycle.is_up_at(10.1), "it drops at the end of the period")


func test_the_timer_repeats() -> void:
	var cycle := BarrierCycle.new(10.0, 3.0, 1.0)
	for lap in 5:
		var start := lap * 10.0
		assert_false(cycle.is_up_at(start + 2.0), "lap %d" % lap)
		assert_true(cycle.is_chiming(start + 6.2), "lap %d" % lap)
		assert_true(cycle.is_up_at(start + 8.0), "lap %d" % lap)


func test_the_chime_always_comes_before_each_rise() -> void:
	var cycle := BarrierCycle.new(QueueBarrier.PERIOD, QueueBarrier.UP_TIME, QueueBarrier.CHIME)
	var time := 0.0
	var chimed_for := 0.0
	var was_up := cycle.is_up_at(0.0)
	var frame := 0
	while time < 80.0:
		var step := 0.016 if frame % 4 != 0 else 0.05
		frame += 1
		time += step
		if cycle.is_chiming(time):
			chimed_for += step
		var up := cycle.is_up_at(time)
		if up and not was_up:
			assert_true(chimed_for >= QueueBarrier.CHIME - 0.06, "a rise at %f came after a %f chime" % [time, chimed_for])
			chimed_for = 0.0
		was_up = up


func test_each_rise_is_counted_once_however_the_frames_fall() -> void:
	var cycle := BarrierCycle.new(10.0, 3.0, 1.0)
	var rises := 0
	var time := 0.0
	for frame in 3000:
		var step := 0.016 if frame % 3 != 0 else 0.033
		rises += cycle.rises_between(time, time + step)
		time += step
	assert_eq(rises, floori((time - 7.0) / 10.0) + 1)
	assert_eq(cycle.rises_between(6.9, 7.1), 1)
	assert_eq(cycle.rises_between(7.1, 16.9), 0)


func test_the_warning_leaves_time_to_step_off_the_line() -> void:
	var walk := PlayerStats.BASE_SPEED * (QueueBarrier.CHIME - 0.3)
	assert_true(walk > RoomBackdrop.TILE, "a whole cell in the chime, less reaction time: %f" % walk)
	assert_true(QueueBarrier.CHIME * PlayerStats.BASE_WARNING >= 0.2)


func test_twice_as_fast_keeps_the_whole_chime() -> void:
	var cycle := BarrierCycle.new(10.0, 3.0, 1.0)
	var fast := BarrierCycle.faster(cycle, 2.0)
	assert_near(fast.period, 5.0)
	assert_near(fast.up_time, 1.5)
	assert_near(fast.chime, 1.0, "the warning never shortens")
	assert_true(fast.is_chiming(fast.rise_at() - 0.5))
	assert_true(fast.is_up_at(fast.rise_at() + 0.1))


# --- one barrier ---

func test_a_barrier_body_blocks_only_while_its_rope_is_up() -> void:
	var barrier := _barrier()
	assert_eq(barrier._body.collision_layer, 0, "down, it blocks nothing")
	assert_eq(barrier._body.collision_mask, 0)
	barrier.advance(QueueBarrier.PERIOD - QueueBarrier.UP_TIME - 0.5)
	assert_true(barrier.is_chiming())
	assert_eq(barrier._body.collision_layer, 0, "a chime only warns")
	barrier.advance(0.6)
	assert_true(barrier.is_up())
	assert_eq(barrier._body.collision_layer, QueueBarrier.LAYER)
	barrier.advance(QueueBarrier.UP_TIME)
	assert_false(barrier.is_up())
	assert_eq(barrier._body.collision_layer, 0, "and drops again")
	barrier.free()


func test_only_grandpa_and_his_dentures_test_the_barrier_layer() -> void:
	assert_true(QueueBarrier.LAYER != 1 and QueueBarrier.LAYER != Hole.LAYER)
	assert_true(QueueBarrier.LAYER != 2 and QueueBarrier.LAYER != 4, "not the player's or the enemies' own layer")
	var player := Player.new()
	var no_upgrades: Array[UpgradeDef] = []
	player.setup(RunState.new(no_upgrades, {}))
	player._ready()
	assert_true(player.collision_mask & QueueBarrier.LAYER != 0, "a raised rope stops him")
	assert_true(player.collision_mask & 1 != 0 and player.collision_mask & Hole.LAYER != 0, "as walls and holes still do")
	player.free()
	assert_true(ThrownDentures.BLOCKED_BY & QueueBarrier.LAYER != 0, "and his dentures")
	assert_true(ThrownDentures.BLOCKED_BY & ThrownDentures.WALL_LAYER != 0)
	assert_eq(ThrownDentures.BLOCKED_BY & Hole.LAYER, 0, "they still fly over holes")
	var walker := Enemy.new()
	walker.setup(load("res://data/enemies/intern_reaper.tres"), null, 0.5)
	walker._ready()
	assert_eq(walker.collision_mask & QueueBarrier.LAYER, 0, "staff duck under the rope")
	walker.free()


func test_enemy_shots_and_lanes_pass_under_the_rope() -> void:
	var shots := FileAccess.get_file_as_string("res://scripts/actors/projectile.gd")
	assert_true(shots.contains("PhysicsRayQueryParameters2D.create(global_position, next, 1)"), "shots look at the wall layer only")
	var enemy := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	assert_false(enemy.contains("QueueBarrier"), "nothing an enemy does tests a barrier")


func test_the_walk_grid_never_changes_for_a_barrier() -> void:
	var layout := _room_with(_line(6, 4, 8))
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_BARRIER))
	var grid := WalkGrid.from_layout(layout)
	for x in range(4, 9):
		assert_true(grid.is_open(Vector2i(x, 6)), "enemies walk across it at %d" % x)


func test_a_boss_gate_change_chimes_first_then_holds_then_starts_down() -> void:
	var barrier := _barrier()
	barrier.take_control(QueueBarrier.RISE)
	assert_true(barrier.is_chiming(), "warned like the hazard")
	assert_false(barrier.is_up())
	barrier.advance(QueueBarrier.CHIME - 0.1)
	assert_false(barrier.is_up(), "nothing rises during the chime")
	barrier.advance(0.2)
	assert_true(barrier.is_up(), "then every rope is up")
	assert_true(barrier.is_held())
	barrier.advance(QueueBarrier.GATE_HOLD)
	assert_false(barrier.is_held())
	assert_false(barrier.is_up(), "the timer starts again down")
	# From there the next rise is always warned.
	var chimed := false
	for i in 1000:
		barrier.advance(0.02)
		chimed = chimed or barrier.is_chiming()
		if barrier.is_up():
			break
	assert_true(chimed and barrier.is_up(), "it chimed before it rose again")
	barrier.take_control(QueueBarrier.DROP)
	barrier.advance(QueueBarrier.CHIME + 0.05)
	assert_false(barrier.is_up(), "a gate change can drop them too")
	barrier.free()


func test_a_faster_barrier_restarts_down() -> void:
	var barrier := _barrier()
	barrier.advance(QueueBarrier.PERIOD - 1.0)
	assert_true(barrier.is_up())
	barrier.cycle_faster(2.0)
	assert_false(barrier.is_up(), "speeding up never raises a rope unwarned")
	assert_near(barrier.cycle().period, QueueBarrier.PERIOD / 2.0)
	assert_near(barrier.cycle().chime, QueueBarrier.CHIME)
	barrier.free()


func test_a_barrier_never_costs_a_pill() -> void:
	var empty: Array[UpgradeDef] = []
	var run := RunState.new(empty, {})
	var barrier := _barrier()
	var pills := run.health.pills
	for i in 800:
		barrier.advance(0.05)
	barrier.take_control(QueueBarrier.RISE)
	barrier.advance(8.0)
	assert_eq(run.health.pills, pills)
	assert_false(barrier.has_method("hit_target") or barrier.has_method("damage"), "a barrier has no way to hurt")
	barrier.free()


# --- rising under Grandpa ---

func test_a_rope_rising_under_his_feet_pushes_him_to_the_nearer_side() -> void:
	var center := Vector2(100, 100)
	var rope := QueueBarrier.rope_rect(center, true)
	var feet_size := Player.FEET_BOX_SIZE
	var a_little_above := Rect2(center + Vector2(0, -3) - feet_size / 2.0, feet_size)
	var shift := BarrierCycle.push_out(a_little_above, rope, true)
	assert_true(shift.y < 0.0 and is_zero_approx(shift.x), "up, the nearer side: %s" % str(shift))
	assert_false(Rect2(a_little_above.position + shift, feet_size).intersects(rope), "and clear of the rope")
	var a_little_below := Rect2(center + Vector2(0, 4) - feet_size / 2.0, feet_size)
	assert_true(BarrierCycle.push_out(a_little_below, rope, true).y > 0.0, "down when below the middle")
	var upright := QueueBarrier.rope_rect(center, false)
	var to_the_left := Rect2(center + Vector2(-2, 0) - feet_size / 2.0, feet_size)
	var sideways := BarrierCycle.push_out(to_the_left, upright, false)
	assert_true(sideways.x < 0.0 and is_zero_approx(sideways.y), str(sideways))


func test_a_push_never_goes_into_a_blocked_side_when_the_other_is_free() -> void:
	var center := Vector2(100, 100)
	var rope := QueueBarrier.rope_rect(center, true)
	var feet := Rect2(center + Vector2(0, -3) - Player.FEET_BOX_SIZE / 2.0, Player.FEET_BOX_SIZE)
	var shift := BarrierCycle.push_out(feet, rope, true, false, true)
	assert_true(shift.y > 0.0, "the side above is a seat, so down: %s" % str(shift))
	assert_false(Rect2(feet.position + shift, feet.size).intersects(rope))
	assert_true(shift.length() < RoomBackdrop.TILE, "a short shove, never a long throw")


func test_feet_off_the_rope_are_left_alone() -> void:
	var rope := QueueBarrier.rope_rect(Vector2(100, 100), true)
	var feet := Rect2(Vector2(100, 120) - Player.FEET_BOX_SIZE / 2.0, Player.FEET_BOX_SIZE)
	assert_eq(BarrierCycle.push_out(feet, rope, true), Vector2.ZERO)


# --- in the layout ---

func test_barriers_are_walkable_floor_kept_clear_of_doors() -> void:
	var symbol := RoomLayout.SYMBOL_BARRIER
	assert_eq(symbol, "=")
	assert_true(RoomLayout.ALLOWED.contains(symbol))
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(symbol))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol))
	assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol))
	assert_eq(RoomLayout.BARRIER_DOOR_CLEARANCE, 2)
	var good := _room_with(_line(6, 4, 8))
	assert_eq(good.validate().size(), 0, str(good.validate()))
	assert_true(_room_with({Vector2i(10, 3): "="}).validate().size() > 0, "two cells below the north door is too close")
	assert_true(_room_with({Vector2i(3, 5): "="}).validate().size() > 0, "two cells from the west door is too close")
	assert_eq(_room_with({Vector2i(10, 4): "="}).validate().size(), 0, "three cells away is fine")


func test_raised_barriers_never_shut_grandpa_in_or_out() -> void:
	# A line from the north wall to the south wall would cut the east door off while it is up.
	var wall_to_wall := {}
	for y in range(1, 10):
		wall_to_wall[Vector2i(14, y)] = "="
	var fence := _room_with(wall_to_wall)
	assert_true(fence.validate().size() > 0, "a line from wall to wall is refused")
	# A pen round the healing cell would hold it out of reach while up.
	var pen := {}
	for x in range(13, 16):
		pen[Vector2i(x, 5)] = "="
		pen[Vector2i(x, 7)] = "="
	pen[Vector2i(13, 6)] = "="
	pen[Vector2i(15, 6)] = "="
	pen[Vector2i(14, 6)] = "H"
	var penned := _room_with(pen)
	assert_true(penned.validate().size() > 0, "a pen round what he must reach is refused")
	var line_with_room_to_go_round := _room_with(_line(6, 4, 15))
	assert_eq(line_with_room_to_go_round.validate().size(), 0, str(line_with_room_to_go_round.validate()))


func test_a_line_knows_which_way_its_rope_runs() -> void:
	var across := _room_with(_line(7, 4, 8))
	assert_true(across.barrier_runs_across(Vector2i(6, 7)))
	var changes := {Vector2i(14, 4): "=", Vector2i(14, 5): "=", Vector2i(14, 6): "="}
	var upright := _room_with(changes)
	assert_false(upright.barrier_runs_across(Vector2i(14, 5)))
	assert_eq(upright.validate().size(), 0, str(upright.validate()))
	var alone := _room_with({Vector2i(14, 6): "="})
	assert_true(alone.barrier_runs_across(Vector2i(14, 6)), "a lone post runs across")


func test_a_rope_pushes_only_onto_open_floor_beside_it() -> void:
	var layout := _room_with({Vector2i(6, 6): "8", Vector2i(6, 7): "=", Vector2i(7, 7): "="})
	assert_false(TerminalProps.free_for_grandpa(layout, Vector2i(6, 6)), "a row of seats")
	assert_true(TerminalProps.free_for_grandpa(layout, Vector2i(6, 8)), "plain floor")
	assert_false(TerminalProps.free_for_grandpa(layout, Vector2i(7, 7)), "another rope")
	assert_false(TerminalProps.free_for_grandpa(layout, Vector2i(0, 7)), "a wall")


func test_old_layouts_hold_no_barriers() -> void:
	var layout: RoomLayout = load("res://data/rooms/floor_1/combat_01.tres")
	assert_true(layout.cells_of(RoomLayout.SYMBOL_BARRIER).is_empty())
