extends Node2D

# The title screen, where the game opens after the boot scene: the afterlife's waiting room, animated
# (TitleRoom), with the game's name on a brass plaque (TitleBrand), the tagline under it, and the menu
# as paper tickets on the strip from the TAKE 1 machine (TitleMenu, TicketButton). Moving through the
# menu slides a ticket out; choosing one tears it off, then its action runs. The version is bottom left
# and the build id (BuildInfo) bottom right. Seated Harold wears what the current slot's save has him
# wear (SeatedLook), read only. The full loop (--smoke) never comes here. The dev keys (F3, F5, F6) do
# nothing here; they work in the Waiting Room.

const VERSION_SETTING := "application/config/version"
const LABELS := TitleMenu.LABELS
const TAGLINE_Y := 110.0

var _ui: CanvasLayer
var _menu: Control
var _overlay: CanvasLayer
var _overlay_closed_frame := -1
var _focus_id := ""
var _tearing: TicketButton


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicPlayer.play(MusicRules.title())
	# Back from a run, the bars beside a wide picture lose the last area's frame.
	SideBars.reset()
	var room := TitleRoom.new()
	room.set_look(SeatedLook.from_worn(_worn(), CosmeticDef.all()))
	add_child(room)
	_ui = CanvasLayer.new()
	add_child(_ui)
	var tagline := Label.new()
	tagline.text = tr(TitleBrand.TAGLINE)
	HudStyle.style_label(tagline, HudStyle.SMALL, HudStyle.DIM_TEXT)
	tagline.position = Vector2(0, TAGLINE_Y)
	tagline.custom_minimum_size.x = GameSettings.VIEW.x
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(tagline)
	_menu = Control.new()
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_menu)
	var version := Label.new()
	version.text = "v%s" % str(ProjectSettings.get_setting(VERSION_SETTING, "0.5.0"))
	HudStyle.style_label(version, HudStyle.SMALL, HudStyle.DIM_TEXT)
	version.position = Vector2(HudStyle.BUILD_MARGIN, GameSettings.VIEW.y - 16)
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(version)
	_ui.add_child(HudStyle.build_label())
	_build_menu()
	_ui.add_child(PadFocus.new())


# What the current slot has Harold wear, read from its save as the game reads it; nothing on a fresh
# install or when no save could be read.
func _worn() -> Dictionary:
	if Progress.data == null:
		return {}
	return Progress.data.cosmetics_worn


func _build_menu() -> void:
	for child in _menu.get_children():
		_menu.remove_child(child)
		child.free()
	_tearing = null
	var focus: Button = null
	var ids := TitleMenu.ids(SaveSlots.slots_with_progress(Progress.ROOT))
	for index in ids.size():
		var id := ids[index]
		var ticket := TicketButton.new()
		ticket.setup(id, index, tr(TitleMenu.label(id)))
		ticket.pressed.connect(_tear.bind(ticket))
		_menu.add_child(ticket)
		if focus == null or id == _focus_id:
			focus = ticket
	focus.grab_focus.call_deferred()


# W and S move through the menu as well as the arrows.
func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null or _tearing != null:
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


# The chosen ticket tears off the strip; its action runs once it has fallen away.
func _tear(ticket: TicketButton) -> void:
	if _tearing != null or _overlay != null or Engine.get_process_frames() == _overlay_closed_frame:
		return
	_tearing = ticket
	_focus_id = ticket.menu_id
	ticket.tear()
	get_tree().create_timer(TitleMenu.TEAR_TIME).timeout.connect(_torn.bind(ticket.menu_id))


func _torn(id: String) -> void:
	if not is_inside_tree():
		return
	_choose(id)
	# Back on the menu (an overlay closed, or nothing opened), the strip is whole again.
	if _overlay == null and id != "quit":
		_build_menu()


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
		if child is TicketButton:
			ids.append((child as TicketButton).menu_id)
	return ids
