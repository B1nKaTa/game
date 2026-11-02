extends TestCase


func test_frame_count_from_strip_width() -> void:
	assert_eq(SpriteVisual.frame_count(128, 32), 4)


func test_frame_count_is_at_least_one() -> void:
	assert_eq(SpriteVisual.frame_count(16, 32), 1)
	assert_eq(SpriteVisual.frame_count(64, 0), 1)


func test_flash_is_full_at_the_start_and_gone_at_the_end() -> void:
	assert_near(SpriteVisual.flash_amount(SpriteVisual.HIT_FLASH_TIME, SpriteVisual.HIT_FLASH_TIME), 1.0)
	assert_near(SpriteVisual.flash_amount(0.0, SpriteVisual.HIT_FLASH_TIME), 0.0)


func test_flash_fades_over_its_last_part() -> void:
	var duration := 0.1
	assert_near(SpriteVisual.flash_amount(duration * 0.5, duration), 1.0)
	assert_near(SpriteVisual.flash_amount(duration * SpriteVisual.FLASH_FADE * 0.5, duration), 0.5)


func test_flash_with_no_duration_is_off() -> void:
	assert_near(SpriteVisual.flash_amount(0.05, 0.0), 0.0)


func test_flash_does_not_touch_an_unready_visual() -> void:
	var visual := SpriteVisual.new()
	visual.flash(Color.WHITE)
	visual.set_alpha(0.5)
	assert_near(visual.get_alpha(), 0.5)
	visual.free()


func test_once_frame_covers_every_frame_over_the_duration() -> void:
	assert_eq(SpriteVisual.once_frame(0.0, 0.2, 4), 0)
	assert_eq(SpriteVisual.once_frame(0.05, 0.2, 4), 1)
	assert_eq(SpriteVisual.once_frame(0.19, 0.2, 4), 3)


func test_once_frame_holds_the_last_frame_after_the_end() -> void:
	assert_eq(SpriteVisual.once_frame(0.5, 0.2, 4), 3)


func test_once_frame_with_no_duration_shows_the_last_frame() -> void:
	assert_eq(SpriteVisual.once_frame(0.0, 0.0, 4), 3)


func test_play_once_runs_for_its_duration() -> void:
	var visual := SpriteVisual.new()
	visual.setup("no_such_art", Vector2(20, 24), Color.WHITE, 32)
	assert_false(visual.is_playing_once())
	visual.play_once("attack", 0.2)
	assert_true(visual.is_playing_once())
	visual._process(0.1)
	assert_true(visual.is_playing_once())
	visual._process(0.11)
	assert_false(visual.is_playing_once())
	visual.free()


func test_play_once_restarts_the_same_animation() -> void:
	var visual := SpriteVisual.new()
	visual.setup("no_such_art", Vector2(20, 24), Color.WHITE, 32)
	visual.play_once("attack", 0.2)
	visual._process(0.15)
	visual.play_once("attack", 0.2)
	visual._process(0.15)
	assert_true(visual.is_playing_once(), "second swing started over")
	visual.free()


func test_a_frozen_frame_does_not_advance_play_once() -> void:
	var visual := SpriteVisual.new()
	visual.setup("no_such_art", Vector2(20, 24), Color.WHITE, 32)
	visual.play_once("attack", 0.2)
	visual._process(0.0)
	assert_true(visual.is_playing_once())
	visual.free()


func test_playing_a_loop_ends_play_once() -> void:
	var visual := SpriteVisual.new()
	visual.setup("no_such_art", Vector2(20, 24), Color.WHITE, 32)
	visual.play_once("attack", 0.2)
	visual.play("walk")
	assert_false(visual.is_playing_once())
	visual.free()


func test_enemy_damage_before_it_is_in_the_tree_is_safe() -> void:
	var enemy := Enemy.new()
	enemy.setup(load("res://data/enemies/intern_reaper.tres"), null, 0.5)
	enemy.take_damage(1.0, Vector2.ZERO)
	assert_true(enemy.hp > 0.0)
	enemy.free()
