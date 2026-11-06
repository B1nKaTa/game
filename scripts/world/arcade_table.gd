class_name ArcadeTable
extends BreakableBlock

# One game in the Arcade Room. Standing by it, the interact key asks to play, and the room opens the
# card-table overlay. Each game plays once per visit, the slot machine for three pulls, and coming
# back through the door fills it again. Solid like the Retirement Plan, and nothing breaks it.
signal play_wanted(game: String)

const SLOT := "slot"
const BLACKJACK := "blackjack"
const POKER := "poker"
# An arcade layout's game cells take these in reading order.
const GAMES: Array[String] = [SLOT, BLACKJACK, POKER]
const NAMES := {SLOT: "Slot Machine", BLACKJACK: "Blackjack", POKER: "Draw Poker"}
const USE_RADIUS := 40.0
const PROMPT := "Play"
const USED_UP := "Come back next visit"
const FELT := Color("1f7a4a")
const FELT_EDGE := Color("0c3a22")
const RIM := Color("6b3f22")
const SLOT_BODY := Color("c8463c")
const REEL_FACE := Color("f4efe2")
const CARD_FACE := Color("fbfaf5")
const CARD_RED := Color("c8463c")
const TEXT_COLOR := Color("ece9e0")
const PROMPT_COLOR := Color("ffd24a")
const FONT_SIZE := 10
const DIE_FACE := Color("fbfaf5")
const DIE_EDGE := Color.BLACK
const DIE_PIP := Color("1a1620")

var game := SLOT
var plays_left := 0
var _feet: Node2D
var _near := false


static func plays_per_visit(game_name: String) -> int:
	return SlotMachine.PULLS_PER_VISIT if game_name == SLOT else 1


static func display_name(game_name: String) -> String:
	return NAMES.get(game_name, game_name)


# A die showing five, for the arcade's doors and its square on the maps.
static func draw_die(canvas: CanvasItem, center: Vector2, size: float) -> void:
	var half := size / 2.0
	var face := Rect2(center - Vector2(half, half), Vector2(size, size))
	canvas.draw_rect(face, DIE_FACE)
	canvas.draw_rect(face, DIE_EDGE, false, maxf(1.0, size / 12.0))
	var pip := maxf(1.0, size / 9.0)
	var step := size * 0.27
	for offset: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2.ZERO, Vector2(-1, 1), Vector2(1, 1)]:
		canvas.draw_circle(center + offset * step, pip, DIE_PIP)


func setup(game_name: String, feet: Node2D) -> void:
	game = game_name
	_feet = feet
	plays_left = plays_per_visit(game)


func refill() -> void:
	plays_left = plays_per_visit(game)


# Spends one play, or refuses when none are left this visit.
func use_play() -> bool:
	if plays_left <= 0:
		return false
	plays_left -= 1
	return true


func can_break_by(_source: String) -> bool:
	return false


# Blasts do nothing here.
func take_blast() -> void:
	pass


func is_near() -> bool:
	return _near


func _process(_delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_feet):
		return
	_near = global_position.distance_to(_feet.global_position) <= USE_RADIUS
	if _near and plays_left > 0 and Input.is_action_just_pressed("interact"):
		play_wanted.emit(game)


# arcade_table_slot for the slot machine, arcade_table_cards for both card games (PropArt).
func art_id() -> String:
	return "arcade_table_slot" if game == SLOT else "arcade_table_cards"


func _draw() -> void:
	var half := RoomBackdrop.TILE / 2.0
	var art := PropArt.texture(art_id())
	if art != null:
		PropArt.draw(self, art)
	else:
		var top := Rect2(-half, -half, half * 2.0, half * 2.0)
		draw_rect(top, RIM)
		draw_rect(top.grow(-3.0), FELT)
		draw_rect(top, FELT_EDGE, false, 2.0)
		match game:
			SLOT:
				_draw_slot_top()
			_:
				_draw_cards_top()
	_draw_centered(display_name(game), Vector2(0, -half - 4.0), TEXT_COLOR)
	if _near:
		var prompt := KeyBindings.with_key("interact", PROMPT) if plays_left > 0 else USED_UP
		_draw_centered(prompt, Vector2(0, half + 12.0), PROMPT_COLOR)


func _draw_slot_top() -> void:
	draw_rect(Rect2(-11, -9, 22, 18), SLOT_BODY)
	for i in 3:
		draw_rect(Rect2(-9 + i * 6.5, -5, 5, 10), REEL_FACE)
	draw_line(Vector2(12, -8), Vector2(12, 2), Color.BLACK, 2.0)
	draw_circle(Vector2(12, -9), 2.0, CARD_RED)


func _draw_cards_top() -> void:
	for i in 2:
		var card := Rect2(-9 + i * 8, -7, 10, 14)
		draw_rect(card, CARD_FACE)
		draw_rect(card, Color.BLACK, false, 1.0)
	draw_circle(Vector2(3, 0), 2.0, CARD_RED)


func _draw_centered(text: String, at: Vector2, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var spot := at - Vector2(width / 2.0, 0)
	draw_string_outline(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 3, Color.BLACK)
	draw_string(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
