class_name TarotCard
extends Node2D

# One of Sister Celestine's tarot cards, lying flat on the floor where she dealt it. Dealt, it slides
# out of her hand and lies face down, showing its patterned back. Turned, it flips over and shows its
# symbol, with its name on a tag under it, before its attack begins; once its attack is done it lies
# dimmed, and when her hand is over the cards fade away. Harmless: it blocks nothing and hurts no one.
#
# Drawn as a 32x48 placeholder, the size of the tarot art (D:\grandpa-art\newpaths\objects\tarot_*.png,
# each 32x48), so a texture can replace the drawing one to one: art_id() names the file stem it
# shows now, the back's while face down.
const SIZE := Vector2(32, 48)
# The file stems of the art, by CelestineBehavior.Card (Tower, Death, Wheel, Star), and the back's.
const ART_IDS: Array[String] = ["tarot_tower", "tarot_death", "tarot_wheel", "tarot_star"]
const BACK_ART_ID := "tarot_card_back"
const NAMES: Array[String] = ["The Tower", "Death", "The Wheel", "The Star"]
const DEAL_TIME := 0.15
const FLIP_TIME := 0.16
const FADE := 0.3
const SPENT_ALPHA := 0.55
const BACK := Color("2b1846")
const BACK_PATTERN := Color("6a4a9c")
const GOLD := Color("e2c25a")
const FACE := Color("f1e6c8")
const INK := Color("2a2430")
const TAG := Color(0.08, 0.05, 0.12, 0.85)
const TAG_TEXT := Color("f6efe0")
const TAG_FONT := 8
# The name tag is drawn on a node of its own, this far above the cards (relative), so a card dealt
# just below in a column never covers the tag of the one above it.
const TAG_Z := 1
# The symbols' own colours.
const TOWER_STONE := Color("8a7f9a")
const BOLT := Color("f2c64a")
const BONE := Color("e9e4dc")
const WHEEL_GOLD := Color("c9932e")
const STAR_GOLD := Color("f2c64a")

var card := 0
var _source: Node2D
var _face_up := false
var _flip_left := 0.0
var _deal_delay := 0.0
var _deal_left := DEAL_TIME
var _from := Vector2.ZERO
var _spent := false
var _vanishing := false
var _fade_left := FADE
var _tag: Node2D


static func art_id_of(which: int, face_up: bool) -> String:
	if not face_up:
		return BACK_ART_ID
	return ART_IDS[clampi(which, 0, ART_IDS.size() - 1)]


static func name_of(which: int) -> String:
	return NAMES[clampi(which, 0, NAMES.size() - 1)]


# Dealt by source, landing delay after the deal starts, sliding in from where source stands.
func setup(which: int, source: Node2D, delay := 0.0) -> void:
	card = which
	_source = source
	_deal_delay = delay
	_deal_left = DEAL_TIME
	z_index = Hole.FLOOR_Z


# Where it slides out from as it is dealt, once it lies where it lands.
func slide_from(point: Vector2) -> void:
	_from = point - global_position


# The file stem of the art it shows now.
func art_id() -> String:
	return art_id_of(card, _face_up)


func card_name() -> String:
	return name_of(card)


func is_dealt() -> bool:
	return _deal_delay <= 0.0 and _deal_left <= 0.0


func is_face_up() -> bool:
	return _face_up


# Whether its face shows: turned and past the middle of its flip.
func shows_symbol() -> bool:
	return _face_up and _flip_left <= FLIP_TIME / 2.0


func is_spent() -> bool:
	return _spent


func turn() -> void:
	_face_up = true
	_flip_left = FLIP_TIME


# Its attack is done: it lies dimmed.
func mark_spent() -> void:
	_spent = true


# Her hand is over: it fades away.
func vanish() -> void:
	_vanishing = true


func advance(delta: float) -> void:
	if _deal_delay > 0.0:
		_deal_delay -= delta
	elif _deal_left > 0.0:
		_deal_left -= delta
	if _flip_left > 0.0:
		_flip_left -= delta
	if _vanishing:
		_fade_left -= delta


func _ready() -> void:
	_tag = Node2D.new()
	_tag.z_index = TAG_Z
	add_child(_tag)
	_tag.draw.connect(_draw_tag_now)


# The node its name tag is drawn on, above every card.
func tag_node() -> Node2D:
	return _tag


func _process(delta: float) -> void:
	queue_redraw()
	if _tag != null:
		_tag.queue_redraw()
	advance(delta)
	if (_vanishing and _fade_left <= 0.0) or not is_instance_valid(_source) or (_source is Enemy and (_source as Enemy).is_dead()):
		queue_free()


func _draw() -> void:
	if _deal_delay > 0.0:
		return
	var alpha := 1.0
	if _vanishing:
		alpha = clampf(_fade_left / FADE, 0.0, 1.0)
	if _spent:
		alpha *= SPENT_ALPHA
	# Sliding out of her hand as it is dealt.
	var slide := clampf(_deal_left / DEAL_TIME, 0.0, 1.0)
	var offset := _from * slide
	# A flip squeezes it to an edge and opens it again.
	var width := 1.0
	if _flip_left > 0.0:
		width = maxf(absf(cos((1.0 - _flip_left / FLIP_TIME) * PI)), 0.08)
	draw_set_transform(offset, 0.0, Vector2(width, 1.0))
	var rect := Rect2(-SIZE / 2.0, SIZE)
	if shows_symbol() or (_face_up and _flip_left <= 0.0):
		_draw_face(rect, alpha)
	else:
		_draw_back(rect, alpha)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _alpha() -> float:
	var alpha := 1.0
	if _vanishing:
		alpha = clampf(_fade_left / FADE, 0.0, 1.0)
	if _spent:
		alpha *= SPENT_ALPHA
	return alpha


func _draw_tag_now() -> void:
	if _deal_delay > 0.0 or not shows_symbol() or _vanishing:
		return
	var offset := _from * clampf(_deal_left / DEAL_TIME, 0.0, 1.0)
	_draw_tag(_tag, offset + Vector2(0.0, SIZE.y / 2.0 + 2.0), _alpha())


func _draw_back(rect: Rect2, alpha: float) -> void:
	draw_rect(rect, Color(BACK, alpha))
	draw_rect(rect.grow(-2.0), Color(GOLD, alpha), false, 1.0)
	# A lattice of small diamonds, a crescent moon in the middle and stars in the corners.
	for row in 5:
		for column in 3:
			var at := rect.position + Vector2(7.0 + column * 9.0, 7.0 + row * 8.5)
			if Vector2(at - rect.get_center()).length() < 8.0:
				continue
			var diamond := PackedVector2Array([at + Vector2(0, -2), at + Vector2(2, 0), at + Vector2(0, 2), at + Vector2(-2, 0)])
			draw_colored_polygon(diamond, Color(BACK_PATTERN, alpha))
	draw_circle(rect.get_center(), 6.0, Color(GOLD, alpha))
	draw_circle(rect.get_center() + Vector2(2.5, -1.5), 5.0, Color(BACK, alpha))
	draw_rect(rect, Color(INK, alpha), false, 1.0)


func _draw_face(rect: Rect2, alpha: float) -> void:
	draw_rect(rect, Color(FACE, alpha))
	draw_rect(rect.grow(-2.0), Color(GOLD, alpha), false, 1.0)
	draw_rect(rect, Color(INK, alpha), false, 1.0)
	var middle := rect.get_center() + Vector2(0.0, -2.0)
	match card:
		0:
			# The Tower: a stone tower struck by a bolt, its crown flying off.
			draw_rect(Rect2(middle + Vector2(-6, -8), Vector2(12, 20)), Color(TOWER_STONE, alpha))
			draw_rect(Rect2(middle + Vector2(-7, -12), Vector2(14, 4)), Color(TOWER_STONE, alpha))
			draw_rect(Rect2(middle + Vector2(-2, 4), Vector2(4, 8)), Color(INK, alpha))
			draw_rect(Rect2(middle + Vector2(-6, -8), Vector2(12, 20)), Color(INK, alpha), false, 1.0)
			draw_polyline(PackedVector2Array([middle + Vector2(10, -18), middle + Vector2(3, -11), middle + Vector2(7, -10), middle + Vector2(0, -2)]), Color(BOLT, alpha), 2.0)
		1:
			# Death: a scythe, its long snath and curved blade.
			draw_line(middle + Vector2(-6, 13), middle + Vector2(5, -13), Color(INK, alpha), 2.0)
			var blade := PackedVector2Array()
			for i in 7:
				var t := i / 6.0
				blade.append(middle + Vector2(5, -13) + Vector2(-t * 15.0, sin(t * PI) * 5.0 + t * 2.0))
			draw_polyline(blade, Color(INK, alpha), 4.0)
			draw_polyline(blade, Color(BONE, alpha), 2.0)
		2:
			# The Wheel: a golden wheel with eight spokes and a hub.
			draw_arc(middle, 10.0, 0.0, TAU, 24, Color(WHEEL_GOLD, alpha), 3.0)
			for i in 8:
				draw_line(middle, middle + Vector2.from_angle(i * TAU / 8.0) * 10.0, Color(WHEEL_GOLD, alpha), 1.5)
			draw_circle(middle, 3.0, Color(INK, alpha))
		_:
			# The Star: a large eight-pointed star over small ones.
			var points := PackedVector2Array()
			for i in 16:
				var reach := 11.0 if i % 2 == 0 else 4.0
				points.append(middle + Vector2.from_angle(-PI / 2.0 + i * PI / 8.0) * reach)
			draw_colored_polygon(points, Color(STAR_GOLD, alpha))
			var outline := points.duplicate()
			outline.append(points[0])
			draw_polyline(outline, Color(INK, alpha), 1.0)
			for at: Vector2 in [Vector2(-10, 12), Vector2(9, 13), Vector2(-11, -14)]:
				draw_circle(middle + at, 1.5, Color(STAR_GOLD, alpha))
	# The card's number in the corner, as the deck numbers them.
	var numeral: String = ["XVI", "XIII", "X", "XVII"][clampi(card, 0, 3)]
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, rect.size.y - 3.0), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(INK, alpha))


func _draw_tag(canvas: CanvasItem, at: Vector2, alpha: float) -> void:
	var font := ThemeDB.fallback_font
	var text := card_name()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_FONT).x
	var box := Rect2(at - Vector2(width / 2.0 + 3.0, 0.0), Vector2(width + 6.0, TAG_FONT + 4.0))
	canvas.draw_rect(box, Color(TAG, TAG.a * alpha))
	canvas.draw_string(font, Vector2(box.position.x + 3.0, box.position.y + TAG_FONT + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_FONT, Color(TAG_TEXT, alpha))
