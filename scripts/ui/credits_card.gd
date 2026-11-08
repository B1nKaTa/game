class_name CreditsCard
extends CanvasLayer

# A short card of credits that scrolls up over an opaque backing and closes on its own at the end, or
# at once on Esc, Enter or a click.

signal closed

const LAYER := 60
const SPEED := 30.0
# Where the first line starts: low on the screen, but already in view.
const START_Y := 250.0
const LINE_GAP := 6
const SHEET_X := 110.0
const LINES := [
	[TitleBrand.FULL_NAME, 24],
	["", 11],
	["A game by Stanislav Zlatkov", 13],
	["", 11],
	["Design, code and placeholder art", 11],
	["Stanislav Zlatkov", 13],
	["", 11],
	["Made with Godot Engine", 11],
	["Godot Engine is under the MIT license, godotengine.org/license", 9],
	["", 11],
	["Thanks for playing.", 13],
	["Please take a number.", 11],
]

var _column: VBoxContainer
var _opened_frame := -1
var _done := false


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	add_child(MenuStyle.backing())
	# The credits are typed on a long form that runs up the clipboard.
	add_child(MenuStyle.panel(Vector2(SHEET_X, 12), Vector2(GameSettings.VIEW.x - 2.0 * SHEET_X, GameSettings.VIEW.y - 18.0)))
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", LINE_GAP)
	_column.position = Vector2(0, START_Y)
	_column.custom_minimum_size.x = GameSettings.VIEW.x
	add_child(_column)
	for line in LINES:
		var color := MenuStyle.GOLD if line[1] >= 13 and line != LINES[2] else MenuStyle.TEXT
		var label := MenuStyle.label(tr(line[0]), line[1], color)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Each line only as wide as its text, centred, so a stamped title's box fits its words.
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_column.add_child(label)
	var hint := MenuStyle.label(tr("Esc: back"), 9, MenuStyle.DIM)
	hint.position = Vector2(SHEET_X + 10.0, GameSettings.VIEW.y - 24)
	add_child(hint)


func _process(delta: float) -> void:
	_column.position.y -= SPEED * delta
	if _column.position.y + _column.size.y < 0.0:
		_close()
		return
	if Engine.get_process_frames() == _opened_frame:
		return
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed(PadInput.BACK_ACTION):
		_close()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		_close()


func _close() -> void:
	if _done:
		return
	_done = true
	closed.emit()
