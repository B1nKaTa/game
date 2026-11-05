extends TestCase

# OverlapRoute, which the floor-5 bosses ask before they overlap two attacks: whether Grandpa can still
# walk clear of everything coming, and where to mark a spot that stays safe.
const ROOM := Rect2(0, 0, 320, 320)
# The middle of the grid position his feet stand on, so the answers below do not hang on rounding.
const FEET := Vector2(104, 168)


func test_an_empty_room_is_safe_and_marks_where_he_stands() -> void:
	var route := OverlapRoute.new(ROOM)
	var out := route.escape(FEET)
	assert_true(out["safe"])
	assert_true(out["pure"].distance_to(FEET) < OverlapRoute.STEP, "the nearest safe spot is under him")


func test_nothing_saves_him_from_a_whole_room_hit_before_he_can_react() -> void:
	var route := OverlapRoute.new(ROOM)
	route.add_rect(ROOM, 0.1, 0.5)
	assert_false(route.escape(FEET)["safe"])
	assert_true(OverlapRoute.REACT >= 0.2, "a reaction of at least the bot's")


func test_he_walks_out_of_a_strip_that_hurts_later() -> void:
	var route := OverlapRoute.new(ROOM)
	route.add_rect(Rect2(0, 0, 160, 320), 1.5, 3.0)
	var out := route.escape(FEET)
	assert_true(out["safe"], "about 80 px to walk in 1.5 s")
	assert_true(out["pure"].x > 160.0 + OverlapRoute.MARGIN, "the mark is clear of the strip with room to spare: %s" % str(out["pure"]))
	assert_true(route.danger_end_at(out["pure"]) <= 0.0)


func test_a_wall_in_the_way_leaves_no_way_out() -> void:
	var route := OverlapRoute.new(ROOM)
	route.add_rect(Rect2(0, 0, 160, 320), 1.5, 3.0)
	route.add_block(Rect2(150, 0, 30, 320))
	var out := route.escape(FEET)
	assert_false(out["safe"])
	assert_eq(out["pure"], Vector2.INF)


func test_a_closed_cell_counts_as_a_wall() -> void:
	var route := OverlapRoute.new(ROOM)
	route.add_rect(Rect2(0, 0, 160, 320), 1.5, 3.0)
	route.set_open(func(spot: Vector2) -> bool: return WalkGrid.cell_of(spot).x != 5)
	assert_false(route.escape(FEET)["safe"], "column 5 is solid from top to bottom")


func test_red_tape_holds_him_long_enough_to_be_caught() -> void:
	var route := OverlapRoute.new(ROOM)
	route.add_rect(Rect2(0, 0, 160, 320), 1.5, 3.0)
	for y in 10:
		route.add_sticky(Vector2i(4, y), 0.0)
	assert_false(route.escape(FEET)["safe"], "the tape across his way holds him past the strip's start")
	var late := OverlapRoute.new(ROOM)
	late.add_rect(Rect2(0, 0, 160, 320), 1.5, 3.0)
	for y in 10:
		late.add_sticky(Vector2i(4, y), 5.0)
	assert_true(late.escape(FEET)["safe"], "tape strung only later holds no one")


func test_a_strike_on_his_feet_is_kept_when_he_can_step_out() -> void:
	var route := OverlapRoute.new(ROOM)
	var plan := route.strike_plan(FEET, 44.0, 1.2)
	assert_eq(plan["spot"], FEET, "with nothing else coming it falls on him")
	assert_true(plan["mark"].distance_to(FEET) > 44.0, "and the mark is outside it")
	route.set_extra_circle(plan["spot"], 44.0, 1.2, 1.2 + OverlapRoute.STEP_TIME)
	assert_true(route.escape(FEET)["safe"])


func test_a_strike_moves_off_him_rather_than_take_the_last_way_out() -> void:
	# Boxed in a corridor: walls above and below, a strip hurting to the left, and the only way out to
	# the right. A strike on his feet still lets him walk right, but one on the way out would not.
	var route := OverlapRoute.new(ROOM)
	route.add_block(Rect2(0, 0, 320, 150))
	route.add_block(Rect2(0, 186, 320, 134))
	route.add_rect(Rect2(0, 150, 60, 36), 0.6, 3.0)
	var plan := route.strike_plan(FEET, 44.0, 1.2)
	assert_true(plan["spot"] != Vector2.INF, "a spot is found")
	route.set_extra_circle(plan["spot"], 44.0, 1.2, 1.2 + OverlapRoute.STEP_TIME)
	var out := route.escape(FEET)
	assert_true(out["safe"], "and it leaves him a way out")
	assert_true(plan["mark"].distance_to(plan["spot"]) > 44.0)


func test_the_answer_is_cautious_about_its_grid() -> void:
	assert_true(OverlapRoute.MARGIN >= OverlapRoute.STEP / 2.0, "nothing passes between two grid points unseen")
	assert_near(OverlapRoute.STEP_TIME, OverlapRoute.STEP / PlayerStats.BASE_SPEED, "a step at his base speed, never faster")


# The floor is worked out block by block and cell by cell for speed: it must block exactly the
# positions where his feet box touches a block or a closed cell, and a route sharing that floor must
# answer as one that worked it out itself.
func test_the_fast_floor_matches_the_plain_rule_and_can_be_shared() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var room := Rect2(32, 32, 576, 288)
	for trial in 20:
		var blocks: Array[Rect2] = []
		for b in 6:
			blocks.append(Rect2(rng.randf_range(0, 640), rng.randf_range(0, 352), rng.randf_range(8, 90), rng.randf_range(8, 90)))
		var closed_x := rng.randi_range(2, 18)
		var is_open := func(spot: Vector2) -> bool: return WalkGrid.cell_of(spot).x != closed_x
		var route := OverlapRoute.new(room)
		for block in blocks:
			route.add_block(block)
		route.set_open(is_open)
		route.add_rect(Rect2(200, 32, 64, 288), 1.0, 1.4)
		var shared := OverlapRoute.new(room)
		shared.add_rect(Rect2(200, 32, 64, 288), 1.0, 1.4)
		shared.share_floor(route)
		var half := Player.FEET_BOX_SIZE / 2.0
		var mismatch := 0
		for j in floori(room.size.y / OverlapRoute.STEP):
			for i in floori(room.size.x / OverlapRoute.STEP):
				var spot := room.position + Vector2(i + 0.5, j + 0.5) * OverlapRoute.STEP
				var box := Rect2(spot - half, Player.FEET_BOX_SIZE)
				var plain := false
				for block in blocks:
					plain = plain or block.intersects(box)
				for corner in [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]:
					plain = plain or not is_open.call(corner)
				if route.is_blocked_at(spot) != plain or shared.is_blocked_at(spot) != plain:
					mismatch += 1
		assert_eq(mismatch, 0, "trial %d: blocked positions" % trial)
		var feet := room.position + Vector2(3.5, 8.5) * OverlapRoute.STEP
		assert_eq(shared.escape(feet), route.escape(feet), "trial %d: the same way out" % trial)
