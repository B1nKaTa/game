class_name PosterBoard
extends Node2D

# The Bounty Office's cork board, hung low on the north wall left of the north door: a WANTED card at
# the top and one poster per bounty in two rows of ten. Each poster is a sepia print of its boss, cut
# from his own sprite (art/props/waiting_room/poster_<boss id>.png), over a rubber stamp that tells its
# state: REWARD while it is up, TAKEN while Grandpa holds it, DENIED once the boss is beaten and the
# reward waits at the desk, and CLOSED, on grey paper with the print crossed out, once it is collected.
# The pictures are built by tools/art/waiting_props.py; with none, the old code drawing stands in.

const BOARD_SIZE := Vector2(258, 84)
# The board's middle in the Bounty Office: clear of the west wall (x 32) and the north door's jamb
# (x 298), with its top under the HUD's band.
const BOARD_CENTER := Vector2(161, 82)
const ART := "poster_board"
const PAPER_SIZE := Vector2(24, 28)
const GAP := Vector2(1, 2)
# Where the first poster's top-left sits, from the board's top-left: past the frame and the WANTED card.
const GRID_ORIGIN := Vector2(4, 22)
const COLUMNS := 10
const MAX_PAPERS := 20
const PORTRAIT_AT := Vector2(4, 3)
const STAMP_Y := 19.0
const CLOSED_PRINT := Color(0.6, 0.6, 0.6)
# The code drawing, used only while the pictures are missing.
const CORK := Color("8a5e38")
const FRAME := Color("3a2416")
const PAPER := Color("c2ab80")
const INK := Color("3a281a")
const STAMP_COLORS := {
	BountyBoard.POSTER_OPEN: Color("a02a22"),
	BountyBoard.POSTER_TAKEN: Color("2c3e78"),
	BountyBoard.POSTER_WON: Color("a02a22"),
	BountyBoard.POSTER_CLOSED: Color("241e1a"),
}
const STAMP_WORDS := {
	BountyBoard.POSTER_OPEN: "REWARD",
	BountyBoard.POSTER_TAKEN: "TAKEN",
	BountyBoard.POSTER_WON: "DENIED",
	BountyBoard.POSTER_CLOSED: "CLOSED",
}
const TITLE := "WANTED"
const TITLE_FONT := 8
const STAMP_FONT := 6

# Each poster on the board, in order: {"id": the boss's id, "state": a BountyBoard.POSTER_ state}.
var _posters: Array[Dictionary] = []


# Hung on the wall, under every body: Harold walks in front of it wherever he stands, and the station's
# prompt (z 0) draws over it.
func _ready() -> void:
	z_index = -1


func show_posters(hung: Array[Dictionary]) -> void:
	_posters = hung.slice(0, MAX_PAPERS)
	queue_redraw()


func posters() -> Array[Dictionary]:
	return _posters


static func paper_rect(index: int) -> Rect2:
	var column := index % COLUMNS
	var row := int(index / float(COLUMNS))
	var origin := -BOARD_SIZE / 2.0 + GRID_ORIGIN
	return Rect2(origin + Vector2(column * (PAPER_SIZE.x + GAP.x), row * (PAPER_SIZE.y + GAP.y)), PAPER_SIZE)


static func stamp_art(state: String) -> String:
	return "poster_stamp_" + {BountyBoard.POSTER_OPEN: "reward", BountyBoard.POSTER_TAKEN: "taken",
		BountyBoard.POSTER_WON: "denied", BountyBoard.POSTER_CLOSED: "closed"}.get(state, "reward")


static func portrait_art(id: String) -> String:
	return "poster_" + id


func _draw() -> void:
	var box := Rect2(-BOARD_SIZE / 2.0, BOARD_SIZE)
	var board := PropArt.texture(ART)
	if board != null:
		draw_texture(board, box.position)
	else:
		draw_rect(box, CORK)
		draw_rect(box, FRAME, false, 3.0)
		_draw_word(TITLE, Vector2(0, box.position.y + 15.0), TITLE_FONT, Color("efe6c8"))
	for i in _posters.size():
		_draw_poster(paper_rect(i), _posters[i])


func _draw_poster(paper: Rect2, poster: Dictionary) -> void:
	var state: String = poster.get("state", BountyBoard.POSTER_OPEN)
	var closed := state == BountyBoard.POSTER_CLOSED
	var sheet := PropArt.texture("poster_paper_closed" if closed else "poster_paper")
	if sheet == null:
		draw_rect(paper, PAPER.darkened(0.35) if closed else PAPER)
		draw_rect(Rect2(paper.position + PORTRAIT_AT, Vector2(16, 14)), INK)
		_draw_word(STAMP_WORDS.get(state, ""), paper.position + Vector2(PAPER_SIZE.x / 2.0, STAMP_Y + 6.0), STAMP_FONT, STAMP_COLORS.get(state, INK))
		return
	draw_texture(sheet, paper.position)
	var print_art := PropArt.texture(portrait_art(str(poster.get("id", ""))))
	if print_art == null:
		print_art = PropArt.texture("poster_unknown")
	if print_art != null:
		draw_texture(print_art, paper.position + PORTRAIT_AT, CLOSED_PRINT if closed else Color.WHITE)
	if closed:
		var cross := PropArt.texture("poster_cross")
		if cross != null:
			draw_texture(cross, paper.position + PORTRAIT_AT)
	var stamp := PropArt.texture(stamp_art(state))
	if stamp != null:
		draw_texture(stamp, paper.position + Vector2(0, STAMP_Y))


func _draw_word(word: String, middle: Vector2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, middle - Vector2(width / 2.0, 0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
