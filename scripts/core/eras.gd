class_name Eras
extends RefCounted

# The moments of Harold's life a film reel lets him relive for one room.

const FOOTBALL := "rec_football_1960"
const BUS := "no12_bus_1975"
const STARTING: Array[String] = [FOOTBALL, BUS]

const _DATA := {
	FOOTBALL: {"title": "Football on the Rec, 1960", "age": 18, "speed": 1.45, "art": "harold_1960"},
	BUS: {"title": "The No. 12 Bus, 1975", "age": 40, "speed": 1.15, "art": "harold_1975"},
}
const RETURN_LINES := ["Those were the days.", "My knees remember that.", "Where did the years go?"]


static func is_known(id: String) -> bool:
	return _DATA.has(id)


static func title(id: String) -> String:
	return _DATA.get(id, {}).get("title", "")


static func speed_mult(id: String) -> float:
	return _DATA.get(id, {}).get("speed", 1.0)


static func art_id(id: String) -> String:
	return _DATA.get(id, {}).get("art", "")


# The era a reel holds: one of the unlocked ones, the same for the same floor seed and room.
static func pick(unlocked: Array, seed_text: String, room_id: int) -> String:
	var known := unlocked.filter(func(id): return is_known(str(id)))
	if known.is_empty():
		return FOOTBALL
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:reel:%d" % [seed_text, room_id])
	return str(known[rng.randi_range(0, known.size() - 1)])


# The saved list kept to the eras this build knows, or the starting ones when none is left.
static func known_or_starting(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if raw is Array:
		for id in raw:
			if is_known(str(id)) and not out.has(str(id)):
				out.append(str(id))
	return out if not out.is_empty() else STARTING.duplicate()
