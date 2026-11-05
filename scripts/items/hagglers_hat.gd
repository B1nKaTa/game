extends ItemEffect

# Haggler's Hat: the cheapest item for sale in each shop costs half, marked as such. Heals, Slips and
# Thermoses keep their prices, and a free item stays free.

const SHARE := 0.5


func on_shop_open(_ctx: EffectContext, stock: Array[Dictionary]) -> void:
	var cheapest: Dictionary = {}
	for entry in stock:
		if entry["kind"] != ShopRules.KIND_ITEM or int(entry["price"]) <= 0:
			continue
		if cheapest.is_empty() or int(entry["price"]) < int(cheapest["price"]):
			cheapest = entry
	if cheapest.is_empty():
		return
	cheapest["price"] = ShopRules.price_after(int(cheapest["price"]), SHARE)
	cheapest["half"] = true
