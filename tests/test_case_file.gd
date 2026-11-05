extends TestCase

# Harold's case file (Tab): its tabs, its grids and pages, what each page says, its key and pad button,
# and the HUD's item row with the file's key beside it.


func _root() -> Window:
	return Engine.get_main_loop().root


func _plain_run() -> RunState:
	var none: Array[UpgradeDef] = []
	return RunState.new(none, {})


func _items(count: int) -> Array[ItemDef]:
	var all := Content.items()
	var list: Array[ItemDef] = []
	for i in count:
		list.append(all[i % all.size()])
	return list


func _open(run: RunState, data: ProgressData) -> CaseFile:
	var file := CaseFile.new()
	file.setup(run, {"floor": "Records Basement (floor 1)", "route": "Records Basement", "time": 75.0}, data)
	_root().add_child(file)
	# Nodes added while the test runner starts get no _ready of their own, so it is called here.
	if file._body == null:
		file._ready()
	return file


func _close(file: CaseFile) -> void:
	file.get_parent().remove_child(file)
	file.free()
	Engine.get_main_loop().paused = false


func _texts(node: Node, into: PackedStringArray) -> PackedStringArray:
	for child in node.get_children():
		if child is Label or child is Button:
			into.append(child.text)
		_texts(child, into)
	return into


# --- the data ---

func test_initials_fit_a_cell() -> void:
	assert_eq(CaseFileData.initials("Rolling Pin"), "RP")
	assert_eq(CaseFileData.initials("Kettle"), "KE")
	assert_eq(CaseFileData.initials("Wreath of Thorns"), "WT")
	assert_eq(CaseFileData.initials("The Chairman of the Board"), "CB")
	assert_eq(CaseFileData.initials(""), "?")
	for item in Content.items():
		assert_true(CaseFileData.initials(item.display_name).length() <= 2, item.id)


func test_copies_of_one_item_share_a_cell_with_a_count() -> void:
	var all := Content.items()
	var held: Array[ItemDef] = [all[0], all[1], all[0], all[0]]
	var cells := CaseFileData.held_cells(held)
	assert_eq(cells.size(), 2)
	assert_eq(cells[0]["id"], all[0].id)
	assert_eq(int(cells[0]["count"]), 3)
	assert_true(cells[0]["badge"], "a held stack shows its badge")
	assert_eq(int(cells[1]["count"]), 1)


func test_the_catalog_lists_every_item_and_counts_what_was_found() -> void:
	var all := Content.items()
	var run := _plain_run()
	run.found.append(all[2].id)
	var cells := CaseFileData.catalog(all, {all[0].id: 3, all[1].id: 0}, run)
	assert_eq(cells.size(), all.size())
	assert_eq(CaseFileData.found_line(cells), "3/%d found" % all.size())
	assert_eq(int(cells[0]["count"]), 3)
	assert_false(cells[3]["known"])
	assert_eq(cells[3]["name"], CaseFileData.UNKNOWN_NAME, "an unfound item keeps its name hidden")
	assert_eq(CaseFileData.item_detail(cells[3])[0], CaseFileData.UNKNOWN_NAME)
	var detail := CaseFileData.item_detail(cells[0])
	assert_eq(detail[0], all[0].display_name)
	assert_eq(detail[1], all[0].description)
	assert_true(" ".join(PackedStringArray(detail)).contains("Times found: 3"))
	assert_true(cells[0]["icon"].begins_with(CaseFileData.ITEM_ICON_DIR), "each cell names where its icon will go")


func test_a_hundred_items_page_through_both_grids() -> void:
	var per_harold := CaseFile.GRID_COLUMNS * CaseFile.HAROLD_ROWS
	var per_catalog := CaseFile.GRID_COLUMNS * CaseFile.CATALOG_ROWS
	assert_eq(CaseFileData.page_count(100, per_harold), ceili(100.0 / per_harold))
	assert_eq(CaseFileData.page_count(0, per_harold), 1)
	var list: Array = range(100)
	var seen := 0
	for page in CaseFileData.page_count(100, per_catalog):
		seen += CaseFileData.page_of(list, page, per_catalog).size()
	assert_eq(seen, 100, "every item is on some page")
	var grid_bottom := CaseFile.LEFT_PAGE.position.y + 8.0 + 22.0 + CaseFile.CATALOG_ROWS * (CaseFile.CELL + CaseFile.CELL_GAP)
	assert_true(grid_bottom + 16.0 < CaseFile.LEFT_PAGE.end.y, "the catalog grid and its page row fit the page")
	var grid_width := CaseFile.GRID_COLUMNS * (CaseFile.CELL + CaseFile.CELL_GAP)
	assert_true(grid_width <= CaseFile.LEFT_PAGE.size.x - 12.0, "eight cells fit across")


func test_the_bestiary_names_a_floor_for_every_enemy_and_leaves_out_the_dummy() -> void:
	var defs := CaseFileData.enemy_defs()
	var floors := CaseFileData.enemy_floors()
	assert_true(defs.size() > 40)
	var missing: PackedStringArray = []
	for def in defs:
		assert_false(def.id == "training_dummy")
		if not floors.has(def.id):
			missing.append(def.id)
	assert_true(missing.size() <= 2, "enemies on no floor: %s" % str(missing))
	var run := _plain_run()
	run.note_kill("intern_reaper")
	var cells := CaseFileData.bestiary(defs, {"regional_reaper": 0}, run, floors)
	var by_id := {}
	for cell in cells:
		by_id[cell["id"]] = cell
	assert_true(by_id["intern_reaper"]["known"])
	assert_eq(int(by_id["intern_reaper"]["count"]), 1)
	assert_true(by_id["regional_reaper"]["known"], "a boss beaten before the file still counts as met")
	assert_false(by_id["mall_santa"]["known"])
	var detail := CaseFileData.enemy_detail(by_id["intern_reaper"])
	assert_eq(detail[0], by_id["intern_reaper"]["def"].display_name)
	assert_true(" ".join(PackedStringArray(detail)).contains("Found on:"))
	assert_eq(CaseFileData.enemy_detail(by_id["mall_santa"])[0], CaseFileData.UNKNOWN_NAME)


func test_the_harold_page_shows_his_stats_and_the_run() -> void:
	var run := _plain_run()
	run.keys = 4
	run.cursed = true
	var labels := []
	for row in CaseFileData.stat_rows(run):
		labels.append(row[0])
	for wanted in ["Pills", "Damage", "Speed", "Dodge", "Thermos"]:
		assert_true(labels.has(wanted), wanted)
	var rows := {}
	for row in CaseFileData.run_rows(run, {"floor": "Records Basement (floor 1)", "route": "Records Basement", "time": 3725.0}, ["Name badge"]):
		rows[row[0]] = row[1]
	assert_eq(rows["Slips"], "4")
	assert_eq(rows["Run time"], "1:02:05")
	assert_eq(rows["Floor"], "Records Basement (floor 1)")
	assert_eq(rows["Curses"], "Cursed ticket")
	assert_eq(rows["Blessings"], "Name badge")
	assert_eq(CaseFileData.blessings({Mementos.START_PENSION_PERK: true}), ["Name badge"])


func test_the_stats_and_log_pages_read_the_saved_history() -> void:
	var data := ProgressData.new()
	data.run_count = 6
	data.record_run({"n": 6, "result": RunLog.DIED, "depth": 3, "kills": {"mall_cop": 5}, "pension": 77, "time": 400.0, "items": ["kettle"], "found": ["kettle"], "hits": 3})
	var lifetime := {}
	for row in CaseFileData.lifetime_rows(data):
		lifetime[row[0]] = row[1]
	assert_eq(lifetime["Runs"], "6")
	assert_eq(lifetime["Enemies defeated"], "5")
	assert_eq(lifetime["Deaths"], "1")
	var best := {}
	for row in CaseFileData.best_rows(data):
		best[row[0]] = row[1]
	assert_eq(best["Most Pension"], "77")
	assert_eq(best["Longest run"], "6:40")
	assert_eq(best["Deepest floor"], "3")
	var names := CaseFileData.names_by_id(Content.items(), CaseFileData.enemy_defs())
	var detail := CaseFileData.log_detail(data.run_log[0], names)
	assert_true(detail[0].contains("Run 6"))
	assert_true(" ".join(PackedStringArray(detail)).contains("x5"), "the kills by enemy")


# --- the window ---

func test_the_file_opens_on_harold_pauses_and_steps_through_every_tab() -> void:
	var data := ProgressData.new()
	var run := _plain_run()
	for item in _items(40):
		run.add_item(item)
	var file := _open(run, data)
	assert_true(Engine.get_main_loop().paused, "the game pauses while it is open")
	assert_eq(file.current_tab(), CaseFileData.TAB_HAROLD)
	var texts := " | ".join(_texts(file, PackedStringArray()))
	for tab in CaseFileData.TABS:
		assert_true(texts.contains(CaseFileData.TAB_NAMES[tab]), "a paper tab for %s" % tab)
	assert_true(texts.contains("Page 1 / "), "forty items page on the Harold tab")
	for i in CaseFileData.TABS.size():
		file.show_tab_named(CaseFileData.TABS[i])
		assert_eq(file.current_tab(), CaseFileData.TABS[i])
	file.show_tab_named(CaseFileData.TAB_ITEMS)
	texts = " | ".join(_texts(file, PackedStringArray()))
	assert_true(texts.contains("found"), "the catalog counts what was found")
	_close(file)
	assert_false(Engine.get_main_loop().paused)


func test_q_and_e_and_the_shoulder_buttons_wrap_round_the_tabs() -> void:
	assert_eq(CaseFile.step_tab(0, -1), CaseFileData.TABS.size() - 1)
	assert_eq(CaseFile.step_tab(CaseFileData.TABS.size() - 1, 1), 0)
	assert_eq(CaseFile.step_tab(1, 1), 2)
	assert_eq(CaseFile.hint_text(false, PadInput.XBOX), CaseFile.HINT)
	assert_eq(CaseFile.hint_text(true, PadInput.PLAYSTATION), "L1 / R1: tabs    Circle: close")


func test_in_the_waiting_room_the_harold_tab_has_no_active_case() -> void:
	var file := _open(null, ProgressData.new())
	var texts := " | ".join(_texts(file, PackedStringArray()))
	assert_true(texts.contains(CaseFileData.NO_CASE))
	_close(file)


# --- the key ---

func test_tab_opens_it_and_the_touchpad_on_a_pad() -> void:
	KeyBindings.reset_to_defaults()
	assert_eq(KeyBindings.label_for("case_file"), "Tab")
	assert_eq(KeyBindings.pad_label_for("case_file", PadInput.PLAYSTATION), "Touchpad")
	assert_eq(KeyBindings.action_label("case_file"), "Case file")


func test_an_older_keys_file_keeps_its_bindings_and_the_file_keeps_tab() -> void:
	KeyBindings.reset_to_defaults()
	var path := OS.get_temp_dir().path_join("grandpa_keys_case_%d.json" % Time.get_ticks_usec())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"dodge": {"type": "key", "code": KEY_SHIFT}, "map": {"type": "key", "code": KEY_N}}))
	file.close()
	KeyBindings.load_from(path)
	assert_eq(KeyBindings.label_for("dodge"), "Shift")
	assert_eq(KeyBindings.label_for("map"), "N")
	assert_eq(KeyBindings.label_for("case_file"), "Tab", "a file older than the action keeps its default")
	# One that already put Tab on dodge keeps it there, and the case file takes dodge's old key.
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"dodge": {"type": "key", "code": KEY_TAB}}))
	file.close()
	KeyBindings.reset_to_defaults()
	KeyBindings.load_from(path)
	assert_eq(KeyBindings.label_for("dodge"), "Tab")
	assert_eq(KeyBindings.label_for("case_file"), "Space", "no action is left without a key")
	DirAccess.remove_absolute(path)
	KeyBindings.reset_to_defaults()


# --- the HUD's item row ---

func test_the_item_row_shows_the_count_and_the_newest_three() -> void:
	assert_eq(Hud.items_text(PackedStringArray()), "Items: 0")
	assert_eq(Hud.items_text(PackedStringArray(["A", "B"])), "Items: 2   B, A")
	var names: PackedStringArray = []
	for item in _items(100):
		names.append(item.display_name)
	var text := Hud.items_text(names)
	assert_true(text.begins_with("Items: 100   "))
	assert_eq(text.trim_prefix("Items: 100   ").split(", ").size(), 3, "only the newest three names")
	assert_eq(Hud.case_hint_text("Tab"), "Tab: Case file")


func test_the_item_row_fits_one_line_clear_of_the_potion_slot_and_the_small_map() -> void:
	var font := ThemeDB.fallback_font
	var hint_width := font.get_string_size(Hud.case_hint_text("Touchpad"), HORIZONTAL_ALIGNMENT_LEFT, -1, Hud.ITEM_ROW_FONT).x + 6.0
	var rects := Hud.item_row_rects(hint_width)
	var names_rect: Rect2 = rects[0]
	var hint_rect: Rect2 = rects[1]
	assert_true(names_rect.end.x <= hint_rect.position.x, "the names stop before the hint")
	assert_true(hint_rect.end.x <= FloorMapView.MINI_RECT.position.x, "the hint stops before the small map")
	assert_true(names_rect.position.y >= Hud.TOP_BAND_SIZE.y, "under the top band and the potion slot")
	assert_true(names_rect.position.y >= Hud.POTION_SLOT_AT.y + PotionSlot.SIZE.y, "below the potion slot")
	assert_true(names_rect.end.y <= Hud.BAND_BOTTOM, "inside the band speech stays below")
	var hud := Hud.new()
	var run := _plain_run()
	for item in _items(100):
		run.add_item(item)
	hud.setup(run)
	_root().add_child(hud)
	if hud._items == null:
		hud._ready()
	var label: Label = hud._items
	assert_true(label.clip_text and label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "a long row is cut with an ellipsis")
	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_OFF, "it never wraps onto a second line")
	assert_true(label.position.x + label.size.x <= FloorMapView.MINI_RECT.position.x)
	assert_true(label.text.begins_with("Items: 100"))
	hud.get_parent().remove_child(hud)
	hud.free()
