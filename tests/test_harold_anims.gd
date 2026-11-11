extends TestCase

# SpriteVisual falls back to the attack strip for an anim it lacks, so Player asks first: "" means
# keep today's look.


func test_a_missing_strip_plays_nothing() -> void:
	for anim in ["hurt", "death", "dodge"]:
		assert_eq(Player.feedback_anim("no_such_art", anim), "", anim)
		assert_eq(Player.feedback_anim("", anim), "", anim)


func test_a_present_strip_plays() -> void:
	# idle exists for old Harold today, so it stands in for a present strip.
	assert_eq(Player.feedback_anim("grandpa", "idle"), "idle")


func test_without_strips_he_keeps_todays_look() -> void:
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	player._ready()
	var has_death := SpriteVisual.has_anim("grandpa", "death")
	assert_near(player.death_anim_time(), Player.DEATH_ANIM_TIME if has_death else 0.0)
	assert_eq(player.uses_dodge_ghosts(), not SpriteVisual.has_anim("grandpa", "dodge"))
	player.free()


func test_a_landed_hit_plays_hurt_only_with_its_strip() -> void:
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	player._ready()
	assert_true(player.take_hit(1))
	var has_hurt := SpriteVisual.has_anim("grandpa", "hurt")
	assert_eq(player._visual.anim() == "hurt", has_hurt, "hurt plays exactly when its strip is there")
	player.free()


func test_an_era_without_a_dodge_strip_keeps_the_ghosts() -> void:
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	player._ready()
	for id in Eras.STARTING:
		player.set_era(id)
		assert_eq(player.uses_dodge_ghosts(), not SpriteVisual.has_anim(player._visual.art_id(), "dodge"), id)
	player.free()
