class_name RunLog
extends RefCounted

# One run's line in the case file's Log, and how it adds to the lifetime totals and the best run
# (ProgressData.record_run). An entry is a plain Dictionary so it saves as it is, and every key is
# optional when read back, so an entry from an older build still shows.

const CAP := 50
const DIED := "died"
const CLEARED := "cleared"
const ABANDONED := "abandoned"
const ENDED := "ended"
# Lifetime totals kept by ProgressData.lifetime. Runs and endings come from fields the save already had.
const LIFETIME_KEYS: Array[String] = ["wins", "deaths", "kills", "hits", "pension", "items"]
# The best single run, by ProgressData.best_run. time is in seconds.
const BEST_KEYS: Array[String] = ["kills", "pension", "time", "items", "depth"]


# The entry for a run that just ended. info holds what only the scene knows: result, depth, floor,
# room, killer, date and run number.
static func entry(run: RunState, info: Dictionary) -> Dictionary:
	var item_ids: Array = []
	for item in run.items:
		item_ids.append(item.id)
	return {
		"n": int(info.get("n", 0)),
		"date": str(info.get("date", "")),
		"result": str(info.get("result", ENDED)),
		"depth": int(info.get("depth", 1)),
		"floor": str(info.get("floor", "")),
		"room": str(info.get("room", "")),
		"killer": str(info.get("killer", "")),
		"ending": "",
		"time": snappedf(run.play_time, 0.1),
		"seeds": Array(run.seeds),
		"pension": run.pension_earned,
		"kills": run.kills.duplicate(),
		"met": run.met.keys(),
		"found": Array(run.found),
		"items": item_ids,
		"hits": run.hits_taken,
		"cursed": run.cursed,
	}


static func kill_total(entry_data: Dictionary) -> int:
	var total := 0
	var kills: Variant = entry_data.get("kills", {})
	if kills is Dictionary:
		for id in kills:
			total += maxi(int(kills[id]), 0)
	return total


# A stored entry made safe to show: anything not a Dictionary is dropped by the caller, and every
# field falls back to an empty value of its type.
static func clean(raw: Dictionary) -> Dictionary:
	var kills := {}
	var raw_kills: Variant = raw.get("kills", {})
	if raw_kills is Dictionary:
		for id in raw_kills:
			if (raw_kills[id] is int or raw_kills[id] is float) and int(raw_kills[id]) > 0:
				kills[str(id)] = int(raw_kills[id])
	return {
		"n": maxi(_int(raw.get("n", 0)), 0),
		"date": _text(raw.get("date", "")),
		"result": _text(raw.get("result", ENDED)),
		"depth": maxi(_int(raw.get("depth", 1)), 1),
		"floor": _text(raw.get("floor", "")),
		"room": _text(raw.get("room", "")),
		"killer": _text(raw.get("killer", "")),
		"ending": _text(raw.get("ending", "")),
		"time": maxf(_float(raw.get("time", 0.0)), 0.0),
		"seeds": _strings(raw.get("seeds", [])),
		"pension": maxi(_int(raw.get("pension", 0)), 0),
		"kills": kills,
		"met": _strings(raw.get("met", [])),
		"found": _strings(raw.get("found", [])),
		"items": _strings(raw.get("items", [])),
		"hits": maxi(_int(raw.get("hits", 0)), 0),
		"cursed": raw.get("cursed", false) is bool and raw.get("cursed", false),
	}


# What the Log's list shows for one run: its number, its date and how it ended.
static func headline(entry_data: Dictionary) -> String:
	var number := "Run %d" % int(entry_data.get("n", 0))
	var date := str(entry_data.get("date", "")).substr(0, 10)
	var head := "%s  %s" % [number, date] if not date.is_empty() else number
	return "%s  -  %s" % [head, outcome(entry_data)]


# How a run ended, in a few words.
static func outcome(entry_data: Dictionary) -> String:
	var where := str(entry_data.get("floor", ""))
	var depth := int(entry_data.get("depth", 1))
	match str(entry_data.get("result", "")):
		DIED:
			var killer := str(entry_data.get("killer", ""))
			var text := "Died on floor %d" % depth
			if not killer.is_empty():
				text += ", to %s" % killer
			return text
		CLEARED:
			var ending := str(entry_data.get("ending", ""))
			if not ending.is_empty():
				return "Ending: %s" % str(EndingRules.entry(ending).get("title", ending))
			return "Cleared %s" % where if not where.is_empty() else "Cleared floor %d" % depth
		ABANDONED:
			return "Abandoned on floor %d" % depth
	return "Ended on floor %d" % depth


static func _int(value: Variant) -> int:
	return int(value) if value is int or value is float else 0


static func _float(value: Variant) -> float:
	return float(value) if value is int or value is float else 0.0


static func _text(value: Variant) -> String:
	return value if value is String else ""


static func _strings(value: Variant) -> Array:
	var list: Array = []
	if value is Array:
		for each in value:
			if each is String and not each.is_empty():
				list.append(each)
	return list
