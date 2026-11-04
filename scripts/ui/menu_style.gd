class_name MenuStyle
extends RefCounted

# The look shared by the title screen, Options, the slot picker and the pause menu: an opaque dark box,
# small text for the 640x360 view, and the gold highlight bar on whichever item is selected. Hovering an
# item with the mouse selects it, so the bar is only ever on one item.

const BACK := Color(0.08, 0.06, 0.1, 1.0)
const BOX := Color(0.12, 0.1, 0.15, 1.0)
const EDGE := Color("5a4a6e")
const GOLD := Color("ffd24a")
const TEXT := Color("ece9e0")
const DIM := Color("9a94a8")
const DARK_TEXT := Color("1a1214")
const SHADE := Color(0.0, 0.0, 0.0, 0.6)
const FONT := 11
const TITLE_FONT := 16


static func box(color := BOX, edge := EDGE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	return style


# A whole-screen rect behind a panel: opaque for a big panel, shaded for a small box over another.
static func backing(color := BACK) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.position = Vector2.ZERO
	rect.size = Vector2(GameSettings.VIEW)
	# It sits under the panel's own controls and only keeps clicks from reaching the scene behind.
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	return rect


static func panel(at: Vector2, size: Vector2) -> Panel:
	var node := Panel.new()
	node.position = at
	node.size = size
	node.add_theme_stylebox_override("panel", box())
	return node


static func label(text: String, font_size := FONT, color := TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


# A flat button whose selected look is the gold bar, with dark text on it. A tight one has no margin
# above or below its text, for long lists such as the Input tab's.
static func button(text: String, font_size := FONT, tight := false) -> Button:
	var node := Button.new()
	node.text = text
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.add_theme_font_size_override("font_size", font_size)
	var plain := StyleBoxFlat.new()
	plain.bg_color = Color(0, 0, 0, 0)
	plain.set_content_margin_all(0 if tight else 2)
	plain.content_margin_left = 6
	plain.content_margin_right = 6
	var bar := plain.duplicate() as StyleBoxFlat
	bar.bg_color = GOLD
	for state in ["normal", "disabled"]:
		node.add_theme_stylebox_override(state, plain)
	for state in ["hover", "focus", "pressed", "hover_pressed"]:
		node.add_theme_stylebox_override(state, bar)
	node.add_theme_color_override("font_color", TEXT)
	node.add_theme_color_override("font_disabled_color", DIM)
	for state in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		node.add_theme_color_override(state, DARK_TEXT)
	node.mouse_entered.connect(node.grab_focus)
	return node


# A slider styled to the menus: a thin track, a gold fill, and a gold edge while selected.
static func slider(min_value: int, max_value: int, value: int) -> HSlider:
	var node := HSlider.new()
	node.min_value = min_value
	node.max_value = max_value
	node.step = 1
	node.value = value
	node.custom_minimum_size = Vector2(150, 14)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("2a2333")
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = Color("b89a4a")
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = GOLD
	focus.set_border_width_all(1)
	node.add_theme_stylebox_override("slider", track)
	node.add_theme_stylebox_override("grabber_area", fill)
	node.add_theme_stylebox_override("grabber_area_highlight", fill)
	node.add_theme_stylebox_override("focus", focus)
	node.mouse_entered.connect(node.grab_focus)
	return node
