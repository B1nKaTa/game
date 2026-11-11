class_name MusicRules
extends RefCounted

# Which song plays where. The scenes say where Grandpa is and get back a song id; MusicPlayer plays
# res://audio/music/<id>.wav if it is there and stays quiet if not. The songs are rendered by
# tools/music/render_band.py (see the README there), and these ids are its songs' names.

const DIR := "res://audio/music/"
const TITLE := "take_a_number"
const HOLD := "please_hold"
const LANDING := "landing"
const ARCADE := "the_arcade"
const MINI_BOSS := "mini_boss"
const CHAIRMAN := "the_chairman"
const ENDING := "ending"
const TRUE_ENDING := "eternal_feud"
const GAME_OVER := "game_over"
const CHAIRMAN_ID := "chairman_of_the_board"
# Each path's rooms, by FloorDef id.
const PATH_THEMES := {
	"floor_1": "records_basement",
	"cemetery": "unkempt_cemetery",
	"sunset_shores": "sunset_shores",
	"furnace_works": "furnace_works",
	"funeral_parlour": "funeral_parlour",
	"flashback_cinema": "flashback_cinema",
	"last_resort_cruise": "last_resort_cruise",
	"seance_hotline": "seance_hotline",
	"terminal_zero": "terminal_zero",
	"head_office": "head_office",
}
# Floor bosses by depth.
const FLOOR_BOSSES := {
	1: "boss_depth_1",
	2: "boss_depth_2",
	3: "final_arrangements",
	4: "boss_depth_4",
	5: "boss_depth_5",
}
# Played once, not looped.
const STINGS := [GAME_OVER]


static func title() -> String:
	return TITLE


# The opening plays the hold music, which carries on into the Waiting Room without a restart.
static func opening() -> String:
	return HOLD


# The Waiting Room's departments all play the hold music, except the Dealer's Back Room.
static func waiting_room(department: String) -> String:
	return ARCADE if department == Departments.BACK_ROOM else HOLD


# A run's room as Grandpa walks in. Boss rooms keep the path's theme until the boss shows up.
static func room(floor_id: String, room_type: String) -> String:
	match room_type:
		RoomLayout.TYPE_CROSSROADS, RoomLayout.TYPE_LANDING:
			return LANDING
		RoomLayout.TYPE_ARCADE:
			return ARCADE
	return path_theme(floor_id)


# A path's exploration theme. A floor with none (the Crossroads, a landing) gets the landing's.
static func path_theme(floor_id: String) -> String:
	return PATH_THEMES.get(floor_id, LANDING)


# When a boss appears: the Chairman has his own, a floor boss its depth's, any other the mini boss's.
static func boss(boss_id: String, is_floor_boss: bool, depth: int) -> String:
	if boss_id == CHAIRMAN_ID:
		return CHAIRMAN
	if is_floor_boss:
		return FLOOR_BOSSES.get(clampi(depth, 1, FLOOR_BOSSES.size()), FLOOR_BOSSES[1])
	return MINI_BOSS


static func ending(true_ending := false) -> String:
	return TRUE_ENDING if true_ending else ENDING


# The song under an ending's scene: Eternal Feud, the true ending, has its own.
static func ending_scene(ending_id: String) -> String:
	return ending(ending_id == EndingRules.ETERNAL_FEUD)


static func game_over() -> String:
	return GAME_OVER


static func loops(id: String) -> bool:
	return not STINGS.has(id)


static func path_for(id: String) -> String:
	return DIR + id + ".wav"


# Every song the game can ask for.
static func all_ids() -> Array[String]:
	var ids: Array[String] = [TITLE, HOLD, LANDING, ARCADE, MINI_BOSS, CHAIRMAN, ENDING, TRUE_ENDING, GAME_OVER]
	for id: String in PATH_THEMES.values():
		ids.append(id)
	for id: String in FLOOR_BOSSES.values():
		ids.append(id)
	return ids
