class_name PosterBoard
extends Node2D

# The Bounty Office's cork board: one small paper per poster showing, up to twenty in two rows, with a
# red TAKEN across the taken one. Placeholder art, drawn in code. It is wider than the station's cell,
# from about column 5 to 8, still clear of the north door at column 10.

const BOARD_SIZE := Vector2(104, 30)
# A bare cork board in a wooden frame; the posters on it stay code (PropArt).
const ART := "poster_board"
const PAPER_SIZE := Vector2(8, 11)
const GAP := 2.0
const COLUMNS := 10
const MAX_PAPERS := 20
const CORK := Color("9a6b3f")
const FRAME := Color("4a3220")
const PAPER := Color("efe6c8")
const INK := Color("3a2a1a")
const TAKEN_COLOR := Color("d8322e")
const TITLE := "WANTED"
const TITLE_FONT := 8
const TAKEN_FONT := 7

var _count := 0
var _taken := -1


# taken_index is the taken poster's place among those showing, or -1.
func show_posters(count: int, taken_index: int) -> void:
	_count = clampi(count, 0, MAX_PAPERS)
	_taken = taken_index if taken_index < _count else -1
	queue_redraw()


static func paper_rect(index: int) -> Rect2:
	var column := index % COLUMNS
	var row := int(index / float(COLUMNS))
	var origin := -BOARD_SIZE / 2.0 + Vector2(GAP + 1.0, GAP + 1.0)
	return Rect2(origin + Vector2(column * (PAPER_SIZE.x + GAP), row * (PAPER_SIZE.y + GAP)), PAPER_SIZE)


func _draw() -> void:
	var box := Rect2(-BOARD_SIZE / 2.0, BOARD_SIZE)
	var art := PropArt.texture(ART)
	if art != null:
		PropArt.draw(self, art)
	else:
		draw_rect(box, CORK)
		draw_rect(box, FRAME, false, 2.0)
	var font := ThemeDB.fallback_font
	var title_width := font.get_string_size(TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT).x
	var title_at := Vector2(-title_width / 2.0, box.position.y - 3.0)
	draw_string_outline(font, title_at, TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT, 2, Color.BLACK)
	draw_string(font, title_at, TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT, PAPER)
	for i in _count:
		var paper := paper_rect(i)
		draw_rect(paper, PAPER)
		# A face and two lines of small print, so each reads as a poster.
		draw_circle(paper.position + Vector2(PAPER_SIZE.x / 2.0, 3.5), 1.5, INK)
		draw_line(paper.position + Vector2(1.5, 7.0), paper.position + Vector2(PAPER_SIZE.x - 1.5, 7.0), INK, 1.0)
		draw_line(paper.position + Vector2(1.5, 9.0), paper.position + Vector2(PAPER_SIZE.x - 2.5, 9.0), INK, 1.0)
	if _taken >= 0:
		var taken := paper_rect(_taken)
		draw_line(taken.position, taken.end, TAKEN_COLOR, 2.0)
		var width := font.get_string_size("TAKEN", HORIZONTAL_ALIGNMENT_LEFT, -1, TAKEN_FONT).x
		var at := taken.get_center() + Vector2(-width / 2.0, 3.0)
		draw_string_outline(font, at, "TAKEN", HORIZONTAL_ALIGNMENT_LEFT, -1, TAKEN_FONT, 2, PAPER)
		draw_string(font, at, "TAKEN", HORIZONTAL_ALIGNMENT_LEFT, -1, TAKEN_FONT, TAKEN_COLOR)
