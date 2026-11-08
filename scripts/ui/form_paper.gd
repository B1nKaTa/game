class_name FormPaper
extends Panel

# A big menu panel drawn as the waiting room's paperwork: a sheet of form paper clipped to a wooden
# clipboard, in the depth look (one light from the upper left, a dark outline, a hard shadow, no glow).
# The board shows a few pixels round the sheet and the steel clip bites its top edge in the middle. The
# sheet is ruled faintly from rules_from down, every rule_step pixels, so typed rows sit on lines like a
# form's fields; no rule ever runs across another. What the panel holds is laid over it as before.

const BOARD_MARGIN := 6.0
const CLIP_SIZE := Vector2(56, 12)
const OUTLINE := Color("1a100c")
const SHADOW := Color(0, 0, 0, 0.55)
const CLIP := Color("8d8a92")
const CLIP_LIGHT := Color("c9c6cc")
const CLIP_DARK := Color("4a4850")
const RULE := Color(0.42, 0.5, 0.62, 0.28)

var rules_from := -1.0
var rule_step := 18.0


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var sheet := Rect2(Vector2.ZERO, size)
	var board := sheet.grow(BOARD_MARGIN)
	draw_rect(Rect2(board.position + Vector2(4, 4), board.size), SHADOW)
	draw_rect(board, OUTLINE)
	draw_rect(board.grow(-1), MenuStyle.BOARD)
	draw_rect(Rect2(board.position + Vector2(1, 1), Vector2(board.size.x - 2, 2)), MenuStyle.BOARD_LIGHT)
	draw_rect(Rect2(board.position + Vector2(1, board.size.y - 3), Vector2(board.size.x - 2, 2)), MenuStyle.BOARD_DARK)
	draw_rect(sheet, OUTLINE)
	draw_rect(sheet.grow(-1), MenuStyle.PAPER)
	# The sheet's own shade along its right and bottom edges, where it lifts off the board.
	draw_rect(Rect2(sheet.position + Vector2(1, sheet.size.y - 3), Vector2(sheet.size.x - 2, 2)), MenuStyle.PAPER_SHADE)
	draw_rect(Rect2(sheet.position + Vector2(sheet.size.x - 3, 1), Vector2(2, sheet.size.y - 2)), MenuStyle.PAPER_SHADE)
	if rules_from >= 0.0:
		var y := rules_from
		while y < size.y - 6.0:
			draw_rect(Rect2(6, y, size.x - 12, 1), RULE)
			y += rule_step
	_draw_clip(Vector2(round(size.x / 2.0), -BOARD_MARGIN))


# The clipboard's steel clip: a flat plate across the top edge with a rolled bar under it.
func _draw_clip(top_middle: Vector2) -> void:
	var plate := Rect2(top_middle - Vector2(CLIP_SIZE.x / 2.0, 2), CLIP_SIZE)
	draw_rect(Rect2(plate.position + Vector2(2, 2), plate.size), SHADOW)
	draw_rect(plate, OUTLINE)
	draw_rect(plate.grow(-1), CLIP)
	draw_rect(Rect2(plate.position + Vector2(1, 1), Vector2(plate.size.x - 2, 2)), CLIP_LIGHT)
	draw_rect(Rect2(plate.position + Vector2(1, plate.size.y - 3), Vector2(plate.size.x - 2, 2)), CLIP_DARK)
	var bar := Rect2(top_middle + Vector2(-CLIP_SIZE.x / 2.0 + 6, CLIP_SIZE.y - 3), Vector2(CLIP_SIZE.x - 12, 4))
	draw_rect(bar, OUTLINE)
	draw_rect(bar.grow(-1), CLIP_DARK)
