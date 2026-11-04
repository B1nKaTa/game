class_name Departments
extends RefCounted

# The Waiting Room is a small floor of departments on the run floors' room grid. The lobby and the
# hallway are open from the start, and every other department opens on the first clear of its floor.
# A department that holds a merchant also opens when that merchant's own rule opens, so a save that
# opened a merchant by its old clear count never finds it behind a closed door.

const LOBBY := "lobby"
const HALLWAY := "hallway"
const BOUNTY_OFFICE := "bounty_office"
const TRAINING_YARD := "training_yard"
const APOTHECARY_WING := "apothecary_wing"
const BOILER_ROOM := "boiler_room"
const DECOR_OFFICE := "decor_office"
const BACK_ROOM := "back_room"
const LAYOUT_DIR := "res://data/rooms/waiting_room/"

# In this order the map numbers its rooms, and open_ids lists them.
const ALL: Array[Dictionary] = [
	{"id": LOBBY, "name": "Lobby", "cell": Vector2i(0, 0), "layout": LAYOUT_DIR + "lobby.tres", "opens_on": "", "arrival": ""},
	{"id": HALLWAY, "name": "Hallway", "cell": Vector2i(-1, 0), "layout": LAYOUT_DIR + "hallway.tres", "opens_on": "", "arrival": ""},
	{"id": BOUNTY_OFFICE, "name": "Bounty Office", "cell": Vector2i(0, -1), "layout": LAYOUT_DIR + "bounty_office.tres", "opens_on": "floor_1",
		"arrival": "A new door creaks open: the Bounty Office. Someone in there wants names."},
	{"id": TRAINING_YARD, "name": "Training Yard", "cell": Vector2i(1, 0), "layout": LAYOUT_DIR + "training_yard.tres", "opens_on": "cemetery",
		"arrival": "The Training Yard is open. Somebody has set up a dummy that looks very familiar."},
	{"id": APOTHECARY_WING, "name": "Apothecary Wing", "cell": Vector2i(-1, -1), "layout": LAYOUT_DIR + "apothecary_wing.tres", "opens_on": "sunset_shores", "merchant": "potion_merchant",
		"arrival": "Madame Murk has moved into the Apothecary Wing. It smells of liniment."},
	{"id": BOILER_ROOM, "name": "Boiler Room", "cell": Vector2i(-1, 1), "layout": LAYOUT_DIR + "boiler_room.tres", "opens_on": "furnace_works", "merchant": "bomb_merchant",
		"arrival": "Boom Bernard has set up shop in the Boiler Room. Mind the fumes."},
	{"id": DECOR_OFFICE, "name": "Decor Office", "cell": Vector2i(-2, 0), "layout": LAYOUT_DIR + "decor_office.tres", "opens_on": "funeral_parlour",
		"arrival": "The Decor Office is open. Condolences accepted, sympathy extra."},
	{"id": BACK_ROOM, "name": "Back Room", "cell": Vector2i(0, 1), "layout": LAYOUT_DIR + "back_room.tres", "opens_on": "golden_years_mall",
		"arrival": "A door marked PRIVATE swings open. The Dealer has a back room."},
]

# The lobby has only four sides, so a hallway joins it to three of the departments. Each department
# is reached through the lobby and the hallway alone, whatever order floors are cleared in.
const LINKS := [
	[LOBBY, BOUNTY_OFFICE], [LOBBY, TRAINING_YARD], [LOBBY, BACK_ROOM], [LOBBY, HALLWAY],
	[HALLWAY, APOTHECARY_WING], [HALLWAY, BOILER_ROOM], [HALLWAY, DECOR_OFFICE],
]

# The floors whose first clear opens a department, by path id, for the closed door's hint. Kept here
# so nothing in the Waiting Room's rules loads a FloorDef.
const FLOOR_NAMES := {
	"floor_1": "The Records Basement",
	"cemetery": "The Unkempt Cemetery",
	"sunset_shores": "Sunset Shores Eternal Care",
	"furnace_works": "The Furnace Works",
	"funeral_parlour": "Eternal Rest Funeral Parlour",
	"golden_years_mall": "Golden Years Mall at 7 a.m.",
}

# When a merchant appears is read by MerchantRules: "depth" and "clears" count clears at a depth,
# "paths" names the paths that must all have been cleared, and "legacy_clears" keeps a merchant open
# for a save made before clears were kept by depth. No rule means always there. "kind" picks the
# panel: upgrades by default, or "potions" for brews. "department" is the room each one stands in.
const MERCHANTS := [
	{"id": "black_market", "department": LOBBY, "title": "Black Market. You didn't see me.", "cell": Vector2i(6, 3), "color": Color("8a4fbf"), "art": "merchant"},
	{"id": "optometrist", "department": LOBBY, "title": "Dr. Squint, Unlicensed Optometrist", "cell": Vector2i(6, 7), "color": Color("4fbfa8"), "art": "optometrist"},
	{"id": "potion_merchant", "department": APOTHECARY_WING, "kind": "potions", "depth": 2, "clears": 1, "legacy_clears": 1, "title": "Madame Murk, Discount Apothecary", "cell": Vector2i(4, 3), "color": Color("c0508f"), "art": "apothecary"},
	{"id": "bomb_merchant", "department": BOILER_ROOM, "paths": ["sunset_shores", "furnace_works"], "legacy_clears": 3, "title": "Boom Bernard, Fuel Dealer", "cell": Vector2i(4, 3), "color": Color("d9822b"), "art": "fuel_dealer"},
]

# Every counter, board and NPC that is not a merchant: {"id", "department", "cell", "title",
# "prompt", "art" or "size", "color"}. An entry with "art" is drawn as that sprite, one without as a
# board of its size and colour.
const STATIONS: Array[Dictionary] = [
	{"id": "key_board", "department": LOBBY, "cell": Vector2i(20, 7), "title": "Key Settings", "prompt": "Key Settings", "label": "Keys", "size": Vector2(28, 36), "color": Color("6b4a2a")},
	{"id": "crafter", "department": LOBBY, "cell": Vector2i(11, 7), "title": "Agnes, Afterlife Arts and Crafts", "prompt": "Craft", "art": "crafter", "color": Color("c98a3c")},
	{"id": "forms_counter", "department": LOBBY, "cell": Vector2i(11, 3), "title": "Forms Counter. Refiling, Window 2", "prompt": "Refile", "label": "Forms", "size": Vector2(28, 36), "color": Color("7a6f5a")},
	# The TrophyWall draws the frames on the top wall above it, so the station itself draws no board.
	{"id": "trophy_wall", "department": LOBBY, "cell": Vector2i(20, 3), "title": "Trophy Wall", "prompt": "Look", "board": false},
]

# The trophy wall's frames hang centred over this lobby column, on the line between the top wall and
# the first floor row, clear of the north door at column 15.
const TROPHY_WALL_COLUMN := 20
const TROPHY_WALL_Y := 34.0

# The door out to a run stands inside the lobby, since all four lobby walls lead to departments. It is
# off the row the east and west doors share, so walking across the lobby never starts a run.
const RUN_DOOR_CELL := Vector2i(26, 8)

# Reserved for the loadout bench, built once a second weapon exists. Plain floor, with nothing on it.
const LOADOUT_BENCH_CELLS: Array[Vector2i] = [Vector2i(14, 7), Vector2i(15, 7), Vector2i(16, 7), Vector2i(14, 8), Vector2i(15, 8), Vector2i(16, 8)]


# The room id in the built map, which is the index in ALL, or -1 for an unknown id.
static func index_of(id: String) -> int:
	for i in ALL.size():
		if ALL[i]["id"] == id:
			return i
	return -1


static func entry(id: String) -> Dictionary:
	var at := index_of(id)
	return ALL[at] if at >= 0 else {}


static func id_of(room_id: int) -> String:
	return ALL[room_id]["id"] if room_id >= 0 and room_id < ALL.size() else ""


static func load_layouts() -> Dictionary:
	var layouts := {}
	for each: Dictionary in ALL:
		layouts[each["id"]] = load(each["layout"])
	return layouts


# An ordinary floor map of department rooms, joined by LINKS, that starts in the lobby.
static func build_map(layouts: Dictionary) -> FloorMap:
	var map := FloorMap.new()
	for i in ALL.size():
		var room := FloorRoom.new()
		room.id = i
		room.room_type = RoomLayout.TYPE_DEPARTMENT
		room.layout = layouts[ALL[i]["id"]]
		room.cell = ALL[i]["cell"]
		room.decor_seed = i
		map.rooms.append(room)
	for link: Array in LINKS:
		map.join(map.room(index_of(link[0])), map.room(index_of(link[1])))
	map.start_id = index_of(LOBBY)
	map.boss_id = map.start_id
	return map


static func is_open(id: String, data: ProgressData) -> bool:
	var each := entry(id)
	if each.is_empty():
		return false
	var opens_on: String = each["opens_on"]
	if opens_on.is_empty() or data.has_cleared_path(opens_on):
		return true
	if each.has("merchant"):
		var merchant := merchant_entry(each["merchant"])
		return not merchant.is_empty() and MerchantRules.is_open(merchant, data)
	return false


static func open_ids(data: ProgressData) -> Array[String]:
	var ids: Array[String] = []
	for each: Dictionary in ALL:
		if is_open(each["id"], data):
			ids.append(each["id"])
	return ids


# Open departments not yet announced. The lobby and the hallway are always open and never announced.
static func newly_opened(data: ProgressData) -> Array[String]:
	var ids: Array[String] = []
	for id in open_ids(data):
		if id != LOBBY and id != HALLWAY and not data.departments_seen.has(id):
			ids.append(id)
	return ids


static func closed_hint(id: String) -> String:
	var opens_on: String = entry(id).get("opens_on", "")
	if opens_on.is_empty():
		return ""
	return "Opens when %s is cleared" % FLOOR_NAMES.get(opens_on, "a floor")


static func merchant_entry(merchant_id: String) -> Dictionary:
	for merchant: Dictionary in MERCHANTS:
		if merchant["id"] == merchant_id:
			return merchant
	return {}
