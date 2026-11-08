class_name TitleBoard
extends Node2D

# The NOW SERVING board on the title screen's wall, in room pixels from its top-left: the board's art,
# its label in small capitals, and three seven-segment digits that read NowServing.display. The board
# never reaches Harold's number; when it would, it stutters and drops back (NowServing).

const ART := "res://art/title/board.png"
const LABEL := "NOW SERVING"
const LABEL_AT := Vector2(32, 8)
const DIGITS_AT := Vector2(32, 16)
const DIGIT := Vector2i(5, 9)
const DIGIT_GAP := 2
const LIT := Color("ff7a3c")
const LIT_CORE := Color("ffc08a")
# Unlit segments stay faint even under the lamp, so a lit digit never reads as an 8.
const UNLIT := Color("1c0c0c")
const LABEL_COLOR := Color("d8c9a0")
# Segments a to g of a 5x9 digit, as rects in its own pixels.
const SEGMENTS := {
	"a": Rect2(1, 0, 3, 1), "b": Rect2(4, 1, 1, 3), "c": Rect2(4, 5, 1, 3), "d": Rect2(1, 8, 3, 1),
	"e": Rect2(0, 5, 1, 3), "f": Rect2(0, 1, 1, 3), "g": Rect2(1, 4, 3, 1),
}
const LIT_SEGMENTS := {
	"0": "abcdef", "1": "bc", "2": "abdeg", "3": "abcdg", "4": "bcfg", "5": "acdfg", "6": "acdefg",
	"7": "abc", "8": "abcdefg", "9": "abcdfg", "-": "g", " ": "",
}

var serving: NowServing
var _time := 0.0
var _shown := ""


func _ready() -> void:
	var art := Sprite2D.new()
	art.texture = load(ART)
	art.centered = false
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(art)
	# The board's own drawing goes over its art.
	var face := Node2D.new()
	face.draw.connect(_draw_face.bind(face))
	add_child(face)
	set_meta("face", face)


func _process(delta: float) -> void:
	_time += delta
	if serving == null:
		return
	serving.tick(delta)
	var text := serving.display(_time)
	if text != _shown:
		_shown = text
		(get_meta("face") as Node2D).queue_redraw()


func _draw_face(face: Node2D) -> void:
	var label_at := LABEL_AT - Vector2(PixelGlyphs.text_width(PixelGlyphs.SMALL, LABEL) / 2.0, 0).round()
	PixelGlyphs.draw_text(face, PixelGlyphs.SMALL, LABEL, label_at, LABEL_COLOR)
	var text := _shown.rpad(3)
	var width := 3 * DIGIT.x + 2 * DIGIT_GAP
	var at := DIGITS_AT - Vector2(round(width / 2.0), 0)
	for i in 3:
		var lit: String = LIT_SEGMENTS.get(text[i], "")
		for segment: String in SEGMENTS:
			var rect: Rect2 = SEGMENTS[segment]
			rect.position += at + Vector2(i * (DIGIT.x + DIGIT_GAP), 0)
			if lit.contains(segment):
				face.draw_rect(rect, LIT)
				# A paler core on the long bars, so a lit digit glows.
				if rect.size.x > 1.0:
					face.draw_rect(Rect2(rect.position + Vector2(1, 0), Vector2(1, 1)), LIT_CORE)
				else:
					face.draw_rect(Rect2(rect.position + Vector2(0, 1), Vector2(1, 1)), LIT_CORE)
			else:
				face.draw_rect(rect, UNLIT)
