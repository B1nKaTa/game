class_name OuijaBoard
extends Node2D

# Madame Zara's talking board, laid on the floor of her room for the whole fight: a translucent board of
# dark wood with a letter grid on it, YES and NO on the top row and the letters A to Z, under the bodies.
# The planchette (OuijaPlanchette) slides from letter to letter over it. It is one large framed board
# of letters, sharing nothing with the carpet's scattered stars and moons. It hurts no one, and fades
# when she falls. It lies at the room's origin and holds the board in room space.
const COLUMNS := 7
const ROWS := 4
# How far in from the room's edge the outer letters stand at most, and the most room between letters,
# so in a large room the board lies in its middle and a word never takes long to spell.
const INSET := 48.0
const MOST_STEP := Vector2(96, 80)
const LABELS: Array[String] = [
	"YES", "A", "B", "C", "D", "E", "NO",
	"F", "G", "H", "I", "J", "K", "L",
	"M", "N", "O", "P", "Q", "R", "S",
	"T", "U", "V", "W", "X", "Y", "Z",
]
const WOOD := Color(0.3, 0.19, 0.11, 0.42)
const RIM := Color(0.86, 0.7, 0.36, 0.55)
const LETTER := Color(0.96, 0.88, 0.68, 0.72)
const LETTER_SIZE := 14
const BOARD_Z := -8
const FADE := 0.6

var _source: Enemy
var _room := Rect2()
var _fading := false
var _fade_left := FADE


# The middle of every letter's place on the board over a room, in LABELS order.
static func slots(room: Rect2) -> Array[Vector2]:
	var board := letters_rect(room)
	var step := Vector2(board.size.x / (COLUMNS - 1), board.size.y / (ROWS - 1))
	var points: Array[Vector2] = []
	for row in ROWS:
		for column in COLUMNS:
			points.append(board.position + Vector2(column * step.x, row * step.y))
	return points


# Where the letters stand: the room less INSET, no wider or taller than MOST_STEP allows, in its middle.
static func letters_rect(room: Rect2) -> Rect2:
	var inner := room.grow(-INSET)
	var size := Vector2(minf(inner.size.x, MOST_STEP.x * (COLUMNS - 1)), minf(inner.size.y, MOST_STEP.y * (ROWS - 1)))
	return Rect2(inner.get_center() - size / 2.0, size)


static func slot_of(label: String) -> int:
	return LABELS.find(label)


# The letters of a word as points on the board, in order. A letter not on the board is skipped.
static func word_path(word: String, room: Rect2) -> Array[Vector2]:
	var points := slots(room)
	var path: Array[Vector2] = []
	for i in word.length():
		var index := slot_of(word[i])
		if index >= 0:
			path.append(points[index])
	return path


func setup(source: Enemy, room: Rect2) -> void:
	_source = source
	_room = room
	z_index = BOARD_Z
	z_as_relative = false


func room() -> Rect2:
	return _room


func is_fading() -> bool:
	return _fading


func _process(delta: float) -> void:
	if not _fading and (not is_instance_valid(_source) or _source.is_dead()):
		_fading = true
	if _fading:
		_fade_left -= delta
		queue_redraw()
		if _fade_left <= 0.0:
			queue_free()


func _draw() -> void:
	if not _room.has_area():
		return
	var alpha := clampf(_fade_left / FADE, 0.0, 1.0) if _fading else 1.0
	var board := letters_rect(_room).grow(26.0)
	draw_rect(board, Color(WOOD, WOOD.a * alpha))
	draw_rect(board, Color(RIM, RIM.a * alpha), false, 2.0)
	draw_rect(board.grow(-5.0), Color(RIM, RIM.a * 0.5 * alpha), false, 1.0)
	var font := ThemeDB.fallback_font
	var points := slots(_room)
	for i in points.size():
		var text := LABELS[i]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE).x
		draw_string(font, points[i] + Vector2(-width / 2.0, LETTER_SIZE * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE, Color(LETTER, LETTER.a * alpha))
