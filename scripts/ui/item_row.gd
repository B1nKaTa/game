class_name ItemRow
extends Control

# The HUD's item row once any of its newest items has an icon: "Items: N", then each newest item's icon
# at ICON px, or its name where it has none. With no icon at all the HUD keeps its plain label.

const ICON := 12.0
const GAP := 3.0

var _pieces: Array = []


# What the row draws, in order: ["text", words] or ["icon", texture].
static func pieces(count: int, entries: Array[Dictionary]) -> Array:
	var out: Array = [["text", "Items: %d   " % count]]
	for i in entries.size():
		var icon: Texture2D = entries[i]["icon"]
		if icon != null:
			out.append(["icon", icon])
		else:
			out.append(["text", str(entries[i]["name"]) + (", " if i < entries.size() - 1 else "")])
	return out


func show_pieces(list: Array) -> void:
	_pieces = list
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := HudStyle.font()
	var x := 0.0
	for piece in _pieces:
		if x >= size.x:
			return
		if piece[0] == "icon":
			draw_texture_rect(piece[1], Rect2(Vector2(x, 0.0), Vector2(ICON, ICON)), false)
			x += ICON + GAP
		else:
			draw_string(font, Vector2(x, 9.0), piece[1], HORIZONTAL_ALIGNMENT_LEFT, size.x - x, Hud.ITEM_ROW_FONT)
			x += font.get_string_size(piece[1], HORIZONTAL_ALIGNMENT_LEFT, -1, Hud.ITEM_ROW_FONT).x
