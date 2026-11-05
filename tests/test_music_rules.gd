extends TestCase

# Which song plays where. MusicPlayer and the scenes name autoloads, so their hooks are read as source
# text (see LESSONS); MusicRules itself is pure and called directly.

const FLOOR_DIR := "res://data/floors/"
const CATALOG := "res://tools/music/catalog.py"


func _path_floors() -> Array[FloorDef]:
	var floors: Array[FloorDef] = []
	for file in DirAccess.get_files_at(FLOOR_DIR):
		if not file.ends_with(".tres"):
			continue
		var def := load(FLOOR_DIR + file) as FloorDef
		if def != null and def.floor_boss != null:
			floors.append(def)
	return floors


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func test_the_title_plays_take_a_number() -> void:
	assert_eq(MusicRules.title(), "take_a_number")


func test_the_opening_plays_the_hold_music_so_it_carries_into_the_waiting_room() -> void:
	assert_eq(MusicRules.opening(), MusicRules.HOLD)
	assert_eq(MusicRules.waiting_room(Departments.LOBBY), MusicRules.opening())


func test_every_waiting_room_department_plays_the_hold_music_but_the_back_room() -> void:
	for entry: Dictionary in Departments.ALL:
		var id: String = entry["id"]
		var expected := MusicRules.ARCADE if id == Departments.BACK_ROOM else MusicRules.HOLD
		assert_eq(MusicRules.waiting_room(id), expected, id)


func test_all_ten_paths_have_their_own_theme() -> void:
	var floors := _path_floors()
	assert_eq(floors.size(), 10, "path floors")
	var seen := {}
	for def in floors:
		var theme := MusicRules.path_theme(def.id)
		assert_true(MusicRules.PATH_THEMES.has(def.id), "%s has a theme" % def.id)
		assert_false(seen.has(theme), "%s shares %s" % [def.id, theme])
		seen[theme] = true


func test_a_path_plays_its_theme_in_every_room_but_the_arcade_and_the_crossings() -> void:
	for def in _path_floors():
		var theme: String = MusicRules.PATH_THEMES[def.id]
		for type: String in [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_ITEM, RoomLayout.TYPE_HEALING, RoomLayout.TYPE_SIDE,
				RoomLayout.TYPE_TREASURE, RoomLayout.TYPE_SHOP, RoomLayout.TYPE_SECRET, RoomLayout.TYPE_VAULT,
				RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_FLOOR_BOSS]:
			assert_eq(MusicRules.room(def.id, type), theme, "%s %s" % [def.id, type])
		assert_eq(MusicRules.room(def.id, RoomLayout.TYPE_ARCADE), MusicRules.ARCADE, def.id + " arcade")
		assert_eq(MusicRules.room(def.id, RoomLayout.TYPE_CROSSROADS), MusicRules.LANDING, def.id + " crossroads")


func test_the_landings_and_the_crossroads_play_the_landing() -> void:
	for id in ["crossroads", "landing", "landing_3", "landing_4", "landing_5"]:
		var def := load(FLOOR_DIR + id + ".tres") as FloorDef
		assert_true(def != null, id)
		assert_eq(MusicRules.room(def.id, RoomLayout.TYPE_LANDING), MusicRules.LANDING, id)
		assert_eq(MusicRules.room(def.id, RoomLayout.TYPE_CROSSROADS), MusicRules.LANDING, id)
		assert_eq(MusicRules.path_theme(def.id), MusicRules.LANDING, id + " has no theme of its own")


func test_each_floor_boss_plays_its_depths_theme_and_the_chairman_his_own() -> void:
	for def in _path_floors():
		var expected: String = MusicRules.FLOOR_BOSSES[def.depth]
		if def.floor_boss.id == MusicRules.CHAIRMAN_ID:
			expected = MusicRules.CHAIRMAN
		assert_eq(MusicRules.boss(def.floor_boss.id, true, def.depth), expected, def.id)


func test_mortimer_gets_final_arrangements() -> void:
	var parlour := load(FLOOR_DIR + "funeral_parlour.tres") as FloorDef
	assert_eq(parlour.floor_boss.id, "mortimer_grimsby")
	assert_eq(MusicRules.boss(parlour.floor_boss.id, true, parlour.depth), "final_arrangements")


func test_the_chairman_id_is_the_head_office_boss() -> void:
	var office := load(FLOOR_DIR + "head_office.tres") as FloorDef
	assert_eq(office.floor_boss.id, MusicRules.CHAIRMAN_ID)
	assert_eq(MusicRules.CHAIRMAN_ID, EndingRules.CHAIRMAN)


func test_every_mini_boss_shares_the_mini_boss_theme() -> void:
	for def in _path_floors():
		assert_true(def.mini_boss != null, def.id)
		assert_eq(MusicRules.boss(def.mini_boss.id, false, def.depth), MusicRules.MINI_BOSS, def.id)


func test_a_depth_past_the_list_still_gets_a_boss_theme() -> void:
	assert_eq(MusicRules.boss("someone", true, 0), MusicRules.FLOOR_BOSSES[1])
	assert_eq(MusicRules.boss("someone", true, 9), MusicRules.FLOOR_BOSSES[5])


func test_the_endings_and_game_over() -> void:
	assert_eq(MusicRules.ending(), "ending")
	assert_eq(MusicRules.ending(true), "eternal_feud")


func test_every_ending_plays_the_ending_song_and_the_true_ending_its_own() -> void:
	for each: Dictionary in EndingRules.ALL:
		var expected := "eternal_feud" if each["id"] == EndingRules.ETERNAL_FEUD else "ending"
		assert_eq(MusicRules.ending_scene(each["id"]), expected, each["id"])
		assert_true(MusicRules.all_ids().has(MusicRules.ending_scene(each["id"])), each["id"])
	assert_eq(MusicRules.game_over(), "game_over")


func test_only_the_game_over_sting_plays_once() -> void:
	for id in MusicRules.all_ids():
		assert_eq(MusicRules.loops(id), id != MusicRules.GAME_OVER, id)


func test_songs_load_from_the_music_folder() -> void:
	assert_eq(MusicRules.path_for("please_hold"), "res://audio/music/please_hold.wav")


func test_every_song_the_game_asks_for_is_in_the_music_catalog() -> void:
	var catalog := _source(CATALOG)
	assert_false(catalog.is_empty(), "the catalog is readable")
	var ids := MusicRules.all_ids()
	assert_eq(ids.size(), 24)
	for id in ids:
		assert_true(catalog.contains("\"%s\": dict(" % id), id)


func test_the_rendered_songs_stay_out_of_git() -> void:
	var ignore := _source("res://.gitignore")
	assert_true(ignore.contains("audio/music/*.wav"))
	assert_true(ignore.contains("audio/music/*.wav.import"))


func test_the_player_is_an_autoload_that_stays_quiet_in_checks_and_tests() -> void:
	assert_true(_source("res://project.godot").contains("MusicPlayer=\"*res://scripts/autoload/music_player.gd\""))
	var player := _source("res://scripts/autoload/music_player.gd")
	assert_true(player.contains("has(\"--smoke\")") and player.contains("has(\"--script\")"), "quiet under --smoke and --script")
	assert_true(player.contains("if not ResourceLoader.exists(path):"), "a missing song is silence")
	assert_true(player.contains("const FADE := 1.2"))
	assert_true(player.contains("AudioServer.get_bus_index(BUS) != -1 else \"Master\""), "falls back to Master")


func test_the_scenes_ask_for_music_where_they_change() -> void:
	var floor_scene := _source("res://scripts/scenes/floor_scene.gd")
	for call in ["MusicRules.room(_floor_def.id, _map.room(_current_id).room_type)",
			"MusicRules.boss(boss.def.id, boss.def == _floor_def.floor_boss, _floor_def.depth)",
			"MusicRules.game_over()", "MusicRules.ending_scene(_ending_id)"]:
		assert_true(floor_scene.contains(call), call)
	# The room's music comes back after a boss falls.
	var defeated := floor_scene.substr(floor_scene.find("func _on_boss_defeated"))
	assert_true(defeated.contains("_play_room_music()"), "the path theme returns")
	assert_true(_source("res://scripts/scenes/waiting_room.gd").contains("MusicRules.waiting_room(Departments.id_of(target_id))"))
	assert_true(_source("res://scripts/scenes/opening.gd").contains("MusicRules.opening()"))
	assert_true(_source("res://scripts/scenes/title_screen.gd").contains("MusicPlayer.play(MusicRules.title())"))
	assert_true(_source("res://scripts/ui/ending_archive_panel.gd").contains("MusicPlayer.play(MusicRules.ending_scene(id))"), "a replay plays its ending's song")
