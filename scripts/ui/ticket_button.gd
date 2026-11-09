class_name TicketButton
extends Button

# One menu item on the title screen: a paper queue ticket on the strip hanging from the TAKE 1 machine's
# slot, drawn as pixel art on the room's own 3 px grid (TitleRoom.ROOM_SCALE) so it belongs to the
# room: cream paper lit from above, a dark outline, a stub on the left with its printed number in red,
# a perforated line between stub and ticket and a tear line under it, and a soft shadow. Its label is in
# the game's pixel font in dark ink. Tickets in the strip sit in the machine's shade; the selected one
# is pulled further out, lit, and pointed at by a chevron. Torn off, it jerks, falls and fades
# (TitleMenu.tear) while the rest of the strip stays. It keeps Button's focus, mouse and pad handling,
# so the menu's keys, stick and PadFocus all work as before; only its look is drawn here.

const CELL := 3.0
# The ticket in cells (TitleMenu.TICKET_SIZE / CELL), and the stub's width before the perforation.
const CELLS := Vector2i(26, 7)
const STUB := 8
const OUTLINE := Color("2e2119")
const PAPER := Color("e4d8b6")
const PAPER_LIGHT := Color("f3ead0")
const PAPER_SHADE := Color("c7b78f")
const STUB_PAPER := Color("d9c99f")
const PERFORATION := Color("8a7656")
const NUMBER_INK := Color("9a2c22")
const INK := Color("2a1f1c")
const SHADOW := Color(0.02, 0.01, 0.03, 0.45)
const ARROW := Color("ffd24a")
const ARROW_DARK := Color("7a5a14")
# The strip in the machine's shade, and the pulled-out ticket in the lamplight.
const SHADE := Color(0.72, 0.68, 0.66)
const LIT := Color(1.08, 1.04, 0.96)
const SLIDE_SPEED := 10.0
const FIRST_NUMBER := 43

var menu_id := ""
var index := 0
var label_text := ""
var _torn := -1.0
var _slide := 0.0


func setup(id: String, at_index: int, label: String) -> void:
	menu_id = id
	index = at_index
	label_text = label
	# The Button's own text stays for anything that reads it, drawn clear; this node draws the ticket.
	text = label
	flat = true
	focus_mode = Control.FOCUS_ALL
	# The hidden text must not make the button taller than its ticket.
	add_theme_font_override("font", HudStyle.font())
	add_theme_font_size_override("font_size", HudStyle.SMALL)
	clip_text = true
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(state, Color(0, 0, 0, 0))
	var rect := TitleMenu.ticket_rect(index)
	position = rect.position
	size = rect.size
	custom_minimum_size = rect.size
	mouse_entered.connect(grab_focus)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func is_torn() -> bool:
	return _torn >= 0.0


func tear() -> void:
	_torn = 0.0
	release_focus()
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if _torn >= 0.0:
		_torn += delta
		var motion := TitleMenu.tear(_torn)
		var rect := TitleMenu.ticket_rect(index, true)
		position = rect.position + motion["offset"]
		rotation = motion["angle"]
		modulate.a = motion["alpha"]
		return
	size = TitleMenu.TICKET_SIZE
	var target := 1.0 if has_focus() else 0.0
	_slide = move_toward(_slide, target, SLIDE_SPEED * delta)
	# It slides out a whole cell at a time, so it stays on the room's grid.
	var out := roundf(TitleMenu.STICK_OUT / CELL * _slide) * CELL
	position = TitleMenu.ticket_rect(index).position + Vector2(out, 0)
	queue_redraw()


# A block of cells, in cells from the ticket's top-left.
func _cells(x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(Vector2(x, y) * CELL, Vector2(w, h) * CELL), color)


func _draw() -> void:
	var selected := has_focus() or _torn >= 0.0
	var tone := LIT if selected else SHADE
	var w := CELLS.x
	var h := CELLS.y
	# The shadow it casts on the wall, a cell down and right.
	draw_rect(Rect2(Vector2(CELL, CELL), Vector2(w, h) * CELL), SHADOW)
	_cells(0, 0, w, h, OUTLINE)
	_cells(1, 1, STUB - 1, h - 2, STUB_PAPER * tone)
	_cells(STUB + 1, 1, w - STUB - 2, h - 2, PAPER * tone)
	_cells(1, 1, w - 2, 1, PAPER_LIGHT * tone)
	_cells(1, h - 2, w - 2, 1, PAPER_SHADE * tone)
	# The perforation between stub and ticket, and the tear line along the bottom: every other cell.
	for y in range(1, h - 1):
		_cells(STUB, y, 1, 1, (PERFORATION if y % 2 == 1 else PAPER_SHADE) * tone)
	for x in range(1, w - 1, 2):
		_cells(x, h - 1, 1, 1, PERFORATION * tone)
	# The stub's printed number, in the signs' small capitals at one cell a pixel.
	var number := "%02d" % ((FIRST_NUMBER + index) % 100)
	var number_at := Vector2(1 + (STUB - 1 - PixelGlyphs.text_width(PixelGlyphs.SMALL, number)) / 2, 1) * CELL
	PixelGlyphs.draw_text(self, PixelGlyphs.SMALL, number, number_at, NUMBER_INK * tone, CELL)
	var font := HudStyle.font()
	var width := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL).x
	var body := Rect2(Vector2(STUB + 1, 1) * CELL, Vector2(w - STUB - 2, h - 2) * CELL)
	var at := Vector2(round(body.position.x + (body.size.x - width) / 2.0), round(body.get_center().y) + 3.0)
	draw_string(font, at, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL, INK)
	if has_focus() and _torn < 0.0:
		# A chevron on the room's grid pointing in at the selected ticket from the left.
		var mid := int(h / 2.0)
		for step in 3:
			_cells(-5 + step, mid - 2 + step, 1, 1, ARROW_DARK)
			_cells(-5 + step, mid + 2 - step, 1, 1, ARROW_DARK)
			_cells(-4 + step, mid - 2 + step, 1, 1, ARROW)
			_cells(-4 + step, mid + 2 - step, 1, 1, ARROW)
