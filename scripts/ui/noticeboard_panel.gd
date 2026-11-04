class_name NoticeboardPanel
extends CanvasLayer

# The lobby's noticeboard: every letter that has arrived, the unread ones marked NEW. Picking one shows
# its text and marks it read.

signal closed

const PANEL_POSITION := Vector2(60, 24)
const PANEL_SIZE := Vector2(520, 0)
const PANEL_BACK := Color(0.09, 0.07, 0.11)
const PANEL_EDGE := Color("625e6f")
const ROW_FONT := 10
const LETTER_FONT := 11
const NEW_MARK := "NEW"
const LETTER_COLOR := Color("f4efe2")
const NO_LETTERS := "No letters yet. The living write when a floor is cleared."
const PICK_ONE := "Pick a letter to read it."
# Past this the letters scroll, so ten of them still leave the letter and Leave on the 360 px screen.
const LIST_MAX_HEIGHT := 150.0
const ROW_HEIGHT := 24.0

var _title := ""
var _scroll: ScrollContainer
var _list: VBoxContainer
var _letter: Label


func setup(title: String) -> void:
	_title = title


static func row_text(letter: Dictionary, data: ProgressData) -> String:
	var sender := "From: %s" % letter["from"]
	return sender if LetterBook.is_read(letter, data) else "%s  %s" % [NEW_MARK, sender]


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = PANEL_POSITION
	panel.custom_minimum_size = PANEL_SIZE
	# It covers most of the screen, so it gets its own opaque backing.
	var back := StyleBoxFlat.new()
	back.bg_color = PANEL_BACK
	back.border_color = PANEL_EDGE
	back.set_border_width_all(1)
	back.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", back)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var title := Label.new()
	title.text = _title
	column.add_child(title)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)
	_letter = Label.new()
	_letter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_letter.custom_minimum_size = Vector2(PANEL_SIZE.x - 12.0, 30.0)
	_letter.add_theme_font_size_override("font_size", LETTER_FONT)
	_letter.add_theme_color_override("font_color", LETTER_COLOR)
	column.add_child(_letter)
	var close := Button.new()
	close.text = "Leave"
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var letters := LetterBook.arrived(Progress.data)
	for letter in letters:
		var button := Button.new()
		button.text = row_text(letter, Progress.data)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", ROW_FONT)
		button.pressed.connect(read.bind(letter["path"]))
		_list.add_child(button)
	_scroll.custom_minimum_size.y = minf(maxi(letters.size(), 1) * ROW_HEIGHT, LIST_MAX_HEIGHT)
	if letters.is_empty():
		_letter.text = NO_LETTERS
	elif _letter.text.is_empty():
		_letter.text = PICK_ONE


# Shows a letter and marks it read. The full-loop check calls it as a press of that letter's row.
func read(path_id: String) -> void:
	for letter in LetterBook.arrived(Progress.data):
		if letter["path"] == path_id:
			_letter.text = "%s:  \"%s\"" % [letter["from"], letter["text"]]
			Progress.read_letter(path_id)
	_rebuild()


func letters_listed() -> int:
	return _list.get_child_count() if _list != null else 0
