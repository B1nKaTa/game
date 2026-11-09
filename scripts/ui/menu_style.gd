class_name MenuStyle
extends RefCounted

# The look shared by Options, the slot picker, the pause menu, confirm boxes and the credits: the
# waiting room's paperwork. A panel is an official form clipped to a clipboard (FormPaper), a small box
# is a slip of the same paper on a board edge, text is typed in the game's pixel font in dark ink, a
# title is stamped in red in a ruled box, and the selected item wears a highlighter stroke. Hovering an
# item with the mouse selects it, so the stroke is only ever on one item. Sizes are kept as before and
# drawn at the pixel font's whole sizes (8 or 16, pixel_size).

# Behind a big panel: the dark of the room, opaque.
const BACK := Color("120d0c")
const PAPER := Color("e6dcc2")
const PAPER_SHADE := Color("cfc2a2")
const BOARD := Color("6a4526")
const BOARD_LIGHT := Color("8c5f36")
const BOARD_DARK := Color("3a2414")
const BOX := PAPER
const EDGE := Color("4a3a2e")
# Gold is the controller's focus edge on every panel (PadFocus); on the paper a title is stamped red.
const GOLD := Color("ffd24a")
const STAMP := Color("a8322a")
const MARKER := Color("f2d566")
const TEXT := Color("2a201c")
const DIM := Color("6c5e54")
const DARK_TEXT := Color("1a1214")
const SHADE := Color(0.0, 0.0, 0.0, 0.6)
const FONT := 11
const TITLE_FONT := 16


# The pixel font's whole size for a size asked for: titles at 16, everything else at 8.
static func pixel_size(font_size: int) -> int:
	return HudStyle.LARGE if font_size >= TITLE_FONT else HudStyle.SMALL


# A slip of paper with an ink edge, for cards and lists inside a panel.
static func box(color := BOX, edge := EDGE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	return style


# A small box on its own (the pause menu, a question): paper on a clipboard's edge, with a shadow.
static func clipboard_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = BOARD
	style.set_border_width_all(4)
	style.set_content_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 0
	style.shadow_offset = Vector2(3, 3)
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


# A big panel: a form on a clipboard, ruled from rules_from down (FormPaper).
static func panel(at: Vector2, size: Vector2, rules_from := -1.0, rule_step := 18.0) -> Panel:
	var node := FormPaper.new()
	node.position = at
	node.size = size
	node.rules_from = rules_from
	node.rule_step = rule_step
	return node


# Typed text. Asked for in gold, it is stamped in red instead, and a title-sized stamp gets its ruled
# box on a scrap of paper, so it reads on the form or on the dark around it.
static func label(text: String, font_size := FONT, color := TEXT) -> Label:
	var node := Label.new()
	node.text = text
	var stamped := color.is_equal_approx(GOLD)
	node.add_theme_font_override("font", HudStyle.font())
	node.add_theme_font_size_override("font_size", pixel_size(font_size))
	node.add_theme_color_override("font_color", STAMP if stamped else color)
	if stamped and font_size >= TITLE_FONT:
		var stamp := StyleBoxFlat.new()
		stamp.bg_color = PAPER
		stamp.border_color = STAMP
		stamp.set_border_width_all(2)
		stamp.content_margin_left = 6
		stamp.content_margin_right = 6
		stamp.content_margin_top = 2
		stamp.content_margin_bottom = 1
		node.add_theme_stylebox_override("normal", stamp)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


# A flat typed button whose selected look is a highlighter stroke under dark text. A tight one has no
# margin above or below its text, for long lists such as the Input tab's.
static func button(text: String, font_size := FONT, tight := false) -> Button:
	var node := Button.new()
	node.text = text
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.add_theme_font_override("font", HudStyle.font())
	node.add_theme_font_size_override("font_size", pixel_size(font_size))
	var plain := StyleBoxFlat.new()
	plain.bg_color = Color(0, 0, 0, 0)
	plain.set_content_margin_all(0 if tight else 2)
	plain.content_margin_left = 6
	plain.content_margin_right = 6
	var bar := plain.duplicate() as StyleBoxFlat
	bar.bg_color = MARKER
	bar.border_color = STAMP
	bar.border_width_left = 2
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


# A slider typed onto the form: a pencilled track, an inked fill, and a red edge while selected.
static func slider(min_value: int, max_value: int, value: int) -> HSlider:
	var node := HSlider.new()
	node.min_value = min_value
	node.max_value = max_value
	node.step = 1
	node.value = value
	node.custom_minimum_size = Vector2(150, 14)
	var track := StyleBoxFlat.new()
	track.bg_color = PAPER_SHADE
	track.border_color = DIM
	track.border_width_bottom = 1
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = Color("7a5a3a")
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = STAMP
	focus.set_border_width_all(1)
	node.add_theme_stylebox_override("slider", track)
	node.add_theme_stylebox_override("grabber_area", fill)
	node.add_theme_stylebox_override("grabber_area_highlight", fill)
	node.add_theme_stylebox_override("focus", focus)
	node.mouse_entered.connect(node.grab_focus)
	return node
