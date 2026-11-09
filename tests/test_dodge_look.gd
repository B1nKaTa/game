extends TestCase


# The aim mark is a ring round the point: four arms drew a plus at the mouse, which read as a cross in the
# real-window shots, and the game never shows one.
func test_the_aim_mark_is_a_ring_not_a_plus() -> void:
	var center := Vector2(100, 50)
	var points := Player.crosshair_ring(center)
	assert_true(points.size() >= 12, "round enough to read as a ring")
	for point in points:
		assert_near(point.distance_to(center), Player.CROSSHAIR_RADIUS, "on the ring")
	assert_true(points[0].is_equal_approx(points[points.size() - 1]), "closed")
	assert_false(FileAccess.get_file_as_string("res://scripts/actors/player.gd").contains("crosshair_lines"), "no four-armed mark is left")


func test_a_new_player_has_no_crosshair_until_asked() -> void:
	var player := Player.new()
	assert_false(player.show_crosshair, "menus still need the normal mouse pointer")
	player.free()


func test_ghost_starts_faint_and_fades_to_nothing() -> void:
	assert_near(DodgeGhost.alpha_at(DodgeGhost.FADE_TIME), DodgeGhost.START_ALPHA)
	assert_near(DodgeGhost.alpha_at(DodgeGhost.FADE_TIME / 2.0), DodgeGhost.START_ALPHA / 2.0)
	assert_near(DodgeGhost.alpha_at(0.0), 0.0)
	assert_near(DodgeGhost.alpha_at(-1.0), 0.0, "never goes negative")


func test_a_visual_without_art_makes_no_ghost() -> void:
	var visual := SpriteVisual.new()
	visual.setup("no_such_art", Vector2(20, 24), Color.WHITE, 32)
	assert_true(visual.make_ghost() == null)
	visual.free()


func test_ghost_timing_spawns_at_a_steady_rate() -> void:
	var left := 0.0
	var spawned := 0
	for i in 12:
		left -= 1.0 / 60.0
		if left <= 0.0:
			spawned += 1
			left = Player.GHOST_EVERY
	assert_true(spawned >= 3 and spawned <= 5, "a 0.2 second dodge leaves a few ghosts, had %d" % spawned)
