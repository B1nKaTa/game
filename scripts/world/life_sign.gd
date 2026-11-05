class_name LifeSign
extends Node2D

# A small framed lobby card on an easel in a Flashback Cinema room. When Harold walks up to it, it shows
# one line of his life in a speech-bubble card above it, and walking away hides it again. It never
# pauses play and blocks nothing. Its line is chosen the first time it shows (pick, which records it
# as shown for the run and the save) and it keeps that line for as long as the room lasts.
const NEAR := 46.0
# He must step a little further off before the card hides, so it never flickers at the edge.
const FAR := 62.0
const FONT_SIZE := 10
const LINE_WIDTH := 220.0
const LINE_GAP := 2.0
const PAD := Vector2(6, 4)
# The card's height, for where the bubble goes above it or below it (Npc.bubble_box).
const CARD_HEIGHT := 22.0
const BUBBLE_Z := 50
const CARD_GOLD := Color("c9a24a")
const CARD_PAPER := Color("d9c49a")
const CARD_INK := Color("4a3522")
const EASEL := Color("5a3e26")
const BUBBLE_EDGE := Color("8a6a2a")

# Returns the line's id, or "" when there is none left to show this run.
var pick: Callable
var line_id := ""
var _player: Node2D
var _showing := false
var _bubble: Node2D
var _rows: PackedStringArray = []


func setup(player: Node2D, picker: Callable) -> void:
	_player = player
	pick = picker


func _ready() -> void:
	add_to_group("life_signs")
	_bubble = Node2D.new()
	_bubble.z_as_relative = false
	_bubble.z_index = BUBBLE_Z
	_bubble.visible = false
	_bubble.draw.connect(_draw_bubble)
	add_child(_bubble)
	queue_redraw()


func is_showing() -> bool:
	return _showing


func showing_text() -> String:
	return LifeSigns.text_of(line_id) if _showing else ""


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	update_for(_player.global_position + Player.FEET_OFFSET)


# Shows or hides the card's line for where Harold's feet are, in global space.
func update_for(feet: Vector2) -> void:
	var distance := feet.distance_to(global_position)
	if not _showing and distance <= NEAR:
		if line_id.is_empty() and pick.is_valid():
			line_id = pick.call()
		if line_id.is_empty():
			return
		_rows = wrap_text(LifeSigns.text_of(line_id))
		_showing = true
	elif _showing and distance > FAR:
		_showing = false
	_bubble.visible = _showing
	_bubble.queue_redraw()


# The line broken into rows no wider than LINE_WIDTH, at the card's font size.
static func wrap_text(text: String) -> PackedStringArray:
	var font := ThemeDB.fallback_font
	var rows: PackedStringArray = []
	var row := ""
	for word in text.split(" ", false):
		var tried := word if row.is_empty() else row + " " + word
		if row.is_empty() or font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x <= LINE_WIDTH:
			row = tried
		else:
			rows.append(row)
			row = word
	if not row.is_empty():
		rows.append(row)
	return rows


static func box_size_for(rows: PackedStringArray) -> Vector2:
	var font := ThemeDB.fallback_font
	var widest := 0.0
	for row in rows:
		widest = maxf(widest, font.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
	return Vector2(widest, rows.size() * (FONT_SIZE + LINE_GAP) - LINE_GAP) + PAD * 2.0


func _draw() -> void:
	var art := PropArt.texture("life_sign")
	if art != null:
		draw_texture(art, -art.get_size() / 2.0)
		return
	# An easel's three legs, and the card on it: a gold frame round a sepia still.
	draw_line(Vector2(-7, 12), Vector2(-3, -6), EASEL, 2.0)
	draw_line(Vector2(7, 12), Vector2(3, -6), EASEL, 2.0)
	draw_line(Vector2(0, 12), Vector2(0, 2), EASEL.darkened(0.3), 1.0)
	draw_rect(Rect2(-9, -12, 18, 13), CARD_GOLD)
	draw_rect(Rect2(-7, -10, 14, 9), CARD_PAPER)
	draw_rect(Rect2(-2, -8, 3, 5), CARD_INK)
	draw_circle(Vector2(-0.5, -8.5), 1.5, CARD_INK)
	draw_rect(Rect2(-9, -12, 18, 13), Color.BLACK, false, 1.0)


func _draw_bubble() -> void:
	if not _showing or _rows.is_empty():
		return
	var font := ThemeDB.fallback_font
	var box_size := box_size_for(_rows)
	var screen := _bubble.get_global_transform_with_canvas()
	var box := Npc.bubble_box(screen.origin, screen.get_scale(), CARD_HEIGHT, box_size, Vector2(RoomBackdrop.VIEW_SIZE))
	var below := box.position.y > 0.0
	var tail_y := box.position.y if below else box.end.y
	var tail_tip := Vector2(0, tail_y - 5.0 if below else tail_y + 5.0)
	_bubble.draw_colored_polygon(PackedVector2Array([Vector2(-4, tail_y), Vector2(4, tail_y), tail_tip]), Npc.BUBBLE_COLOR)
	_bubble.draw_rect(box, Npc.BUBBLE_COLOR)
	_bubble.draw_rect(box.grow(-2.0), BUBBLE_EDGE, false, 1.0)
	_bubble.draw_rect(box, Color.BLACK, false, 1.0)
	for i in _rows.size():
		var at := box.position + Vector2(PAD.x, PAD.y + FONT_SIZE - 2.0 + i * (FONT_SIZE + LINE_GAP))
		_bubble.draw_string(font, at, _rows[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Npc.BUBBLE_TEXT_COLOR)
