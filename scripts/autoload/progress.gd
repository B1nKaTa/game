extends Node

signal pension_changed(amount: int)
signal condolences_changed(amount: int)

# The old single save. It is only ever read, by the copy into slot 1 (SaveSlots.migrate), and stays
# where it is.
const SAVE_PATH := "user://save.json"
# The folder the slots live in.
const ROOT := "user://"
const SMOKE_PATH := "user://smoke_save.json"
const SMOKE_RUN_PATH := "user://smoke_run.json"
const DEV_PATH := "user://save_dev.json"

var data: ProgressData
var notice := ""
# How the run just played went, for the Coach on return: died, and bosses beaten. Not saved.
var last_run := {}
# Back Room visits with a game won since the last run, handed to the next run as table visits for the
# endings (RunState.extra_table_visits). Not saved.
var table_wins_before_run := 0
var _store: SaveStore
# While a dev run is on, the real progress and its store wait here untouched, and every save goes to
# the dev file instead.
var _real_data: ProgressData
var _real_store: SaveStore
# The depth whose landing a run under the dev profile starts on: 3 for F3, 4 for F5, 5 for F6. A run
# started through the dev Waiting Room's run door starts on the Floor 3 landing.
var dev_start_depth := DevStart.START_DEPTH
# The selected save slot, 1 to SaveSlots.COUNT. 0 in the full loop and test runs, which keep their own
# files and never touch a slot.
var slot := 0
# An interrupted run the next floor scene resumes instead of starting fresh. Set by Game.resume_run.
var resume := {}
var _smoke := false


func _ready() -> void:
	_smoke = OS.get_cmdline_user_args().has("--smoke")
	if _smoke:
		_store = SaveStore.new(SMOKE_PATH)
		_store.delete_all()
		RunCheckpoint.delete(SMOKE_RUN_PATH)
	elif RunMode.is_script_run():
		# A test or probe run reads the old save as before and copies nothing into any slot.
		_store = SaveStore.new(SAVE_PATH)
	else:
		SaveSlots.migrate(ROOT)
		slot = SaveSlots.read_last(ROOT)
		_store = SaveStore.new(SaveSlots.save_path(ROOT, slot))
	reload()


# Switches to a slot's progress, and remembers it as the last used slot. Never in the full loop.
func select_slot(number: int) -> void:
	if _smoke or number < 1 or number > SaveSlots.COUNT:
		return
	end_dev_run(false)
	slot = number
	_store = SaveStore.new(SaveSlots.save_path(ROOT, slot))
	SaveSlots.write_last(ROOT, slot)
	reload()


# Empties a slot for a new game: its progress and its interrupted run.
func clear_slot(number: int) -> void:
	if _smoke or number < 1 or number > SaveSlots.COUNT:
		return
	SaveSlots.delete_slot(ROOT, number)
	if number == slot:
		reload()


func slot_summary(number: int) -> Dictionary:
	return SaveSlots.summary(ROOT, number)


# Where this slot's interrupted run is kept, or "" when nothing may keep one: a dev run, or a test run.
func run_path() -> String:
	if is_dev_run():
		return ""
	if _smoke:
		return SMOKE_RUN_PATH
	if slot < 1:
		return ""
	return SaveSlots.run_path(ROOT, slot)


func read_checkpoint() -> Dictionary:
	var path := run_path()
	return {} if path.is_empty() else RunCheckpoint.read(path)


func write_checkpoint(checkpoint: Dictionary) -> bool:
	var path := run_path()
	return false if path.is_empty() else RunCheckpoint.write(path, checkpoint)


func clear_checkpoint() -> void:
	var path := run_path()
	if not path.is_empty():
		RunCheckpoint.delete(path)


# A resumed run's Pension, as its checkpoint kept it (see RunCheckpoint.apply_pension). Condolences stay.
func restore_pension(checkpoint: Dictionary) -> void:
	if RunCheckpoint.apply_pension(data, checkpoint):
		_save_pension()


func is_dev_run() -> bool:
	return _real_store != null


# Swaps in progress made up for a dev run. Nothing it earns or spends can reach the real save, since
# the real store is set aside until end_dev_run.
func begin_dev_run(dev_data: ProgressData, dev_path := DEV_PATH, start_depth := DevStart.START_DEPTH) -> void:
	if is_dev_run():
		end_dev_run()
	dev_start_depth = start_depth
	_real_data = data
	_real_store = _store
	_store = SaveStore.new(dev_path)
	_store.delete_all()
	data = dev_data
	pension_changed.emit(data.pension)
	condolences_changed.emit(data.condolences)


# Throws the dev run's progress away and brings back the real progress exactly as it was. Nothing is
# written to the real save here: the real progress was never touched while it waited. announce is
# false when the game quits, as the scenes that listen may already be gone.
func end_dev_run(announce := true) -> void:
	if not is_dev_run():
		return
	_store.delete_all()
	_store = _real_store
	data = _real_data
	dev_start_depth = DevStart.START_DEPTH
	_real_store = null
	_real_data = null
	if announce:
		pension_changed.emit(data.pension)
		condolences_changed.emit(data.condolences)


# Quitting during a dev run or the dev Waiting Room ends it too, so its file never outlives the game.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		end_dev_run(false)


func _exit_tree() -> void:
	end_dev_run(false)


func reload() -> void:
	data = _store.load_progress()
	# ProgressData loads no defs, so a poster id that matches none is dropped here.
	BountyBoard.drop_unknown_taken(BountyBoard.all(), data)
	# A poster retired before it paid an item, as the Regional Reaper's paid a hood, gives its item now.
	BountyBoard.grant_retired_items(BountyBoard.all(), data)
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


func buy(def: UpgradeDef, option := "") -> bool:
	if not data.buy(def, option):
		return false
	_store.save_progress(data)
	pension_changed.emit(data.pension)
	return true


# Switches a filed form to its other option, free the first time and REFILE_FEE after.
func refile(def: UpgradeDef) -> bool:
	if not data.refile(def):
		return false
	_save_pension()
	return true


func spend(amount: int) -> bool:
	if not data.spend(amount):
		return false
	_save_pension()
	return true


func add_condolences(amount: int) -> void:
	data.add_condolences(amount)
	_save_condolences()


func spend_condolences(amount: int) -> bool:
	if not data.spend_condolences(amount):
		return false
	_save_condolences()
	return true


# Saves at once, so a boss beaten in a run that ends in death still counts.
func record_boss_beaten(boss_id: String, is_floor_boss: bool) -> int:
	var paid := data.record_boss_beaten(boss_id, is_floor_boss)
	_save_condolences()
	return paid


func buy_cosmetic(def: CosmeticDef) -> bool:
	if not data.buy_cosmetic(def):
		return false
	_save_condolences()
	return true


func wear(def: CosmeticDef) -> bool:
	if not data.wear(def):
		return false
	_store.save_progress(data)
	return true


func take_off(slot: String) -> void:
	if not data.cosmetics_worn.has(slot):
		return
	data.take_off(slot)
	_store.save_progress(data)


func _save_condolences() -> void:
	_store.save_progress(data)
	condolences_changed.emit(data.condolences)


func mark_coach_met() -> void:
	if data.coach_met:
		return
	data.coach_met = true
	_store.save_progress(data)


func take_bounty(def: BountyDef) -> bool:
	if not BountyBoard.take(def, data):
		return false
	_save_both_currencies()
	return true


# Pays a won poster straight into the save, so no run multiplier touches it. Empty when nothing was paid.
func collect_bounty(def: BountyDef) -> Dictionary:
	var paid := BountyBoard.collect(def, data)
	if not paid.is_empty():
		_save_both_currencies()
	return paid


func _save_both_currencies() -> void:
	_store.save_progress(data)
	pension_changed.emit(data.pension)
	condolences_changed.emit(data.condolences)


func start_run() -> void:
	last_run = {"died": false, "bosses": 0}
	data.start_run()
	_store.save_progress(data)


# Calls the last run's ticket on return to the Waiting Room. Saves only when a ticket was called, so a
# visit with nothing new leaves the save as it was.
func call_ticket() -> String:
	var before := data.ticket_called
	var event := data.call_ticket(Content.upgrades(), randf())
	if data.ticket_called != before:
		_store.save_progress(data)
	return event


func accept_cursed_ticket() -> bool:
	if not data.accept_cursed_ticket():
		return false
	_store.save_progress(data)
	return true


func decline_cursed_ticket() -> void:
	if not data.cursed_offer:
		return
	data.decline_cursed_ticket()
	_store.save_progress(data)


# Saved the moment an ending is chosen, before its scene plays, so quitting during the scene never
# plays it as new again. Returns the Condolences paid.
func record_ending(id: String) -> int:
	var paid := data.record_ending(id)
	_save_condolences()
	return paid


# A run that ended goes into the case file's Log and lifetime totals, saved at once.
func record_run(entry: Dictionary) -> void:
	data.record_run(entry)
	_store.save_progress(data)


func set_last_run_ending(id: String) -> void:
	data.set_last_ending(id)
	_store.save_progress(data)


func record_repeat_death(n: int) -> void:
	data.record_repeat_death(n)
	_store.save_progress(data)


func read_letter(path_id: String) -> void:
	if data.letters_read.has(path_id):
		return
	data.read_letter(path_id)
	_store.save_progress(data)


# Read once, as a run starts, and saved at once, so a cursed run cut short never curses the next.
func take_cursed_run() -> bool:
	var cursed := data.take_cursed_run()
	if cursed:
		_store.save_progress(data)
	return cursed


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
	# A path's first clear hangs its boss's memento, which the Waiting Room sounds on return.
	if not data.has_cleared_path(path_id):
		for entry: Dictionary in Mementos.ALL:
			if entry["path"] == path_id:
				last_run["new_memento"] = true
	data.record_floor_cleared(depth, path_id)
	_store.save_progress(data)


# Paths whose first-clear items have been announced, so each path's news plays once.
func mark_item_paths_seen(ids: Array) -> void:
	if ids.is_empty():
		return
	for id in ids:
		data.item_paths_seen[str(id)] = true
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
	var run := RunState.new(Content.upgrades(), data.upgrades, data.form_choices)
	run.unlocked_items = data.items_unlocked
	run.paths_cleared = data.paths_cleared
	run.effects.set_combos(Content.combos())

	run.perks = Mementos.perks(data)
	run.apply_perks()
	run.look = RunState.look_from(data.cosmetics_worn, CosmeticDef.all())
	return run
