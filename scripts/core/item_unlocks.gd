class_name ItemUnlocks
extends RefCounted

# Where each item comes from. Every item has exactly one source: open from the start, a path's first
# clear, a recipe crafted at Agnes, or a wanted poster's reward. test_item_unlocks holds every shipped
# item to that.

const START := "start"
const FIRST_CLEAR := "first_clear"
const RECIPE := "recipe"
const BOUNTY := "bounty"
# The Waiting Room's arrival notice for the items a path's first clear opened.
const NOTICE := "Lost and found: %s"


# How many of the three gated sources an item claims. Anything but 0 or 1 is a data mistake.
static func source_count(item: ItemDef) -> int:
	var count := 0
	if item.needs_recipe():
		count += 1
	if item.from_bounty:
		count += 1
	if not item.first_clear_path.is_empty():
		count += 1
	return count


static func source_of(item: ItemDef) -> String:
	if item.needs_recipe():
		return RECIPE
	if item.from_bounty:
		return BOUNTY
	if not item.first_clear_path.is_empty():
		return FIRST_CLEAR
	return START


# Recipe items join once crafted and poster items once won, both kept in items_unlocked. A first-clear
# item joins once its path's floor boss has fallen.
static func is_open(item: ItemDef, unlocked: Dictionary, paths_cleared: Dictionary) -> bool:
	match source_of(item):
		RECIPE, BOUNTY:
			return unlocked.has(item.id)
		FIRST_CLEAR:
			return paths_cleared.has(item.first_clear_path)
	return true


# Path id -> the display names of the items its first clear opened, for every cleared path whose
# items have not been announced yet. Paths whose clear opens nothing are left out.
static func unannounced(items: Array[ItemDef], data: ProgressData) -> Dictionary:
	var found := {}
	for item in items:
		var path := item.first_clear_path
		if path.is_empty() or not data.has_cleared_path(path) or data.item_paths_seen.has(path):
			continue
		if not found.has(path):
			found[path] = PackedStringArray()
		found[path].append(item.display_name)
	return found


static func notice_for(names: PackedStringArray) -> String:
	return NOTICE % ", ".join(names)
