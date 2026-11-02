class_name ShopRules
extends RefCounted

const KIND_ITEM := "item"
const KIND_HEAL := "heal"
const KIND_KEY := "key"
const KIND_BOMB := "bomb"
const ITEM_PRICE := 60
const HEAL_PRICE := 20
const KEY_PRICE := 25
const BOMB_PRICE := 20
const ITEMS_FOR_SALE := 2
const PLACE_SHOP := "shop"
const PLACE_TREASURE := "treasure"
const PLACE_BOSS := "boss"


static func stock(all_items: Array[ItemDef], run: RunState, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item in RoomRules.pick_items(all_items, run, ITEMS_FOR_SALE, rng):
		entries.append({"kind": KIND_ITEM, "price": ITEM_PRICE, "item": item})
	entries.append({"kind": KIND_HEAL, "price": HEAL_PRICE, "item": null})
	entries.append({"kind": KIND_KEY, "price": KEY_PRICE, "item": null})
	entries.append({"kind": KIND_BOMB, "price": BOMB_PRICE, "item": null})
	return entries


# A reward can wait in any place the player can still reach this run.
static func reward_place(treasure_ahead: bool, boss_ahead: bool, roll: float) -> String:
	var places := [PLACE_SHOP]
	if treasure_ahead:
		places.append(PLACE_TREASURE)
	if boss_ahead:
		places.append(PLACE_BOSS)
	return places[mini(int(roll * places.size()), places.size() - 1)]
