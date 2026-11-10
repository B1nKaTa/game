extends ItemEffect

# Haggler's Hat: the cheapest item for sale in every shop is free. Heals, Slips, Thermoses and potions keep
# their prices.


func on_shop_open(_ctx: EffectContext, stock: Array[Dictionary]) -> void:
	var cheapest: Dictionary = {}
	for entry in stock:
		if entry["kind"] != ShopRules.KIND_ITEM or int(entry["price"]) <= 0:
			continue
		if cheapest.is_empty() or int(entry["price"]) < int(cheapest["price"]):
			cheapest = entry
	if cheapest.is_empty():
		return
	cheapest["price"] = 0
