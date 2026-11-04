class_name DevStart
extends RefCounted

# Testing shortcuts for debug builds only, both on a throwaway profile with every upgrade at its top
# level and the first two floors counted as cleared. The profile lives in memory and in its own file,
# never in the real save, and is thrown away when the shortcut ends (Progress.begin_dev_run).
# - F3 in the Waiting Room: a fresh run that starts on the Floor 3 landing. It ends on returning.
# - F4 in the Waiting Room: the Waiting Room again with every department open. F4 again, walking
#   through the run door, or quitting the game ends it. The run door then starts the F3 dev run on
#   the same throwaway profile, since floor_scene starts any run under a dev profile as one.

const START_DEPTH := 3
const KEY := KEY_F3
const HINT := "DEV  F3: Start at Floor 3 (max upgrades)"
const WAITING_KEY := KEY_F4
const WAITING_HINT := "F4: Dev Waiting Room (all departments)"
const WAITING_HINT_ON := "F4: Back to the real save"
# Shown on screen in every department while the dev Waiting Room's profile is on.
const PROFILE_LABEL := "DEV PROFILE"
# What a strong player plausibly has on reaching the third floor.
const PENSION := 300
const KEYS := 3
const BOMBS := 5
const ITEMS := ["pill_organizer", "slippers", "hearing_aid"]
const BREWED_POTION := "healing_tonic"
# Both first-floor bosses and both second-floor bosses beaten, and the Parlour's once, so the Mall's
# lock is open as after a third-floor clear.
const CLEARS_BY_DEPTH := {1: 2, 2: 2, 3: 1}
const PATHS_CLEARED := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour"]
# For the dev Waiting Room, the profile also counts the Mall's path cleared, so every department is
# open at once. It only ever touches the throwaway profile.
const ALL_PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]


static func is_available() -> bool:
	return allowed(OS.is_debug_build())


# Release exports are not debug builds, so the shortcut never exists there.
static func allowed(debug_build: bool) -> bool:
	return debug_build


# all_departments is true for the dev Waiting Room (F4) and false for the Floor 3 run (F3).
static func progress(upgrades: Array[UpgradeDef], recipes: Array[ItemDef], all_departments := false) -> ProgressData:
	var data := ProgressData.new()
	data.opening_seen = true
	data.pension = PENSION
	for def in upgrades:
		data.upgrades[def.id] = def.max_level()
	for depth: int in CLEARS_BY_DEPTH:
		for i in CLEARS_BY_DEPTH[depth]:
			data.record_floor_cleared(depth)
	for id: String in PATHS_CLEARED:
		data.paths_cleared[id] = true
	# Only the path ids are added, not more clears, so the third floor's locks stay as they were.
	if all_departments:
		for id: String in ALL_PATHS:
			data.paths_cleared[id] = true
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
