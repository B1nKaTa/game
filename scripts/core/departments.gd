class_name Departments
extends RefCounted

# The Waiting Room is a small floor of departments on the run floors' room grid. The lobby, the
# hallway and the annexe's two corridors are open from the start, and every other department opens on
# the first clear of its floor. A department that holds a merchant also opens when that merchant's own
# rule opens, so a save that opened a merchant by its old clear count never finds it behind a closed
# door.

const LOBBY := "lobby"
const HALLWAY := "hallway"
const BOUNTY_OFFICE := "bounty_office"
const TRAINING_YARD := "training_yard"
const APOTHECARY_WING := "apothecary_wing"
const BOILER_ROOM := "boiler_room"
const DECOR_OFFICE := "decor_office"
const BACK_ROOM := "back_room"
# The fourth and fifth floors' departments, up the annexe's two corridors.
const ANNEXE := "annexe"
const UPPER_LANDING := "upper_landing"
const PURSERS_OFFICE := "pursers_office"
const PRO_SHOP := "pro_shop"
const DUTY_FREE := "duty_free"
const EXECUTIVE_SUITE := "executive_suite"
const LAYOUT_DIR := "res://data/rooms/waiting_room/"
# Every side of the lobby and the hallway is taken, so the annexe is reached through the Bounty Office.
# The Records Basement is the only path open before any clear, so every save opens the Bounty Office
# before it can clear anything else, and the annexe never waits behind a door that is still closed.
const ANNEXE_GATE := BOUNTY_OFFICE

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
	{"id": BACK_ROOM, "name": "Back Room", "cell": Vector2i(0, 1), "layout": LAYOUT_DIR + "back_room.tres", "opens_on": "flashback_cinema",
		"arrival": "A door marked PRIVATE swings open. The Dealer has a back room."},
	# Two corridors north of the Bounty Office, open from the start and holding nothing. The fourth
	# floor's departments hang off the first and the fifth floor's off the second.
	{"id": ANNEXE, "name": "Annexe", "cell": Vector2i(0, -2), "layout": LAYOUT_DIR + "annexe.tres", "opens_on": "", "arrival": ""},
	{"id": UPPER_LANDING, "name": "Upper Landing", "cell": Vector2i(0, -3), "layout": LAYOUT_DIR + "upper_landing.tres", "opens_on": "", "arrival": ""},
	{"id": PURSERS_OFFICE, "name": "Purser's Office", "cell": Vector2i(-1, -2), "layout": LAYOUT_DIR + "pursers_office.tres", "opens_on": "last_resort_cruise",
		"arrival": "The Purser's Office is open. Every run now sets off with a Bon Voyage Bag."},
	{"id": PRO_SHOP, "name": "Pro Shop", "cell": Vector2i(1, -2), "layout": LAYOUT_DIR + "pro_shop.tres", "opens_on": "seance_hotline",
		"arrival": "The Pro Shop has opened. Its Golf Glove charges a swing faster."},
	{"id": DUTY_FREE, "name": "Duty Free", "cell": Vector2i(-1, -3), "layout": LAYOUT_DIR + "duty_free.tres", "opens_on": "terminal_zero",
		"arrival": "Duty Free is open. Frequent Flyer Miles take a little off every shop."},
	{"id": EXECUTIVE_SUITE, "name": "Executive Suite", "cell": Vector2i(0, -4), "layout": LAYOUT_DIR + "executive_suite.tres", "opens_on": "head_office",
		"arrival": "The Executive Suite is open. The Severance Desk offers a Golden Handshake."},
]

# The lobby has only four sides, so a hallway joins it to three of the departments. Each department
# is reached through the lobby and the corridors alone, whatever order floors are cleared in, except
# that the annexe's door is in the Bounty Office (see ANNEXE_GATE).
const LINKS := [
	[LOBBY, BOUNTY_OFFICE], [LOBBY, TRAINING_YARD], [LOBBY, BACK_ROOM], [LOBBY, HALLWAY],
	[HALLWAY, APOTHECARY_WING], [HALLWAY, BOILER_ROOM], [HALLWAY, DECOR_OFFICE],
	[ANNEXE_GATE, ANNEXE], [ANNEXE, PURSERS_OFFICE], [ANNEXE, PRO_SHOP], [ANNEXE, UPPER_LANDING],
	[UPPER_LANDING, DUTY_FREE], [UPPER_LANDING, EXECUTIVE_SUITE],
]

# The floors whose first clear opens a department, by path id, for the closed door's hint. Kept here
# so nothing in the Waiting Room's rules loads a FloorDef.
const FLOOR_NAMES := {
	"floor_1": "The Records Basement",
	"cemetery": "The Unkempt Cemetery",
	"sunset_shores": "Sunset Shores Eternal Care",
	"furnace_works": "The Furnace Works",
	"funeral_parlour": "Eternal Rest Funeral Parlour",
	"flashback_cinema": "The Flashback Cinema, Last Showing",
	"last_resort_cruise": "The Last Resort Cruise",
	"seance_hotline": "Beyond Calling Psychic Hotline, Night Shift",
	"terminal_zero": "Departures, Terminal Zero",
	"head_office": "Head Office, Eternity Incorporated",
}

# How many department names one arrival notice holds before the news goes on to the next notice.
const NAMES_PER_NOTICE := 3

# When a merchant appears is read by MerchantRules: "depth" and "clears" count clears at a depth,
# "paths" names the paths that must all have been cleared, and "legacy_clears" keeps a merchant open
# for a save made before clears were kept by depth. No rule means always there. "kind" picks the
# panel: upgrades by default, or "potions" for brews. "department" is the room each one stands in.
const MERCHANTS := [
	{"id": "black_market", "department": LOBBY, "title": "Black Market. You didn't see me.", "cell": Vector2i(6, 3), "color": Color("8a4fbf"), "art": "merchant"},
	{"id": "optometrist", "department": LOBBY, "title": "Dr. Squint, Unlicensed Optometrist", "cell": Vector2i(6, 7), "color": Color("4fbfa8"), "art": "optometrist"},
	{"id": "potion_merchant", "department": APOTHECARY_WING, "kind": "potions", "depth": 2, "clears": 1, "legacy_clears": 1, "title": "Madame Murk, Discount Apothecary", "cell": Vector2i(4, 3), "color": Color("c0508f"), "art": "apothecary"},
	{"id": "bomb_merchant", "department": BOILER_ROOM, "paths": ["sunset_shores", "furnace_works"], "legacy_clears": 3, "title": "Boom Bernard, Fuel Dealer", "cell": Vector2i(4, 3), "color": Color("d9822b"), "art": "fuel_dealer"},
	# The deep floors' counters. Each is a board, since its keeper stands beside it as an NPC (NPCS), a
	# few cells off so one press never both opens the counter and talks.
	{"id": "pro_shop", "department": PRO_SHOP, "paths": ["seance_hotline"], "title": "Pro Shop. Gloves, Tees and Regrets", "cell": Vector2i(4, 3), "label": "Pro Shop", "size": Vector2(40, 24), "color": Color("3f7a4a")},
	{"id": "duty_free", "department": DUTY_FREE, "paths": ["terminal_zero"], "title": "Duty Free. Tax Paid in Full, at Death", "cell": Vector2i(4, 3), "label": "Duty Free", "size": Vector2(40, 24), "color": Color("4a5f8a")},
	{"id": "severance_desk", "department": EXECUTIVE_SUITE, "paths": ["head_office"], "title": "Severance Desk. Please Take a Seat", "cell": Vector2i(6, 3), "label": "Severance", "size": Vector2(48, 24), "color": Color("8a6a3a")},
]

# Every counter, board and NPC that is not a merchant: {"id", "department", "cell", "title",
# "prompt", "art" or "size", "color"}. An entry with "art" is drawn as that sprite, one without as a
# board of its size and colour.
const STATIONS: Array[Dictionary] = [
	{"id": "key_board", "department": LOBBY, "cell": Vector2i(20, 7), "title": "Key Settings", "prompt": "Key Settings", "label": "Keys", "size": Vector2(28, 36), "color": Color("6b4a2a")},
	{"id": "crafter", "department": LOBBY, "cell": Vector2i(11, 7), "title": "Agnes, Afterlife Arts and Crafts", "prompt": "Craft", "art": "crafter", "color": Color("c98a3c")},
	{"id": "forms_counter", "department": LOBBY, "cell": Vector2i(11, 3), "title": "Forms Counter. Refiling, Window 2", "prompt": "Refile", "label": "Forms", "size": Vector2(28, 36), "color": Color("7a6f5a")},
	# The TrophyWall draws the frames on the top wall above it, so the station itself draws no board. Its
	# prompt sits low, under the wall's "Endings found" line.
	{"id": "trophy_wall", "department": LOBBY, "cell": Vector2i(20, 3), "title": "Trophy Wall", "prompt": "Look", "board": false, "prompt_offset": Vector2(-20, -4)},
	# A red box with a paper tongue, and a cork board that marks NEW while a letter waits unread.
	{"id": "ticket_machine", "department": LOBBY, "cell": Vector2i(23, 3), "title": "Take a Number", "prompt": "Ticket", "size": Vector2(20, 28), "color": Color("c8323a"), "look": "ticket_machine"},
	{"id": "noticeboard", "department": LOBBY, "cell": Vector2i(23, 7), "title": "Noticeboard. Letters from the Living", "prompt": "Read", "size": Vector2(34, 24), "color": Color("a8794a"), "look": "noticeboard"},
	# A PosterBoard draws the cork board and its posters, so the station draws none. It stands off the
	# middle column, since (10, 2) would be beside the cell a north door would use. Its prompt sits
	# higher than a station's, over the board's WANTED title ("prompt_offset").
	{"id": "bounty_board", "department": BOUNTY_OFFICE, "cell": Vector2i(6, 2), "title": "Bounty Office. Overdue Accounts", "prompt": "Wanted posters", "board": false, "prompt_offset": Vector2(-30, -32)},
	{"id": "item_rack", "department": TRAINING_YARD, "cell": Vector2i(15, 3), "title": "Item Rack", "prompt": "Try items", "label": "Rack", "size": Vector2(36, 28), "color": Color("6a5a48")},
	# No named clerk keeps the Decor Office. Looks are bought and worn at this one counter.
	{"id": "decor_counter", "department": DECOR_OFFICE, "cell": Vector2i(10, 4), "title": "Decor Office. Sympathy in Every Shade", "prompt": "Browse", "label": "Decor", "size": Vector2(44, 24), "color": Color("8a6a8a")},
	# A brass plaque that counts Head Office clears (plaque_text).
	{"id": "employee_plaque", "department": EXECUTIVE_SUITE, "cell": Vector2i(14, 3), "title": "Employee of Eternity", "prompt": "Read", "label": "Plaque", "size": Vector2(30, 20), "color": Color("b08a2a")},
	# A grey filing cabinet holding every ending found (EndingArchivePanel).
	{"id": "ending_archive", "department": EXECUTIVE_SUITE, "cell": Vector2i(14, 7), "title": "Ending Archive. Files 27B-1 to 27B-11", "prompt": "Browse files", "size": Vector2(22, 34), "color": Color("6a6a72"), "look": "filing_cabinet"},
]

# People who stand in a department, each made from its NpcDef on the department's first entry. They
# talk on their own, and the scene listens to what they say where it needs to. An entry with "greets"
# says its NpcDef's moment for the run just played on arrival (NpcDef.greeting_key).
const NPCS: Array[Dictionary] = [
	{"id": "deputy_dolores", "department": BOUNTY_OFFICE, "cell": Vector2i(10, 6), "def": "res://data/npcs/deputy_dolores.tres"},
	{"id": "coach_bertram", "department": TRAINING_YARD, "cell": Vector2i(5, 5), "def": "res://data/npcs/coach_bertram.tres"},
	# The Purser stands alone: the Bon Voyage Bag is packed for every run while her office is open.
	{"id": "purser", "department": PURSERS_OFFICE, "cell": Vector2i(7, 4), "def": "res://data/npcs/purser.tres", "greets": true},
	{"id": "pro_shop_keeper", "department": PRO_SHOP, "cell": Vector2i(9, 4), "def": "res://data/npcs/pro_shop_keeper.tres", "greets": true},
	{"id": "duty_free_clerk", "department": DUTY_FREE, "cell": Vector2i(9, 4), "def": "res://data/npcs/duty_free_clerk.tres", "greets": true},
	{"id": "severance_clerk", "department": EXECUTIVE_SUITE, "cell": Vector2i(6, 6), "def": "res://data/npcs/severance_clerk.tres", "greets": true},
	# Gerald, once the true ending has put him in the queue too. "needs_ending" keeps him out until then
	# (npc_stands). He stands off the way across, clear of the trophy captions and the loadout bench.
	{"id": "gerald", "department": LOBBY, "cell": Vector2i(17, 4), "def": "res://data/npcs/gerald.tres", "greets": true, "needs_ending": EndingRules.ETERNAL_FEUD},
]

# The trophy wall's frames hang centred on this x in the lobby, the line between columns 19 and 20, on
# the line between the top wall and the first floor row. Ten frames fill the top wall between the
# north door at column 15 and the lantern at column 24 (test_mementos).
const TROPHY_WALL_X := 640.0
const TROPHY_WALL_Y := 34.0

# The door out to a run stands inside the lobby, since all four lobby walls lead to departments. It is
# off the row the east and west doors share, so walking across the lobby never starts a run.
const RUN_DOOR_CELL := Vector2i(26, 8)

# The Training Yard's dummy, spawned on the yard's first entry. It is the only enemy anywhere in the
# Waiting Room, so its FloorDef stays enemy-free.
const TRAINING_DUMMY := "res://data/enemies/training_dummy.tres"
const DUMMY_CELL := Vector2i(10, 5)

# The Dealer's back room: card tables only, at the Arcade's own odds, so the slot machine stays in the
# Arcade. One table per G cell of the Back Room, and they refill on every visit.
const BACK_ROOM_GAMES: Array[String] = [ArcadeTable.BLACKJACK, ArcadeTable.POKER]
const BACK_ROOM_DEALER := "res://data/npcs/dealer_back_room.tres"

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


# Whether a room is open from the start: the lobby and the corridors, which no floor opens.
static func is_corridor(id: String) -> bool:
	var each := entry(id)
	return not each.is_empty() and str(each["opens_on"]).is_empty()


# The rooms open from the start, in map order: the lobby and the corridors.
static func corridor_ids() -> Array[String]:
	var ids: Array[String] = []
	for each: Dictionary in ALL:
		if is_corridor(each["id"]):
			ids.append(each["id"])
	return ids


# Open departments not yet announced. The lobby and the corridors are always open and never announced.
static func newly_opened(data: ProgressData) -> Array[String]:
	var ids: Array[String] = []
	for id in open_ids(data):
		if not is_corridor(id) and not data.departments_seen.has(id):
			ids.append(id)
	return ids


# What the Executive Suite's plaque says, from how many times Head Office has been cleared.
static func plaque_text(clears: int) -> String:
	if clears <= 0:
		return "Employee of Eternity: position vacant. Clear Head Office to apply."
	if clears == 1:
		return "Employee of Eternity: Grandpa. Head Office cleared once. No raise."
	return "Employee of Eternity: Grandpa. Head Office cleared %d times. No raise." % clears


# The arrival news for those departments, a few names to a line, since the HUD's notice is one line
# of the 640 px screen and all six names together fill it edge to edge.
static func opening_notices(ids: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	for start in range(0, ids.size(), NAMES_PER_NOTICE):
		var names: Array[String] = []
		for id in ids.slice(start, start + NAMES_PER_NOTICE):
			names.append(entry(id)["name"])
		lines.append("New departments open: %s." % ", ".join(names))
	return lines


static func closed_hint(id: String) -> String:
	var opens_on: String = entry(id).get("opens_on", "")
	if opens_on.is_empty():
		return ""
	return "Opens when %s is cleared" % FLOOR_NAMES.get(opens_on, "a floor")


# Whether a department NPC stands there yet: always, unless he waits on an ending being found.
static func npc_stands(npc: Dictionary, data: ProgressData) -> bool:
	var needs := str(npc.get("needs_ending", ""))
	return needs.is_empty() or data.endings_found.has(needs)


static func station_entry(station_id: String) -> Dictionary:
	for station: Dictionary in STATIONS:
		if station["id"] == station_id:
			return station
	return {}


static func merchant_entry(merchant_id: String) -> Dictionary:
	for merchant: Dictionary in MERCHANTS:
		if merchant["id"] == merchant_id:
			return merchant
	return {}
