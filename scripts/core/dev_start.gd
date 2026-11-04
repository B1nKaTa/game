class_name DevStart
extends RefCounted

# A testing shortcut for debug builds only: a fresh run that starts on the Floor 3 landing, with every
# upgrade at its top level and the first two floors counted as cleared. Its progress lives in memory and
# in its own file, never in the real save, and is thrown away when the run ends.

const START_DEPTH := 3
const KEY := KEY_F3
const HINT := "DEV  F3: Start at Floor 3 (max upgrades)"
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
# Launched with `-- --dev-all-departments`, the dev profile also counts the Mall's path cleared, so
# every Waiting Room department is open at once. It only ever touches the dev run's throwaway progress.
const ALL_DEPARTMENTS_FLAG := "--dev-all-departments"
const ALL_PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]


static func is_available() -> bool:
	return allowed(OS.is_debug_build())


# Release exports are not debug builds, so the shortcut never exists there.
static func allowed(debug_build: bool) -> bool:
	return debug_build


static func all_departments(user_args: PackedStringArray) -> bool:
	return user_args.has(ALL_DEPARTMENTS_FLAG)


# user_args are the command line's user arguments (after `--`), passed in so tests can set them.
static func progress(upgrades: Array[UpgradeDef], recipes: Array[ItemDef], user_args := PackedStringArray()) -> ProgressData:
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
	if all_departments(user_args):
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
