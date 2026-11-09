class_name ReelSlot
extends Control

# The HUD's film reel, on the right panel's second row left of the run timer: a small brass reel and
# the flashback key while Harold holds a memory, and nothing while he holds none.

const AT := Vector2(408, 22)
const SIZE := Vector2(64, 13)
const DISC_CENTER := Vector2(6, 6.5)
const DISC_RADIUS := 6.0
const HOLE_RADIUS := 1.5
const HOLE_REACH := 3.2
const TEXT_AT := Vector2(15, 1)
const BRASS := Color("d9a441")
const BRASS_DARK := Color("7a5520")
const HOLE := Color("2a1d10")

var _held := false
var _label: Label


static func text_for(era: String, key: String) -> String:
	return "" if era.is_empty() else "[%s]" % key


func _ready() -> void:
	if _label != null:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	_label = Label.new()
	_label.position = TEXT_AT
	_label.size = Vector2(SIZE.x - TEXT_AT.x, 12)
	_label.clip_text = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudStyle.style_label(_label, HudStyle.SMALL)
	add_child(_label)


func show_reel(era: String, key: String) -> void:
	_ready()
	_held = not era.is_empty()
	_label.text = text_for(era, key)
	queue_redraw()


func label_text() -> String:
	return _label.text if _label != null else ""


# A brass disc with three dark holes round a hub, drawn in code.
func _draw() -> void:
	if not _held:
		return
	draw_circle(DISC_CENTER, DISC_RADIUS, BRASS)
	draw_arc(DISC_CENTER, DISC_RADIUS, 0.0, TAU, 20, BRASS_DARK, 1.0)
	for i in 3:
		var angle := -PI / 2.0 + i * TAU / 3.0
		draw_circle(DISC_CENTER + Vector2(cos(angle), sin(angle)) * HOLE_REACH, HOLE_RADIUS, HOLE)
	draw_circle(DISC_CENTER, 1.0, HOLE)
