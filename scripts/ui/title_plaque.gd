class_name TitlePlaque
extends Node2D

# The game's name on a brass plaque hung on two chains, drawn in room pixels on the room's own grid:
# TitleBrand.NAME in large embossed block letters (PixelGlyphs.BIG, each cell CELL px square) and
# TitleBrand.SUBTITLE engraved under it in small capitals. A sheen sweeps across it now and then. Its
# origin is the top middle of the plate; build() sizes it from the text, so a new name just fits.

const CELL := 3
const PAD_X := 7
const PAD_Y := 3
const GAP := 2
const OUTLINE := Color("1f1408")
const DEEP := Color("5a3c14")
const BASE := Color("b0812c")
const LIGHT := Color("dcb14c")
const SHINE := Color("fff1b0")
const PLATE := Color("8a6224")
const PLATE_LIGHT := Color("a87a34")
const PLATE_DARK := Color("5e4018")
const ENGRAVE := Color("2e1d0a")
const CHAIN := Color("3c3a40")
const CHAIN_LIGHT := Color("6a6872")
const SHEEN_EVERY := 7.0
const SHEEN_TIME := 0.9

var title_text := TitleBrand.NAME
var subtitle_text := TitleBrand.SUBTITLE
# The chains run up from the plate this far, to the ceiling.
var chain_length := 4.0
var size := Vector2.ZERO
var _sheen := -1.0
var _clock := 2.5


func _ready() -> void:
	build()


func build() -> void:
	var big := PixelGlyphs.text_width(PixelGlyphs.BIG, title_text.to_upper()) * CELL
	var small := PixelGlyphs.text_width(PixelGlyphs.SMALL, subtitle_text.to_upper())
	var width := maxi(big, small) + 2 * PAD_X
	if width % 2 == 1:
		width += 1
	var height := PAD_Y - 1 + PixelGlyphs.glyph_height(PixelGlyphs.BIG) * CELL + GAP + PixelGlyphs.glyph_height(PixelGlyphs.SMALL) + PAD_Y
	size = Vector2(width, height)
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	if _sheen < 0.0 and _clock >= SHEEN_EVERY:
		_clock = 0.0
		_sheen = 0.0
	if _sheen >= 0.0:
		_sheen += delta
		if _sheen > SHEEN_TIME:
			_sheen = -1.0
		queue_redraw()


func _draw() -> void:
	var left := -size.x / 2.0
	_draw_chain(Vector2(left + 7, 0))
	_draw_chain(Vector2(-left - 8, 0))
	var plate := Rect2(Vector2(left, 0), size)
	draw_rect(plate, OUTLINE)
	draw_rect(plate.grow(-1), PLATE_DARK)
	draw_rect(Rect2(plate.position + Vector2(1, 1), plate.size - Vector2(3, 3)), PLATE_LIGHT)
	draw_rect(Rect2(plate.position + Vector2(2, 2), plate.size - Vector2(4, 4)), PLATE)
	# Four flat round rivets, a lit pixel on each.
	for corner: Vector2 in [Vector2(3, 3), Vector2(size.x - 5, 3), Vector2(3, size.y - 5), Vector2(size.x - 5, size.y - 5)]:
		var at := plate.position + corner
		draw_rect(Rect2(at, Vector2(2, 2)), PLATE_DARK)
		draw_rect(Rect2(at, Vector2(1, 1)), SHINE)
	var name_text := title_text.to_upper()
	var name_at := Vector2(round(-PixelGlyphs.text_width(PixelGlyphs.BIG, name_text) * CELL / 2.0), PAD_Y - 1)
	var cells := PixelGlyphs.cells(PixelGlyphs.BIG, name_text)
	# Embossed solid letters: a dark drop edge down and right, the brass face, lit on its top and left
	# edges and shaded on its bottom and right edges, so each stroke reads as one raised bar.
	var lit := {}
	for c in cells:
		lit[c] = true
	for c in cells:
		draw_rect(Rect2(name_at + Vector2(c) * CELL + Vector2(1, 1), Vector2(CELL, CELL)), OUTLINE)
	for c in cells:
		draw_rect(Rect2(name_at + Vector2(c) * CELL, Vector2(CELL, CELL)), BASE)
	var band := lerpf(-12.0, size.x + 12.0, _sheen / SHEEN_TIME) + left
	for c in cells:
		var at := name_at + Vector2(c) * CELL
		if not lit.has(c + Vector2i(1, 0)):
			draw_rect(Rect2(at + Vector2(CELL - 1, 0), Vector2(1, CELL)), DEEP)
		if not lit.has(c + Vector2i(0, 1)):
			draw_rect(Rect2(at + Vector2(0, CELL - 1), Vector2(CELL, 1)), DEEP)
		if not lit.has(c - Vector2i(0, 1)):
			draw_rect(Rect2(at, Vector2(CELL, 1)), LIGHT)
		if not lit.has(c - Vector2i(1, 0)):
			draw_rect(Rect2(at, Vector2(1, CELL)), LIGHT)
		if _sheen >= 0.0 and absf(at.x + at.y * 0.6 - band) < 3.0:
			draw_rect(Rect2(at, Vector2(CELL, CELL)), SHINE)
	var sub_text := subtitle_text.to_upper()
	var sub_at := Vector2(round(-PixelGlyphs.text_width(PixelGlyphs.SMALL, sub_text) / 2.0), name_at.y + PixelGlyphs.glyph_height(PixelGlyphs.BIG) * CELL + GAP)
	# Engraved: the letter cut dark, with the brass catching light on its lower lip.
	PixelGlyphs.draw_text(self, PixelGlyphs.SMALL, sub_text, sub_at + Vector2(0, 1), PLATE_LIGHT)
	PixelGlyphs.draw_text(self, PixelGlyphs.SMALL, sub_text, sub_at, ENGRAVE)


# A chain of small round links from the ceiling down to the plate's top edge.
func _draw_chain(bottom: Vector2) -> void:
	# Each link is a hollow diamond seen face on, then one pixel of the next link seen edge on; no row
	# ever runs a bar across the line, so the chain never reads as a row of crosses.
	var y := -chain_length
	while y < 0.0:
		draw_rect(Rect2(Vector2(bottom.x, y), Vector2(1, 1)), CHAIN_LIGHT)
		draw_rect(Rect2(Vector2(bottom.x - 1, y + 1), Vector2(1, 1)), CHAIN)
		draw_rect(Rect2(Vector2(bottom.x + 1, y + 1), Vector2(1, 1)), CHAIN)
		draw_rect(Rect2(Vector2(bottom.x, y + 2), Vector2(1, 1)), CHAIN)
		draw_rect(Rect2(Vector2(bottom.x, y + 3), Vector2(1, 1)), CHAIN)
		y += 4.0
