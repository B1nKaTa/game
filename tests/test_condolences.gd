extends TestCase


func test_the_first_beat_of_each_boss_pays_once() -> void:
	var data := ProgressData.new()
	assert_eq(data.record_boss_beaten("senior_adjuster", false), ProgressData.FIRST_MINI_BOSS_CONDOLENCES)
	assert_eq(data.record_boss_beaten("senior_adjuster", false), 0)
	assert_eq(data.record_boss_beaten("regional_reaper", true), ProgressData.FIRST_FLOOR_BOSS_CONDOLENCES)
	assert_eq(data.condolences, 15)


func test_spending_never_goes_below_zero() -> void:
	var data := ProgressData.new()
	data.add_condolences(10)
	assert_false(data.spend_condolences(11))
	assert_true(data.spend_condolences(10))
	assert_eq(data.condolences, 0)
	data.add_condolences(-4)
	assert_eq(data.condolences, 0)


func test_condolences_and_beaten_bosses_survive_a_save() -> void:
	var data := ProgressData.new()
	data.record_boss_beaten("matron_mercy", false)
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(loaded.condolences, ProgressData.FIRST_MINI_BOSS_CONDOLENCES)
	assert_eq(loaded.record_boss_beaten("matron_mercy", false), 0, "never paid twice")


func test_chests_rarely_pay_condolences() -> void:
	assert_eq(RoomRules.chest_condolences(0.01), RoomRules.CHEST_CONDOLENCES)
	assert_eq(RoomRules.chest_condolences(0.5), 0)


# The rule itself does not check what was beaten, so the guard lives in floor_scene. This pins it there.
func test_the_floor_scene_pays_only_for_real_bosses() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(source.contains("if boss.is_summon or not boss.def.is_boss"))
