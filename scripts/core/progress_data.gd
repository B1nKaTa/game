class_name ProgressData
extends RefCounted

const VERSION := 1
const RETIREMENT_CAP := 1000
const RETIREMENT_TIERS := [10, 50, 100, 250, 500, 750, 1000]
const NO_DEPOSIT_RUN := -1
# Switching a form's milestone option costs this, after each form's one free switch.
const REFILE_FEE := 40
# The share the clerk takes off the one form on deal for a visit.
const CLERK_DEAL_CUT := 0.25
# Condolences paid the first time each boss falls, and for each floor cleared in a cursed run.
const FIRST_MINI_BOSS_CONDOLENCES := 5
const FIRST_FLOOR_BOSS_CONDOLENCES := 10
const CURSED_FLOOR_CONDOLENCES := 10
# Paid the first time each ending is found. The true ending also gives Gerald's Hat.
const ENDING_CONDOLENCES := 15
const GERALDS_HAT := "geralds_hat"
# The deepest floor, whose boss falling ends a run as a win. Mirrors FloorScene.LAST_DEPTH.
const LAST_DEPTH := 5

var pension: int = 0
var upgrades: Dictionary = {}
var opening_seen: bool = false
var retirement_balance: int = 0
var retirement_peak: int = 0
var run_count: int = 0
var retirement_deposit_run: int = NO_DEPOSIT_RUN
var recipes_found: Dictionary = {}
var items_unlocked: Dictionary = {}
var crafted_for_next_run: String = ""
# How many first-floor bosses have been beaten. The Cemetery opens on it.
var floors_cleared: int = 0
# Clears of floors below the first, by depth as a string key, since JSON keys are strings.
var deep_clears: Dictionary = {}
# The ids of every path whose floor boss has fallen at least once.
var paths_cleared: Dictionary = {}
# Path id -> how many times its floor boss has fallen, for the Executive Suite's plaque. Optional in a
# save: an older one counts each cleared path once.
var path_clears: Dictionary = {}
# A save from before clears were kept by depth keeps the merchants its old count had opened.
var legacy_clears: int = 0
# The one brew waiting in the potion slot for the next run.
var brewed_potion: String = ""
# The Waiting Room overhaul's fields. Each is optional in a save and falls back as noted.
# Form id -> "a" or "b", the option chosen at each form's milestone. A missing entry reads as "a".
var form_choices: Dictionary = {}
# Form id -> true once that form's one free switch of option is spent.
var free_refile_used: Dictionary = {}
# The cosmetic currency. It buys only looks, never power.
var condolences: int = 0
# EnemyDef id -> true for every boss beaten since first-beat Condolences began.
var bosses_beaten: Dictionary = {}
# The BountyDef id of the wanted poster Grandpa has taken, or "" for none.
var bounty_taken: String = ""
# Whether the taken poster's boss has been beaten, so the poster waits to be collected.
var bounty_won: bool = false
# BountyDef id -> true for every poster collected for good.
var bounties_retired: Dictionary = {}
# Cosmetic id -> true for every cosmetic or decor owned.
var cosmetics_owned: Dictionary = {}
# Slot -> cosmetic id for each look Grandpa wears.
var cosmetics_worn: Dictionary = {}
# Department id -> true once its opening has been announced.
var departments_seen: Dictionary = {}
# Whether Coach Bertram has said his first hello.
var coach_met: bool = false
# The last queue ticket whose event has been called. An old save starts at its run_count.
var ticket_called: int = 0
# The run_count of the last run that reached an ending, and of the last one the lobby's sign served
# ("Now serving: you."). Both 0 in a new or old save, so nothing is served back-dated.
var finished_run: int = 0
var served_run: int = 0
# The form id the clerk is selling at a discount this visit, or "".
var clerk_deal: String = ""
# Whether a cursed ticket is on offer this visit.
var cursed_offer: bool = false
# Whether the next run is a cursed one.
var cursed_next_run: bool = false
# Letter id -> true for every letter read.
var letters_read: Dictionary = {}
# Whether any ending has been seen. Still written for older builds, which read it as their one card.
# A save that has it and no endings_found has found Briefly Alive.
var ending_seen: bool = false
# EndingRules id -> true for every ending found. Optional in a save.
var endings_found: Dictionary = {}
# Repeat Customer's last quick death, 1 to EndingRules.REPEAT_DEATHS, or 0 for none yet, so the next
# is never the same. And every quick death seen, by its number as a string key.
var last_repeat_death: int = 0
var repeat_deaths_seen: Dictionary = {}
# Path id -> true for every path whose first-clear items the Waiting Room has announced. An older save
# starts empty, so its cleared paths announce their items once.
var item_paths_seen: Dictionary = {}
# The case file's history, each optional in a save (RunLog). An older save starts with them empty, its
# crafted items counted as found and its beaten bosses as met.
# ItemDef id -> times picked up, for every item found. EnemyDef id -> times defeated, for every one met.
var items_seen: Dictionary = {}
var enemies_seen: Dictionary = {}
# RunLog.LIFETIME_KEYS -> a total over every logged run, and RunLog.BEST_KEYS -> the best single run.
var lifetime: Dictionary = {}
var best_run: Dictionary = {}
# The last RunLog.CAP runs, newest first.
var run_log: Array = []
# The Flashback Cinema's lobby card lines shown so far (LifeSigns), each id stamped with the order it
# was last seen in. Optional in a save.
var life_signs_seen: Dictionary = {}
# How many room rules Harold has kept to a clear, and how many he has broken. Optional in a save.
var rules_kept: int = 0
var rules_broken: int = 0
# The eras a film reel can hold (Eras). Optional in a save; an older one starts with Eras.STARTING.
var eras_unlocked: Array[String] = Eras.STARTING.duplicate()
# The first run's control tips done (FirstRunTips ids). A save older than this field that has played a
# run counts them all done.
var tips_done: Dictionary = {}

# The first path at each depth, the only one open before that depth's first clear.
const FIRST_PATH_BY_DEPTH := {1: "floor_1", 2: "sunset_shores", 3: "funeral_parlour", 4: "last_resort_cruise", 5: "terminal_zero"}
# Every path id at each depth. Mirrors floor_scene.gd's PATHS_BY_DEPTH by id, since ProgressData
# must not load FloorDefs.
const PATHS_AT_DEPTH := {1: ["floor_1", "cemetery"], 2: ["sunset_shores", "furnace_works"], 3: ["funeral_parlour", "flashback_cinema"], 4: ["last_resort_cruise", "seance_hotline"], 5: ["terminal_zero", "head_office"]}


func level_of(id: String) -> int:
	return int(upgrades.get(id, 0))


func add_pension(amount: int) -> void:
	pension += maxi(amount, 0)


func spend(amount: int) -> bool:
	if amount < 0 or pension < amount:
		return false
	pension -= amount
	return true


# The price of filing the next level, less the clerk's deal when this form is on it. -1 when maxed.
func price_of(def: UpgradeDef) -> int:
	var price := def.price_at(level_of(def.id))
	if price < 0:
		return -1
	if not clerk_deal.is_empty() and clerk_deal == def.id:
		return ceili(price * (1.0 - CLERK_DEAL_CUT))
	return price


func can_buy(def: UpgradeDef) -> bool:
	var price := price_of(def)
	return price >= 0 and pension >= price


# Filing the milestone level stores the option chosen, where an empty option means option A. Any
# other option refuses the filing, so a typo never buys a level without a choice.
func buy(def: UpgradeDef, option := "") -> bool:
	if not can_buy(def):
		return false
	var next := level_of(def.id) + 1
	var at_milestone := def.has_choice() and next == def.milestone_level
	var chosen := UpgradeDef.OPTION_A if option.is_empty() else option
	if at_milestone and chosen != UpgradeDef.OPTION_A and chosen != UpgradeDef.OPTION_B:
		return false
	pension -= price_of(def)
	upgrades[def.id] = next
	if at_milestone:
		form_choices[def.id] = chosen
	return true


# The option a form runs with: "" below its milestone, else the stored choice, or "a" when none is.
func choice_of(def: UpgradeDef) -> String:
	if not def.has_choice() or level_of(def.id) < def.milestone_level:
		return ""
	return str(form_choices.get(def.id, UpgradeDef.OPTION_A))


# What switching the option costs: -1 with nothing to switch, 0 while the free switch is unused.
func refile_price(def: UpgradeDef) -> int:
	if choice_of(def).is_empty():
		return -1
	return REFILE_FEE if free_refile_used.has(def.id) else 0


func refile(def: UpgradeDef) -> bool:
	var price := refile_price(def)
	if price < 0 or pension < price:
		return false
	var current := choice_of(def)
	pension -= price
	form_choices[def.id] = UpgradeDef.OPTION_B if current == UpgradeDef.OPTION_A else UpgradeDef.OPTION_A
	free_refile_used[def.id] = true
	return true


func add_condolences(amount: int) -> void:
	condolences += maxi(amount, 0)


func spend_condolences(amount: int) -> bool:
	if amount < 0 or condolences < amount:
		return false
	condolences -= amount
	return true


func owns_cosmetic(id: String) -> bool:
	return cosmetics_owned.has(id)


# Only what is on sale can be bought, once, with Condolences. A poster's cosmetic is never for sale.
func can_buy_cosmetic(def: CosmeticDef) -> bool:
	return def != null and def.price > 0 and not owns_cosmetic(def.id) and condolences >= def.price


func buy_cosmetic(def: CosmeticDef) -> bool:
	if not can_buy_cosmetic(def):
		return false
	condolences -= def.price
	cosmetics_owned[def.id] = true
	return true


# One look per slot. Decor stands in the lobby once owned, so it is never worn.
func wear(def: CosmeticDef) -> bool:
	if def == null or def.slot == CosmeticDef.SLOT_DECOR or not owns_cosmetic(def.id):
		return false
	cosmetics_worn[def.slot] = def.id
	return true


func take_off(slot: String) -> void:
	cosmetics_worn.erase(slot)


func is_worn(def: CosmeticDef) -> bool:
	return def != null and cosmetics_worn.get(def.slot, "") == def.id


# Pays the first-beat Condolences once per boss, and returns what was paid, which is 0 after the first.
# It also marks a taken poster for this boss as won, on every beat, so a poster for a boss beaten
# before is still winnable.
func record_boss_beaten(boss_id: String, is_floor_boss: bool) -> int:
	if boss_id.is_empty():
		return 0
	if bounty_matches_boss(bounty_taken, boss_id):
		bounty_won = true
	if bosses_beaten.has(boss_id):
		return 0
	bosses_beaten[boss_id] = true
	var paid := FIRST_FLOOR_BOSS_CONDOLENCES if is_floor_boss else FIRST_MINI_BOSS_CONDOLENCES
	add_condolences(paid)
	return paid


# Marks an ending found and returns the Condolences paid: ENDING_CONDOLENCES the first time, else 0.
# The Eternal Feud also gives Gerald's Hat, owned at once and ready to wear.
func record_ending(id: String) -> int:
	if not EndingRules.is_ending(id):
		return 0
	ending_seen = true
	finished_run = run_count
	if endings_found.has(id):
		return 0
	endings_found[id] = true
	if id == EndingRules.ETERNAL_FEUD:
		cosmetics_owned[GERALDS_HAT] = true
	add_condolences(ENDING_CONDOLENCES)
	return ENDING_CONDOLENCES


func record_repeat_death(n: int) -> void:
	if n < 1 or n > EndingRules.REPEAT_DEATHS:
		return
	last_repeat_death = n
	repeat_deaths_seen[str(n)] = true


# Whether a taken poster is the one for this boss. A poster's BountyDef id is its boss's EnemyDef id,
# which test_bounties pins for every poster, so ProgressData never has to load a BountyDef.
static func bounty_matches_boss(poster_id: String, boss_id: String) -> bool:
	return not poster_id.is_empty() and poster_id == boss_id


# A deal and a cursed offer last only the visit they were called on.
func start_run() -> void:
	run_count += 1
	clerk_deal = ""
	cursed_offer = false


# Calls the ticket of the run just finished, once. Returns the event called, or "" when nothing was:
# a number not called, a ticket already called, or a deal with every form filed in full.
func call_ticket(upgrade_defs: Array[UpgradeDef], roll: float) -> String:
	if ticket_called >= run_count:
		return ""
	ticket_called = run_count
	var event := TicketRules.event_for(run_count)
	if event == TicketRules.CLERK_DEAL:
		clerk_deal = TicketRules.deal_form(upgrade_defs, self, roll)
		if clerk_deal.is_empty():
			return ""
	elif event == TicketRules.CURSED_OFFER:
		cursed_offer = true
	return event


# Whether the run just finished reached an ending and the lobby's sign has not served it yet. A death
# never sets finished_run, and a new run moves run_count past it, so the chance lasts one return.
func serve_pending() -> bool:
	return finished_run > 0 and finished_run == run_count and served_run < finished_run


# Serves the finished run, once. Returns whether there was one to serve.
func take_serving() -> bool:
	if not serve_pending():
		return false
	served_run = finished_run
	return true


# Opting in to the cursed ticket, only while one is on offer, makes the next run a cursed one.
func accept_cursed_ticket() -> bool:
	if not cursed_offer:
		return false
	cursed_offer = false
	cursed_next_run = true
	return true


func decline_cursed_ticket() -> void:
	cursed_offer = false


func read_letter(path_id: String) -> void:
	if not path_id.is_empty():
		letters_read[path_id] = true


# Whether the run starting now is cursed. A cursed ticket lasts one run.
func take_cursed_run() -> bool:
	var cursed := cursed_next_run
	cursed_next_run = false
	return cursed


# Returns how many tiers this deposit newly reached. A tier pays once ever, so
# cashing out and depositing again can't earn the same rewards twice.
func retirement_deposit(amount: int) -> int:
	var moved := mini(mini(amount, pension), RETIREMENT_CAP - retirement_balance)
	if moved <= 0:
		return 0
	pension -= moved
	retirement_balance += moved
	retirement_deposit_run = run_count
	var reached := 0
	for tier: int in RETIREMENT_TIERS:
		if retirement_peak < tier and tier <= retirement_balance:
			reached += 1
	retirement_peak = maxi(retirement_peak, retirement_balance)
	return reached


func can_release_retirement() -> bool:
	return retirement_balance > 0 and retirement_deposit_run != run_count


func release_retirement() -> int:
	if not can_release_retirement():
		return 0
	var amount := retirement_balance
	retirement_balance = 0
	pension += amount
	return amount


func next_retirement_tier() -> int:
	for tier: int in RETIREMENT_TIERS:
		if retirement_peak < tier:
			return tier
	return -1


func find_recipe(id: String) -> void:
	recipes_found[id] = true


func has_recipe(id: String) -> bool:
	return recipes_found.has(id)


func is_unlocked(id: String) -> bool:
	return items_unlocked.has(id)


# Each item is crafted once ever, and only one crafted item can wait for the next run at a time.
func can_craft(id: String, price: int) -> bool:
	return has_recipe(id) and not is_unlocked(id) and pension >= price and crafted_for_next_run.is_empty()


func craft(id: String, price: int) -> bool:
	if not can_craft(id, price):
		return false
	pension -= price
	items_unlocked[id] = true
	crafted_for_next_run = id
	return true


func take_crafted_item() -> String:
	var id := crafted_for_next_run
	crafted_for_next_run = ""
	return id


# First-floor clears stay in floors_cleared, so older saves and the Cemetery's rule keep their meaning.
func record_floor_cleared(depth := 1, path_id := "") -> void:
	if depth <= 1:
		floors_cleared += 1
	else:
		deep_clears[str(depth)] = clears_at(depth) + 1
	if not path_id.is_empty():
		# Counted before the path is marked, since a marked path with no count reads as one clear.
		path_clears[path_id] = clears_of_path(path_id) + 1
		paths_cleared[path_id] = true


func clears_at(depth: int) -> int:
	if depth <= 1:
		return floors_cleared
	return int(deep_clears.get(str(depth), 0))


func has_cleared_path(id: String) -> bool:
	return paths_cleared.has(id)


# How many times a path's floor boss has fallen. A path cleared with no count, as a dev profile's or an
# older save's, counts once.
func clears_of_path(id: String) -> int:
	if path_clears.has(id):
		return int(path_clears[id])
	return 1 if paths_cleared.has(id) else 0


# Only one brew can wait at a time, and it costs Pension.
func can_brew(price: int) -> bool:
	return price > 0 and pension >= price and brewed_potion.is_empty()


func brew(id: String, price: int) -> bool:
	if not can_brew(price):
		return false
	pension -= price
	brewed_potion = id
	return true


func take_brewed_potion() -> String:
	var id := brewed_potion
	brewed_potion = ""
	return id


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"pension": pension,
		"upgrades": upgrades,
		"opening_seen": opening_seen,
		"retirement_balance": retirement_balance,
		"retirement_peak": retirement_peak,
		"run_count": run_count,
		"retirement_deposit_run": retirement_deposit_run,
		"recipes_found": recipes_found,
		"items_unlocked": items_unlocked,
		"crafted_for_next_run": crafted_for_next_run,
		"floors_cleared": floors_cleared,
		"deep_clears": deep_clears,
		"paths_cleared": paths_cleared,
		"path_clears": path_clears,
		"legacy_clears": legacy_clears,
		"brewed_potion": brewed_potion,
		"form_choices": form_choices,
		"free_refile_used": free_refile_used,
		"condolences": condolences,
		"bosses_beaten": bosses_beaten,
		"bounty_taken": bounty_taken,
		"bounty_won": bounty_won,
		"bounties_retired": bounties_retired,
		"cosmetics_owned": cosmetics_owned,
		"cosmetics_worn": cosmetics_worn,
		"departments_seen": departments_seen,
		"coach_met": coach_met,
		"ticket_called": ticket_called,
		"finished_run": finished_run,
		"served_run": served_run,
		"clerk_deal": clerk_deal,
		"cursed_offer": cursed_offer,
		"cursed_next_run": cursed_next_run,
		"letters_read": letters_read,
		"ending_seen": ending_seen,
		"endings_found": endings_found,
		"last_repeat_death": last_repeat_death,
		"repeat_deaths_seen": repeat_deaths_seen,
		"item_paths_seen": item_paths_seen,
		"items_seen": items_seen,
		"enemies_seen": enemies_seen,
		"lifetime": lifetime,
		"best_run": best_run,
		"run_log": run_log,
		"life_signs_seen": life_signs_seen,
		"rules_kept": rules_kept,
		"rules_broken": rules_broken,
		"eras_unlocked": eras_unlocked.duplicate(),
		"tips_done": tips_done.duplicate(),
	}


static func from_dict(raw: Variant) -> ProgressData:
	if not raw is Dictionary:
		return null
	for key in ["version", "pension", "upgrades", "opening_seen"]:
		if not raw.has(key):
			return null
	if int(raw["version"]) != VERSION or int(raw["pension"]) < 0:
		return null
	if not raw["upgrades"] is Dictionary or not raw["opening_seen"] is bool:
		return null
	# Ids of paths, bosses, posters and departments that were replaced move to their new ones first.
	raw = PathMigration.migrate_save(raw)
	var data := ProgressData.new()
	data.pension = int(raw["pension"])
	data.opening_seen = raw["opening_seen"]
	for id in raw["upgrades"]:
		data.upgrades[str(id)] = int(raw["upgrades"][id])
	# These came later, so older saves simply don't have them.
	data.retirement_balance = clampi(int(raw.get("retirement_balance", 0)), 0, RETIREMENT_CAP)
	data.retirement_peak = clampi(int(raw.get("retirement_peak", 0)), data.retirement_balance, RETIREMENT_CAP)
	data.run_count = maxi(int(raw.get("run_count", 0)), 0)
	data.retirement_deposit_run = int(raw.get("retirement_deposit_run", NO_DEPOSIT_RUN))
	data.recipes_found = _id_set(raw.get("recipes_found"))
	data.items_unlocked = _id_set(raw.get("items_unlocked"))
	var crafted: Variant = raw.get("crafted_for_next_run", "")
	data.crafted_for_next_run = crafted if crafted is String else ""
	data.floors_cleared = maxi(int(raw.get("floors_cleared", 0)), 0)
	data.deep_clears = {}
	var deep: Variant = raw.get("deep_clears", {})
	if deep is Dictionary:
		for key in deep:
			data.deep_clears[str(key)] = maxi(int(deep[key]), 0)
	data.paths_cleared = _id_set(raw.get("paths_cleared"))
	var counts: Variant = raw.get("path_clears", {})
	if counts is Dictionary:
		for id in counts:
			data.path_clears[str(id)] = maxi(int(counts[id]), 0)
	# Only a save older than clears by depth lacks the key. Its count is frozen here, once.
	data.legacy_clears = maxi(int(raw.get("legacy_clears", data.floors_cleared)), 0)
	var brewed: Variant = raw.get("brewed_potion", "")
	data.brewed_potion = brewed if brewed is String else ""
	# The Waiting Room overhaul's fields: an older save lacks them all.
	var choices: Variant = raw.get("form_choices", {})
	if choices is Dictionary:
		for id in choices:
			if choices[id] is String and (choices[id] == "a" or choices[id] == "b"):
				data.form_choices[str(id)] = choices[id]
	data.free_refile_used = _id_set(raw.get("free_refile_used"))
	data.condolences = maxi(int(raw.get("condolences", 0)), 0)
	data.bosses_beaten = _id_set(raw.get("bosses_beaten"))
	data.bounty_taken = _string_or_empty(raw.get("bounty_taken", ""))
	data.bounty_won = _bool_or_false(raw.get("bounty_won", false))
	data.bounties_retired = _id_set(raw.get("bounties_retired"))
	data.cosmetics_owned = _id_set(raw.get("cosmetics_owned"))
	var worn: Variant = raw.get("cosmetics_worn", {})
	if worn is Dictionary:
		for slot in worn:
			if worn[slot] is String:
				data.cosmetics_worn[str(slot)] = worn[slot]
	data.departments_seen = _id_set(raw.get("departments_seen"))
	data.coach_met = _bool_or_false(raw.get("coach_met", false))
	# Every ticket an old save has already had counts as called, so no event fires back-dated.
	data.ticket_called = maxi(int(raw.get("ticket_called", data.run_count)), 0)
	data.finished_run = maxi(int(raw.get("finished_run", 0)), 0)
	data.served_run = maxi(int(raw.get("served_run", 0)), 0)
	data.clerk_deal = _string_or_empty(raw.get("clerk_deal", ""))
	data.cursed_offer = _bool_or_false(raw.get("cursed_offer", false))
	data.cursed_next_run = _bool_or_false(raw.get("cursed_next_run", false))
	data.letters_read = _id_set(raw.get("letters_read"))
	data.ending_seen = _bool_or_false(raw.get("ending_seen", false))
	# Only real ending ids and quick-death numbers are kept. A save from before the endings saw the one
	# card, which is Briefly Alive.
	for id in _id_set(raw.get("endings_found")):
		if EndingRules.is_ending(id):
			data.endings_found[id] = true
	if data.ending_seen and not raw.has("endings_found"):
		data.endings_found[EndingRules.BRIEFLY_ALIVE] = true
	var last_death: Variant = raw.get("last_repeat_death", 0)
	if (last_death is int or last_death is float) and int(last_death) >= 1 and int(last_death) <= EndingRules.REPEAT_DEATHS:
		data.last_repeat_death = int(last_death)
	for key in _id_set(raw.get("repeat_deaths_seen")):
		if key.is_valid_int() and int(key) >= 1 and int(key) <= EndingRules.REPEAT_DEATHS:
			data.repeat_deaths_seen[str(int(key))] = true
	data.item_paths_seen = _id_set(raw.get("item_paths_seen"))
	# The case file's history. An older save has none: what it already records seeds the catalog.
	data.items_seen = _count_map(raw.get("items_seen"))
	if not raw.has("items_seen"):
		for id in data.items_unlocked:
			data.items_seen[id] = 0
	data.enemies_seen = _count_map(raw.get("enemies_seen"))
	if not raw.has("enemies_seen"):
		for id in data.bosses_beaten:
			data.enemies_seen[id] = 0
	var totals := _count_map(raw.get("lifetime"))
	for key in RunLog.LIFETIME_KEYS:
		if totals.has(key):
			data.lifetime[key] = totals[key]
	var best := _count_map(raw.get("best_run"))
	for key in RunLog.BEST_KEYS:
		if best.has(key):
			data.best_run[key] = best[key]
	var log_raw: Variant = raw.get("run_log", [])
	if log_raw is Array:
		for each in log_raw:
			if each is Dictionary and data.run_log.size() < RunLog.CAP:
				data.run_log.append(RunLog.clean(each))
	# The Flashback Cinema's lobby cards. An older save has seen none of them.
	data.life_signs_seen = _count_map(raw.get("life_signs_seen"))
	# The room rules' counts. An older save has kept and broken none.
	data.rules_kept = maxi(int(raw.get("rules_kept", 0)), 0)
	data.rules_broken = maxi(int(raw.get("rules_broken", 0)), 0)
	# Only eras this build knows; none left (or an older save) gives the starting ones.
	data.eras_unlocked = Eras.known_or_starting(raw.get("eras_unlocked", Eras.STARTING))
	# Control tips: an older save that has played a run is past them.
	if raw.has("tips_done"):
		for id in _id_set(raw.get("tips_done")):
			if FirstRunTips.ORDER.has(id):
				data.tips_done[id] = true
	elif data.run_count > 0:
		for id in FirstRunTips.ORDER:
			data.tips_done[id] = true

	data._infer_first_paths()
	return data


func mark_tip(id: String) -> bool:
	if tips_done.has(id) or not FirstRunTips.ORDER.has(id):
		return false
	tips_done[id] = true
	return true


func reset_tips() -> void:
	tips_done.clear()


# A lobby card's line was shown: it is stamped one later than every line seen before, so the next run
# can offer the ones seen longest ago first once all have been seen (LifeSigns.order).
func see_life_sign(id: String) -> void:
	if id.is_empty():
		return
	var latest := 0
	for each in life_signs_seen:
		latest = maxi(latest, int(life_signs_seen[each]))
	life_signs_seen[id] = latest + 1


# A run that ended goes to the top of the Log, the oldest past RunLog.CAP drops off, and its kills,
# finds and pay add to the lifetime totals and the catalog.
func record_run(entry: Dictionary) -> void:
	var clean := RunLog.clean(entry)
	run_log.push_front(clean)
	while run_log.size() > RunLog.CAP:
		run_log.pop_back()
	var result: String = clean["result"]
	_add_total("wins", 1 if result == RunLog.CLEARED and int(clean["depth"]) >= LAST_DEPTH else 0)
	_add_total("deaths", 1 if result == RunLog.DIED or result == RunLog.ABANDONED else 0)
	var kills := RunLog.kill_total(clean)
	_add_total("kills", kills)
	_add_total("hits", int(clean["hits"]))
	_add_total("pension", int(clean["pension"]))
	_add_total("items", clean["found"].size())
	_raise_best("kills", kills)
	_raise_best("pension", int(clean["pension"]))
	_raise_best("time", int(clean["time"]))
	_raise_best("items", clean["items"].size())
	_raise_best("depth", int(clean["depth"]))
	for id in clean["found"]:
		items_seen[id] = int(items_seen.get(id, 0)) + 1
	for id in clean["met"]:
		if not enemies_seen.has(id):
			enemies_seen[id] = 0
	for id in clean["kills"]:
		enemies_seen[id] = int(enemies_seen.get(id, 0)) + int(clean["kills"][id])


# The ending a cleared run reached, chosen after its entry was logged.
func set_last_ending(id: String) -> void:
	if not run_log.is_empty():
		run_log[0]["ending"] = id


func total(key: String) -> int:
	return int(lifetime.get(key, 0))


func best(key: String) -> int:
	return int(best_run.get(key, 0))


func _add_total(key: String, amount: int) -> void:
	lifetime[key] = total(key) + maxi(amount, 0)


func _raise_best(key: String, value: int) -> void:
	best_run[key] = maxi(best(key), value)


# A save from before paths were kept has its clears but no path ids. At each depth only one path is
# open before that depth's first clear, so that one must have been it.
func _infer_first_paths() -> void:
	for depth: int in FIRST_PATH_BY_DEPTH:
		var id: String = FIRST_PATH_BY_DEPTH[depth]
		if clears_at(depth) > 0 and not _has_path_at_depth(depth):
			paths_cleared[id] = true


func _has_path_at_depth(depth: int) -> bool:
	for id in PATHS_AT_DEPTH[depth]:
		if paths_cleared.has(id):
			return true
	return false


# Id -> a count of zero or more, from a saved Dictionary. Anything else reads as empty.
static func _count_map(raw: Variant) -> Dictionary:
	var counts := {}
	if raw is Dictionary:
		for id in raw:
			if raw[id] is int or raw[id] is float:
				counts[str(id)] = maxi(int(raw[id]), 0)
	return counts


static func _id_set(raw: Variant) -> Dictionary:
	var ids := {}
	if raw is Dictionary:
		for id in raw:
			ids[str(id)] = true
	return ids


static func _string_or_empty(raw: Variant) -> String:
	return raw if raw is String else ""


static func _bool_or_false(raw: Variant) -> bool:
	return raw if raw is bool else false
