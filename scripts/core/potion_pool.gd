class_name PotionPool
extends RefCounted

# Which potion a potion drop holds, and which one a shop sells. A drop is most often the Small Potion;
# else a run potion of a rolled rarity, picked evenly. Shops sell one run potion. The Waiting Room's
# brews are apart from this.

const SMALL_ID := "small_potion"
const SMALL_SHARE := 0.55
const COMMON_SHARE := 0.30
const SHOP_COMMON_SHARE := 0.7
const PRICES := {"common": 25, "rare": 40}


static func of_rarity(all: Array[PotionDef], rarity: String) -> Array[PotionDef]:
	var list: Array[PotionDef] = []
	for def in all:
		if def.run_rarity == rarity:
			list.append(def)
	return list


static func roll(all: Array[PotionDef], roll_kind: float, roll_pick: float) -> PotionDef:
	var small: PotionDef = null
	for def in all:
		if def.id == SMALL_ID:
			small = def
	if roll_kind < SMALL_SHARE:
		return small
	var picked := _pick(all, "common" if roll_kind < SMALL_SHARE + COMMON_SHARE else "rare", roll_pick)
	return picked if picked != null else small


static func shop_roll(all: Array[PotionDef], roll_kind: float, roll_pick: float) -> PotionDef:
	return _pick(all, "common" if roll_kind < SHOP_COMMON_SHARE else "rare", roll_pick)


static func shop_price(def: PotionDef, pension_mult: float) -> int:
	return maxi(roundi(int(PRICES.get(def.run_rarity, PRICES["common"])) * maxf(pension_mult, 0.0)), 1)


# One of the rarity, or of the other when it has none.
static func _pick(all: Array[PotionDef], rarity: String, roll_pick: float) -> PotionDef:
	var list := of_rarity(all, rarity)
	if list.is_empty():
		list = of_rarity(all, "rare" if rarity == "common" else "common")
	if list.is_empty():
		return null
	return list[clampi(int(roll_pick * list.size()), 0, list.size() - 1)]
