class_name ActiveSlot
extends Control

# The HUD's active slot, in the top band between the left panel and the right panel: the held active's
# icon (or a box in its rarity colour with its initials), its key and name, and a charge bar along the
# bottom with a tick per room, gold when ready. Nothing while no active is held.

const RIGHT_EDGE := 400.0
const GAP := 4.0
const TOP := 3.0
const HEIGHT := 16.0
const MIN_WIDTH := 40.0
const ICON := 14.0
const TEXT_AT := Vector2(18, 1)
const BAR_HEIGHT := 2.0
const BAR_EMPTY := Color(0.0, 0.0, 0.0, 0.5)
const BAR_FILL := Color("9fd8ff")
const BAR_READY := Color("ffd24a")

var _item: ItemDef
var _fraction := 0.0
var _needed := 0
var _label: Label


static func label_text(key: String, item: ItemDef) -> String:
	return "" if item == null else "[%s] %s" % [key, item.display_name]


static func charge_fraction(charge: int, needed: int) -> float:
	return 0.0 if needed <= 0 else clampf(float(charge) / float(needed), 0.0, 1.0)


# Where the slot sits when the left panel ends at left_end: just after it, up to RIGHT_EDGE, never
# narrower than MIN_WIDTH.
static func slot_rect(left_end: float) -> Rect2:
	var x := minf(left_end + GAP, RIGHT_EDGE - MIN_WIDTH)
	return Rect2(Vector2(x, TOP), Vector2(RIGHT_EDGE - x, HEIGHT))


func _ready() -> void:
	if _label != null:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.position = TEXT_AT
	_label.clip_text = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudStyle.style_label(_label, HudStyle.SMALL)
	add_child(_label)


func show_active(item: ItemDef, charge: int, needed: int, key: String) -> void:
	_ready()
	_item = item
	_needed = needed
	_fraction = charge_fraction(charge, needed)
	_label.text = label_text(key, item)
	_label.size = Vector2(maxf(size.x - TEXT_AT.x, 0.0), 12.0)
	queue_redraw()


func label_text_shown() -> String:
	return _label.text if _label != null else ""


func _draw() -> void:
	if _item == null:
		return
	var icon := ItemIcons.texture(_item.id)
	var box := Rect2(Vector2(1, 0), Vector2(ICON, ICON))
	if icon != null:
		draw_texture_rect(icon, box, false)
	else:
		draw_rect(box, ItemRarity.name_color(_item))
		draw_rect(box, Color.BLACK, false, 1.0)
		var font := HudStyle.font()
		var text := CaseFileData.initials(_item.display_name)
		draw_string(font, Vector2(2, 10), text, HORIZONTAL_ALIGNMENT_LEFT, ICON, 8, Color.BLACK)
	var bar := Rect2(Vector2(0, size.y - BAR_HEIGHT), Vector2(size.x, BAR_HEIGHT))
	draw_rect(bar, BAR_EMPTY)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _fraction, BAR_HEIGHT)), BAR_READY if _fraction >= 1.0 else BAR_FILL)
	for i in range(1, _needed):
		var x := bar.size.x * i / _needed
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color.BLACK, 1.0)
