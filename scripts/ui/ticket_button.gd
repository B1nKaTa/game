class_name TicketButton
extends Button

# One menu item on the title screen: a paper ticket on the strip from the TAKE 1 machine, its label in
# the pixel font. Unselected tickets sit in the strip's shade; the selected one slides out (TitleMenu)
# in bright paper with a stub and a chevron pointing at it. Torn off, it jerks, falls and fades
# (TitleMenu.tear) while the rest of the strip stays. It keeps Button's focus, mouse and pad handling,
# so the menu's keys, stick and PadFocus all work as before; only its look is drawn here.

const PAPER := Color("e8e0c8")
const PAPER_DIM := Color("8f8878")
const EDGE := Color("231a1c")
const PERFORATION := Color("3a3032")
const STUB := Color("c24a30")
const INK := Color("2a2026")
const INK_DIM := Color("3a3436")
const ARROW := Color("ffd24a")
const SLIDE_SPEED := 14.0

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
	# The hidden text must not make the button taller than its ticket.
	add_theme_font_override("font", HudStyle.font())
	add_theme_font_size_override("font_size", HudStyle.SMALL)
	clip_text = true
	focus_mode = Control.FOCUS_ALL
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
	position = TitleMenu.ticket_rect(index).position + Vector2(round(TitleMenu.STICK_OUT * _slide), 0)
	queue_redraw()


func _draw() -> void:
	var lit := has_focus() or _torn >= 0.0
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, EDGE)
	draw_rect(rect.grow(-1), PAPER if lit else PAPER_DIM)
	# Perforations along the top and bottom seams, where it joins its neighbours on the strip.
	for x in range(3, int(size.x) - 2, 3):
		draw_rect(Rect2(x, 0, 1, 1), PERFORATION)
		draw_rect(Rect2(x, size.y - 1, 1, 1), PERFORATION)
	# Two punched notches at the ends, like a raffle ticket.
	for y in [int(size.y / 2.0) - 1, int(size.y / 2.0)]:
		draw_rect(Rect2(0, y, 2, 1), EDGE)
		draw_rect(Rect2(size.x - 2, y, 2, 1), EDGE)
	if lit:
		draw_rect(Rect2(4, 2, 2, size.y - 4), STUB)
	var font := HudStyle.font()
	var width := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL).x
	var at := Vector2(round((size.x - width) / 2.0) + 2.0, round(size.y / 2.0) + 3.0)
	draw_string(font, at, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL, INK if lit else INK_DIM)
	if has_focus() and _torn < 0.0:
		# A chevron pointing in at the selected ticket from the left.
		var tip := Vector2(-3, round(size.y / 2.0))
		for step in 4:
			draw_rect(Rect2(tip.x - 6 + step, tip.y - 4 + step, 2, 1), ARROW)
			draw_rect(Rect2(tip.x - 6 + step, tip.y + 3 - step, 2, 1), ARROW)
