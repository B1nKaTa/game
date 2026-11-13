class_name CaseFile
extends CanvasLayer

# Harold's case file: a manila folder with five paper tabs (CaseFileData.TABS). Tab opens it on the
# Harold tab during a run or in the Waiting Room, and pauses the game while it is open. Q and E, or
# the shoulder buttons, switch tabs; the arrows, the D-pad or the mouse move round a page; Tab, Esc or
# B (Circle) close it. Everything it shows comes from CaseFileData. Placeholder look until the art
# pass: cells show an icon from CaseFileData.icon_path when one exists, else a colour chip and initials.

signal closed

const LAYER := 55
const VIEW := Vector2(640, 360)
const FOLDER := Rect2(12, 22, 616, 330)
const LEFT_PAGE := Rect2(24, 34, 290, 300)
const RIGHT_PAGE := Rect2(326, 34, 290, 300)
const TAB_AT := Vector2(26, 5)
const TAB_SIZE := Vector2(96, 18)
const TAB_GAP := 4.0
const CELL := 30.0
const CELL_GAP := 4.0
const GRID_COLUMNS := 8
const HAROLD_ROWS := 3
const CATALOG_ROWS := 6
const FONT := 9
const STAT_LABEL_WIDTH := 62.0
const RUN_LABEL_WIDTH := 96.0
const FILE_LABEL_WIDTH := 130.0
const HEAD_FONT := 12
const DESK := Color(0.05, 0.035, 0.03, 0.88)
const MANILA := Color("cfae68")
const MANILA_DARK := Color("a8874a")
const MANILA_EDGE := Color("6e5228")
const PAPER := Color("f1e8d0")
const PAPER_EDGE := Color("b9a886")
const INK := Color("2b2218")
const INK_DIM := Color("6f6250")
const STAMP := Color("9c2f2a")
const HINT := "Q / E: tabs    Tab / Esc: close"
const PAD_HINT := "%s / %s: tabs    %s: close"

var _run: RunState
# The save the file reads, handed in by the scene (Progress.data). The file never names the Progress
# autoload itself, so a probe or test that loads it before the autoloads still compiles it.
var _data: ProgressData
# What only the scene knows about the run: floor, route, time.
var _info := {}
var _tab := 0
var _pages := {}
var _selected := {}
var _opened_frame := -1
var _was_paused := false
var _done := false
var _body: Control
var _tab_buttons: Array[Button] = []
var _detail: VBoxContainer
var _hint: Label
var _focus: PadFocus
# The grid's cells on the page shown, so the selected one keeps its mark when focus moves away.
var _cells: Array = []
# The content, loaded once per opening.
var _items: Array[ItemDef] = []
var _enemies: Array[EnemyDef] = []
var _floors := {}


# run is null in the Waiting Room, where the Harold tab says there is no active case.
func setup(run: RunState, info := {}, data: ProgressData = null) -> void:
	_run = run
	_info = info
	_data = data


static func tab_count() -> int:
	return CaseFileData.TABS.size()


# The tab Q or E, LB or RB moves to from tab, wrapping round.
static func step_tab(tab: int, step: int) -> int:
	return posmod(tab + step, tab_count())


# A cell's picture: an item's icon through ItemIcons, an enemy's from its icon path, or null.
static func cell_texture(cell: Dictionary) -> Texture2D:
	if cell.get("item") != null:
		return ItemIcons.texture(str(cell.get("id", "")))
	var icon_path := str(cell.get("icon", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		return load(icon_path) as Texture2D
	return null


func current_tab() -> String:
	return CaseFileData.TABS[_tab]


func current_page() -> int:
	return int(_pages.get(_tab, 0))


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	if _data == null:
		_data = ProgressData.new()
	# Through the main loop, so the file pauses the game even while it is still being added.
	var tree := Engine.get_main_loop() as SceneTree
	_was_paused = tree.paused
	tree.paused = true
	_items = Content.items()
	_enemies = CaseFileData.enemy_defs()
	_floors = CaseFileData.enemy_floors()
	var desk := MenuStyle.backing(DESK)
	add_child(desk)
	var folder := Panel.new()
	folder.position = FOLDER.position
	folder.size = FOLDER.size
	folder.add_theme_stylebox_override("panel", _box(MANILA, MANILA_EDGE, 2))
	folder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(folder)
	for i in tab_count():
		var button := _make_tab(i)
		_tab_buttons.append(button)
		add_child(button)
	for page in [LEFT_PAGE, RIGHT_PAGE]:
		var paper := Panel.new()
		paper.position = page.position
		paper.size = page.size
		paper.add_theme_stylebox_override("panel", _box(PAPER, PAPER_EDGE, 1))
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(paper)
	_hint = _label("", 8, INK)
	_hint.position = Vector2(FOLDER.position.x + 12, FOLDER.end.y - 15)
	_hint.size = Vector2(FOLDER.size.x - 24, 12)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_hint)
	_body = Control.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.size = VIEW
	add_child(_body)
	_focus = PadFocus.new()
	_focus.tabs = _switch_tab
	add_child(_focus)
	_show_tab(0)


func _exit_tree() -> void:
	(Engine.get_main_loop() as SceneTree).paused = _was_paused


func _process(_delta: float) -> void:
	_hint.text = hint_text(ActiveDevice.using_pad, ActiveDevice.family)


static func hint_text(pad: bool, family: String) -> String:
	if not pad:
		return HINT
	return PAD_HINT % [PadInput.button_name(JOY_BUTTON_LEFT_SHOULDER, family), PadInput.button_name(JOY_BUTTON_RIGHT_SHOULDER, family), PadInput.button_name(JOY_BUTTON_B, family)]


func _input(event: InputEvent) -> void:
	if _done or Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed("case_file") or event.is_action_pressed("pause") or event.is_action_pressed(PadInput.BACK_ACTION):
		get_viewport().set_input_as_handled()
		close()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		if key.physical_keycode == KEY_Q:
			get_viewport().set_input_as_handled()
			_switch_tab(-1)
		elif key.physical_keycode == KEY_E:
			get_viewport().set_input_as_handled()
			_switch_tab(1)
		elif key.physical_keycode == KEY_PAGEUP:
			get_viewport().set_input_as_handled()
			_turn_page(-1)
		elif key.physical_keycode == KEY_PAGEDOWN:
			get_viewport().set_input_as_handled()
			_turn_page(1)


func close() -> void:
	if _done:
		return
	_done = true
	closed.emit()


# The scene frees it; a leave() lets the Waiting Room close it as any of its panels.
func leave() -> void:
	close()


func handles_pause_key() -> bool:
	return true


func _switch_tab(step: int) -> void:
	_show_tab(step_tab(_tab, step))
	Sfx.play("ui_move")


func show_tab_named(tab_id: String) -> void:
	var at := CaseFileData.TABS.find(tab_id)
	if at >= 0:
		_show_tab(at)


func _show_tab(index: int) -> void:
	_tab = index
	for i in _tab_buttons.size():
		_style_tab(_tab_buttons[i], i == _tab)
	_rebuild()


func _turn_page(step: int) -> void:
	var total := _page_total()
	if total <= 1:
		return
	_pages[_tab] = posmod(current_page() + step, total)
	_selected[_tab] = 0
	_rebuild()


func _page_total() -> int:
	match current_tab():
		CaseFileData.TAB_HAROLD:
			return CaseFileData.page_count(_held().size(), GRID_COLUMNS * HAROLD_ROWS) if _run != null else 1
		CaseFileData.TAB_ITEMS:
			return CaseFileData.page_count(_items.size(), GRID_COLUMNS * CATALOG_ROWS)
		CaseFileData.TAB_BESTIARY:
			return CaseFileData.page_count(_enemies.size(), GRID_COLUMNS * CATALOG_ROWS)
	return 1


func _rebuild() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_detail = null
	_cells.clear()
	match current_tab():
		CaseFileData.TAB_HAROLD:
			_build_harold()
		CaseFileData.TAB_ITEMS:
			var found := CaseFileData.catalog(_items, _data.items_seen, _run)
			_build_catalog(found, "Items", CaseFileData.found_line(found), true)
		CaseFileData.TAB_BESTIARY:
			var cells := CaseFileData.bestiary(_enemies, _data.enemies_seen, _run, _floors)
			_build_catalog(cells, "Bestiary", CaseFileData.met_line(cells), false)
		CaseFileData.TAB_STATS:
			_build_stats()
		CaseFileData.TAB_LOG:
			_build_log()


# --- Harold ---

func _held() -> Array[Dictionary]:
	return CaseFileData.held_cells(_run.items, _run.active) if _run != null else []


func _build_harold() -> void:
	var left := LEFT_PAGE.grow(-8)
	var title := "HAROLD   -   Case no. %d" % _data.run_count
	_add_head(title, left.position)
	if _run == null:
		_add_wrapped(CaseFileData.NO_CASE, 10, INK_DIM, left.position + Vector2(0, 30), left.size.x)
		_build_waiting_right()
		return
	var rows := CaseFileData.stat_rows(_run)
	var half := ceili(rows.size() / 2.0)
	for i in rows.size():
		var column := 0 if i < half else 1
		var at := left.position + Vector2(column * left.size.x / 2.0, 20.0 + (i % half) * 11.0)
		_add_row(rows[i], at, left.size.x / 2.0 - 6.0, STAT_LABEL_WIDTH)
	var y := 22.0 + half * 11.0
	var forms := CaseFileData.upgrade_rows(_data.upgrades, Content.upgrades())
	var form_parts: PackedStringArray = []
	for row in forms:
		form_parts.append("%s %s" % [row[0], str(row[1]).trim_prefix("Lv ")])
	var forms_label := _add_wrapped("Forms: " + (", ".join(form_parts) if not form_parts.is_empty() else "none"), 8, INK_DIM, left.position + Vector2(0, y), left.size.x)
	forms_label.max_lines_visible = 2
	y += 24.0
	var held := _held()
	var held_label := _label("Held items: %d" % _run.items.size(), FONT, INK)
	held_label.position = left.position + Vector2(0, y)
	_body.add_child(held_label)
	y += 14.0
	var grid_at := left.position + Vector2(2, y)
	_add_grid(held, GRID_COLUMNS * HAROLD_ROWS, grid_at, true)
	_add_page_row(held.size(), GRID_COLUMNS * HAROLD_ROWS, Vector2(left.position.x, grid_at.y + HAROLD_ROWS * (CELL + CELL_GAP)))
	_detail = _add_detail_box(Vector2(left.position.x, grid_at.y + HAROLD_ROWS * (CELL + CELL_GAP) + 16.0), Vector2(left.size.x, left.end.y - (grid_at.y + HAROLD_ROWS * (CELL + CELL_GAP) + 16.0)))
	if held.is_empty():
		_show_detail(["No items held yet."])
	_build_run_right()


func _build_run_right() -> void:
	var right := RIGHT_PAGE.grow(-8)
	_add_head("THIS RUN", right.position)
	var rows := CaseFileData.run_rows(_run, _info, CaseFileData.blessings(_run.perks))
	var box := VBoxContainer.new()
	box.position = right.position + Vector2(0, 20)
	box.size = Vector2(right.size.x, right.size.y - 20)
	box.add_theme_constant_override("separation", 1)
	_body.add_child(box)
	for row in rows:
		box.add_child(_wrapped_row(row, right.size.x, RUN_LABEL_WIDTH))


func _build_waiting_right() -> void:
	var right := RIGHT_PAGE.grow(-8)
	_add_head("ON FILE", right.position)
	var rows: Array = [["Pension", "%d" % _data.pension], ["Condolences", "%d" % _data.condolences]]
	rows.append_array(CaseFileData.upgrade_rows(_data.upgrades, Content.upgrades()))
	var box := VBoxContainer.new()
	box.position = right.position + Vector2(0, 20)
	box.size = Vector2(right.size.x, right.size.y - 20)
	_body.add_child(box)
	for row in rows:
		box.add_child(_wrapped_row(row, right.size.x, FILE_LABEL_WIDTH))


# --- Items and Bestiary ---

func _build_catalog(cells: Array[Dictionary], title: String, counter: String, items: bool) -> void:
	var left := LEFT_PAGE.grow(-8)
	_add_head(title.to_upper(), left.position)
	var count := _label(counter, 10, STAMP)
	count.position = left.position + Vector2(0, 1)
	count.size = Vector2(left.size.x, 14)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_body.add_child(count)
	var grid_at := left.position + Vector2(2, 22)
	_add_grid(cells, GRID_COLUMNS * CATALOG_ROWS, grid_at, items)
	_add_page_row(cells.size(), GRID_COLUMNS * CATALOG_ROWS, Vector2(left.position.x, grid_at.y + CATALOG_ROWS * (CELL + CELL_GAP) + 4.0))
	var right := RIGHT_PAGE.grow(-8)
	_add_head("DETAILS", right.position)
	_detail = _add_detail_box(right.position + Vector2(0, 22), right.size - Vector2(0, 22))


# --- Stats ---

func _build_stats() -> void:
	var left := LEFT_PAGE.grow(-8)
	_add_head("LIFETIME", left.position)
	var y := 22.0
	for row in CaseFileData.lifetime_rows(_data):
		_add_row(row, left.position + Vector2(0, y), left.size.x, 170.0, 10)
		y += 15.0
	var right := RIGHT_PAGE.grow(-8)
	_add_head("BEST SINGLE RUN", right.position)
	y = 22.0
	for row in CaseFileData.best_rows(_data):
		_add_row(row, right.position + Vector2(0, y), right.size.x, 170.0, 10)
		y += 15.0
	_add_wrapped("Counted since this file was opened. Older runs count toward Runs, Endings and Floors only.", 8, INK_DIM, right.position + Vector2(0, y + 10.0), right.size.x)


# --- Log ---

func _build_log() -> void:
	var left := LEFT_PAGE.grow(-8)
	_add_head("RUN LOG", left.position)
	var entries: Array = _data.run_log
	var counter := _label("Last %d of %d kept" % [entries.size(), RunLog.CAP], 8, INK_DIM)
	counter.position = left.position + Vector2(0, 2)
	counter.size = Vector2(left.size.x, 12)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_body.add_child(counter)
	var right := RIGHT_PAGE.grow(-8)
	_add_head("DETAILS", right.position)
	_detail = _add_detail_box(right.position + Vector2(0, 22), right.size - Vector2(0, 22))
	if entries.is_empty():
		_show_detail(["No runs on file yet. Every run from now on is kept here."])
		return
	var scroll := ScrollContainer.new()
	scroll.position = left.position + Vector2(0, 20)
	scroll.size = Vector2(left.size.x, left.size.y - 20)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_body.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = left.size.x - 10
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	var names := CaseFileData.names_by_id(Content.all_items(), _enemies)
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var button := _ink_button(RunLog.headline(entry))
		button.clip_text = true
		button.custom_minimum_size = Vector2(left.size.x - 12, 13)
		button.focus_entered.connect(_show_detail_lines.bind(CaseFileData.log_detail(entry, names)))
		list.add_child(button)
	_show_detail(CaseFileData.log_detail(entries[0], names))


# --- building blocks ---

func _add_grid(cells: Array[Dictionary], per_page: int, at: Vector2, _items_grid: bool) -> void:
	var shown := CaseFileData.page_of(cells, current_page(), per_page)
	for i in shown.size():
		var cell: Dictionary = shown[i]
		var button := CaseCell.new()
		button.cell = cell
		button.position = at + Vector2((i % GRID_COLUMNS) * (CELL + CELL_GAP), floori(i / float(GRID_COLUMNS)) * (CELL + CELL_GAP))
		button.size = Vector2(CELL, CELL)
		button.focus_entered.connect(_on_cell_focused.bind(cell, i))
		button.mouse_entered.connect(button.grab_focus)
		_body.add_child(button)
		_cells.append(button)
	if not shown.is_empty():
		var chosen := clampi(int(_selected.get(_tab, 0)), 0, shown.size() - 1)
		_on_cell_focused.call_deferred(shown[chosen], chosen)


func _on_cell_focused(cell: Dictionary, index: int) -> void:
	_selected[_tab] = index
	for i in _cells.size():
		if is_instance_valid(_cells[i]):
			_cells[i].selected = i == index
			_cells[i].queue_redraw()
	if cell.has("def"):
		_show_detail(CaseFileData.enemy_detail(cell))
	elif current_tab() == CaseFileData.TAB_HAROLD:
		var item: ItemDef = cell["item"]
		var head := item.display_name + (" x%d" % int(cell["count"]) if int(cell["count"]) > 1 else "")
		_show_detail([head, item.description])
	else:
		_show_detail(CaseFileData.item_detail(cell))


func _add_page_row(total: int, per_page: int, at: Vector2) -> void:
	var pages := CaseFileData.page_count(total, per_page)
	if pages <= 1:
		return
	var back := _ink_button("< Prev")
	back.position = at
	back.pressed.connect(_turn_page.bind(-1))
	_body.add_child(back)
	var label := _label("Page %d / %d" % [current_page() + 1, pages], FONT, INK)
	label.position = at + Vector2(110, 1)
	_body.add_child(label)
	var next := _ink_button("Next >")
	next.position = at + Vector2(220, 0)
	next.pressed.connect(_turn_page.bind(1))
	_body.add_child(next)


func _add_detail_box(at: Vector2, size: Vector2) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.position = at
	box.size = size
	box.clip_contents = true
	box.add_theme_constant_override("separation", 3)
	_body.add_child(box)
	return box


func _show_detail_lines(lines: Array) -> void:
	_show_detail(lines)


func _show_detail(lines: Array) -> void:
	if _detail == null or not is_instance_valid(_detail):
		return
	for child in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()
	for i in lines.size():
		var label := _label(str(lines[i]), 11 if i == 0 else 9, INK if i <= 1 else INK_DIM)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = _detail.size.x
		_detail.add_child(label)


# A label that wraps within width. A plain Control parent never sizes a wrapping label, so it sits in
# a column of that width, as the detail box's lines do.
func _add_wrapped(text: String, font_size: int, color: Color, at: Vector2, width: float) -> Label:
	var column := VBoxContainer.new()
	column.position = at
	column.size = Vector2(width, 0)
	_body.add_child(column)
	var label := _label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = width
	column.add_child(label)
	return label


func _add_head(text: String, at: Vector2) -> void:
	var head := _label(text, HEAD_FONT, INK)
	head.position = at
	_body.add_child(head)
	var rule := ColorRect.new()
	rule.color = PAPER_EDGE
	rule.position = at + Vector2(0, 16)
	rule.size = Vector2(LEFT_PAGE.size.x - 16, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(rule)


func _add_row(row: Array, at: Vector2, width: float, label_width: float, font_size := FONT) -> void:
	var name_label := _label(str(row[0]), font_size, INK_DIM)
	name_label.position = at
	name_label.size = Vector2(label_width, 12)
	_body.add_child(name_label)
	var value := _label(str(row[1]), font_size, INK)
	value.position = at + Vector2(label_width, 0)
	value.size = Vector2(width - label_width, 12)
	value.clip_text = true
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_body.add_child(value)


func _wrapped_row(row: Array, width: float, label_width: float) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 4)
	var name_label := _label(str(row[0]), FONT, INK_DIM)
	name_label.custom_minimum_size.x = label_width
	name_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	line.add_child(name_label)
	var value := _label(str(row[1]), FONT, INK)
	value.custom_minimum_size.x = width - label_width - 4.0
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_child(value)
	return line


func _make_tab(index: int) -> Button:
	var button := Button.new()
	button.text = tr(CaseFileData.TAB_NAMES[CaseFileData.TABS[index]])
	button.position = TAB_AT + Vector2(index * (TAB_SIZE.x + TAB_GAP), 0)
	button.size = TAB_SIZE
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(_on_tab_pressed.bind(index))
	button.mouse_entered.connect(button.grab_focus)
	button.set_meta("sfx", "")
	return button


func _on_tab_pressed(index: int) -> void:
	if index != _tab:
		Sfx.play("ui_move")
		_show_tab(index)


func _style_tab(button: Button, active: bool) -> void:
	var face := _box(MANILA if active else MANILA_DARK, MANILA_EDGE, 1)
	face.border_width_bottom = 0
	face.set_corner_radius_all(0)
	face.corner_radius_top_left = 4
	face.corner_radius_top_right = 4
	face.content_margin_top = 1
	face.content_margin_bottom = 1
	var lit := face.duplicate() as StyleBoxFlat
	lit.border_color = MenuStyle.GOLD
	lit.set_border_width_all(2)
	lit.border_width_bottom = 0
	for state in ["normal", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, face)
	for state in ["hover", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, lit)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, INK if active else INK_DIM)
	button.size = TAB_SIZE + (Vector2(0, 4) if active else Vector2.ZERO)


func _ink_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT)
	var plain := StyleBoxFlat.new()
	plain.bg_color = Color(0, 0, 0, 0)
	plain.content_margin_left = 3
	plain.content_margin_right = 3
	plain.content_margin_top = 0
	plain.content_margin_bottom = 0
	var bar := plain.duplicate() as StyleBoxFlat
	bar.bg_color = MenuStyle.GOLD
	for state in ["normal", "disabled"]:
		button.add_theme_stylebox_override(state, plain)
	for state in ["hover", "focus", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, bar)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, INK)
	button.mouse_entered.connect(button.grab_focus)
	return button


static func _label(text: String, font_size: int, color: Color) -> Label:
	var label := MenuStyle.label(text, font_size, color)
	return label


static func _box(color: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(width)
	return style


# One grid cell: the icon when the art pass has dropped one at the cell's icon path, else a colour
# chip with initials; a dark "?" for anything not yet found; a count badge for more than one.
class CaseCell extends Button:
	var cell: Dictionary
	# The cell whose details show, marked even while focus is elsewhere (on a tab, or with the mouse away).
	var selected := false

	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL
		var none := StyleBoxEmpty.new()
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			add_theme_stylebox_override(state, none)
		set_meta("sfx", "")

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var known: bool = cell.get("known", false)
		var font := ThemeDB.fallback_font
		draw_rect(rect, Color(0.85, 0.79, 0.65))
		var picture := CaseFile.cell_texture(cell)
		if known and picture != null:
			draw_texture_rect(picture, rect.grow(-2), false)
		elif known:
			var chip: Color = cell.get("color", Color.WHITE)
			draw_rect(rect.grow(-3), chip)
			var text := CaseFileData.initials(str(cell.get("name", "")))
			var ink := CaseFile.INK if chip.get_luminance() > 0.45 else Color("f6efe0")
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font, Vector2((size.x - width) / 2.0, size.y / 2.0 + 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
		else:
			draw_rect(rect.grow(-3), CaseFileData.UNKNOWN_COLOR)
			var width := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(font, Vector2((size.x - width) / 2.0, size.y / 2.0 + 5.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.4, 0.34))
		draw_rect(rect, CaseFile.PAPER_EDGE, false, 1.0)
		var count := int(cell.get("count", 0))
		if known and count > 1 and cell.get("badge", false):
			var badge := "x%d" % count
			var badge_width := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var tag := Rect2(size.x - badge_width - 4.0, size.y - 10.0, badge_width + 4.0, 10.0)
			draw_rect(tag, CaseFile.STAMP)
			draw_string(font, tag.position + Vector2(2, 8), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		if known and cell.get("use", false):
			var use_text := tr("USE")
			var use_width := font.get_string_size(use_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var use_tag := Rect2(1.0, size.y - 11.0, use_width + 4.0, 10.0)
			draw_rect(use_tag, CaseFile.PAPER)
			draw_string(font, use_tag.position + Vector2(2, 8), use_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, CaseFile.INK)
		if has_focus():
			draw_rect(rect.grow(1), MenuStyle.GOLD, false, 2.0)
		elif selected:
			draw_rect(rect.grow(1), CaseFile.INK, false, 2.0)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
			queue_redraw()
