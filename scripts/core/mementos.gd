class_name Mementos
extends RefCounted

# Each floor boss beaten for the first time hangs a memento on the lobby's trophy wall, and each
# memento gives a small permanent perk. A memento hangs once its floor's path is cleared, so a save
# from before the wall hangs every one it has earned at once.

const START_PENSION_PERK := "start_pension"
const PROP_COINS_PERK := "prop_coins"
const FIRST_HEAL_PERK := "first_heal"
const FIRE_PERK := "fire_shrug"
const BOSS_ROOM_PILL_PERK := "boss_room_pill"
const TREASURE_CHOICE_PERK := "treasure_choice"

# The name badge's Pension at the start of each run.
const START_PENSION := 10
# The bent shovel multiplies the coin chance of every breakable.
const PROP_COIN_MULT := 1.25
# The bedpan's extra pill on the first heal of a run.
const FIRST_HEAL_EXTRA := 1
# The top hat's pill on first entering a boss room.
const BOSS_ROOM_HEAL := 1
# The empty sack's extra item in treasure rooms.
const TREASURE_EXTRA := 1

# In floor order, the same order as the frames on the wall.
const ALL: Array[Dictionary] = [
	{"boss": "regional_reaper", "boss_name": "Regional Reaper", "short_name": "Reaper", "path": "floor_1",
		"memento": "Name badge", "perk": START_PENSION_PERK, "perk_text": "Start each run with 10 Pension"},
	{"boss": "tired_undertaker", "boss_name": "Digby, Tired Undertaker", "short_name": "Digby", "path": "cemetery",
		"memento": "Bent shovel", "perk": PROP_COINS_PERK, "perk_text": "Breakables drop Pension a little more often"},
	{"boss": "matron_mercy", "boss_name": "Matron Mercy", "short_name": "Matron", "path": "sunset_shores",
		"memento": "Bedpan", "perk": FIRST_HEAL_PERK, "perk_text": "The first heal of each run restores one extra pill"},
	{"boss": "old_smokey", "boss_name": "Old Smokey", "short_name": "Smokey", "path": "furnace_works",
		"memento": "Coal shovel", "perk": FIRE_PERK, "perk_text": "Every second hit from fire is shrugged off"},
	{"boss": "mortimer_grimsby", "boss_name": "Mortimer Grimsby", "short_name": "Mortimer", "path": "funeral_parlour",
		"memento": "Top hat", "perk": BOSS_ROOM_PILL_PERK, "perk_text": "+1 pill on entering a boss room"},
	{"boss": "mall_santa", "boss_name": "The Mall Santa", "short_name": "Santa", "path": "golden_years_mall",
		"memento": "Empty sack", "perk": TREASURE_CHOICE_PERK, "perk_text": "One more item to choose from in treasure rooms"},
]

const EMPTY_WALL_TEXT := "Empty frames. Beat a floor boss to hang one."


static func is_hung(entry: Dictionary, data: ProgressData) -> bool:
	return data.has_cleared_path(entry["path"])


static func hung(data: ProgressData) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Dictionary in ALL:
		if is_hung(entry, data):
			list.append(entry)
	return list


static func perks(data: ProgressData) -> Dictionary:
	var owned := {}
	for entry in hung(data):
		owned[entry["perk"]] = true
	return owned


# What looking at the wall says, one notice line each: every hung memento with its perk, or that the
# frames are empty.
static func wall_lines(data: ProgressData) -> PackedStringArray:
	var lines: PackedStringArray = []
	for entry in hung(data):
		lines.append("%s: %s" % [entry["memento"], entry["perk_text"]])
	if lines.is_empty():
		lines.append(EMPTY_WALL_TEXT)
	return lines
