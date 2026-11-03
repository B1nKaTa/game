class_name MerchantRules
extends RefCounted

# A Waiting Room merchant entry may say when it appears:
# - "depth" and "clears": that many clears of floors at that depth.
# - "paths": every listed path id has been cleared.
# - "legacy_clears": a save from before clears by depth with at least that many clears keeps it.
# Entries without "clears" or "paths" are always there. The numbers live in the Waiting Room's list.


static func is_open(entry: Dictionary, data: ProgressData) -> bool:
	if entry.has("legacy_clears") and data.legacy_clears >= int(entry["legacy_clears"]):
		return true
	if entry.has("paths"):
		for id in entry["paths"]:
			if not data.has_cleared_path(id):
				return false
		return true
	return data.clears_at(int(entry.get("depth", 1))) >= int(entry.get("clears", 0))


static func open_ones(entries: Array, data: ProgressData) -> Array:
	var open: Array = []
	for entry: Dictionary in entries:
		if is_open(entry, data):
			open.append(entry)
	return open
