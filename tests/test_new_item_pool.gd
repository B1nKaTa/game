extends TestCase

# The pool is the approved list: 107 items, each with one source, the old quotas kept.

const LIST := ["afterimage", "alarm_clock", "bad_hip", "bifocals", "bingo_dabber", "boomerang_bite", "bottomless_flask",
	"brass_topper", "brown_envelope", "budgie", "bureaucrats_stamp", "cactus_brooch", "cane_hook", "cane_sword",
	"casserole_dish", "chattering_bounce", "coin_purse_cane", "comfort_care_lanyard", "complaint_form", "compound_interest",
	"coupon_booklet", "dentures_in_glass", "desk_drawer", "dinner_bell", "dog_treats", "early_bird_special",
	"eternal_warranty", "exchange_desk", "ferret", "filing_cabinet", "fine_print", "fizzy_tablet", "flask_holster",
	"floor_plan", "glass_hip", "glue_gun", "gold_fillings", "gold_star", "hagglers_hat", "harmonica",
	"hearing_aid_feedback", "heart_monitor", "hospital_bracelet", "hot_soup_thermos", "in_triplicate",
	"inheritance_letter", "key_cutter", "knitting_needles", "last_orders", "life_alert_button", "life_jacket",
	"lightning_rod", "locksmiths_apron", "loose_paperwork", "lottery_scratcher", "magnifying_glass", "megaphone",
	"mittens", "model_citizen", "money_belt", "moths", "nitro_tablets", "obituary_clippings", "old_projector",
	"paper_cuts", "parrot", "pet_cemetery_plot", "pet_rock", "photo_album", "photo_of_grandkids", "photocopier",
	"piggy_bank", "pill_organizer", "pocket_watch", "pogo_cane", "polyester_suit", "pressure_cooker", "prune_juice",
	"racing_pigeon", "reapers_scythe", "repeat_offender", "rex", "rocking_chair", "rolling_pin", "rose_tinted",
	"rubber_stamp_collection", "rusty_hinge", "scrapbook", "second_brew", "senior_discount", "shark_tooth", "sheepdog",
	"spare_set", "strong_dentures", "tea_break", "tea_cosy", "tea_urn", "thermos_lob", "those_were_the_days",
	"titanium_hip", "tortoise", "turned_auditor", "unpaid_bill", "velcro_shoes", "walking_frame", "wheelchair_wheels",
	"windup_teeth"]
const PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema",
	"last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]
const POSTERS := {"augustine": "photocopier", "celestine": "sheepdog", "crabtree": "thermos_lob", "lorraine": "parrot",
	"projectionist": "old_projector", "tired_undertaker": "pet_cemetery_plot", "doreen": "bureaucrats_stamp",
	"matron_mercy": "comfort_care_lanyard", "sergeant_wanda": "complaint_form", "commodore_wellington": "life_jacket",
	"mortimer_grimsby": "pocket_watch", "regional_reaper": "reapers_scythe", "chairman_of_the_board": "money_belt",
	"madame_zara": "heart_monitor", "reverend": "tea_urn", "senior_adjuster": "filing_cabinet",
	"foreman_klaus": "nitro_tablets", "head_groundskeeper": "titanium_hip"}


func test_the_pool_is_the_approved_list() -> void:
	var ids: Array = []
	for item in Content.items():
		assert_false(ids.has(item.id), "%s ships once" % item.id)
		ids.append(item.id)
	ids.sort()
	assert_eq(ids, LIST)
	assert_eq(RetiredContent.RETIRED_ITEMS.size(), 48)
	for id: String in RetiredContent.RETIRED_ITEMS:
		assert_false(LIST.has(id), "%s is retired" % id)


func test_the_pool_adds_up() -> void:
	var sources := {}
	var rarity := {}
	var kinds := {}
	var cursed: Array[String] = []
	var per_path := {}
	for item in Content.items():
		var source := ItemUnlocks.source_of(item)
		sources[source] = int(sources.get(source, 0)) + 1
		rarity[item.rarity] = int(rarity.get(item.rarity, 0)) + 1
		kinds[item.kind] = int(kinds.get(item.kind, 0)) + 1
		assert_true(ItemUnlocks.source_count(item) <= 1, item.id)
		assert_true(ItemDef.BUILDS.has(item.build), item.id)
		assert_eq(Array(item.tags), [item.build], item.id)
		assert_false(item.description.is_empty(), item.id)
		assert_true(CoachTips.TIPS.has(item.id), "%s has a tip" % item.id)
		if item.cursed:
			cursed.append(item.id)
		if not item.first_clear_path.is_empty():
			per_path[item.first_clear_path] = int(per_path.get(item.first_clear_path, 0)) + 1
	assert_eq(sources, {ItemUnlocks.START: 47, ItemUnlocks.FIRST_CLEAR: 30, ItemUnlocks.RECIPE: 18, ItemUnlocks.BOUNTY: 12})
	assert_eq(rarity, {ItemDef.COMMON: 40, ItemDef.RARE: 52, ItemDef.LEGENDARY: 15})
	assert_eq(kinds, {ItemDef.KIND_PASSIVE: 89, ItemDef.KIND_PET: 10, ItemDef.KIND_ACTIVE: 8})
	cursed.sort()
	assert_eq(cursed, ["glass_hip", "nitro_tablets", "polyester_suit", "prune_juice", "unpaid_bill"] as Array[String])
	for path: String in PATHS:
		assert_eq(per_path.get(path, 0), 3, "%s opens three" % path)
	assert_eq(Content.sets().size(), 11)
	assert_eq(Content.run_potions().size(), 7)
	assert_true(Content.combos().is_empty())


func test_the_posters_pay_the_new_rewards() -> void:
	for def in BountyBoard.all():
		if POSTERS.has(def.id):
			assert_eq(def.extra_id, POSTERS[def.id], def.id)
	assert_eq(ItemKit.item("tea_urn").craft_price, 350)
	assert_true(ItemKit.item("photocopier").from_bounty)


# Every shipped item, run potion and set says what the approved list says, word for word.
func test_every_entry_matches_the_approved_list() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://docs/superpowers/specs/2026-11-10-new-item-list-items.json"))
	assert_true(raw is Dictionary)
	if not raw is Dictionary:
		return
	var seen := 0
	for entry: Dictionary in raw["items"]:
		var id := str(entry["id"])
		match str(entry["kind"]):
			"potion":
				var def := Content.potion(id)
				assert_true(def != null, id)
				if def != null:
					assert_eq(def.display_name, entry["name"], id)
					assert_eq(def.description, entry["desc"], id)
					assert_eq(def.run_rarity, entry["rarity"], id)
			"set":
				var found: SetDef = null
				for def in Content.sets():
					if def.id == id:
						found = def
				assert_true(found != null, id)
				if found != null:
					assert_eq(found.display_name, entry["name"], id)
					assert_eq(found.description, entry["desc"], id)
					assert_eq(found.build, entry["build"], id)
			_:
				var item := ItemKit.item(id)
				assert_true(item != null and LIST.has(id), id)
				if item != null:
					assert_eq(item.display_name, entry["name"], id)
					assert_eq(item.description, entry["desc"], id)
					assert_eq(item.rarity, entry["rarity"], id)
					assert_eq(item.build, entry["build"], id)
					assert_eq(item.kind, entry["kind"], id)
					assert_eq(item.cursed, bool(entry["cursed"]), id)
		seen += 1
	assert_eq(seen, 125)
