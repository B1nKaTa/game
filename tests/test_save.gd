extends TestCase

const PATH := "user://test_save.json"


func _store() -> SaveStore:
	var store := SaveStore.new(PATH)
	store.delete_all()
	return store


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _upgrade(prices: Array) -> UpgradeDef:
	var def := UpgradeDef.new()
	def.id = "cane"
	def.prices = PackedInt32Array(prices)
	return def


func test_no_save_starts_new_without_warning() -> void:
	var store := _store()
	var data := store.load_progress()
	assert_eq(data.pension, 0)
	assert_eq(store.last_status, SaveStore.STATUS_NEW)


func test_round_trip() -> void:
	var store := _store()
	var data := ProgressData.new()
	data.pension = 42
	data.upgrades = {"cane": 2}
	data.opening_seen = true
	assert_true(store.save_progress(data))
	var loaded := store.load_progress()
	assert_eq(loaded.pension, 42)
	assert_eq(loaded.level_of("cane"), 2)
	assert_true(loaded.opening_seen)
	assert_eq(store.last_status, SaveStore.STATUS_OK)
	store.delete_all()


func test_damaged_save_uses_backup() -> void:
	var store := _store()
	var data := ProgressData.new()
	data.pension = 10
	store.save_progress(data)
	data.pension = 20
	store.save_progress(data)
	_write(PATH, "{not json")
	var loaded := store.load_progress()
	assert_eq(loaded.pension, 10)
	assert_eq(store.last_status, SaveStore.STATUS_BACKUP)
	store.delete_all()


func test_both_damaged_resets_and_reports() -> void:
	var store := _store()
	_write(PATH, "garbage")
	_write(PATH + ".bak", "garbage")
	var loaded := store.load_progress()
	assert_eq(loaded.pension, 0)
	assert_eq(store.last_status, SaveStore.STATUS_RESET)
	store.delete_all()


func test_missing_main_with_backup_recovers() -> void:
	var store := _store()
	var data := ProgressData.new()
	data.pension = 7
	store.save_progress(data)
	store.save_progress(data)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	assert_eq(store.load_progress().pension, 7)
	assert_eq(store.last_status, SaveStore.STATUS_BACKUP)
	store.delete_all()


func test_from_dict_rejects_bad_data() -> void:
	assert_true(ProgressData.from_dict("nope") == null)
	assert_true(ProgressData.from_dict({"version": 99, "pension": 1, "upgrades": {}, "opening_seen": false}) == null)
	assert_true(ProgressData.from_dict({"version": 1, "pension": -5, "upgrades": {}, "opening_seen": false}) == null)
	assert_true(ProgressData.from_dict({"version": 1, "pension": 5}) == null)


func test_buy_spends_pension_and_raises_level() -> void:
	var data := ProgressData.new()
	data.pension = 30
	var def := _upgrade([10, 100])
	assert_true(data.buy(def))
	assert_eq(data.pension, 20)
	assert_eq(data.level_of("cane"), 1)


func test_cannot_buy_without_pension() -> void:
	var data := ProgressData.new()
	data.pension = 5
	assert_false(data.buy(_upgrade([10])))
	assert_eq(data.pension, 5)
	assert_eq(data.level_of("cane"), 0)


func test_cannot_buy_past_max_level() -> void:
	var data := ProgressData.new()
	data.pension = 100
	data.upgrades = {"cane": 1}
	assert_false(data.buy(_upgrade([10])))
	assert_eq(data.pension, 100)
