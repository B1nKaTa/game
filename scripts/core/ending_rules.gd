class_name EndingRules
extends RefCounted

# Which ending plays when the Chairman of the Board falls, from a small snapshot of the run
# (RunState.ending_snapshot) and the endings already found. Pure rules: nothing here saves or loads.
#
# Every ending whose condition holds is a candidate, in ORDER. The first not yet found wins, and if
# all are found the first plays again. Briefly Alive always holds until the Eternal Feud is found;
# from then on Repeat Customer takes its place, and when no ending 2 to 9 is left to find it is
# Repeat Customer every time, with a different quick death.

# The bosses whose fall ends a run with a scene: the Chairman's with an ending, Augustine's with his.
const CHAIRMAN := "chairman_of_the_board"
const AUGUSTINE := "augustine"
const ETERNAL_FEUD := "eternal_feud"
const NEW_MANAGEMENT := "new_management"
const CRASHING_THE_FUNERAL := "crashing_the_funeral"
const FORTUNE_AND_GLORY := "fortune_and_glory"
const EXCESS_BAGGAGE := "excess_baggage"
const HOUSE_ALWAYS_WINS := "house_always_wins"
const LITERALLY := "literally"
const BY_A_THREAD := "by_a_thread"
const SCENIC_ROUTE := "scenic_route"
const REPEAT_CUSTOMER := "repeat_customer"
const BRIEFLY_ALIVE := "briefly_alive"

# Tuned by testing: a run of all five depths without lingering, a rich run, a full bag.
const FAST_RUN_SECONDS := 2100.0
const FORTUNE_PENSION := 2500
const BAGGAGE_ITEMS := 12
# Arcade or Back Room visits with at least one game won.
const TABLE_VISITS := 3
# How many of endings 2 to 9 make the Eternal Feud due.
const FEUD_NEEDS := 5
# The east path of every depth.
const SCENIC_PATHS := {1: "cemetery", 2: "furnace_works", 3: "flashback_cinema", 4: "seance_hotline", 5: "head_office"}
const REPEAT_DEATHS := 5
const HAT_NOTICE := "Gerald left you his hat. You can wear it from the Decor Office."
const TOTAL := 11

# The order endings are chosen in.
const ORDER: Array[String] = [
	ETERNAL_FEUD, NEW_MANAGEMENT, CRASHING_THE_FUNERAL, FORTUNE_AND_GLORY, EXCESS_BAGGAGE,
	HOUSE_ALWAYS_WINS, LITERALLY, BY_A_THREAD, SCENIC_ROUTE, REPEAT_CUSTOMER, BRIEFLY_ALIVE,
]

# The archive's files, in number order.
const ALL: Array[Dictionary] = [
	{"id": BRIEFLY_ALIVE, "number": 1, "title": "Briefly Alive", "cause": "Cause of death: stairs. Again.", "hint": "Applicant has not yet left the building."},
	{"id": NEW_MANAGEMENT, "number": 2, "title": "Under New Management", "cause": "Cause of death: paperwork.", "hint": "Applicant was not harmed during the interview."},
	{"id": CRASHING_THE_FUNERAL, "number": 3, "title": "Crashing the Funeral", "cause": "Cause of death: his own funeral.", "hint": "Applicant arrived before his paperwork."},
	{"id": FORTUNE_AND_GLORY, "number": 4, "title": "Fortune and Glory", "cause": "Cause of death: property tax.", "hint": "Applicant attempted to pay in cash."},
	{"id": EXCESS_BAGGAGE, "number": 5, "title": "Excess Baggage", "cause": "Cause of death: none. Status: haunting.", "hint": "Applicant arrived with too much luggage."},
	{"id": HOUSE_ALWAYS_WINS, "number": 6, "title": "The House Always Wins", "cause": "Cause of death: the house.", "hint": "Applicant was seen at the tables. Often."},
	{"id": LITERALLY, "number": 7, "title": "Back from the Dead (Literally)", "cause": "Cause of death: pest control.", "hint": "Applicant's ticket was cursed."},
	{"id": BY_A_THREAD, "number": 8, "title": "By a Thread", "cause": "Cause of death: grapes.", "hint": "Applicant was hanging on by a thread."},
	{"id": SCENIC_ROUTE, "number": 9, "title": "The Scenic Route", "cause": "Cause of death: jet lag.", "hint": "Applicant took the long way round."},
	{"id": ETERNAL_FEUD, "number": 10, "title": "Eternal Feud", "cause": "Cause of death: Gerald.", "hint": "Find five other files."},
	{"id": REPEAT_CUSTOMER, "number": 11, "title": "Repeat Customer", "cause": "Cause of death: varies.", "hint": "File opens once 27B-10 is closed."},
]

# Ending 11's quick deaths, 1 to 5, each with its own card.
const REPEAT_CAUSES: Array[String] = [
	"Cause of death: stairs.",
	"Cause of death: a sandwich.",
	"Cause of death: bath time.",
	"Cause of death: a light bulb.",
	"Cause of death: daytime television.",
]
# Endings 2 to 9, which count towards the Eternal Feud.
const FEUD_COUNTS: Array[String] = [
	NEW_MANAGEMENT, CRASHING_THE_FUNERAL, FORTUNE_AND_GLORY, EXCESS_BAGGAGE, HOUSE_ALWAYS_WINS,
	LITERALLY, BY_A_THREAD, SCENIC_ROUTE,
]


static func choose(snap: Dictionary, found: Dictionary) -> String:
	var first := ""
	for id in ORDER:
		if not holds(id, snap, found):
			continue
		if not found.has(id):
			return id
		if first.is_empty():
			first = id
	if found.has(ETERNAL_FEUD):
		return REPEAT_CUSTOMER
	return first if not first.is_empty() else BRIEFLY_ALIVE


static func holds(id: String, snap: Dictionary, found: Dictionary) -> bool:
	match id:
		ETERNAL_FEUD:
			return not found.has(ETERNAL_FEUD) and feud_count(found) >= FEUD_NEEDS
		NEW_MANAGEMENT:
			return not bool(snap.get("lost_pill_in_boss_room", true))
		CRASHING_THE_FUNERAL:
			return float(snap.get("play_time", INF)) <= FAST_RUN_SECONDS
		FORTUNE_AND_GLORY:
			return int(snap.get("pension_earned", 0)) >= FORTUNE_PENSION
		EXCESS_BAGGAGE:
			return int(snap.get("items", 0)) >= BAGGAGE_ITEMS
		HOUSE_ALWAYS_WINS:
			return int(snap.get("arcade_visits_won", 0)) >= TABLE_VISITS
		LITERALLY:
			return bool(snap.get("cursed", false))
		BY_A_THREAD:
			return int(snap.get("pills", 0)) == 1
		SCENIC_ROUTE:
			var paths: Dictionary = snap.get("paths", {})
			for depth: int in SCENIC_PATHS:
				if str(paths.get(depth, "")) != SCENIC_PATHS[depth]:
					return false
			return true
		REPEAT_CUSTOMER:
			return found.has(ETERNAL_FEUD)
		BRIEFLY_ALIVE:
			return not found.has(ETERNAL_FEUD)
	return false


static func feud_count(found: Dictionary) -> int:
	var count := 0
	for id in FEUD_COUNTS:
		if found.has(id):
			count += 1
	return count


static func found_count(found: Dictionary) -> int:
	var count := 0
	for id in ORDER:
		if found.has(id):
			count += 1
	return count


static func is_ending(id: String) -> bool:
	return ORDER.has(id)


static func entry(id: String) -> Dictionary:
	for each in ALL:
		if each["id"] == id:
			return each
	return {}


# A quick death from 1 to REPEAT_DEATHS, never last, from a roll in [0, 1).
static func pick_repeat_death(last: int, roll: float) -> int:
	var choices: Array[int] = []
	for n in range(1, REPEAT_DEATHS + 1):
		if n != last:
			choices.append(n)
	return choices[clampi(int(roll * choices.size()), 0, choices.size() - 1)]


# One line of the Ending Archive: a found file's number, title and cause, or a missing one's hint.
# Repeat Customer counts its quick deaths instead of naming one.
static func archive_row(each: Dictionary, data: ProgressData) -> String:
	var number := "27B-%d" % int(each["number"])
	if not data.endings_found.has(each["id"]):
		return "%s  ???  %s" % [number, each["hint"]]
	if each["id"] == REPEAT_CUSTOMER:
		return "%s  %s.  Quick deaths seen: %d/%d." % [number, each["title"], data.repeat_deaths_seen.size(), REPEAT_DEATHS]
	return "%s  %s.  %s" % [number, each["title"], each["cause"]]


static func found_line(data: ProgressData) -> String:
	return "Endings found: %d/%d" % [found_count(data.endings_found), TOTAL]


# Which quick death the Archive replays: any one already seen, or any at all if none was kept.
static func replay_death(data: ProgressData, roll: float) -> int:
	var seen: Array[int] = []
	for n in range(1, REPEAT_DEATHS + 1):
		if data.repeat_deaths_seen.has(str(n)):
			seen.append(n)
	if seen.is_empty():
		return clampi(int(roll * REPEAT_DEATHS) + 1, 1, REPEAT_DEATHS)
	return seen[clampi(int(roll * seen.size()), 0, seen.size() - 1)]


# What the Waiting Room says on arrival after an ending found for the first time.
static func found_notices(id: String, paid: int) -> Array[String]:
	var each := entry(id)
	var lines: Array[String] = []
	if each.is_empty():
		return lines
	lines.append("New file for the Ending Archive: 27B-%d, %s. +%d Condolences" % [each["number"], each["title"], paid])
	if id == ETERNAL_FEUD:
		lines.append(HAT_NOTICE)
	return lines


static func repeat_cause(n: int) -> String:
	return REPEAT_CAUSES[clampi(n, 1, REPEAT_DEATHS) - 1]
