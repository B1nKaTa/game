class_name CaseFileData
extends RefCounted

# What Harold's case file shows on each tab, worked out from the run, the save and the content, with
# no nodes, so tests read it directly. CaseFile draws it. Every grid cell is a Dictionary with an id,
# a name, a colour, whether it is known, a count, and an icon path that need not exist yet: the art
# pass drops a PNG at that path and the cell shows it instead of its colour chip and initials.

const TAB_HAROLD := "harold"
const TAB_ITEMS := "items"
const TAB_BESTIARY := "bestiary"
const TAB_STATS := "stats"
const TAB_LOG := "log"
const TABS: Array[String] = [TAB_HAROLD, TAB_ITEMS, TAB_BESTIARY, TAB_STATS, TAB_LOG]
const TAB_NAMES := {
	TAB_HAROLD: "Harold",
	TAB_ITEMS: "Items",
	TAB_BESTIARY: "Bestiary",
	TAB_STATS: "Stats",
	TAB_LOG: "Log",
}
const NO_CASE := "No active case. Harold is between runs."
const ITEM_ICON_DIR := ItemIcons.DIR
const ENEMY_ICON_DIR := "res://art/icons/enemies/"
const UNKNOWN_NAME := "???"
const UNKNOWN_COLOR := Color(0.16, 0.13, 0.11)
const ENEMIES_DIR := "res://data/enemies/"
const FLOORS_DIR := "res://data/floors/"
# Never in the Bestiary: the Training Yard's dummy is no enemy.
const NOT_ENEMIES: Array[String] = ["training_dummy"]
# A Bestiary cell for someone met in an older run who is in the game no more, as a retired path's
# bosses: it keeps its count, under a name made from its id, with this placeholder colour.
const HISTORY_COLOR := Color(0.42, 0.38, 0.34)
const HISTORY_LINE := "No longer found on any floor."


# Up to two capitals for a cell with no icon: "Rolling Pin" -> "RP", "Kettle" -> "KE".
static func initials(text: String) -> String:
	var words: PackedStringArray = []
	for word in text.replace("-", " ").split(" ", false):
		var letters := ""
		for c in word:
			if c.to_upper() != c.to_lower():
				letters += c
		if not letters.is_empty() and not ["the", "of", "a", "an", "and"].has(letters.to_lower()):
			words.append(letters)
	if words.is_empty():
		return "?"
	if words.size() == 1:
		return words[0].substr(0, 2).to_upper()
	return (words[0].substr(0, 1) + words[1].substr(0, 1)).to_upper()


static func page_count(total: int, per_page: int) -> int:
	return maxi(ceili(float(total) / float(maxi(per_page, 1))), 1)


static func page_of(list: Array, page: int, per_page: int) -> Array:
	var start := clampi(page, 0, page_count(list.size(), per_page) - 1) * per_page
	return list.slice(start, start + per_page)


static func icon_path(dir: String, id: String) -> String:
	return dir + id + ".png"


# --- Harold ---

# The held items as grid cells, one per kind in pickup order, with a count where he holds more than one.
static func held_cells(items: Array[ItemDef], active: ItemDef = null) -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	if active != null:
		var first := item_cell(active, true, 1)
		first["badge"] = true
		first["use"] = true
		cells.append(first)
	var at := {}
	for item in items:
		if at.has(item.id):
			cells[at[item.id]]["count"] += 1
			continue
		at[item.id] = cells.size()
		var cell := item_cell(item, true, 1)
		cell["badge"] = true
		cells.append(cell)
	return cells


static func item_cell(item: ItemDef, known: bool, count: int) -> Dictionary:
	return {
		"id": item.id,
		"name": item.display_name if known else UNKNOWN_NAME,
		"color": ItemRarity.name_color(item) if known else UNKNOWN_COLOR,
		"known": known,
		"count": count,
		"icon": ItemIcons.path(item.id),
		"item": item,
	}


# His stats as [label, value] rows.
static func stat_rows(run: RunState) -> Array:
	var stats := run.stats
	var rows: Array = [
		["Pills", "%d / %d" % [run.health.pills, run.health.max_pills]],
		["Damage", "x%.2f" % run.damage_mult()],
		["Speed", "%d" % roundi(run.move_speed())],
		["Swing speed", "x%.2f" % run.swing_speed()],
		["Dodge", "%.2f s%s" % [stats.dodge_cooldown, "  x%d" % stats.dodge_charges if stats.dodge_charges > 1 else ""]],
		["Teeth", "x%.2f, %d px" % [run.bite_damage_mult(), roundi(stats.bite_range)]],
		["Thermos", "x%.2f, %d px" % [stats.thermos_damage_mult, roundi(stats.blast_radius)]],
		["Pension", "x%.2f" % stats.pension_mult],
	]
	if stats.heal_bonus > 0:
		rows.append(["Heals", "+%d" % stats.heal_bonus])
	if stats.lucky_swing_chance > 0.0:
		rows.append(["Lucky swing", "%d%%" % roundi(stats.lucky_swing_chance * 100.0)])
	if stats.shop_discount > 0.0:
		rows.append(["Discount", "%d%%" % roundi(stats.shop_discount * 100.0)])
	if stats.floor_lethal_saves > 0:
		rows.append(["Floor saves", "%d" % stats.floor_lethal_saves])
	return rows


# The forms bought in the Waiting Room, by name and level, for the stats page.
static func upgrade_rows(levels: Dictionary, upgrades: Array[UpgradeDef]) -> Array:
	var rows: Array = []
	for def in upgrades:
		var level := int(levels.get(def.id, 0))
		if level > 0:
			rows.append([def.display_name, "Lv %d" % level])
	return rows


# The right page: the run as it stands. info holds what the scene knows: floor, route, time.
static func run_rows(run: RunState, info: Dictionary, perks_text: Array) -> Array:
	var rows: Array = [
		["Floor", str(info.get("floor", ""))],
		["Route", str(info.get("route", ""))],
		["Run time", Hud.timer_text(float(info.get("time", run.play_time)))],
		["Pension this run", "%d" % run.pension_earned],
		["Slips", "%d" % run.keys],
		["Thermoses", "%d" % run.bombs],
		["Potion", run.potion.display_name if run.potion != null else "-"],
		["Kills", "%d" % run.kill_count()],
		["Hits taken", "%d" % run.hits_taken],
	]
	if run.buff != null and run.buff_left > 0.0:
		rows.append(["Buff", "%s, %ds" % [run.buff.display_name, ceili(run.buff_left)]])
	var sets := run.effects.set_names()
	rows.append(["Sets", ", ".join(sets) if not sets.is_empty() else "-"])
	var curses: PackedStringArray = []
	if run.cursed:
		curses.append("Cursed ticket")
	for item in run.items:
		if item.cursed and not curses.has(item.display_name):
			curses.append(item.display_name)
	rows.append(["Curses", ", ".join(curses) if not curses.is_empty() else "-"])
	rows.append(["Blessings", ", ".join(perks_text) if not perks_text.is_empty() else "-"])
	return rows


# The mementos' perks this run carries, by memento name.
static func blessings(perks: Dictionary) -> Array:
	var names: Array = []
	for entry: Dictionary in Mementos.ALL:
		if perks.has(entry["perk"]):
			names.append(entry["memento"])
	return names


# --- Items ---

# Every item as a cell, found or not. Found means picked up in a logged run, held this run, or (for
# an older save) crafted.
static func catalog(all_items: Array[ItemDef], seen: Dictionary, run: RunState) -> Array[Dictionary]:
	var this_run := {}
	if run != null:
		for id in run.found:
			this_run[id] = int(this_run.get(id, 0)) + 1
	var cells: Array[Dictionary] = []
	for item in all_items:
		var times := int(seen.get(item.id, 0)) + int(this_run.get(item.id, 0))
		var known := seen.has(item.id) or this_run.has(item.id)
		cells.append(item_cell(item, known, times))
	return cells


static func found_line(cells: Array[Dictionary]) -> String:
	var found := 0
	for cell in cells:
		if cell["known"]:
			found += 1
	return "%d/%d found" % [found, cells.size()]


# The detail pane for an item: its name, what it does, how often it was found and its shop price.
static func item_detail(cell: Dictionary) -> Array:
	if not cell["known"]:
		return [UNKNOWN_NAME, "Not yet found."]
	var item: ItemDef = cell["item"]
	var lines: Array = [item.display_name, item.description]
	lines.append("Rarity: %s%s" % [item.rarity.capitalize(), ", cursed" if item.cursed else ""])
	lines.append("Times found: %d" % int(cell["count"]))
	if item.needs_recipe():
		lines.append("Crafted from a recipe, never sold.")
	elif item.from_bounty:
		lines.append("A bounty's reward, never sold.")
	else:
		lines.append("Shop price: %d on the first floor" % ShopRules.item_price(item, 1.0, 0.0))
	return lines


# --- Bestiary ---

static func enemy_defs() -> Array[EnemyDef]:
	var list: Array[EnemyDef] = []
	for resource in Content.load_dir(ENEMIES_DIR):
		if resource is EnemyDef and not NOT_ENEMIES.has(resource.id):
			list.append(resource)
	return list


# EnemyDef id -> the name of the first floor (by depth) it appears on: among a floor's enemies, as its
# mini boss, floor boss or mimic, or summoned by one of those.
static func enemy_floors() -> Dictionary:
	var floors: Array[FloorDef] = []
	for resource in Content.load_dir(FLOORS_DIR):
		if resource is FloorDef:
			floors.append(resource)
	floors.sort_custom(func(a: FloorDef, b: FloorDef) -> bool: return a.depth < b.depth)
	var where := {}
	for floor_def in floors:
		var defs: Array = []
		defs.append_array(floor_def.enemies)
		for extra in [floor_def.mini_boss, floor_def.floor_boss, floor_def.mimic]:
			if extra != null:
				defs.append(extra)
		for def in defs.duplicate():
			if def is EnemyDef and def.summon != null:
				defs.append(def.summon)
		for def in defs:
			if def is EnemyDef and not where.has(def.id):
				where[def.id] = floor_def.display_name
	return where


static func bestiary(defs: Array[EnemyDef], seen: Dictionary, run: RunState, floors: Dictionary) -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	var sorted := defs.duplicate()
	# By floor, then the floor's enemies before its bosses, then by name.
	sorted.sort_custom(func(a: EnemyDef, b: EnemyDef) -> bool:
		var ra := _floor_rank(a.id, floors)
		var rb := _floor_rank(b.id, floors)
		if ra != rb:
			return ra < rb
		if a.is_boss != b.is_boss:
			return not a.is_boss
		return a.display_name < b.display_name)
	for def: EnemyDef in sorted:
		var kills := int(seen.get(def.id, 0))
		var met := seen.has(def.id)
		if run != null:
			kills += int(run.kills.get(def.id, 0))
			met = met or run.met.has(def.id)
		cells.append({
			"id": def.id,
			"name": def.display_name if met else UNKNOWN_NAME,
			"color": def.color if met else UNKNOWN_COLOR,
			"known": met,
			"count": kills,
			"icon": icon_path(ENEMY_ICON_DIR, def.id),
			"def": def,
			"floor": str(floors.get(def.id, "")),
		})
	cells.append_array(history_cells(defs, seen))
	return cells


# The ids the save has met that no EnemyDef answers any more, as cells after every real one, by id.
# Their "def" is null, so their detail and their look never reach for one.
static func history_cells(defs: Array[EnemyDef], seen: Dictionary) -> Array[Dictionary]:
	var known := {}
	for def in defs:
		known[def.id] = true
	var ids: Array = seen.keys()
	ids.sort()
	var cells: Array[Dictionary] = []
	for raw_id in ids:
		var id := str(raw_id)
		if id.is_empty() or known.has(id) or NOT_ENEMIES.has(id):
			continue
		cells.append({
			"id": id,
			"name": id.capitalize(),
			"color": HISTORY_COLOR,
			"known": true,
			"count": maxi(int(seen[raw_id]), 0),
			"icon": icon_path(ENEMY_ICON_DIR, id),
			"def": null,
			"floor": "",
		})
	return cells


static func _floor_rank(id: String, floors: Dictionary) -> int:
	var names := floors.values()
	return names.find(floors.get(id, "")) if floors.has(id) else 999


static func met_line(cells: Array[Dictionary]) -> String:
	var met := 0
	for cell in cells:
		if cell["known"]:
			met += 1
	return "%d/%d met" % [met, cells.size()]


# Only what the content already says: the name, the floor, and boss or not. No lore is made up here.
static func enemy_detail(cell: Dictionary) -> Array:
	if not cell["known"]:
		return [UNKNOWN_NAME, "Not yet met."]
	if cell["def"] == null:
		return [str(cell["name"]), HISTORY_LINE, "Defeated: %d" % int(cell["count"])]
	var def: EnemyDef = cell["def"]
	var lines: Array = [def.display_name]
	if not str(cell["floor"]).is_empty():
		lines.append("Found on: %s" % cell["floor"])
	if def.is_boss:
		lines.append("A boss.")
	lines.append("Defeated: %d" % int(cell["count"]))
	return lines


# --- Stats ---

static func lifetime_rows(data: ProgressData) -> Array:
	return [
		["Runs", "%d" % data.run_count],
		["Wins", "%d" % data.total("wins")],
		["Endings found", "%d / %d" % [EndingRules.found_count(data.endings_found), EndingRules.TOTAL]],
		["Deaths", "%d" % data.total("deaths")],
		["Enemies defeated", "%d" % data.total("kills")],
		["Hits taken", "%d" % data.total("hits")],
		["Pension earned", "%d" % data.total("pension")],
		["Items found", "%d" % data.total("items")],
		["Floors cleared", "%d" % (data.floors_cleared + _deep_clear_total(data))],
	]


static func best_rows(data: ProgressData) -> Array:
	return [
		["Most kills", "%d" % data.best("kills")],
		["Most Pension", "%d" % data.best("pension")],
		["Longest run", Hud.timer_text(data.best("time"))],
		["Most items held", "%d" % data.best("items")],
		["Deepest floor", "%d" % data.best("depth")],
	]


static func _deep_clear_total(data: ProgressData) -> int:
	var total := 0
	for key in data.deep_clears:
		total += int(data.deep_clears[key])
	return total


# --- Log ---

# The detail for one logged run. names maps item and enemy ids to their names.
static func log_detail(entry: Dictionary, names: Dictionary) -> Array:
	var lines: Array = [RunLog.headline(entry)]
	lines.append("Time: %s    Pension: %d    Hits taken: %d" % [Hud.timer_text(float(entry.get("time", 0.0))), int(entry.get("pension", 0)), int(entry.get("hits", 0))])
	var seeds: Array = entry.get("seeds", [])
	if not seeds.is_empty():
		lines.append("Seeds: %s" % ", ".join(PackedStringArray(seeds)))
	if entry.get("cursed", false):
		lines.append("On a cursed ticket.")
	var kills: Dictionary = entry.get("kills", {})
	var parts: PackedStringArray = []
	var ids := kills.keys()
	ids.sort_custom(func(a, b) -> bool: return int(kills[a]) > int(kills[b]))
	for id in ids:
		parts.append("%s x%d" % [names.get(id, str(id).capitalize()), int(kills[id])])
	lines.append("Defeated (%d): %s" % [RunLog.kill_total(entry), ", ".join(parts) if not parts.is_empty() else "none"])
	var items: PackedStringArray = []
	for id in entry.get("found", []):
		items.append(names.get(id, str(id).capitalize()))
	lines.append("Items (%d): %s" % [items.size(), ", ".join(items) if not items.is_empty() else "none"])
	return lines


# Item and enemy ids -> display names, for the Log.
static func names_by_id(all_items: Array[ItemDef], defs: Array[EnemyDef]) -> Dictionary:
	var names := {}
	for item in all_items:
		names[item.id] = item.display_name
	for def in defs:
		names[def.id] = def.display_name
	return names
