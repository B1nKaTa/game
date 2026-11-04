extends TestCase

# The rendered sound effects and how the game reaches them: every name the code asks for can play,
# variations are found, gaps keep bursts and NPC blips in check, and every voice has a default.

const SCRIPT_DIRS := ["res://scripts/"]
const CALLS := ["Sfx.play(", "Sfx.play_later(", "_play(", "set_meta(\"sfx"]
const META_KEYS := ["sfx", "sfx_denied"]


func _script_paths(dir: String, into: Array[String]) -> void:
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			into.append(dir + file)
	for sub in DirAccess.get_directories_at(dir):
		_script_paths(dir + sub + "/", into)


func _quoted(line: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.create_from_string("\"([a-z0-9_]*)\"")
	for match in regex.search_all(line):
		found.append(match.get_string(1))
	return found


# Every sound name written in the game's code: each quoted name on a line that plays a sound or
# sets a button's sound, and what each function named for a sound (break_sound, hit_sound) returns.
func _names_in_code() -> Dictionary:
	var names := {}
	var paths: Array[String] = []
	for dir in SCRIPT_DIRS:
		_script_paths(dir, paths)
	for path in paths:
		var in_sound_func := false
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("func ") or line.begins_with("static func "):
				in_sound_func = line.get_slice("(", 0).ends_with("sound")
			var plays := in_sound_func and line.strip_edges().begins_with("return")
			for call in CALLS:
				if line.contains(call):
					plays = true
			if not plays or line.contains("func _play") or line.strip_edges().begins_with("#"):
				continue
			for name in _quoted(line):
				if not name.is_empty() and not META_KEYS.has(name):
					names[name] = path
	return names


func test_the_code_asks_for_many_sounds() -> void:
	var names := _names_in_code()
	assert_true(names.size() >= 70, "found %d names" % names.size())
	# Names returned by the functions named for a sound are read too.
	for name in ["form_maxed", "combo_hit_b", "bj_push", "rock_break", "grass_cut", "ui_back"]:
		assert_true(names.has(name), name)
	assert_false(names.has(""), "no empty name")


func test_every_sound_named_in_code_has_a_file_or_a_fallback() -> void:
	var names := _names_in_code()
	for name: String in names:
		assert_true(SoundBank.can_play(name), "%s (in %s) has no file and no fallback" % [name, names[name]])


func test_every_sound_named_in_code_is_in_the_catalogue() -> void:
	var names := _names_in_code()
	for name: String in names:
		assert_true(SoundBank.NAMES.has(name), "%s (in %s) is not in SoundBank.NAMES" % [name, names[name]])


func test_every_catalogued_sound_has_its_files() -> void:
	for name in SoundBank.NAMES:
		assert_false(SoundBank.variation_paths(name).is_empty(), name)


func test_every_catalogued_sound_loads_as_a_stream() -> void:
	for name in SoundBank.NAMES:
		var streams := SoundBank.load_streams(name)
		assert_false(streams.is_empty(), name)
		for stream in streams:
			assert_true(stream != null and stream.get_length() > 0.0, name)


func test_variations_are_all_found() -> void:
	assert_eq(SoundBank.variation_paths("cane_swing").size(), 3)
	assert_eq(SoundBank.variation_paths("combo_hit_a").size(), 3)
	assert_eq(SoundBank.variation_paths("explosion").size(), 2)
	assert_eq(SoundBank.variation_paths("door_open"), ["res://audio/sfx/door_open.wav"])
	assert_eq(SoundBank.variation_paths("nothing_like_this").size(), 0)


func test_a_sound_with_no_file_falls_back_to_the_synthesized_one() -> void:
	assert_eq(SoundBank.fallback_of("combo_hit_a"), "combo_hit")
	assert_eq(SoundBank.fallback_of("explosion"), "explosion")
	assert_eq(SoundBank.fallback_of("nothing_like_this"), "")
	# coin_pickup has no file today, only its old sweep.
	assert_true(SoundBank.variation_paths("coin_pickup").is_empty())
	var streams := SoundBank.load_streams("coin_pickup")
	assert_eq(streams.size(), 1)
	assert_true(streams[0] is AudioStreamWAV)
	assert_true(SoundBank.load_streams("nothing_like_this").is_empty())


func test_the_same_sound_waits_out_its_gap() -> void:
	var pool := SfxPool.new()
	assert_true(pool.allows("enemy_death", 1000000))
	assert_false(pool.allows("enemy_death", 1000000 + 20000))
	assert_true(pool.allows("enemy_death", 1000000 + 50000), "past the 0.04 s default gap")
	assert_true(pool.allows("combo_hit_a", 1000000 + 20000), "another sound is not held up")
	pool.free()


func test_coins_wait_longer_than_the_default() -> void:
	var pool := SfxPool.new()
	assert_true(pool.allows("coin", 0))
	assert_false(pool.allows("coin", 50000))
	assert_true(pool.allows("coin", 61000))
	pool.free()


func test_blips_never_pass_about_twelve_a_second() -> void:
	var pool := SfxPool.new()
	var played := 0
	# Two people typing at once, every frame for a second at 60 frames a second.
	for frame in 60:
		var now := 5000000 + int(frame * 1000000.0 / 60.0)
		if pool.allows("blip_prim", now):
			played += 1
		if pool.allows("blip_gruff", now + 100):
			played += 1
	assert_true(played <= int(SfxPool.BLIPS_PER_SECOND) + 1, "%d blips in a second" % played)
	assert_true(played >= int(SfxPool.BLIPS_PER_SECOND) - 2, "%d blips in a second" % played)
	pool.free()


func test_all_blips_share_one_gap() -> void:
	assert_eq(SfxPool.gap_key("blip_smooth"), SfxPool.gap_key("blip_boom"))
	assert_near(SfxPool.gap_of("blip_nasal"), 1.0 / SfxPool.BLIPS_PER_SECOND)
	assert_near(SfxPool.gap_of("dodge"), SfxPool.MIN_REPEAT_GAP)


func test_npc_voices_have_a_default() -> void:
	assert_eq(NpcVoice.for_id("someone_new"), NpcVoice.DEFAULT)
	assert_eq(NpcVoice.for_id(""), NpcVoice.DEFAULT)
	assert_true(SoundBank.can_play(NpcVoice.DEFAULT["sound"]))


func test_named_people_each_have_their_own_voice() -> void:
	var dealer := NpcVoice.for_id("dealer")
	var dolores := NpcVoice.for_id("deputy_dolores")
	var coach := NpcVoice.for_id("coach_bertram")
	assert_true(dealer["sound"] != dolores["sound"])
	assert_true(dolores["sound"] != coach["sound"])
	assert_true(float(dolores["pitch"]) > 0.0)


func test_every_npc_def_speaks_in_a_voice_that_plays() -> void:
	for file in DirAccess.get_files_at("res://data/npcs/"):
		if not file.ends_with(".tres"):
			continue
		var def: NpcDef = load("res://data/npcs/" + file)
		var voice := NpcVoice.for_id(def.id)
		assert_true(NpcVoice.VOICES.has(def.id), "%s has its own voice" % def.id)
		assert_true(SoundBank.can_play(voice["sound"]), def.id)
	for sound in NpcVoice.sounds():
		assert_true(SoundBank.can_play(sound), sound)


func test_a_quiet_pool_counts_but_plays_nothing() -> void:
	var pool := SfxPool.new()
	pool.quiet = true
	pool._ready()
	assert_eq(pool.players().size(), 0)
	assert_true(pool.play("coin"))
	assert_eq(pool.plays, 1)
	assert_false(pool.play("coin"), "the gap still holds")
	assert_eq(pool.get_child_count(), 0)
	pool.free()


func test_a_live_pool_plays_on_the_effects_bus() -> void:
	var pool := SfxPool.new()
	pool._ready()
	assert_eq(pool.players().size(), SfxPool.POOL_SIZE)
	for player in pool.players():
		assert_eq(String(player.bus), "Effects")
	pool.free()


func test_sounds_wait_their_turn_and_can_be_cancelled() -> void:
	var pool := SfxPool.new()
	pool.quiet = true
	pool.play_later("card_deal", 0.5)
	pool.play_later("card_flip", 0.6)
	assert_eq(pool.pending(), 2)
	pool._process(0.0)
	assert_eq(pool.pending(), 2, "not due yet")
	pool.cancel_later()
	assert_eq(pool.pending(), 0)
	pool.play_later("card_deal", 0.0)
	assert_eq(pool.plays, 1, "no delay plays at once")
	pool.free()


func test_test_runs_and_the_full_loop_are_quiet() -> void:
	var sounds := Sfx.pool()
	if sounds != null:
		assert_true(sounds.quiet, "the Sounds autoload plays nothing under --script")


func test_a_line_types_out_letter_by_letter() -> void:
	var lines: Array[String] = ["Place your bets."]
	var talk := NpcTalk.new(lines)
	talk.talk()
	assert_eq(talk.revealed(), "")
	assert_true(talk.is_revealing())
	talk.tick(4.0 / NpcTalk.REVEAL_RATE + 0.001)
	assert_eq(talk.revealed(), "Plac")
	talk.tick(1.0)
	assert_eq(talk.revealed(), "Place your bets.")
	assert_false(talk.is_revealing())
	assert_eq(talk.showing(), "Place your bets.", "the whole line still shows for its time")


func test_light_hits_alternate_knocks_and_a_finisher_has_its_own() -> void:
	var feedback := CombatFeedback.new()
	assert_eq(feedback.hit_sound(false, false), "combo_hit_a")
	assert_eq(feedback.hit_sound(false, false), "combo_hit_b")
	assert_eq(feedback.hit_sound(false, true), "combo_finisher")
	assert_eq(feedback.hit_sound(false, false), "combo_hit_a", "a new combo starts on the first knock")
	assert_eq(feedback.hit_sound(true, false), "charged_hit")
	feedback.free()
