class_name ShopRules
extends RefCounted

const KIND_ITEM := "item"
const KIND_HEAL := "heal"
const KIND_KEY := "key"
const KIND_BOMB := "bomb"
const KIND_POTION := "potion"
# What an item cost before rarities. ItemRarity.PRICES now sets it, anchored on this for a rare one.
const ITEM_PRICE := 60
const HEAL_PRICE := 20
const KEY_PRICE := 25
const BOMB_PRICE := 20
const ITEMS_FOR_SALE := 2


# pension_mult is the floor's: items cost more where Pension comes faster. Heals, Slips and Thermoses
# keep their prices.
static func stock(all_items: Array[ItemDef], run: RunState, rng: RandomNumberGenerator, pension_mult := 1.0, potions: Array[PotionDef] = []) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	# Frequent Flyer Miles take their share off every price, and a Lucky Seat Ticket puts a share on. A Ticket Stub
	# Book adds wares. The full loop counts the stock and prices as the rooms set them.
	var discount := run.stats.shop_discount
	var for_sale := ITEMS_FOR_SALE
	if not run.effects.ctx.counting_exact:
		discount -= run.stats.shop_markup
		for_sale += run.stats.shop_extra_items
	for item in RoomRules.pick_items(all_items, run, for_sale, rng, ItemRarity.SHOP):
		entries.append({"kind": KIND_ITEM, "price": item_price(item, pension_mult, discount), "item": item})
	entries.append({"kind": KIND_HEAL, "price": price_after(HEAL_PRICE, discount), "item": null})
	entries.append({"kind": KIND_KEY, "price": price_after(KEY_PRICE, discount), "item": null})
	entries.append({"kind": KIND_BOMB, "price": price_after(BOMB_PRICE, discount), "item": null})
	var potion: PotionDef = PotionPool.shop_roll(potions, rng.randf(), rng.randf()) if not potions.is_empty() else null
	if potion != null:
		entries.append({"kind": KIND_POTION, "price": price_after(PotionPool.shop_price(potion, pension_mult), discount), "item": null, "potion": potion})
	return entries


static func item_price(item: ItemDef, pension_mult: float, discount: float) -> int:
	return price_after(ItemRarity.price(item, pension_mult), discount)


# A price with a share taken off, rounded to the nearest Pension and never below 1. A share below zero
# puts that much on instead.
static func price_after(price: int, discount: float) -> int:
	return maxi(roundi(price * (1.0 - discount)), 1)
