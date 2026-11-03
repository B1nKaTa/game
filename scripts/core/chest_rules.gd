class_name ChestRules
extends RefCounted

# A layout's C cell rolls one of five chests, by its floor's odds:
# - Old Lunchbox: opened by hand for free, a little Pension and sometimes a heal or a Thermos.
# - Locked Chest: 1 Permission Slip, then a treasure as before.
# - Safe Deposit Box: only the player's Thermos opens it, for a big pile of Pension.
# - Gilded Urn: 2 Slips, then a pick of 2 items where the other vanishes.
# - Mimic: looks like a Locked Chest and wakes into an enemy when touched. Never on the first floor.
const LUNCHBOX := "lunchbox"
const LOCKED := "locked"
const SAFE := "safe"
const URN := "urn"
const MIMIC := "mimic"
# Rolls run through the kinds in this order, so the same odds and roll always give the same chest.
const KINDS: Array[String] = [LUNCHBOX, LOCKED, SAFE, URN, MIMIC]
const NAMES := {
	LUNCHBOX: "Old Lunchbox",
	LOCKED: "Locked Chest",
	SAFE: "Safe Deposit Box",
	URN: "Gilded Urn",
	# It passes for a Locked Chest until it wakes.
	MIMIC: "Locked Chest",
}
const PROMPTS := {
	LUNCHBOX: "Open",
	LOCKED: "Use Slip",
	SAFE: "",
	URN: "Use 2 Slips",
	MIMIC: "Use Slip",
}
const SLIPS_NEEDED := {LUNCHBOX: 0, LOCKED: 1, SAFE: 0, URN: 2, MIMIC: 0}
# What a Safe Deposit Box says when Grandpa stands beside it, since no key opens it.
const SAFE_HINT := "Needs a Thermos"
# The shallowest floor a mimic may lie on.
const MIMIC_FROM_DEPTH := 2
const LUNCHBOX_HEAL_CHANCE := 0.2
const LUNCHBOX_BOMB_CHANCE := 0.15
# A lunchbox holds a quarter of a treasure's Pension, a safe twice a treasure's, spread over a few coins.
const LUNCHBOX_SHARE := 0.25
const SAFE_SHARE := 2.0
const SAFE_COINS := 4
const URN_CHOICES := 2
# An urn with no item left to offer pays this many treasures' worth of Pension instead.
const URN_FALLBACK_SHARE := 2.0


# The odds a floor at this depth really uses: a first floor never rolls a mimic, whatever its data says.
static func odds_for_depth(weights: Dictionary, depth: int) -> Dictionary:
	var odds := {}
	for kind in KINDS:
		odds[kind] = maxf(float(weights.get(kind, 0.0)), 0.0)
	if depth < MIMIC_FROM_DEPTH:
		odds[MIMIC] = 0.0
	return odds


# Picks a kind from weights with a roll in [0, 1). Odds that add up to nothing give today's Locked Chest.
static func roll(odds: Dictionary, roll_value: float) -> String:
	var total := 0.0
	for kind in KINDS:
		total += float(odds.get(kind, 0.0))
	if total <= 0.0:
		return LOCKED
	var edge := 0.0
	var picked := LOCKED
	for kind in KINDS:
		var weight := float(odds.get(kind, 0.0))
		if weight <= 0.0:
			continue
		edge += weight / total
		picked = kind
		if roll_value < edge:
			return kind
	return picked


static func display_name(kind: String) -> String:
	return NAMES.get(kind, NAMES[LOCKED])


static func prompt_for(kind: String) -> String:
	return PROMPTS.get(kind, PROMPTS[LOCKED])


static func slips_needed(kind: String) -> int:
	return int(SLIPS_NEEDED.get(kind, 1))


# Lunchboxes, locked chests and urns open with the interact key. A mimic answers it too, by waking.
static func opens_by_hand(kind: String) -> bool:
	return kind == LUNCHBOX or kind == LOCKED or kind == URN


static func opens_by_blast(kind: String) -> bool:
	return kind == SAFE


static func can_open(kind: String, slips: int) -> bool:
	return opens_by_hand(kind) and slips >= slips_needed(kind)


# What else a lunchbox holds besides its coin: a small potion, a Thermos, or nothing.
static func lunchbox_extra(roll_value: float) -> String:
	if roll_value < LUNCHBOX_HEAL_CHANCE:
		return RoomRules.DROP_POTION
	if roll_value < LUNCHBOX_HEAL_CHANCE + LUNCHBOX_BOMB_CHANCE:
		return RoomRules.DROP_BOMB
	return RoomRules.DROP_NONE


static func lunchbox_pension(treasure_pension: int) -> int:
	return maxi(ceili(treasure_pension * LUNCHBOX_SHARE), 1)


static func safe_pension(treasure_pension: int) -> int:
	return maxi(roundi(treasure_pension * SAFE_SHARE), SAFE_COINS)


static func urn_fallback_pension(treasure_pension: int) -> int:
	return maxi(roundi(treasure_pension * URN_FALLBACK_SHARE), 1)


# Splits a total into count coins as even as whole numbers allow, the larger ones first.
static func coin_split(total: int, count: int) -> Array[int]:
	var coins: Array[int] = []
	if count <= 0 or total <= 0:
		return coins
	var parts := mini(count, total)
	for i in parts:
		coins.append(total / parts + (1 if i < total % parts else 0))
	return coins
