class_name EndingCard
extends CanvasLayer

# The card shown the first time the Chairman of the Board falls, before the Waiting Room: plain words
# on an opaque screen. It closes after SHOW_TIME, or on interact or attack once MIN_TIME has passed,
# so the press that won the fight never skips it. Runs go on as normal afterwards.

signal finished

const BOSS_ID := "chairman_of_the_board"
const TEXT := "You reached the top. The paperwork says you may finally rest. Form 27B: Rest, Denied. Please take a number."
const HINT := "Go on"
const SHOW_TIME := 9.0
const MIN_TIME := 1.0
const LAYER := 20
const BACK := Color(0.04, 0.03, 0.05)
const TEXT_COLOR := Color("ece9e0")
const HINT_COLOR := Color(0.75, 0.72, 0.65, 0.8)
const TEXT_SIZE := 14
const HINT_SIZE := 10

var _time := 0.0
var _done := false
var _label: Label


# Whether beating this boss shows the card: the Chairman, the first time only.
static func is_due(boss_id: String, seen: bool) -> bool:
	return boss_id == BOSS_ID and not seen


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var back := ColorRect.new()
	back.color = BACK
	back.size = RoomBackdrop.VIEW_SIZE
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	_label = Label.new()
	_label.text = TEXT
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(80, 100)
	_label.size = Vector2(RoomBackdrop.VIEW_SIZE.x - 160.0, 140)
	_label.add_theme_font_size_override("font_size", TEXT_SIZE)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	var hint := Label.new()
	hint.text = KeyBindings.with_key("interact", HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, RoomBackdrop.VIEW_SIZE.y - 40.0)
	hint.size = Vector2(RoomBackdrop.VIEW_SIZE.x, 20)
	hint.add_theme_font_size_override("font_size", HINT_SIZE)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)


func text() -> String:
	return _label.text if _label != null else TEXT


# Polled, not read from input events, since the full loop presses keys with Input.action_press.
func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	var pressed := Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack")
	if _time >= SHOW_TIME or (_time >= MIN_TIME and pressed):
		_done = true
		finished.emit()
