class_name DevStart
extends RefCounted

# Testing shortcuts for debug builds only, all on a throwaway profile with every upgrade at its top
# level and every floor above the start counted as cleared. The profile lives in memory and in its own
# file, never in the real save, and is thrown away when the shortcut ends (Progress.begin_dev_run).
# - F3, F5 and F6 in the Waiting Room: a fresh run that starts on the Floor 3, 4 or 5 landing. It ends
#   on returning.
# - F4 in the Waiting Room: the Waiting Room again with every department open. F4 again, walking
#   through the run door, or quitting the game ends it. The run door then starts the F3 dev run on
#   the same throwaway profile, since floor_scene starts any run under a dev profile as one.

# The depth a dev run starts at when nothing chose another: F3's, and the dev Waiting Room's run door.
const START_DEPTH := 3
# Each key starts a dev run on the landing of its depth. F4 is the dev Waiting Room's, so it is skipped.
const START_KEYS := {KEY_F3: 3, KEY_F5: 4, KEY_F6: 5}
const HINT := "DEV  F3/F5/F6: Floor 3/4/5 (max upgrades)"
const WAITING_KEY := KEY_F4
# In a floor, a debug build's F7 hands Harold a film reel (RuleKeeper), to try a flashback at once.
const REEL_KEY := KEY_F7
const WAITING_HINT := "F4: Dev Waiting Room (all departments)"
const WAITING_HINT_ON := "F4: Back to the real save"
# Shown on screen in every department while the dev Waiting Room's profile is on.
const PROFILE_LABEL := "DEV PROFILE"
# What a strong player plausibly has on reaching the third floor. The deeper starts take the same.
const PENSION := 300
const KEYS := 3
const BOMBS := 5
const ITEMS := ["pill_organizer", "slippers", "hearing_aid"]
const BREWED_POTION := "healing_tonic"
# For the dev Waiting Room, the profile also counts every path cleared, so every department is open at
# once, and the depths deeper than the start get their clears, so every wanted poster shows. It only ever
# touches the throwaway profile.
const ALL_PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]


static func is_available() -> bool:
	return allowed(OS.is_debug_build())


# Release exports are not debug builds, so the shortcut never exists there.
static func allowed(debug_build: bool) -> bool:
	return debug_build


# The depth a key starts at, or 0 for a key that starts no dev run.
static func depth_for_key(keycode: int) -> int:
	return int(START_KEYS.get(keycode, 0))


# Clears by depth for a dev run starting at start_depth: both paths of every depth above it beaten,
# and the open path of its own depth once, so its locked path is open as after a clear there.
static func clears_by_depth(start_depth := START_DEPTH) -> Dictionary:
	var clears := {}
	for depth in range(1, start_depth):
		clears[depth] = ProgressData.PATHS_AT_DEPTH[depth].size()
	clears[start_depth] = 1
	return clears


# The path ids those clears stand for: every path above start_depth and the open one at it.
static func paths_cleared(start_depth := START_DEPTH) -> Array[String]:
	var ids: Array[String] = []
	for depth in range(1, start_depth):
		for id: String in ProgressData.PATHS_AT_DEPTH[depth]:
			ids.append(id)
	ids.append(ProgressData.FIRST_PATH_BY_DEPTH[start_depth])
	return ids


# all_departments is true for the dev Waiting Room (F4) and false for the dev runs (F3, F5, F6).
# start_depth is the run's: 3 for F3 and F4, 4 for F5, 5 for F6.
static func progress(upgrades: Array[UpgradeDef], recipes: Array[ItemDef], all_departments := false, start_depth := START_DEPTH) -> ProgressData:
	var data := ProgressData.new()
	data.opening_seen = true
	data.pension = PENSION
	for def in upgrades:
		data.upgrades[def.id] = def.max_level()
	var clears := clears_by_depth(start_depth)
	for depth: int in clears:
		for i in clears[depth]:
			data.record_floor_cleared(depth)
	for id: String in paths_cleared(start_depth):
		data.paths_cleared[id] = true
	# At the start depth only the path ids are added, so the third floor's locks stay as they were.
	# Deeper depths are counted cleared on both paths, so their posters can be reached.
	if all_departments:
		for id: String in ALL_PATHS:
			data.paths_cleared[id] = true
		for depth: int in ProgressData.PATHS_AT_DEPTH:
			if depth > start_depth:
				for i in ProgressData.PATHS_AT_DEPTH[depth].size():
					data.record_floor_cleared(depth)
	for item in recipes:
		data.recipes_found[item.id] = true
		data.items_unlocked[item.id] = true
	data.brewed_potion = BREWED_POTION
	return data


static func apply_kit(run: RunState, items: Array[ItemDef]) -> void:
	for item in items:
		if ITEMS.has(item.id) and not run.has_item(item.id):
			run.add_item(item)
	run.keys = KEYS
	run.bombs = BOMBS
	run.changed.emit()
