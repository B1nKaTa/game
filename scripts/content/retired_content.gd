class_name RetiredContent
extends RefCounted

# Old content that has left the game's pools. A retired id's file may still be on disk until the user
# agrees to delete it (the new item list's plan, Task 26): Content.items() leaves it out, Content.all_items()
# still loads it. RENAMED maps an old id to the new item that took its place, for saves and checkpoints.

const RETIRED_ITEMS: Array[String] = ["second_thermos_strap", "rubber_stamps", "pension_statement", "penny_jar", "mothball_pockets"]
# The pair combos of the hundred items. The new list's set bonuses take their place; ComboDef stays.
const RETIRED_COMBOS: Array[String] = ["bingo_night", "card_shark", "dentists_nightmare", "early_riser",
	"family_visit", "full_set", "last_rites", "mobility_scooter", "night_shift", "paper_trail",
	"retirement_plan", "soup_of_the_day"]
const RENAMED := {
	"second_thermos_strap": "flask_holster",
	"rubber_stamps": "rubber_stamp_collection",
	"pension_statement": "compound_interest",
	"penny_jar": "racing_pigeon",
	"mothball_pockets": "moths",
	"wreath_of_thorns": "cactus_brooch",
	"hearing_aid": "hearing_aid_feedback",
	"dentures": "strong_dentures",
}
# What a crafted item whose recipe left cost, refunded to a save that had one waiting.
const RETIRED_RECIPE_PRICES := {"alert_bracelet": 100, "golden_parachute": 110, "lucky_tee": 90, "support_stockings": 80}


static func current_id(id: String) -> String:
	return str(RENAMED.get(id, id))


static func is_retired(id: String) -> bool:
	return RETIRED_ITEMS.has(id)
