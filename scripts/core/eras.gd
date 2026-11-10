class_name Eras
extends RefCounted

# The moments of Harold's life a film reel lets him relive for one room.

const FOOTBALL := "rec_football_1960"
const DANCE := "dance_hall_1962"
const BUS := "no12_bus_1975"
const ALLOTMENT := "allotment_1988"
# In the order of his life. All four are his from the start; endings unlock later ones.
const STARTING: Array[String] = [FOOTBALL, DANCE, BUS, ALLOTMENT]
# He was born in 1942 (87 at the opening's death, in 2029): an era's age is its year minus this.
const BIRTH_YEAR := 1942

const _DATA := {
	FOOTBALL: {"title": "Football on the Rec, 1960", "year": 1960, "speed": 1.25, "art": "harold_1960", "tint": Color("ffd9a0")},
	DANCE: {"title": "The Dance Hall, 1962", "year": 1962, "speed": 1.1, "art": "harold_1962", "tint": Color("f0c8e8")},
	BUS: {"title": "The No. 12 Bus, 1975", "year": 1975, "speed": 1.0, "art": "harold_1975", "tint": Color("c9d8ff")},
	ALLOTMENT: {"title": "The Allotment, 1988", "year": 1988, "speed": 1.0, "art": "harold_1988", "tint": Color("c8e0b0")},
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


static func year(id: String) -> int:
	return int(_DATA.get(id, {}).get("year", 0))


static func age(id: String) -> int:
	return year(id) - BIRTH_YEAR if is_known(id) else 0


# Old Harold's sprite tinted, for an era whose own art is not in yet. White for old Harold.
static func tint(id: String) -> Color:
	var data: Dictionary = _DATA.get(id, {})
	return data.get("tint", Color.WHITE)


# The era a reel holds: one of the unlocked ones, the same for the same floor seed and room.
static func pick(unlocked: Array, seed_text: String, room_id: int) -> String:
	var known := unlocked.filter(func(id): return is_known(str(id)))
	if known.is_empty():
		return FOOTBALL
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:reel:%d" % [seed_text, room_id])
	return str(known[rng.randi_range(0, known.size() - 1)])


# The starting eras, always, then any other saved era this build knows, in saved order.
static func known_or_starting(raw: Variant) -> Array[String]:
	var out: Array[String] = STARTING.duplicate()
	if raw is Array:
		for id in raw:
			if is_known(str(id)) and not out.has(str(id)):
				out.append(str(id))
	return out
