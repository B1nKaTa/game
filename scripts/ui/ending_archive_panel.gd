class_name EndingArchivePanel
extends CanvasLayer

# The Executive Suite's filing cabinet: one row per ending (EndingRules.archive_row), a found one with
# a Replay button. Replay plays the scene over the panel, skippable at once, and the panel comes back
# afterwards, not the Waiting Room's arrival. A controller drives it as every panel: the D-pad moves
# between Replay and Leave, A presses, and B (or Esc) leaves, or ends a replay and shows the files again.

signal closed

const PANEL_POSITION := Vector2(16, 12)
const PANEL_SIZE := Vector2(608, 0)
const PANEL_BACK := Color(0.09, 0.07, 0.11)
const PANEL_EDGE := Color("625e6f")
const ROW_FONT := 10
const ROW_WIDTH := 520.0
const FOUND_COLOR := Color("ece9e0")
const MISSING_COLOR := Color(0.62, 0.6, 0.55)
const COUNT_COLOR := Color("ffd24a")
# Past this the files scroll, so all eleven still leave Leave on the 360 px screen.
const LIST_MAX_HEIGHT := 262.0
const ROW_HEIGHT := 24.0
const REPLAY := "Replay"

var _title := ""
var _panel: PanelContainer
var _list: VBoxContainer
var _scroll: ScrollContainer
var _count: Label
var _cutscene: CutscenePlayer
var _rng := RandomNumberGenerator.new()


func setup(title: String) -> void:
	_title = title


func _ready() -> void:
	_rng.randomize()
	_panel = PanelContainer.new()
	_panel.position = PANEL_POSITION
	_panel.custom_minimum_size = PANEL_SIZE
	# It covers most of the screen, so it gets its own opaque backing.
	var back := StyleBoxFlat.new()
	back.bg_color = PANEL_BACK
	back.border_color = PANEL_EDGE
	back.set_border_width_all(1)
	back.set_content_margin_all(6)
	_panel.add_theme_stylebox_override("panel", back)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = _title
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_count = Label.new()
	_count.add_theme_color_override("font_color", COUNT_COLOR)
	header.add_child(_count)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size.y = minf(EndingRules.ALL.size() * ROW_HEIGHT, LIST_MAX_HEIGHT)
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)
	var close := Button.new()
	close.text = "Leave"
	# The Waiting Room plays the closing sound itself.
	close.set_meta("sfx", "")
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()
	add_child(PadFocus.new())


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var data := Progress.data
	_count.text = EndingRules.found_line(data)
	for each: Dictionary in EndingRules.ALL:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = ROW_HEIGHT - 2.0
		var label := Label.new()
		label.text = EndingRules.archive_row(each, data)
		label.custom_minimum_size.x = ROW_WIDTH
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", ROW_FONT)
		var found := data.endings_found.has(each["id"])
		label.add_theme_color_override("font_color", FOUND_COLOR if found else MISSING_COLOR)
		row.add_child(label)
		if found:
			var button := Button.new()
			button.text = REPLAY
			button.add_theme_font_size_override("font_size", ROW_FONT)
			button.pressed.connect(replay.bind(each["id"]))
			row.add_child(button)
		_list.add_child(row)


# Esc and B in the Waiting Room: a replay ends and the files show again, or the panel closes.
func leave() -> void:
	if is_replaying():
		_cutscene.skip()
	else:
		closed.emit()


func rows_listed() -> int:
	return _list.get_child_count() if _list != null else 0


func replays_offered() -> int:
	var count := 0
	for row in _list.get_children():
		if row.get_child_count() > 1:
			count += 1
	return count


func is_replaying() -> bool:
	return is_instance_valid(_cutscene)


func replay_scene() -> CutscenePlayer:
	return _cutscene if is_instance_valid(_cutscene) else null


# Plays a found ending again over the panel, then shows the panel once more. The probe and the full
# loop call it as a press of that row's Replay.
func replay(id: String) -> void:
	if is_replaying() or not Progress.data.endings_found.has(id):
		return
	var variant := 0
	if id == EndingRules.REPEAT_CUSTOMER:
		variant = EndingRules.replay_death(Progress.data, _rng.randf())
	_cutscene = CutscenePlayer.new()
	_cutscene.setup(CutsceneSteps.for_ending(id, variant), false)
	add_child(_cutscene)
	_panel.visible = false
	# The ending's own music plays under it, and the room's comes back after.
	var room_song := MusicPlayer.current()
	MusicPlayer.play(MusicRules.ending_scene(id))
	await _cutscene.finished
	MusicPlayer.play(room_song)
	_cutscene.queue_free()
	_cutscene = null
	_panel.visible = true
