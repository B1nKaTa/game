class_name TesterPanel
extends CanvasLayer

# The tester panel, for playtest builds only and removed before release. In a run, F9
# (DevStart.CHEAT_KEY) opens it when DevStart.cheats_available(); FloorScene makes it, and nothing
# else does. It pauses the game while open, as the case file does, on the case file's paper. The
# arrows or the D-pad move, Enter or A uses, F9, Esc or B (Circle) close; the mouse works too.
# - God mode: no hit takes a pill while it is on (Health.god_mode).
# - +99 Slips and +99 Thermoses: Slips are the game's keys and Thermoses its bombs, added one at a time
#   through the adders a pickup uses, so never past RunState.MAX_CONSUMABLE.
# - +999 Pension: paid as an item pays (EffectContext.pay), so it lands where a coin's would.
# - Give item: any pool item, through RunState.add_item as a picked-up item, so its effect, any pet it
#   brings and the HUD all follow. One already held is refused, as its pickup is. Give all items gives
#   every passive item not held; actives are left out, since each would swap the last one out.
# - Give potion: any run potion, into the potion slot, replacing the one carried.
# A press that would change nothing (a count at its cap, an item held) is no cheat. The first real
# cheat of a run that is not a tester run yet asks once (CONFIRM, No first); only Yes goes on. Every
# cheat then reports cheat_used BEFORE it changes anything, and the scene makes the run a tester run on
# it (DevStart.mark_tester_run), so nothing the cheat itself pays or records reaches the real save.

signal closed
signal cheat_used

const LAYER := 56
const SHEET := Rect2(96, 22, 448, 316)
const CONFIRM_SHEET := Rect2(170, 128, 300, 96)
const PAD := 10.0
# The slip ignores presses for this long after it opens.
const SLIP_DEAD_SECONDS := 0.25
const LEFT_WIDTH := 168.0
const COLUMN_GAP := 12.0
const CONTENT_TOP := 78.0
const FOOT_HEIGHT := 14.0
const BUTTON_HEIGHT := 13.0
const FONT := 9
const HEAD_FONT := 12
const PENSION_AMOUNT := 999
const TITLE := "TESTER PANEL"
const NOTE := "Playtest builds only. Any cheat makes this a tester run: nothing it earns, clears or finds is saved."
const HINT := "Arrows: move    Enter: use    F9 / Esc: close"
const PAD_HINT := "%s: use    %s: close"
const CONFIRM := "Cheats turn this into a tester run. It will not be saved and earns nothing. Continue?"
const NO := "No"
const YES := "Yes"
const GOD_ON := "God mode: ON"
const GOD_OFF := "God mode: off"
const SLIPS := "+99 Slips (keys)"
const THERMOSES := "+99 Thermoses (bombs)"
const PENSION := "+999 Pension"
const GIVE_ALL := "Give all items"
const ITEMS_HEAD := "GIVE ITEM"
const POTIONS_HEAD := "GIVE POTION"
const HELD_MARK := "%s  (held)"
const ACTIVE_MARK := "%s  (active)"
const READY := "Pick a cheat."
const KEPT := "No cheat used."
const GOD_SAID := "God mode is %s."
const ON_WORD := "on"
const OFF_WORD := "off"
const COUNTS := "Slips %d, Thermoses %d."
const SLIPS_FULL := "Slips are full already."
const THERMOSES_FULL := "Thermoses are full already."
const PAID := "+%d Pension."
const NO_BANK := "This run has no Pension to pay into."
const GIVEN := "Given: %s"
const HELD_ALREADY := "Already held: %s"
const GAVE_ALL := "Given %d items."
const NOTHING_TO_GIVE := "Every passive item is held already."
const POTION_GIVEN := "Potion: %s"
const POTION_HELD := "Already carrying: %s"

# True once the run is a tester run (or a dev run from the start), so no question is asked. The scene
# sets it from Progress.is_dev_run() as it opens the panel.
var tester_run := false
var _run: RunState
var _items: Array[ItemDef] = []
var _potions: Array[PotionDef] = []
var _opened_frame := -1
var _was_paused := false
var _done := false
var _god_button: Button
var _status: Label
var _hint: Label
# Each item's button, by id, so its "held" mark follows what is given.
var _item_buttons := {}
# The cheat waiting on the question's answer, and the question while it shows.
var _pending := Callable()
var _confirm: CanvasLayer
var _confirm_opened_msec := 0


# items: every pool item (Content.items()); potions: every run potion (Content.run_potions()).
func setup(run: RunState, items: Array[ItemDef], potions: Array[PotionDef]) -> void:
	_run = run
	_items = items.duplicate()
	_items.sort_custom(_by_name)
	_potions = potions.duplicate()
	_potions.sort_custom(_potion_by_name)


static func _by_name(a: ItemDef, b: ItemDef) -> bool:
	return a.display_name.to_lower() < b.display_name.to_lower()


static func _potion_by_name(a: PotionDef, b: PotionDef) -> bool:
	return a.display_name.to_lower() < b.display_name.to_lower()


func item_list() -> Array[ItemDef]:
	return _items


func potion_list() -> Array[PotionDef]:
	return _potions


# What Give all items gives: every passive item of items not held already.
static func give_all_list(items: Array[ItemDef], run: RunState) -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for item in items:
		if not item.is_active() and not run.has_item(item.id):
			list.append(item)
	return list


# --- the actions: each returns whether it changed the run now ---

func god_mode() -> bool:
	return _run.health.god_mode


func set_god_mode(on: bool) -> bool:
	if on == god_mode():
		_say(tr(GOD_SAID) % tr(ON_WORD if on else OFF_WORD))
		return false
	return _cheat(_apply_god.bind(on))


func add_slips() -> bool:
	if not _run.can_add_key():
		_say(tr(SLIPS_FULL))
		return false
	return _cheat(_apply_slips)


func add_thermoses() -> bool:
	if not _run.can_add_bomb():
		_say(tr(THERMOSES_FULL))
		return false
	return _cheat(_apply_thermoses)


func add_pension() -> bool:
	if not _run.effects.ctx.pay_pension.is_valid():
		_say(tr(NO_BANK))
		return false
	return _cheat(_apply_pension)


# Refused, as its pickup is, while he holds it already.
func give_item(item: ItemDef) -> bool:
	if item == null:
		return false
	if _run.has_item(item.id):
		_say(tr(HELD_ALREADY) % item.display_name)
		return false
	return _cheat(_apply_item.bind(item))


# Returns how many were given now.
func give_all(items: Array[ItemDef]) -> int:
	var list := give_all_list(items, _run)
	if list.is_empty():
		_say(tr(NOTHING_TO_GIVE))
		return 0
	return list.size() if _cheat(_apply_all.bind(list)) else 0


func give_potion(def: PotionDef) -> bool:
	if def == null:
		return false
	if _run.potion == def:
		_say(tr(POTION_HELD) % def.display_name)
		return false
	return _cheat(_apply_potion.bind(def))


# Whether the question is up, waiting on answer().
func asking() -> bool:
	return _pending.is_valid()


# The question's answer: Yes runs the waiting cheat, No drops it and changes nothing.
func answer(yes: bool) -> void:
	var waiting := _pending
	_pending = Callable()
	if _confirm != null:
		_confirm.queue_free()
		_confirm = null
	if not yes or not waiting.is_valid():
		_say(tr(KEPT))
		return
	tester_run = true
	_run_cheat(waiting)


# A cheat that would change something: at once in a tester run, else after the question.
func _cheat(apply: Callable) -> bool:
	if not tester_run:
		_pending = apply
		if is_inside_tree():
			_show_confirm()
		return false
	_run_cheat(apply)
	return true


# The run becomes a tester run before the cheat touches it.
func _run_cheat(apply: Callable) -> void:
	cheat_used.emit()
	apply.call()


func _apply_god(on: bool) -> void:
	_run.health.god_mode = on
	_say(tr(GOD_SAID) % tr(ON_WORD if on else OFF_WORD))
	_refresh_god()


func _apply_slips() -> void:
	for i in RunState.MAX_CONSUMABLE:
		_run.add_key()
	_say_counts()


func _apply_thermoses() -> void:
	for i in RunState.MAX_CONSUMABLE:
		_run.add_bomb()
	_say_counts()


func _apply_pension() -> void:
	_run.effects.ctx.pay(PENSION_AMOUNT)
	_say(tr(PAID) % PENSION_AMOUNT)


func _apply_item(item: ItemDef) -> void:
	_run.add_item(item)
	_say(tr(GIVEN) % item.display_name)
	_refresh_items()


func _apply_all(list: Array[ItemDef]) -> void:
	for item in list:
		_run.add_item(item)
	_say(tr(GAVE_ALL) % list.size())
	_refresh_items()


func _apply_potion(def: PotionDef) -> void:
	_run.swap_potion(def)
	_say(tr(POTION_GIVEN) % def.display_name)


# --- the paper ---

func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	# Through the main loop, so the panel pauses the game even while it is still being added.
	var tree := Engine.get_main_loop() as SceneTree
	_was_paused = tree.paused
	tree.paused = true
	add_child(MenuStyle.backing(CaseFile.DESK))
	var sheet := Panel.new()
	sheet.position = SHEET.position
	sheet.size = SHEET.size
	sheet.add_theme_stylebox_override("panel", _box(CaseFile.PAPER, CaseFile.MANILA_EDGE, 2))
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sheet)
	var inner := SHEET.grow(-PAD)
	var title := _label(tr(TITLE), HEAD_FONT, CaseFile.STAMP)
	title.position = inner.position
	add_child(title)
	_add_rule(inner.position + Vector2(0, 16), inner.size.x)
	# A plain parent never sizes a wrapping label, so the note sits in a column of the sheet's width.
	var column := VBoxContainer.new()
	column.position = inner.position + Vector2(0, 21)
	column.size = Vector2(inner.size.x, 0)
	add_child(column)
	var note := _label(tr(NOTE), 8, CaseFile.INK_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = inner.size.x
	column.add_child(note)
	var bottom := SHEET.end.y - PAD - FOOT_HEIGHT
	_build_actions(Rect2(inner.position.x, SHEET.position.y + CONTENT_TOP, LEFT_WIDTH, bottom - SHEET.position.y - CONTENT_TOP - 4.0))
	var right_x := inner.position.x + LEFT_WIDTH + COLUMN_GAP
	_build_items(Rect2(right_x, SHEET.position.y + CONTENT_TOP, inner.end.x - right_x, bottom - SHEET.position.y - CONTENT_TOP - 4.0))
	_status = _label(tr(READY), FONT, CaseFile.STAMP)
	_status.position = Vector2(inner.position.x, bottom)
	_status.size = Vector2(inner.size.x * 0.5, FOOT_HEIGHT)
	_status.clip_text = true
	add_child(_status)
	_hint = _label("", 8, CaseFile.INK)
	_hint.position = Vector2(inner.position.x + inner.size.x * 0.5, bottom)
	_hint.size = Vector2(inner.size.x * 0.5, FOOT_HEIGHT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_hint)
	_refresh_god()
	_refresh_items()
	add_child(PadFocus.new())


func _build_actions(area: Rect2) -> void:
	var box := VBoxContainer.new()
	box.position = area.position
	box.size = Vector2(area.size.x, 0)
	box.add_theme_constant_override("separation", 2)
	add_child(box)
	_god_button = _ink_button("", area.size.x)
	_god_button.pressed.connect(_on_god_pressed)
	box.add_child(_god_button)
	var slips := _ink_button(tr(SLIPS), area.size.x)
	slips.pressed.connect(add_slips)
	box.add_child(slips)
	var thermoses := _ink_button(tr(THERMOSES), area.size.x)
	thermoses.pressed.connect(add_thermoses)
	box.add_child(thermoses)
	var pension := _ink_button(tr(PENSION), area.size.x)
	pension.pressed.connect(add_pension)
	box.add_child(pension)
	var all := _ink_button(tr(GIVE_ALL), area.size.x)
	all.pressed.connect(_on_give_all_pressed)
	box.add_child(all)
	var head_y := area.position.y + box.get_child_count() * (BUTTON_HEIGHT + 2.0) + 8.0
	_add_head(tr(POTIONS_HEAD), Vector2(area.position.x, head_y), area.size.x)
	var list := _scroll_list(Rect2(area.position.x, head_y + 20.0, area.size.x, area.end.y - head_y - 20.0))
	for def in _potions:
		var button := _ink_button(def.display_name, area.size.x - 12.0)
		button.pressed.connect(give_potion.bind(def))
		list.add_child(button)


func _build_items(area: Rect2) -> void:
	_add_head(tr(ITEMS_HEAD), area.position, area.size.x)
	var list := _scroll_list(Rect2(area.position.x, area.position.y + 20.0, area.size.x, area.size.y - 20.0))
	for item in _items:
		var button := _ink_button(item.display_name, area.size.x - 12.0)
		button.pressed.connect(_on_item_pressed.bind(item))
		list.add_child(button)
		_item_buttons[item.id] = button


# The question, on a slip of the same paper over the panel, in a layer of its own so the panel's
# PadFocus leaves it alone. No has the focus, and Esc, B or F9 answer No.
func _show_confirm() -> void:
	if _confirm != null:
		return
	_confirm = CanvasLayer.new()
	_confirm.layer = LAYER + 1
	add_child(_confirm)
	_confirm.add_child(MenuStyle.backing(MenuStyle.SHADE))
	var sheet := Panel.new()
	sheet.position = CONFIRM_SHEET.position
	sheet.size = CONFIRM_SHEET.size
	sheet.add_theme_stylebox_override("panel", _box(CaseFile.PAPER, CaseFile.STAMP, 2))
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm.add_child(sheet)
	var inner := CONFIRM_SHEET.grow(-PAD)
	var column := VBoxContainer.new()
	column.position = inner.position
	column.size = Vector2(inner.size.x, 0)
	_confirm.add_child(column)
	var question := _label(tr(CONFIRM), FONT, CaseFile.INK)
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.custom_minimum_size.x = inner.size.x
	column.add_child(question)
	var no := _ink_button(tr(NO), 60.0)
	no.alignment = HORIZONTAL_ALIGNMENT_CENTER
	no.position = Vector2(inner.position.x + inner.size.x / 2.0 - 70.0, inner.end.y - BUTTON_HEIGHT)
	no.pressed.connect(press_slip.bind(false))
	no.mouse_entered.disconnect(no.grab_focus)
	_confirm.add_child(no)
	var yes := _ink_button(tr(YES), 60.0)
	yes.alignment = HORIZONTAL_ALIGNMENT_CENTER
	yes.position = Vector2(inner.position.x + inner.size.x / 2.0 + 10.0, inner.end.y - BUTTON_HEIGHT)
	yes.pressed.connect(press_slip.bind(true))
	yes.mouse_entered.disconnect(yes.grab_focus)
	_confirm.add_child(yes)
	if is_inside_tree():
		no.grab_focus.call_deferred()
	_confirm.add_child(PadFocus.new())
	_confirm_opened_msec = Time.get_ticks_msec()


# A press on the slip's buttons (a click, or Enter on the focused one). For the first SLIP_DEAD_SECONDS
# it does nothing, so the second click of a double-click on a list row cannot answer it.
func press_slip(yes: bool) -> void:
	if _confirm == null:
		return
	if float(Time.get_ticks_msec() - _confirm_opened_msec) / 1000.0 < SLIP_DEAD_SECONDS:
		return
	answer(yes)


func confirm_layer() -> CanvasLayer:
	return _confirm


func _on_god_pressed() -> void:
	set_god_mode(not god_mode())


func _on_give_all_pressed() -> void:
	give_all(_items)


func _on_item_pressed(item: ItemDef) -> void:
	give_item(item)


func _process(_delta: float) -> void:
	if _hint != null:
		_hint.text = hint_text(ActiveDevice.using_pad, ActiveDevice.family)


static func hint_text(pad: bool, family: String) -> String:
	if not pad:
		return HINT
	return PAD_HINT % [PadInput.button_name(JOY_BUTTON_A, family), PadInput.button_name(JOY_BUTTON_B, family)]


func _input(event: InputEvent) -> void:
	if _done or Engine.get_process_frames() == _opened_frame:
		return
	var key := event as InputEventKey
	var cheat_key := key != null and key.pressed and not key.echo and key.physical_keycode == DevStart.CHEAT_KEY
	if cheat_key or event.is_action_pressed("pause") or event.is_action_pressed(PadInput.BACK_ACTION):
		get_viewport().set_input_as_handled()
		# Backing out of the question answers No and leaves the panel open.
		if asking():
			answer(false)
		else:
			close()


func _exit_tree() -> void:
	(Engine.get_main_loop() as SceneTree).paused = _was_paused


func close() -> void:
	if _done:
		return
	_done = true
	closed.emit()


func handles_pause_key() -> bool:
	return true


func _say(text: String) -> void:
	if _status != null:
		_status.text = text


func _say_counts() -> void:
	_say(tr(COUNTS) % [_run.keys, _run.bombs])


func _refresh_god() -> void:
	if _god_button != null:
		_god_button.text = tr(GOD_ON if god_mode() else GOD_OFF)


func _refresh_items() -> void:
	for item in _items:
		var button: Button = _item_buttons.get(item.id)
		if button == null:
			continue
		var text := item.display_name
		if _run.has_item(item.id):
			text = tr(HELD_MARK) % text
		elif item.is_active():
			text = tr(ACTIVE_MARK) % text
		button.text = text


# --- building blocks, in the case file's look ---

func _scroll_list(area: Rect2) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.position = area.position
	scroll.size = area.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = area.size.x - 10.0
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	return list


func _add_head(text: String, at: Vector2, width: float) -> void:
	var head := _label(text, HEAD_FONT, CaseFile.INK)
	head.position = at
	add_child(head)
	_add_rule(at + Vector2(0, 16), width)


func _add_rule(at: Vector2, width: float) -> void:
	var rule := ColorRect.new()
	rule.color = CaseFile.PAPER_EDGE
	rule.position = at
	rule.size = Vector2(width, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)


func _ink_button(text: String, width: float) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.custom_minimum_size = Vector2(width, BUTTON_HEIGHT)
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
		button.add_theme_color_override(state, CaseFile.INK)
	button.mouse_entered.connect(button.grab_focus)
	return button


static func _label(text: String, font_size: int, color: Color) -> Label:
	return MenuStyle.label(text, font_size, color)


static func _box(color: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(width)
	return style
