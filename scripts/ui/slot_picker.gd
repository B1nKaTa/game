class_name SlotPicker
extends CanvasLayer

# The three save slots as cards, for New Game or Load Game. Each card shows what the slot holds, and a
# run in progress. Starting a new game over a slot with progress, deleting a slot, and loading a slot
# whose run was interrupted each ask first.

signal picked(slot: int, action: String)
signal closed

const MODE_NEW := "new"
const MODE_LOAD := "load"
const ACTION_NEW := "new"
const ACTION_LOAD := "load"
const ACTION_RESUME := "resume"
const ACTION_ABANDON := "abandon"
const LAYER := 55
const CARD_TOP := 64.0
const CARD_SIZE := Vector2(184, 228)
const CARD_GAP := 14.0

var _mode := MODE_NEW
var _cards: HBoxContainer
var _confirm: ConfirmBox
var _opened_frame := -1
var _ignore_frame := -1
var _back: Button
var _done := false


func setup(mode: String) -> void:
	_mode = mode


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	add_child(MenuStyle.backing())
	var title := MenuStyle.label(tr("New Game") if _mode == MODE_NEW else tr("Load Game"), MenuStyle.TITLE_FONT + 2, MenuStyle.GOLD)
	title.position = Vector2(0, 22)
	title.custom_minimum_size.x = GameSettings.VIEW.x
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", int(CARD_GAP))
	var width := CARD_SIZE.x * SaveSlots.COUNT + CARD_GAP * (SaveSlots.COUNT - 1)
	_cards.position = Vector2((GameSettings.VIEW.x - width) / 2.0, CARD_TOP)
	add_child(_cards)
	_back = MenuStyle.button(tr("Back"), 12)
	_back.position = Vector2(24, GameSettings.VIEW.y - 34)
	_back.pressed.connect(_close)
	add_child(_back)
	_build_cards()


func _build_cards() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.free()
	var first: Button = null
	for slot in range(1, SaveSlots.COUNT + 1):
		var button := _build_card(slot)
		if first == null and button != null and not button.disabled:
			first = button
	(first if first != null else _back).grab_focus.call_deferred()


func _build_card(slot: int) -> Button:
	var summary: Dictionary = Progress.slot_summary(slot)
	var empty: bool = summary["empty"]
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", MenuStyle.box())
	_cards.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	card.add_child(column)
	column.add_child(MenuStyle.label(tr("Slot %d") % slot, 14, MenuStyle.GOLD))
	if empty:
		column.add_child(MenuStyle.label(tr("Empty"), MenuStyle.FONT, MenuStyle.DIM))
	else:
		for line in [
			tr("Floors cleared: %d") % summary["floors"],
			tr("Deepest floor: %d") % summary["deepest"],
			tr("Pension: %d") % summary["pension"],
			tr("Runs played: %d") % summary["runs"],
			tr("Last played: %s") % summary["date"],
		]:
			column.add_child(MenuStyle.label(line, 10))
		if summary["run_floor"] > 0:
			column.add_child(MenuStyle.label(tr("Run in progress: Floor %d") % summary["run_floor"], 10, MenuStyle.GOLD))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var main := MenuStyle.button(_main_text(empty), 12)
	main.disabled = _mode == MODE_LOAD and empty
	main.pressed.connect(_on_main.bind(slot, summary))
	column.add_child(main)
	if not empty:
		var delete := MenuStyle.button(tr("Delete slot"), 10)
		delete.pressed.connect(_on_delete.bind(slot))
		column.add_child(delete)
	return main


func _main_text(empty: bool) -> String:
	if _mode == MODE_LOAD:
		return tr("Load") if not empty else tr("Empty")
	return tr("Start here") if empty else tr("Overwrite")


func _on_main(slot: int, summary: Dictionary) -> void:
	if _confirm != null:
		return
	if _mode == MODE_NEW:
		if summary["empty"]:
			_pick(slot, ACTION_NEW)
		else:
			_ask(tr("Overwrite slot %d? This can't be undone.") % slot, PackedStringArray([tr("Overwrite"), tr("Cancel")]), _answer_overwrite.bind(slot))
		return
	if summary["run_floor"] > 0:
		_ask(tr("Abandon your run on Floor %d?") % summary["run_floor"], PackedStringArray([tr("Resume run"), tr("Abandon run"), tr("Cancel")]), _answer_abandon.bind(slot))
		return
	_pick(slot, ACTION_LOAD)


func _answer_overwrite(index: int, slot: int) -> void:
	if index == 0:
		_pick(slot, ACTION_NEW)


# Resuming is offered here too, beside abandoning, so a run in another slot is never lost by mistake.
func _answer_abandon(index: int, slot: int) -> void:
	if index == 0:
		_pick(slot, ACTION_RESUME)
	elif index == 1:
		_pick(slot, ACTION_ABANDON)


func _on_delete(slot: int) -> void:
	if _confirm != null:
		return
	_ask(tr("Delete slot %d? This can't be undone.") % slot, PackedStringArray([tr("Delete"), tr("Cancel")]), _answer_delete.bind(slot))


func _answer_delete(index: int, slot: int) -> void:
	if index == 0:
		Progress.clear_slot(slot)


func _ask(question: String, choices: PackedStringArray, answer: Callable) -> void:
	_confirm = ConfirmBox.new()
	_confirm.setup(question, choices)
	_confirm.chosen.connect(_on_answer.bind(answer))
	add_child(_confirm)


func _on_answer(index: int, answer: Callable) -> void:
	_confirm = null
	_ignore_frame = Engine.get_process_frames()
	answer.call(index)
	if not _done and is_inside_tree():
		_build_cards()


func _process(_delta: float) -> void:
	var frame := Engine.get_process_frames()
	if _confirm != null or frame == _opened_frame or frame == _ignore_frame:
		return
	if Input.is_action_just_pressed("pause"):
		_close()


func _pick(slot: int, action: String) -> void:
	if _done:
		return
	_done = true
	picked.emit(slot, action)


func _close() -> void:
	if _done:
		return
	_done = true
	closed.emit()
