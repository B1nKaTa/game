class_name OptionsPanel
extends CanvasLayer

# The one Options panel, opened from the title screen, the pause menu and the Waiting Room's Key
# Settings board. Four tabs: Video, Audio, Game and Input. Changes show at once but are only kept on
# OK; Esc closes without keeping them, after asking when anything changed. Defaults resets the open
# tab. Q and E switch tabs. It runs while the game is paused, as the pause menu opens it.
#
# The Input tab has two columns. The controller one says "coming" until controller support adds it;
# its bindings will live in keys.json under KeyBindings.PAD_KEY, beside the keyboard ones.

signal closed

const LAYER := 60
const AT := Vector2(30, 12)
const SIZE := Vector2(580, 336)
const ROW_HEIGHT := 16.0
const LABEL_WIDTH := 210.0
const INPUT_LABEL_WIDTH := 170.0
const KEY_WIDTH := 170.0
const NOTICE_TIME := 2.5
const HINT_WIDTH := 220.0
# The Input tab lists every action, so its rows are tighter and its text a size smaller.
const INPUT_ROW_HEIGHT := 14.0
const INPUT_FONT := 10
const WAITING_TEXT := "Press a key..."
const TABS: Array[String] = [GameSettings.VIDEO, GameSettings.AUDIO, GameSettings.GAME, GameSettings.INPUT]
const TAB_NAMES := {
	GameSettings.VIDEO: "Video",
	GameSettings.AUDIO: "Audio",
	GameSettings.GAME: "Game",
	GameSettings.INPUT: "Input",
}
const LABELS := {
	"brightness": "Brightness",
	"contrast": "Contrast",
	"gamma": "Gamma",
	"resolution": "Resolution",
	"fullscreen": "Fullscreen",
	"vsync": "Vsync",
	"confine_mouse": "Confine mouse cursor",
	"pixel_perfect": "Pixel-perfect scaling",
	"master": "Master",
	"effects": "Effects",
	"music": "Music",
	"ambience": "Ambience",
	"screen_shake": "Screen shake",
	"hit_stop": "Hit-stop",
	"vibration": "Vibration",
	"heal_at_full": "Pick up heals at full pills",
	"mouse_aim": "Mouse aim",
	"hide_minimap_in_combat": "Hide minimap during combat",
	"minimap_opacity": "Minimap opacity",
	"run_timer": "Show run timer",
	"language": "Language",
}
const LANGUAGE_NAMES := {"en": "English"}
const TAB_KEYS := {
	GameSettings.VIDEO: ["brightness", "contrast", "gamma", "resolution", "fullscreen", "vsync", "confine_mouse", "pixel_perfect"],
	GameSettings.AUDIO: ["master", "effects", "music", "ambience"],
	GameSettings.GAME: ["screen_shake", "hit_stop", "vibration", "heal_at_full", "mouse_aim", "hide_minimap_in_combat", "minimap_opacity", "run_timer", "language"],
}
# A line under a tab's rows, where something on it does not do anything yet.
const TAB_NOTES := {
	GameSettings.AUDIO: "Music and Ambience have nothing to play yet.",
	GameSettings.GAME: "Vibration works once controllers are supported.",
	GameSettings.INPUT: "Select a key and press the new one. A key in use swaps with it.",
}

var _tab: String = GameSettings.VIDEO
var _draft: GameSettings
var _keys_before := {}
var _rows: VBoxContainer
var _tab_buttons := {}
var _note: Label
var _notice: Label
var _notice_left := 0.0
var _waiting_action := ""
var _opened_frame := -1
# The frame an Esc cancelled a key change on, so the same press never also closes the panel.
var _ignore_frame := -1
var _confirm: ConfirmBox
var _done := false


func setup(tab: String = GameSettings.VIDEO) -> void:
	if TABS.has(tab):
		_tab = tab


# The Waiting Room's own Esc handling leaves this panel alone, since it answers Esc itself.
func handles_pause_key() -> bool:
	return true


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	_draft = Settings.current.duplicate_settings()
	_keys_before = KeyBindings.snapshot()
	add_child(MenuStyle.backing())
	add_child(MenuStyle.panel(AT, SIZE))
	var title := MenuStyle.label(tr("Options"), MenuStyle.TITLE_FONT, MenuStyle.GOLD)
	title.position = AT + Vector2(12, 6)
	add_child(title)
	var hint := MenuStyle.label(tr("Q / E: switch tabs"), 9, MenuStyle.DIM)
	hint.position = AT + Vector2(SIZE.x - 12 - HINT_WIDTH, 12)
	hint.size = Vector2(HINT_WIDTH, 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)
	var tabs := HBoxContainer.new()
	tabs.position = AT + Vector2(12, 30)
	tabs.add_theme_constant_override("separation", 8)
	add_child(tabs)
	for tab in TABS:
		var button := MenuStyle.button(tr(TAB_NAMES[tab]), 12)
		button.pressed.connect(_show_tab.bind(tab))
		tabs.add_child(button)
		_tab_buttons[tab] = button
	var line := ColorRect.new()
	line.color = MenuStyle.EDGE
	line.position = AT + Vector2(12, 52)
	line.size = Vector2(SIZE.x - 24, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	_rows = VBoxContainer.new()
	_rows.position = AT + Vector2(12, 58)
	_rows.add_theme_constant_override("separation", 2)
	add_child(_rows)
	_note = MenuStyle.label("", 9, MenuStyle.DIM)
	_note.position = AT + Vector2(12, SIZE.y - 44)
	add_child(_note)
	var bottom := HBoxContainer.new()
	bottom.position = AT + Vector2(12, SIZE.y - 26)
	bottom.add_theme_constant_override("separation", 10)
	add_child(bottom)
	var defaults := MenuStyle.button(tr("Defaults"))
	defaults.pressed.connect(_reset_tab)
	bottom.add_child(defaults)
	var ok := MenuStyle.button(tr("OK"))
	ok.pressed.connect(_keep_and_close)
	bottom.add_child(ok)
	var esc := MenuStyle.label(tr("Esc: close without keeping"), 9, MenuStyle.DIM)
	esc.position = AT + Vector2(SIZE.x - 12 - HINT_WIDTH, SIZE.y - 22)
	esc.size = Vector2(HINT_WIDTH, 12)
	esc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(esc)
	_notice = MenuStyle.label("", 10, MenuStyle.GOLD)
	_notice.position = AT + Vector2(200, SIZE.y - 22)
	add_child(_notice)
	_show_tab(_tab)


func _show_tab(tab: String) -> void:
	_tab = tab
	_waiting_action = ""
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.free()
	for each: String in _tab_buttons:
		var button: Button = _tab_buttons[each]
		button.add_theme_color_override("font_color", MenuStyle.GOLD if each == tab else MenuStyle.TEXT)
	_rows.add_theme_constant_override("separation", 2)
	if tab == GameSettings.INPUT:
		_build_input_rows()
	else:
		for key: String in TAB_KEYS[tab]:
			_build_row(tab, key)
	_note.text = tr(TAB_NOTES.get(tab, ""))
	var first := _first_focus()
	if first != null:
		first.grab_focus.call_deferred()


func _first_focus() -> Control:
	for row in _rows.get_children():
		for child in row.get_children():
			if child is Button or child is Slider:
				return child
	return _tab_buttons[_tab]


func _row(text: String, width := LABEL_WIDTH, tight := false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = INPUT_ROW_HEIGHT if tight else ROW_HEIGHT
	row.add_theme_constant_override("separation", 8)
	var name_label := MenuStyle.label(text, INPUT_FONT if tight else MenuStyle.FONT)
	name_label.custom_minimum_size.x = width
	row.add_child(name_label)
	_rows.add_child(row)
	return row


func _build_row(section: String, key: String) -> void:
	var row := _row(tr(LABELS[key]))
	var current: Variant = _draft.value(section, key)
	if GameSettings.is_slider(section, key):
		var span := GameSettings.range_of(section, key)
		var slider := MenuStyle.slider(span.x, span.y, current)
		var shown := MenuStyle.label(str(current), MenuStyle.FONT, MenuStyle.DIM)
		shown.custom_minimum_size.x = 30
		slider.value_changed.connect(_on_slider.bind(section, key, shown))
		row.add_child(slider)
		row.add_child(shown)
	elif current is bool:
		var toggle := MenuStyle.button(_on_off(current))
		toggle.custom_minimum_size.x = 60
		toggle.pressed.connect(_on_toggle.bind(section, key, toggle))
		row.add_child(toggle)
	else:
		var choice := MenuStyle.button(_choice_text(key, current))
		choice.custom_minimum_size.x = 150
		choice.pressed.connect(_on_choice.bind(section, key, choice, 1))
		choice.gui_input.connect(_on_choice_input.bind(section, key, choice))
		row.add_child(choice)


func _on_off(on: bool) -> String:
	return tr("On") if on else tr("Off")


func _choice_text(key: String, current: String) -> String:
	if key == "language":
		return "< %s >" % LANGUAGE_NAMES.get(current, current)
	var best := GameSettings.best_resolution(DisplayServer.screen_get_size())
	var size := Settings.window_size(_draft)
	var text := GameSettings.resolution_text(size)
	return "< %s%s >" % [text, "*" if size == best else ""]


func _choices_for(key: String) -> Array[String]:
	var list: Array[String] = []
	if key == "language":
		list.assign(GameSettings.LANGUAGES)
		return list
	for size in Settings.resolution_choices():
		list.append(GameSettings.resolution_text(size))
	return list


func _on_slider(level: float, section: String, key: String, shown: Label) -> void:
	_draft.set_value(section, key, int(level))
	shown.text = str(int(level))
	Settings.apply(_draft)


func _on_toggle(section: String, key: String, toggle: Button) -> void:
	_draft.set_value(section, key, not _draft.value(section, key))
	toggle.text = _on_off(_draft.value(section, key))
	Settings.apply(_draft)


func _on_choice(section: String, key: String, choice: Button, step: int) -> void:
	var list := _choices_for(key)
	var now: String = _draft.value(section, key)
	if key == "resolution":
		now = GameSettings.resolution_text(Settings.window_size(_draft))
	var index := maxi(list.find(now), 0)
	_draft.set_value(section, key, list[posmod(index + step, list.size())])
	choice.text = _choice_text(key, _draft.value(section, key))
	Settings.apply(_draft)


# Left and right step a choice either way while it is selected.
func _on_choice_input(event: InputEvent, section: String, key: String, choice: Button) -> void:
	if event.is_action_pressed("ui_left"):
		_on_choice(section, key, choice, -1)
		choice.accept_event()
	elif event.is_action_pressed("ui_right"):
		_on_choice(section, key, choice, 1)
		choice.accept_event()


func _build_input_rows() -> void:
	_rows.add_theme_constant_override("separation", 1)
	var header := _row(tr("Action"), INPUT_LABEL_WIDTH, true)
	header.get_child(0).add_theme_color_override("font_color", MenuStyle.DIM)
	var keyboard := MenuStyle.label(tr("Keyboard / Mouse"), INPUT_FONT, MenuStyle.DIM)
	keyboard.custom_minimum_size.x = KEY_WIDTH
	header.add_child(keyboard)
	header.add_child(MenuStyle.label(tr("Controller"), INPUT_FONT, MenuStyle.DIM))
	for entry in KeyBindings.ACTIONS:
		var action: String = entry["action"]
		var row := _row(tr(entry["label"]), INPUT_LABEL_WIDTH, true)
		var bound := tr(WAITING_TEXT) if action == _waiting_action else KeyBindings.label_for(action)
		var key_button := MenuStyle.button(bound, INPUT_FONT, true)
		key_button.custom_minimum_size.x = KEY_WIDTH
		key_button.pressed.connect(_start_waiting.bind(action))
		row.add_child(key_button)
		row.add_child(MenuStyle.label(tr("coming"), INPUT_FONT, MenuStyle.DIM))


func _start_waiting(action: String) -> void:
	_waiting_action = action
	_refresh_input_rows(action)


# Rewrites the key column in place, so the selected row keeps its highlight.
func _refresh_input_rows(waiting := "") -> void:
	var rows := _rows.get_children()
	for i in KeyBindings.ACTIONS.size():
		var action: String = KeyBindings.ACTIONS[i]["action"]
		var button: Button = rows[i + 1].get_child(1)
		button.text = tr(WAITING_TEXT) if action == waiting else KeyBindings.label_for(action)


# This runs before the buttons see the input, so the next press is taken as the new binding.
func _input(event: InputEvent) -> void:
	if _waiting_action.is_empty() or not event.is_pressed() or event.is_echo():
		return
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	if event is InputEventMouseButton and event.button_index > MOUSE_BUTTON_MIDDLE:
		return
	get_viewport().set_input_as_handled()
	var action := _waiting_action
	_waiting_action = ""
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		_ignore_frame = Engine.get_process_frames()
		_refresh_input_rows()
		return
	var swapped := KeyBindings.rebind(action, _clean_copy(event))
	if not swapped.is_empty():
		_show_notice(tr("Swapped with %s") % tr(KeyBindings.action_label(swapped)))
	_refresh_input_rows()


func _clean_copy(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		var key := InputEventKey.new()
		key.physical_keycode = event.physical_keycode
		return key
	var mouse := InputEventMouseButton.new()
	mouse.button_index = event.button_index
	return mouse


func _unhandled_input(event: InputEvent) -> void:
	if _confirm != null or not _waiting_action.is_empty():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var step := 0
	if key.physical_keycode == KEY_Q:
		step = -1
	elif key.physical_keycode == KEY_E:
		step = 1
	if step != 0:
		get_viewport().set_input_as_handled()
		_show_tab(TABS[posmod(TABS.find(_tab) + step, TABS.size())])


func _show_notice(text: String) -> void:
	_notice.text = text
	_notice_left = NOTICE_TIME


func _process(delta: float) -> void:
	if _notice_left > 0.0:
		_notice_left -= delta
		if _notice_left <= 0.0:
			_notice.text = ""
	var frame := Engine.get_process_frames()
	if _confirm != null or not _waiting_action.is_empty() or frame == _opened_frame or frame == _ignore_frame:
		return
	if Input.is_action_just_pressed("pause"):
		leave()


func _reset_tab() -> void:
	if _tab == GameSettings.INPUT:
		KeyBindings.reset_to_defaults()
	else:
		_draft.reset_section(_tab)
		Settings.apply(_draft)
	_show_tab(_tab)


func has_changes() -> bool:
	return not _draft.equals(Settings.current) or KeyBindings.snapshot() != _keys_before


func _keep_and_close() -> void:
	if _done:
		return
	Settings.commit(_draft)
	if KeyBindings.snapshot() != _keys_before and not Settings.is_quiet():
		KeyBindings.save_to()
	_finish()


# Closing without OK: asks first when anything changed, then puts everything back as it was.
func leave() -> void:
	if _done or _confirm != null:
		return
	if not has_changes():
		_finish()
		return
	_confirm = ConfirmBox.new()
	_confirm.setup(tr("Discard changes?"), PackedStringArray([tr("Discard"), tr("Keep editing")]))
	_confirm.chosen.connect(_on_discard_chosen)
	add_child(_confirm)


func _on_discard_chosen(index: int) -> void:
	_confirm = null
	# The Esc that answered the box must not also close the panel on the same frame.
	_ignore_frame = Engine.get_process_frames()
	if index != 0:
		_first_focus().grab_focus.call_deferred()
		return
	Settings.revert()
	KeyBindings.restore(_keys_before)
	_finish()


func _finish() -> void:
	_done = true
	closed.emit()
