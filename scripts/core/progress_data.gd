class_name ProgressData
extends RefCounted

const VERSION := 1
const RETIREMENT_CAP := 1000
const RETIREMENT_TIERS := [10, 50, 100, 250, 500, 750, 1000]
const NO_DEPOSIT_RUN := -1

var pension: int = 0
var upgrades: Dictionary = {}
var opening_seen: bool = false
var retirement_balance: int = 0
var retirement_peak: int = 0
var run_count: int = 0
var retirement_deposit_run: int = NO_DEPOSIT_RUN
var recipes_found: Dictionary = {}
var items_unlocked: Dictionary = {}
var crafted_for_next_run: String = ""


func level_of(id: String) -> int:
	return int(upgrades.get(id, 0))


func add_pension(amount: int) -> void:
	pension += maxi(amount, 0)


func spend(amount: int) -> bool:
	if amount < 0 or pension < amount:
		return false
	pension -= amount
	return true


func can_buy(def: UpgradeDef) -> bool:
	var price := def.price_at(level_of(def.id))
	return price >= 0 and pension >= price


func buy(def: UpgradeDef) -> bool:
	if not can_buy(def):
		return false
	pension -= def.price_at(level_of(def.id))
	upgrades[def.id] = level_of(def.id) + 1
	return true


func start_run() -> void:
	run_count += 1


# Returns how many tiers this deposit newly reached. A tier pays once ever, so
# cashing out and depositing again can't earn the same rewards twice.
func retirement_deposit(amount: int) -> int:
	var moved := mini(mini(amount, pension), RETIREMENT_CAP - retirement_balance)
	if moved <= 0:
		return 0
	pension -= moved
	retirement_balance += moved
	retirement_deposit_run = run_count
	var reached := 0
	for tier: int in RETIREMENT_TIERS:
		if retirement_peak < tier and tier <= retirement_balance:
			reached += 1
	retirement_peak = maxi(retirement_peak, retirement_balance)
	return reached


func can_release_retirement() -> bool:
	return retirement_balance > 0 and retirement_deposit_run != run_count


func release_retirement() -> int:
	if not can_release_retirement():
		return 0
	var amount := retirement_balance
	retirement_balance = 0
	pension += amount
	return amount


func next_retirement_tier() -> int:
	for tier: int in RETIREMENT_TIERS:
		if retirement_peak < tier:
			return tier
	return -1


func find_recipe(id: String) -> void:
	recipes_found[id] = true


func has_recipe(id: String) -> bool:
	return recipes_found.has(id)


func is_unlocked(id: String) -> bool:
	return items_unlocked.has(id)


# Each item is crafted once ever, and only one crafted item can wait for the next run at a time.
func can_craft(id: String, price: int) -> bool:
	return has_recipe(id) and not is_unlocked(id) and pension >= price and crafted_for_next_run.is_empty()


func craft(id: String, price: int) -> bool:
	if not can_craft(id, price):
		return false
	pension -= price
	items_unlocked[id] = true
	crafted_for_next_run = id
	return true


func take_crafted_item() -> String:
	var id := crafted_for_next_run
	crafted_for_next_run = ""
	return id


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"pension": pension,
		"upgrades": upgrades,
		"opening_seen": opening_seen,
		"retirement_balance": retirement_balance,
		"retirement_peak": retirement_peak,
		"run_count": run_count,
		"retirement_deposit_run": retirement_deposit_run,
		"recipes_found": recipes_found,
		"items_unlocked": items_unlocked,
		"crafted_for_next_run": crafted_for_next_run,
	}


static func from_dict(raw: Variant) -> ProgressData:
	if not raw is Dictionary:
		return null
	for key in ["version", "pension", "upgrades", "opening_seen"]:
		if not raw.has(key):
			return null
	if int(raw["version"]) != VERSION or int(raw["pension"]) < 0:
		return null
	if not raw["upgrades"] is Dictionary or not raw["opening_seen"] is bool:
		return null
	var data := ProgressData.new()
	data.pension = int(raw["pension"])
	data.opening_seen = raw["opening_seen"]
	for id in raw["upgrades"]:
		data.upgrades[str(id)] = int(raw["upgrades"][id])
	# These came later, so older saves simply don't have them.
	data.retirement_balance = clampi(int(raw.get("retirement_balance", 0)), 0, RETIREMENT_CAP)
	data.retirement_peak = clampi(int(raw.get("retirement_peak", 0)), data.retirement_balance, RETIREMENT_CAP)
	data.run_count = maxi(int(raw.get("run_count", 0)), 0)
	data.retirement_deposit_run = int(raw.get("retirement_deposit_run", NO_DEPOSIT_RUN))
	data.recipes_found = _id_set(raw.get("recipes_found"))
	data.items_unlocked = _id_set(raw.get("items_unlocked"))
	var crafted: Variant = raw.get("crafted_for_next_run", "")
	data.crafted_for_next_run = crafted if crafted is String else ""
	return data


static func _id_set(raw: Variant) -> Dictionary:
	var ids := {}
	if raw is Dictionary:
		for id in raw:
			ids[str(id)] = true
	return ids
