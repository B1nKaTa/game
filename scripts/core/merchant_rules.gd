class_name MerchantRules
extends RefCounted

# A Waiting Room merchant entry may carry "clears": how many floors must be cleared before
# that merchant appears. Entries without it are always there. The numbers live in the list in
# the Waiting Room scene, so later floors can move them in one place.


static func is_open(entry: Dictionary, floors_cleared: int) -> bool:
	return floors_cleared >= int(entry.get("clears", 0))


static func open_ones(entries: Array, floors_cleared: int) -> Array:
	var open: Array = []
	for entry: Dictionary in entries:
		if is_open(entry, floors_cleared):
			open.append(entry)
	return open
