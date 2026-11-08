extends Node2D

# The title screen, where the game opens after the boot scene: the Waiting Room's queue drawn in code,
# the game's name above it, the menu bottom left, the version under it and the build id (BuildInfo) bottom right. The full loop (--smoke)
# never comes here. The dev keys (F3, F5, F6) do nothing here; they work in the Waiting Room.

const MENU_AT := Vector2(26, 198)
const MENU_WIDTH := 150.0
const MENU_FONT := 13
const VERSION_SETTING := "application/config/version"
const LABELS := {
	"continue": "Continue",
	"new": "New Game",
	"load": "Load Game",
	"options": "Options",
	"credits": "Credits",
	"quit": "Quit Game",
}

var _ui: CanvasLayer
var _menu: VBoxContainer
var _overlay: CanvasLayer
var _overlay_closed_frame := -1
var _focus_id := ""


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicPlayer.play(MusicRules.title())
	# Back from a run, the bars beside a wide picture lose the last area's frame.
	SideBars.reset()
	add_child(TitleSceneArt.new())
	_ui = CanvasLayer.new()
	add_child(_ui)
	var title := MenuStyle.label(tr("GRANDPA"), 44, MenuStyle.GOLD)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	title.position = Vector2(0, 30)
	title.custom_minimum_size.x = GameSettings.VIEW.x
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(title)
	var subtitle := MenuStyle.label(tr("Please take a number."), 11, MenuStyle.DIM)
	subtitle.position = Vector2(0, 86)
	subtitle.custom_minimum_size.x = GameSettings.VIEW.x
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(subtitle)
	var back := PanelContainer.new()
	back.add_theme_stylebox_override("panel", MenuStyle.box(Color(0.06, 0.04, 0.08, 0.85)))
	back.position = MENU_AT - Vector2(6, 6)
	_ui.add_child(back)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 1)
	_menu.custom_minimum_size.x = MENU_WIDTH
	back.add_child(_menu)
	var version := MenuStyle.label("v%s" % str(ProjectSettings.get_setting(VERSION_SETTING, "0.5.0")), 9, MenuStyle.DIM)
	version.position = Vector2(MENU_AT.x, GameSettings.VIEW.y - 16)
	_ui.add_child(version)
	_ui.add_child(HudStyle.build_label())
	_build_menu()
	_ui.add_child(PadFocus.new())


func _build_menu() -> void:
	for child in _menu.get_children():
		_menu.remove_child(child)
		child.free()
	var focus: Button = null
	for id in SaveSlots.menu_items(SaveSlots.slots_with_progress(Progress.ROOT)):
		var button := MenuStyle.button(tr(LABELS[id]), MENU_FONT)
		button.pressed.connect(_choose.bind(id))
		_menu.add_child(button)
		if focus == null or id == _focus_id:
			focus = button
	focus.grab_focus.call_deferred()


# W and S move through the menu as well as the arrows.
func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	var next: Control = null
	if key.physical_keycode == KEY_W:
		next = focused.find_prev_valid_focus()
	elif key.physical_keycode == KEY_S:
		next = focused.find_next_valid_focus()
	if next != null:
		next.grab_focus()
		get_viewport().set_input_as_handled()


func _choose(id: String) -> void:
	if _overlay != null or Engine.get_process_frames() == _overlay_closed_frame:
		return
	_focus_id = id
	match id:
		"continue":
			Game.continue_game()
		"new":
			var picker := SlotPicker.new()
			picker.setup(SlotPicker.MODE_NEW)
			picker.picked.connect(_on_slot_picked)
			_show(picker)
		"load":
			var picker := SlotPicker.new()
			picker.setup(SlotPicker.MODE_LOAD)
			picker.picked.connect(_on_slot_picked)
			_show(picker)
		"options":
			_show(OptionsPanel.new())
		"credits":
			_show(CreditsCard.new())
		"quit":
			get_tree().quit()


func _show(overlay: CanvasLayer) -> void:
	_overlay = overlay
	overlay.connect("closed", _close_overlay)
	add_child(overlay)


func _close_overlay() -> void:
	if _overlay == null:
		return
	_overlay.queue_free()
	_overlay = null
	_overlay_closed_frame = Engine.get_process_frames()
	_build_menu()


func _on_slot_picked(slot: int, action: String) -> void:
	match action:
		SlotPicker.ACTION_NEW:
			Game.new_game(slot)
		SlotPicker.ACTION_LOAD:
			Game.load_game(slot)
		SlotPicker.ACTION_RESUME:
			Game.resume_slot(slot)
		SlotPicker.ACTION_ABANDON:
			Game.abandon_and_load(slot)


func debug_menu_ids() -> Array[String]:
	var ids: Array[String] = []
	for child in _menu.get_children():
		for id: String in LABELS:
			if tr(LABELS[id]) == child.text:
				ids.append(id)
	return ids
