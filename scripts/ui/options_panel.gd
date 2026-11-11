class_name OptionsPanel
extends CanvasLayer

# The one Options panel, opened from the title screen, the pause menu and the Waiting Room's Key
# Settings board. Four tabs: Video, Audio, Game and Input. Changes show at once but are only kept on
# OK; Esc closes without keeping them, after asking when anything changed. Defaults resets the open
# tab. Q and E switch tabs. It runs while the game is paused, as the pause menu opens it.
#
# The Input tab has two columns, keyboard and mouse, and controller. Pressing a cell waits for the new
# key or button; one already in use swaps with it. Both columns live in keys.json, the controller one
# under KeyBindings.PAD_KEY. Esc, a click, or WAIT_TIME without a press gives up waiting.

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
# Where the rows of settings start, from the panel's top.
const ROWS_TOP := 58.0
const WAITING_TEXT := "Press a key..."
const SHOW_TIPS_TEXT := "Show control tips again"
const TIPS_RESET_TEXT := "Tips will show again"
const PAD_WAITING_TEXT := "Press a button..."
# How long a cell waits for its new binding before giving up, so a pad alone can always back out.
const WAIT_TIME := 5.0
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
	"attack_warnings": "Attack warnings",
	"language": "Language",
}
const LANGUAGE_NAMES := {"en": "English"}
const TAB_KEYS := {
	GameSettings.VIDEO: ["brightness", "contrast", "gamma", "resolution", "fullscreen", "vsync", "confine_mouse", "pixel_perfect"],
	GameSettings.AUDIO: ["master", "effects", "music", "ambience"],
	GameSettings.GAME: ["screen_shake", "hit_stop", "vibration", "heal_at_full", "mouse_aim", "hide_minimap_in_combat", "minimap_opacity", "run_timer", "attack_warnings", "language"],
}
# A line under a tab's rows, where something on it does not do anything yet.
const TAB_NOTES := {
	GameSettings.AUDIO: "Music and Ambience have nothing to play yet.",
	GameSettings.INPUT: "Select a cell and press the new key or button; one in use swaps. The right stick aims, the D-pad walks.",
}

var _tab: String = GameSettings.VIDEO
var _draft: GameSettings
var _keys_before := {}
var _rows: VBoxContainer
var _paper: FormPaper
var _tab_buttons := {}
var _note: Label
# The tab and close hints, which name the device in use and follow a switch at every tab change.
var _tab_hint_label: Label
var _esc_hint: Label
var _notice: Label
var _notice_left := 0.0
var _waiting_action := ""
# The action whose controller cell waits for a button, and how long it still waits.
var _waiting_pad := ""
var _wait_left := 0.0
var _opened_frame := -1
# The frame an Esc cancelled a key change on, so the same press never also closes the panel.
var _ignore_frame := -1
var _confirm: ConfirmBox
var _done := false
# The On/Off buttons of the open tab by key, so F11 can update the Fullscreen one.
var _toggles := {}


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
	Settings.fullscreen_asked.connect(_toggle_fullscreen)
	add_child(MenuStyle.backing())
	# The form is ruled under each row of settings (_show_tab rules it for the tab's rows).
	_paper = MenuStyle.panel(AT, SIZE) as FormPaper
	add_child(_paper)
	var title := MenuStyle.label(tr("Options"), MenuStyle.TITLE_FONT, MenuStyle.GOLD)
	title.position = AT + Vector2(12, 6)
	add_child(title)
	var hint := MenuStyle.label(_tab_hint(), 9, MenuStyle.DIM)
	_tab_hint_label = hint
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
	_rows.position = AT + Vector2(12, ROWS_TOP)
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
	var esc := MenuStyle.label(tr("%s: close without keeping") % _back_name(), 9, MenuStyle.DIM)
	_esc_hint = esc
	esc.position = AT + Vector2(SIZE.x - 12 - HINT_WIDTH, SIZE.y - 22)
	esc.size = Vector2(HINT_WIDTH, 12)
	esc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(esc)
	_notice = MenuStyle.label("", 10, MenuStyle.GOLD)
	_notice.position = AT + Vector2(200, SIZE.y - 22)
	add_child(_notice)
	_show_tab(_tab)
	var focus := PadFocus.new()
	focus.tabs = _step_tab
	add_child(focus)


# What switches tabs on the device in use: Q and E, or the pad's shoulder buttons.
func _tab_hint() -> String:
	if not ActiveDevice.using_pad:
		return tr("Q / E: switch tabs")
	var family := ActiveDevice.family
	return tr("%s / %s: switch tabs") % [PadInput.button_name(JOY_BUTTON_LEFT_SHOULDER, family), PadInput.button_name(JOY_BUTTON_RIGHT_SHOULDER, family)]


# What closes the panel on the device in use: Esc, or the pad's B (Circle).
func _back_name() -> String:
	return PadInput.button_name(JOY_BUTTON_B, ActiveDevice.family) if ActiveDevice.using_pad else "Esc"


# Q and E, or the shoulder buttons, step through the tabs, but never while a key is awaited or a
# question is open.
func _step_tab(step: int) -> void:
	if _confirm != null or _is_waiting() or _done:
		return
	_show_tab(TABS[posmod(TABS.find(_tab) + step, TABS.size())])


func _show_tab(tab: String) -> void:
	_tab = tab
	_waiting_action = ""
	_waiting_pad = ""
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.free()
	for each: String in _tab_buttons:
		var button: Button = _tab_buttons[each]
		button.add_theme_color_override("font_color", MenuStyle.STAMP if each == tab else MenuStyle.TEXT)
	_rows.add_theme_constant_override("separation", 2)
	# A rule under every row: the Input tab's rows are tight (INPUT_ROW_HEIGHT, 1 px apart, under a
	# header row), the others ROW_HEIGHT and 2 px apart.
	if tab == GameSettings.INPUT:
		_paper.rules_from = ROWS_TOP + INPUT_ROW_HEIGHT
		_paper.rule_step = INPUT_ROW_HEIGHT + 1.0
	else:
		_paper.rules_from = ROWS_TOP + ROW_HEIGHT + 1.0
		_paper.rule_step = ROW_HEIGHT + 2.0
	_paper.queue_redraw()
	if tab == GameSettings.INPUT:
		_build_input_rows()
	else:
		for key: String in TAB_KEYS[tab]:
			_build_row(tab, key)
		if tab == GameSettings.GAME:
			_build_tips_row()
	_note.text = tr(TAB_NOTES.get(tab, ""))
	_tab_hint_label.text = _tab_hint()
	_esc_hint.text = tr("%s: close without keeping") % _back_name()
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
		_toggles[key] = toggle
	else:
		var choice := MenuStyle.button(_choice_text(key, current))
		choice.custom_minimum_size.x = 150
		choice.pressed.connect(_on_choice.bind(section, key, choice, 1))
		choice.gui_input.connect(_on_choice_input.bind(section, key, choice))
		row.add_child(choice)


# The Game tab's last row: puts the first run's control tips back for this save.
func _build_tips_row() -> void:
	var row := _row("")
	var button := MenuStyle.button(tr(SHOW_TIPS_TEXT))
	button.custom_minimum_size.x = 210
	button.disabled = Progress.data == null
	button.pressed.connect(_on_show_tips.bind(button))
	row.add_child(button)


func _on_show_tips(button: Button) -> void:
	Progress.reset_tips()
	button.text = tr(TIPS_RESET_TEXT)
	button.disabled = true


func _on_off(on: bool) -> String:
	return tr("On") if on else tr("Off")


func _choice_text(key: String, current: String) -> String:
	if key == "language":
		return "< %s >" % LANGUAGE_NAMES.get(current, current)
	var best: Vector2i = Settings.resolution_choices()[-1]
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


# F11 or Alt+Enter while the panel is open (Settings.fullscreen_asked) switches the draft's Fullscreen,
# as its toggle would, so OK keeps it and closing without OK puts the window back.
func _toggle_fullscreen() -> void:
	if _is_waiting() or _done:
		return
	_draft.set_value(GameSettings.VIDEO, "fullscreen", not _draft.value(GameSettings.VIDEO, "fullscreen"))
	var toggle: Variant = _toggles.get("fullscreen")
	if is_instance_valid(toggle):
		toggle.text = _on_off(_draft.value(GameSettings.VIDEO, "fullscreen"))
	Settings.apply(_draft)


func _exit_tree() -> void:
	if Settings.fullscreen_asked.is_connected(_toggle_fullscreen):
		Settings.fullscreen_asked.disconnect(_toggle_fullscreen)


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
		var pad_button := MenuStyle.button(KeyBindings.pad_label_for(action, ActiveDevice.family), INPUT_FONT, true)
		pad_button.custom_minimum_size.x = KEY_WIDTH
		pad_button.pressed.connect(_start_pad_waiting.bind(action))
		row.add_child(pad_button)


func _is_waiting() -> bool:
	return not _waiting_action.is_empty() or not _waiting_pad.is_empty()


func _start_waiting(action: String) -> void:
	_waiting_pad = ""
	_waiting_action = action
	_wait_left = WAIT_TIME
	_refresh_input_rows()


func _start_pad_waiting(action: String) -> void:
	_waiting_action = ""
	_waiting_pad = action
	_wait_left = WAIT_TIME
	_refresh_input_rows()


func _stop_waiting() -> void:
	_waiting_action = ""
	_waiting_pad = ""
	_refresh_input_rows()


# Rewrites both columns in place, so the selected cell keeps its highlight.
func _refresh_input_rows() -> void:
	if _tab != GameSettings.INPUT:
		return
	var rows := _rows.get_children()
	for i in KeyBindings.ACTIONS.size():
		var action: String = KeyBindings.ACTIONS[i]["action"]
		var key_button: Button = rows[i + 1].get_child(1)
		key_button.text = tr(WAITING_TEXT) if action == _waiting_action else KeyBindings.label_for(action)
		var pad_button: Button = rows[i + 1].get_child(2)
		pad_button.text = tr(PAD_WAITING_TEXT) if action == _waiting_pad else KeyBindings.pad_label_for(action, ActiveDevice.family)


# This runs before the buttons see the input, so the next press is taken as the new binding.
func _input(event: InputEvent) -> void:
	if not _waiting_pad.is_empty():
		_take_pad_input(event)
		return
	if _waiting_action.is_empty() or not event.is_pressed() or event.is_echo():
		return
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	if event is InputEventMouseButton and event.button_index > MOUSE_BUTTON_MIDDLE:
		return
	get_viewport().set_input_as_handled()
	# The fullscreen keys are kept for the window: the cell goes on waiting for another key.
	if GameSettings.is_window_key(event):
		return
	var action := _waiting_action
	_waiting_action = ""
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		_ignore_frame = Engine.get_process_frames()
		_refresh_input_rows()
		return
	_bind(action, _clean_copy(event))


# A controller cell takes the next pad button, trigger or stick push. The D-pad never binds, and a key
# or a click gives up, Esc without closing the panel.
func _take_pad_input(event: InputEvent) -> void:
	if PadInput.is_pad(event):
		get_viewport().set_input_as_handled()
		var taken := PadInput.capture(event)
		if taken == null:
			return
		var action := _waiting_pad
		_waiting_pad = ""
		_bind(action, taken)
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_ignore_frame = Engine.get_process_frames()
		_stop_waiting()


func _bind(action: String, event: InputEvent) -> void:
	var swapped := KeyBindings.rebind(action, event)
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
	if _confirm != null or _is_waiting():
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
		_step_tab(step)


func _show_notice(text: String) -> void:
	_notice.text = text
	_notice_left = NOTICE_TIME


func _process(delta: float) -> void:
	if _notice_left > 0.0:
		_notice_left -= delta
		if _notice_left <= 0.0:
			_notice.text = ""
	if _is_waiting():
		_wait_left -= delta
		if _wait_left <= 0.0:
			_stop_waiting()
		return
	var frame := Engine.get_process_frames()
	if _confirm != null or frame == _opened_frame or frame == _ignore_frame:
		return
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed(PadInput.BACK_ACTION):
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
