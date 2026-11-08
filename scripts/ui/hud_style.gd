class_name HudStyle
extends RefCounted

# The HUD's look (docs/art/art-direction-notes.md, HUD): framed pixel panels in the basement's dark wood
# and brass, the project's own bitmap font (res://art/ui/basement_ledger.fnt, tools/art/font_build.py) drawn at
# whole multiples of its 8 px size, and small pixel icons. Glyphs the font lacks (brackets, symbols) come
# from the engine's own font, so no text is ever lost.
const FONT_PATH := "res://art/ui/basement_ledger.fnt"
const SMALL := 8
const LARGE := 16
const PANEL_FILL := Color(0.07, 0.05, 0.045, 0.86)
const PANEL_EDGE := Color(0.01, 0.01, 0.015)
const PANEL_FRAME := Color("6b5238")
const PANEL_LIGHT := Color("a8865a")
const TEXT := Color("ece3cf")
const DIM_TEXT := Color(0.85, 0.8, 0.7, 0.85)
const PILL_FULL := Color("e8e0d0")
const PILL_CAP := Color("d9584f")
const PILL_EMPTY := Color(0.3, 0.26, 0.24)
const PILL_STEP := 7.0
const BUILD_MARGIN := 8.0

static var _font: FontFile


static func font() -> Font:
	if _font == null and ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
		_font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_font.fallbacks = [ThemeDB.fallback_font]
	return _font if _font != null else ThemeDB.fallback_font


# Puts the pixel font on a label at size (SMALL or LARGE), outlined in black.
static func style_label(label: Label, font_size: int, color := TEXT) -> void:
	label.add_theme_font_override("font", font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)


# The build id (BuildInfo) in small dim pixel text, right-aligned in the bottom-right corner of the
# 640x360 view, on the title screen and the pause menu. It never takes the mouse.
static func build_label() -> Label:
	var label := Label.new()
	label.text = BuildInfo.label()
	style_label(label, SMALL, DIM_TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.custom_minimum_size.x = GameSettings.VIEW.x - 2 * BUILD_MARGIN
	label.position = Vector2(BUILD_MARGIN, GameSettings.VIEW.y - 16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# A framed panel: a dark fill, a black edge, a wooden frame with a lit top edge, and cut corners.
static func draw_panel(canvas: CanvasItem, rect: Rect2) -> void:
	rect = Rect2(rect.position.floor(), rect.size.floor())
	canvas.draw_rect(rect.grow(-1), PANEL_FILL)
	var inner := rect.grow(-1)
	canvas.draw_rect(Rect2(inner.position + Vector2(1, 0), Vector2(inner.size.x - 2, 1)), PANEL_LIGHT)
	canvas.draw_rect(Rect2(inner.position + Vector2(1, inner.size.y - 1), Vector2(inner.size.x - 2, 1)), PANEL_FRAME)
	canvas.draw_rect(Rect2(inner.position + Vector2(0, 1), Vector2(1, inner.size.y - 2)), PANEL_FRAME)
	canvas.draw_rect(Rect2(inner.position + Vector2(inner.size.x - 1, 1), Vector2(1, inner.size.y - 2)), PANEL_FRAME)
	# The black edge, with the corners cut off.
	canvas.draw_rect(Rect2(rect.position + Vector2(2, 0), Vector2(rect.size.x - 4, 1)), PANEL_EDGE)
	canvas.draw_rect(Rect2(rect.position + Vector2(2, rect.size.y - 1), Vector2(rect.size.x - 4, 1)), PANEL_EDGE)
	canvas.draw_rect(Rect2(rect.position + Vector2(0, 2), Vector2(1, rect.size.y - 4)), PANEL_EDGE)
	canvas.draw_rect(Rect2(rect.position + Vector2(rect.size.x - 1, 2), Vector2(1, rect.size.y - 4)), PANEL_EDGE)
	for corner in [Vector2(1, 1), Vector2(rect.size.x - 2, 1), Vector2(1, rect.size.y - 2), Vector2(rect.size.x - 2, rect.size.y - 2)]:
		canvas.draw_rect(Rect2(rect.position + corner, Vector2.ONE), PANEL_EDGE)


# One pill of the health row: a capsule, red cap and white body when full, a dark hollow when not.
static func draw_pill(canvas: CanvasItem, at: Vector2, full: bool) -> void:
	at = at.floor()
	var body := Rect2(at + Vector2(1, 0), Vector2(4, 9))
	canvas.draw_rect(body.grow(1), Color.BLACK)
	canvas.draw_rect(Rect2(at + Vector2(0, 1), Vector2(6, 7)), Color.BLACK)
	if full:
		canvas.draw_rect(Rect2(at + Vector2(1, 0), Vector2(4, 4)), PILL_CAP)
		canvas.draw_rect(Rect2(at + Vector2(1, 5), Vector2(4, 4)), PILL_FULL)
		canvas.draw_rect(Rect2(at + Vector2(1, 4), Vector2(4, 1)), Color.BLACK)
		canvas.draw_rect(Rect2(at + Vector2(2, 1), Vector2(1, 2)), PILL_CAP.lightened(0.45))
	else:
		canvas.draw_rect(Rect2(at + Vector2(1, 0), Vector2(4, 9)), PILL_EMPTY)
		canvas.draw_rect(Rect2(at + Vector2(2, 1), Vector2(2, 7)), PILL_EMPTY.darkened(0.45))


# A small brass coin for Pension.
static func draw_coin(canvas: CanvasItem, at: Vector2) -> void:
	at = at.floor()
	canvas.draw_rect(Rect2(at + Vector2(2, 0), Vector2(5, 9)), Color.BLACK)
	canvas.draw_rect(Rect2(at + Vector2(0, 2), Vector2(9, 5)), Color.BLACK)
	canvas.draw_rect(Rect2(at + Vector2(1, 1), Vector2(7, 7)), Color.BLACK)
	canvas.draw_rect(Rect2(at + Vector2(2, 1), Vector2(5, 7)), Color("e2b33c"))
	canvas.draw_rect(Rect2(at + Vector2(1, 2), Vector2(7, 5)), Color("e2b33c"))
	canvas.draw_rect(Rect2(at + Vector2(3, 3), Vector2(3, 3)), Color("b0821e"))
	canvas.draw_rect(Rect2(at + Vector2(2, 2), Vector2(1, 2)), Color("fff1b8"))
