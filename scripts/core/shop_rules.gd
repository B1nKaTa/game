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


static func stock(all_items: Array[ItemDef], run: RunState, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	# Frequent Flyer Miles take their share off every price.
	var discount := run.stats.shop_discount
	for item in RoomRules.pick_items(all_items, run, ITEMS_FOR_SALE, rng):
		entries.append({"kind": KIND_ITEM, "price": price_after(ITEM_PRICE, discount), "item": item})
	entries.append({"kind": KIND_HEAL, "price": price_after(HEAL_PRICE, discount), "item": null})
	entries.append({"kind": KIND_KEY, "price": price_after(KEY_PRICE, discount), "item": null})
	entries.append({"kind": KIND_BOMB, "price": price_after(BOMB_PRICE, discount), "item": null})
	return entries


# A price with a share taken off, rounded to the nearest Pension and never below 1.
static func price_after(price: int, discount: float) -> int:
	return maxi(roundi(price * (1.0 - discount)), 1)
