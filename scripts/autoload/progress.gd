extends Node

signal pension_changed(amount: int)

const SAVE_PATH := "user://save.json"
const SMOKE_PATH := "user://smoke_save.json"

var data: ProgressData
var notice := ""
var _store: SaveStore


func _ready() -> void:
	var smoke := OS.get_cmdline_user_args().has("--smoke")
	_store = SaveStore.new(SMOKE_PATH if smoke else SAVE_PATH)
	if smoke:
		_store.delete_all()
	reload()


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


func mark_opening_seen() -> void:
	data.opening_seen = true
	_store.save_progress(data)


func make_run() -> RunState:
	return RunState.new(Content.upgrades(), data.upgrades)
