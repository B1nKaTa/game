extends Node

signal pension_changed(amount: int)

const SAVE_PATH := "user://save.json"
const SMOKE_PATH := "user://smoke_save.json"
const DEV_PATH := "user://save_dev.json"

var data: ProgressData
var notice := ""
var _store: SaveStore
# While a dev run is on, the real progress and its store wait here untouched, and every save goes to
# the dev file instead.
var _real_data: ProgressData
var _real_store: SaveStore


func _ready() -> void:
	var smoke := OS.get_cmdline_user_args().has("--smoke")
	_store = SaveStore.new(SMOKE_PATH if smoke else SAVE_PATH)
	if smoke:
		_store.delete_all()
	reload()


func is_dev_run() -> bool:
	return _real_store != null


# Swaps in progress made up for a dev run. Nothing it earns or spends can reach the real save, since
# the real store is set aside until end_dev_run.
func begin_dev_run(dev_data: ProgressData, dev_path := DEV_PATH) -> void:
	if is_dev_run():
		end_dev_run()
	_real_data = data
	_real_store = _store
	_store = SaveStore.new(dev_path)
	_store.delete_all()
	data = dev_data
	pension_changed.emit(data.pension)


# Throws the dev run's progress away and brings back the real progress exactly as it was.
func end_dev_run() -> void:
	if not is_dev_run():
		return
	_store.delete_all()
	_store = _real_store
	data = _real_data
	_real_store = null
	_real_data = null
	pension_changed.emit(data.pension)


func reload() -> void:
	data = _store.load_progress()
	notice = ""
	if _store.last_status == SaveStore.STATUS_BACKUP:
		notice = "Your save was damaged, so a backup was restored."
	elif _store.last_status == SaveStore.STATUS_RESET:
		notice = "Your save was damaged and could not be recovered. Starting fresh."
	pension_changed.emit(data.pension)


func add_pension(amount: int) -> void:
	data.add_pension(amount)
	_store.save_progress(data)
	pension_changed.emit(data.pension)


func buy(def: UpgradeDef) -> bool:
	if not data.buy(def):
		return false
	_store.save_progress(data)
	pension_changed.emit(data.pension)
	return true


func spend(amount: int) -> bool:
	if not data.spend(amount):
		return false
	_save_pension()
	return true


func start_run() -> void:
	data.start_run()
	_store.save_progress(data)


func retirement_deposit(amount: int) -> int:
	var reached := data.retirement_deposit(amount)
	_save_pension()
	return reached


func release_retirement() -> int:
	var amount := data.release_retirement()
	if amount > 0:
		_save_pension()
	return amount


func _save_pension() -> void:
	_store.save_progress(data)
	pension_changed.emit(data.pension)


func mark_opening_seen() -> void:
	data.opening_seen = true
	_store.save_progress(data)


func find_recipe(id: String) -> void:
	data.find_recipe(id)
	_store.save_progress(data)


func craft(item: ItemDef) -> bool:
	if not data.craft(item.id, item.craft_price):
		return false
	_save_pension()
	return true


func take_crafted_item() -> ItemDef:
	var id := data.take_crafted_item()
	if id.is_empty():
		return null
	_store.save_progress(data)
	for item in Content.items():
		if item.id == id:
			return item
	return null


func record_floor_cleared(depth: int, path_id: String) -> void:
	data.record_floor_cleared(depth, path_id)
	_store.save_progress(data)


# Departments whose opening has been announced, so each arrival line plays once.
func mark_departments_seen(ids: Array) -> void:
	if ids.is_empty():
		return
	for id in ids:
		data.departments_seen[str(id)] = true
	_store.save_progress(data)


func brew(def: PotionDef) -> bool:
	if not data.brew(def.id, def.price):
		return false
	_save_pension()
	return true


func take_brewed_potion() -> PotionDef:
	var id := data.take_brewed_potion()
	if id.is_empty():
		return null
	_store.save_progress(data)
	return Content.potion(id)


func make_run() -> RunState:
	var run := RunState.new(Content.upgrades(), data.upgrades)
	run.unlocked_items = data.items_unlocked
	run.perks = Mementos.perks(data)
	run.apply_perks()
	return run
