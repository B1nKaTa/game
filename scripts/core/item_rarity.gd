class_name ItemRarity
extends RefCounted

# Each source rolls a rarity first, then picks an item of that rarity from the run's open pool.

const SHOP := "shop"
const ITEM_ROOM := "item_room"
const ARCADE := "arcade"
const TREASURE := "treasure"
const URN := "urn"
const VAULT := "vault"
const BOSS := "boss"
const ORDER := [ItemDef.COMMON, ItemDef.RARE, ItemDef.LEGENDARY]
# Common, rare and legendary chances out of 100, by source.
const WEIGHTS := {
	SHOP: [70, 27, 3],
	ITEM_ROOM: [60, 35, 5],
	ARCADE: [60, 35, 5],
	TREASURE: [50, 40, 10],
	URN: [40, 45, 15],
	VAULT: [30, 50, 20],
	BOSS: [20, 50, 30],
}
# The shop's item prices by rarity, before the floor's pension_mult and any discount. They keep the
# design's 30 : 55 : 160 ratios, anchored on the 60 an item cost before rarities.
const PRICES := {ItemDef.COMMON: 35, ItemDef.RARE: 60, ItemDef.LEGENDARY: 175}
const COMMON_COLOR := Color("7dd3fc")
const RARE_COLOR := Color("ffd24a")
const LEGENDARY_COLOR := Color("ff8a3c")
const CURSED_COLOR := Color("b26cf0")


# The rarity a roll in [0, 1) lands on for a source. An unknown source rolls as an item room.
static func roll(source: String, roll01: float) -> String:
	var weights: Array = WEIGHTS.get(source, WEIGHTS[ITEM_ROOM])
	var edge := 0.0
	for i in ORDER.size():
		edge += weights[i] / 100.0
		if roll01 < edge:
			return ORDER[i]
	return ORDER[-1]


# The order rarities are tried in when the rolled one has nothing left: the rolled one, then the
# others from common upward.
static func fallback_order(rolled: String) -> Array[String]:
	var order: Array[String] = [rolled]
	for rarity: String in ORDER:
		if rarity != rolled:
			order.append(rarity)
	return order


# A boss's reward and a vault never hold a cursed item.
static func allows_cursed(source: String) -> bool:
	return source != BOSS and source != VAULT


static func color_of(rarity: String) -> Color:
	match rarity:
		ItemDef.RARE:
			return RARE_COLOR
		ItemDef.LEGENDARY:
			return LEGENDARY_COLOR
	return COMMON_COLOR


# What an item's name is drawn in: purple for a cursed one, else its rarity's colour.
static func name_color(item: ItemDef) -> Color:
	return CURSED_COLOR if item.cursed else color_of(item.rarity)



static func base_price(item: ItemDef) -> int:
	return int(PRICES.get(item.rarity, PRICES[ItemDef.COMMON]))


# The shop price on a floor that pays pension_mult, rounded to the nearest Pension.
static func price(item: ItemDef, pension_mult: float) -> int:
	return maxi(roundi(base_price(item) * maxf(pension_mult, 0.0)), 1)
