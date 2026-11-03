class_name CardTablePanel
extends CanvasLayer

# The overlay one Arcade table opens: green felt with the cards or the reels drawn in code, the bet
# and play buttons below. It only freezes Grandpa, as the Waiting Room's panels do, and the room stays
# safe while it is open. The interact key or Leave closes it, and a hand still in play is finished
# first (blackjack stands, poker draws with the cards held), so a bet is never lost by walking away.
signal closed

const READY := "ready"
const PLAYING := "playing"
const DONE := "done"
const HAND_CARDS := 5
const OVERLAY_LAYER := 10
const PANEL_POSITION := Vector2(60, 22)
const PANEL_SIZE := Vector2(520, 316)
const FELT_SIZE := Vector2(500, 150)
const BUTTON_FONT_SIZE := 11
const TITLE_FONT_SIZE := 14
const INFO_FONT_SIZE := 10
const FELT := Color("1f6b40")
const FELT_EDGE := Color("0c3a22")
const FELT_TEXT := Color("f4efe2")
const CARD_FACE := Color("fbfaf5")
const CARD_BACK := Color("8c2a3c")
const CARD_BACK_LINE := Color("e0b04a")
const CARD_EDGE := Color("2b2218")
const BLACK_SUIT := Color("1a1620")
const RED_SUIT := Color("c8463c")
const HELD_COLOR := Color("ffd24a")
const REEL_FACE := Color("f4efe2")
const REEL_EDGE := Color("2b2218")
const CARD_SIZE := Vector2(36, 50)
const POKER_CARD_SIZE := Vector2(44, 62)
const REEL_SIZE := Vector2(76, 92)
const SHORT := "Not enough Pension for that bet."
const NO_PLAYS := "That's all for this visit. Come back later."
const CHOOSE_BET := "Choose a bet."
const SLOT_RULES := "10 a pull. A pair returns the bet, three of a kind pays 5x,"
const SLOT_RULES_2 := "three skulls give a free item and three pills a full heal."
const SYMBOL_NAMES := {
	"cherry": "Cherry",
	"bell": "Bell",
	"pill": "Pill",
	"skull": "Skull",
	"coin": "Coin",
	"dentures": "Dentures",
}

var _table: ArcadeTable
var _room: RoomView
var _rng: RandomNumberGenerator
var _deck: CardDeck
var _blackjack: Blackjack
var _poker: DrawPoker
var _held: Array[bool] = [false, false, false, false, false]
var _reels: Array[String] = []
var _state := READY
var _bet := 0
var _last_payout := 0
var _message := ""
var _opened_frame := -1
var _card_box: StyleBoxFlat
var _back_box: StyleBoxFlat
var _title: Label
var _info: Label
var _felt: FeltView
var _message_label: Label
var _holds: HBoxContainer
var _actions: HBoxContainer


class FeltView extends Control:
	var panel: CardTablePanel

	func _draw() -> void:
		panel._draw_felt(self)


func setup(table: ArcadeTable, room: RoomView, rng: RandomNumberGenerator) -> void:
	_table = table
	_room = room
	use_rng(rng)


# A check can hand in its own seeded generator, so the cards it sees are always the same.
func use_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng
	_deck = CardDeck.new(rng)


func game() -> String:
	return _table.game if _table != null else ""


func state() -> String:
	return _state


func last_payout() -> int:
	return _last_payout


func last_reels() -> Array[String]:
	return _reels


func blackjack() -> Blackjack:
	return _blackjack


func poker() -> DrawPoker:
	return _poker


func held() -> Array[bool]:
	return _held


func message() -> String:
	return _message


func _ready() -> void:
	# Above the HUD, which shares the screen.
	layer = OVERLAY_LAYER
	_opened_frame = Engine.get_process_frames()
	_card_box = _make_box(CARD_FACE)
	_back_box = _make_box(CARD_BACK)
	var panel := PanelContainer.new()
	panel.position = PANEL_POSITION
	panel.custom_minimum_size = PANEL_SIZE
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_title.text = ArcadeTable.display_name(game())
	column.add_child(_title)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", INFO_FONT_SIZE)
	column.add_child(_info)
	_felt = FeltView.new()
	_felt.panel = self
	_felt.custom_minimum_size = FELT_SIZE
	_felt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_felt)
	_message_label = Label.new()
	_message_label.add_theme_font_size_override("font_size", INFO_FONT_SIZE + 1)
	column.add_child(_message_label)
	_holds = HBoxContainer.new()
	column.add_child(_holds)
	_actions = HBoxContainer.new()
	column.add_child(_actions)
	_held.clear()
	for i in HAND_CARDS:
		_held.append(false)
	if game() != ArcadeTable.SLOT:
		_message = CHOOSE_BET
	_refresh()


func _process(_delta: float) -> void:
	# The press that opened the overlay must not close it again.
	if Engine.get_process_frames() != _opened_frame and Input.is_action_just_pressed("interact"):
		leave()


# Finishes any hand in play, then asks to close.
func leave() -> void:
	finish_hand()
	closed.emit()


func finish_hand() -> void:
	if _state != PLAYING:
		return
	if game() == ArcadeTable.BLACKJACK:
		stand()
	elif game() == ArcadeTable.POKER:
		draw_cards()


# --- the slot machine ---

func pull() -> bool:
	if game() != ArcadeTable.SLOT:
		return false
	if _table.plays_left <= 0:
		_say(NO_PLAYS)
		return false
	if not _room.arcade_bet(SlotMachine.BET):
		_say(SHORT)
		return false
	_table.use_play()
	_reels = SlotMachine.spin(_rng)
	var won := SlotMachine.payout(_reels, SlotMachine.BET)
	_last_payout = won["pension"]
	_room.arcade_pay(_last_payout)
	if won["item"]:
		_room.arcade_item_win(_table)
		_message = "Three skulls! A free item waits by the table."
	elif won["full_heal"]:
		_room.arcade_full_heal()
		_message = "Three pills! Every pill back."
	elif _last_payout > SlotMachine.BET:
		_message = "Three of a kind! %d back." % _last_payout
	elif _last_payout > 0:
		_message = "A pair. Your %d back." % _last_payout
	else:
		_message = "Nothing. The reels are very sorry."
	_state = DONE
	_refresh()
	return true


# --- blackjack and draw poker ---

func bet(amount: int) -> bool:
	if game() == ArcadeTable.SLOT or _state == PLAYING or not Blackjack.BETS.has(amount):
		return false
	if _table.plays_left <= 0:
		_say(NO_PLAYS)
		return false
	if not _room.arcade_bet(amount):
		_say(SHORT)
		return false
	_table.use_play()
	_bet = amount
	_last_payout = 0
	_deck.shuffle()
	_state = PLAYING
	_message = ""
	if game() == ArcadeTable.BLACKJACK:
		_blackjack = Blackjack.new(_deck)
		_blackjack.deal()
		if _blackjack.is_over:
			_settle()
	else:
		_poker = DrawPoker.new(_deck)
		_poker.deal()
		for i in HAND_CARDS:
			_held[i] = false
		_message = "Hold any cards, then draw once."
	_refresh()
	return true


func hit() -> void:
	if game() != ArcadeTable.BLACKJACK or _state != PLAYING:
		return
	_blackjack.hit()
	if _blackjack.is_over:
		_settle()
	_refresh()


func stand() -> void:
	if game() != ArcadeTable.BLACKJACK or _state != PLAYING:
		return
	_blackjack.stand()
	_settle()
	_refresh()


func toggle_hold(index: int) -> void:
	if game() != ArcadeTable.POKER or _state != PLAYING or index < 0 or index >= HAND_CARDS:
		return
	_held[index] = not _held[index]
	_refresh()


func draw_cards() -> void:
	if game() != ArcadeTable.POKER or _state != PLAYING:
		return
	_poker.draw(_held)
	_settle()
	_refresh()


# Pays what the rules say for the finished hand.
func _settle() -> void:
	if game() == ArcadeTable.BLACKJACK:
		var result := _blackjack.outcome()
		_last_payout = Blackjack.payout(result, _bet)
		match result:
			Blackjack.BLACKJACK:
				_message = "Blackjack! %d back." % _last_payout
			Blackjack.WIN:
				_message = "You win! %d back." % _last_payout
			Blackjack.PUSH:
				_message = "A push. Your %d back." % _last_payout
			Blackjack.BUST:
				_message = "Bust. The house is very understanding."
			_:
				_message = "The house wins."
	else:
		var hand_name := DrawPoker.rank_hand(_poker.hand)
		_last_payout = DrawPoker.payout(hand_name, _bet)
		if _last_payout > 0:
			_message = "%s! %d back." % [DrawPoker.display_name(hand_name), _last_payout]
		else:
			_message = "Nothing this time."
	_room.arcade_pay(_last_payout)
	_state = DONE


func _say(text: String) -> void:
	_message = text
	_refresh()


# --- the buttons ---

func _refresh() -> void:
	if _actions == null:
		return
	_info.text = _info_text()
	_message_label.text = _message
	for child in _holds.get_children():
		child.queue_free()
	for child in _actions.get_children():
		child.queue_free()
	var plays_left := _table.plays_left > 0
	match game():
		ArcadeTable.SLOT:
			var pull_button := _add_button(_actions, "Pull for %d" % SlotMachine.BET, pull)
			pull_button.disabled = not plays_left
		ArcadeTable.BLACKJACK:
			if _state == PLAYING:
				_add_button(_actions, "Hit", hit)
				_add_button(_actions, "Stand", stand)
			else:
				_add_bet_buttons(plays_left)
		ArcadeTable.POKER:
			if _state == PLAYING:
				for i in HAND_CARDS:
					_add_button(_holds, "Held" if _held[i] else "Hold", toggle_hold.bind(i))
				_add_button(_actions, "Draw", draw_cards)
			else:
				_add_bet_buttons(plays_left)
	_add_button(_actions, KeyBindings.with_key("interact", "Leave"), leave)
	_holds.visible = game() == ArcadeTable.POKER and _state == PLAYING
	_felt.queue_redraw()


func _add_bet_buttons(plays_left: bool) -> void:
	for amount in Blackjack.BETS:
		var button := _add_button(_actions, "Bet %d" % amount, bet.bind(amount))
		button.disabled = not plays_left


func _add_button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	row.add_child(button)
	return button


func _info_text() -> String:
	var left := "Pulls" if game() == ArcadeTable.SLOT else "Hands"
	return "Pension: %d     %s left this visit: %d" % [_room.arcade_balance(), left, _table.plays_left]


static func _make_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(4)
	box.set_border_width_all(1)
	box.border_color = CARD_EDGE
	return box


# --- the felt ---

func _draw_felt(canvas: Control) -> void:
	var area := Rect2(Vector2.ZERO, canvas.size)
	canvas.draw_rect(area, FELT)
	canvas.draw_rect(area, FELT_EDGE, false, 2.0)
	match game():
		ArcadeTable.SLOT:
			_draw_reels(canvas)
		ArcadeTable.BLACKJACK:
			_draw_blackjack(canvas)
		ArcadeTable.POKER:
			_draw_poker(canvas)


func _draw_reels(canvas: Control) -> void:
	var middle := canvas.size.x / 2.0
	for i in SlotMachine.REELS:
		var center := Vector2(middle + (i - 1) * (REEL_SIZE.x + 14.0), 14.0 + REEL_SIZE.y / 2.0)
		var box := Rect2(center - REEL_SIZE / 2.0, REEL_SIZE)
		canvas.draw_rect(box, REEL_FACE)
		canvas.draw_rect(box, REEL_EDGE, false, 2.0)
		if i < _reels.size():
			draw_symbol(canvas, _reels[i], center + Vector2(0, -8))
			_text(canvas, SYMBOL_NAMES.get(_reels[i], _reels[i]), Vector2(box.position.x + 4.0, box.end.y - 6.0), 9, REEL_EDGE)
	_text(canvas, SLOT_RULES, Vector2(10, canvas.size.y - 18.0), 9, FELT_TEXT)
	_text(canvas, SLOT_RULES_2, Vector2(10, canvas.size.y - 7.0), 9, FELT_TEXT)


func _draw_blackjack(canvas: Control) -> void:
	if _blackjack == null:
		_text(canvas, "Dealer stands on 17. Win 2x, blackjack 2.5x, a push returns the bet.", Vector2(10, 20), 10, FELT_TEXT)
		return
	var hide_hole := _state == PLAYING
	_draw_hand_row(canvas, "Dealer", _blackjack.dealer, 8.0, hide_hole)
	_draw_hand_row(canvas, "You", _blackjack.player, 84.0, false)


func _draw_hand_row(canvas: Control, who: String, cards: Array[int], top: float, hide_second: bool) -> void:
	var shown := "?" if hide_second else str(Blackjack.hand_value(cards))
	_text(canvas, who, Vector2(10, top + 20.0), 11, FELT_TEXT)
	_text(canvas, shown, Vector2(10, top + 36.0), 11, FELT_TEXT)
	for i in cards.size():
		var rect := Rect2(Vector2(64.0 + i * (CARD_SIZE.x + 6.0), top), CARD_SIZE)
		if hide_second and i == 1:
			_draw_back(canvas, rect)
		else:
			draw_card(canvas, cards[i], rect)


func _draw_poker(canvas: Control) -> void:
	if _poker == null or _poker.hand.is_empty():
		_text(canvas, "Deal 5, hold any, draw once. Jacks or better pays.", Vector2(10, 20), 10, FELT_TEXT)
	else:
		for i in _poker.hand.size():
			var rect := Rect2(Vector2(10.0 + i * (POKER_CARD_SIZE.x + 10.0), 18.0), POKER_CARD_SIZE)
			draw_card(canvas, _poker.hand[i], rect)
			if _state == PLAYING and _held[i]:
				_text(canvas, "HELD", Vector2(rect.position.x + 6.0, rect.end.y + 14.0), 10, HELD_COLOR)
	# The table, best hand first.
	var row := 0
	for hand_name in DrawPoker.HANDS:
		var line := "%s  %dx" % [DrawPoker.display_name(hand_name), DrawPoker.PAYTABLE[hand_name]]
		_text(canvas, line, Vector2(330, 16.0 + row * 14.0), 10, FELT_TEXT)
		row += 1


func _draw_back(canvas: Control, rect: Rect2) -> void:
	_back_box.draw(canvas.get_canvas_item(), rect)
	canvas.draw_rect(rect.grow(-5.0), CARD_BACK_LINE, false, 1.0)


func draw_card(canvas: Control, card: int, rect: Rect2) -> void:
	_card_box.draw(canvas.get_canvas_item(), rect)
	var color := RED_SUIT if CardDeck.is_red(card) else BLACK_SUIT
	_text(canvas, CardDeck.rank_label(card), rect.position + Vector2(4, 13), 12, color)
	draw_suit(canvas, CardDeck.suit(card), rect.get_center() + Vector2(0, 6), rect.size.x * 0.45, color)


# Suits are drawn as shapes, so they never depend on the font having the symbols.
static func draw_suit(canvas: CanvasItem, suit: int, center: Vector2, size: float, color: Color) -> void:
	var r := size * 0.27
	match suit:
		0:
			canvas.draw_circle(center + Vector2(-r * 0.95, r * 0.25), r, color)
			canvas.draw_circle(center + Vector2(r * 0.95, r * 0.25), r, color)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -size * 0.55), center + Vector2(-size * 0.5, r * 0.15), center + Vector2(size * 0.5, r * 0.15)]), color)
			canvas.draw_colored_polygon(PackedVector2Array([center, center + Vector2(-r * 0.7, size * 0.5), center + Vector2(r * 0.7, size * 0.5)]), color)
		1:
			canvas.draw_circle(center + Vector2(-r * 0.95, -r * 0.4), r, color)
			canvas.draw_circle(center + Vector2(r * 0.95, -r * 0.4), r, color)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-size * 0.5, -r * 0.2), center + Vector2(size * 0.5, -r * 0.2), center + Vector2(0, size * 0.55)]), color)
		2:
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -size * 0.55), center + Vector2(size * 0.38, 0), center + Vector2(0, size * 0.55), center + Vector2(-size * 0.38, 0)]), color)
		_:
			canvas.draw_circle(center + Vector2(0, -r * 1.05), r, color)
			canvas.draw_circle(center + Vector2(-r * 1.05, r * 0.35), r, color)
			canvas.draw_circle(center + Vector2(r * 1.05, r * 0.35), r, color)
			canvas.draw_colored_polygon(PackedVector2Array([center, center + Vector2(-r * 0.7, size * 0.55), center + Vector2(r * 0.7, size * 0.55)]), color)


# Each reel symbol drawn in code, about 30 pixels across.
static func draw_symbol(canvas: CanvasItem, symbol: String, center: Vector2) -> void:
	match symbol:
		"cherry":
			canvas.draw_line(center + Vector2(-7, 6), center + Vector2(1, -14), Color("3f7a32"), 2.0)
			canvas.draw_line(center + Vector2(8, 8), center + Vector2(1, -14), Color("3f7a32"), 2.0)
			canvas.draw_circle(center + Vector2(-7, 8), 7.0, Color("c8263c"))
			canvas.draw_circle(center + Vector2(8, 10), 7.0, Color("c8263c"))
		"bell":
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-5, -14), center + Vector2(5, -14), center + Vector2(13, 8), center + Vector2(-13, 8)]), Color("e8b830"))
			canvas.draw_rect(Rect2(center + Vector2(-15, 8), Vector2(30, 4)), Color("b8862a"))
			canvas.draw_circle(center + Vector2(0, 14), 3.5, Color("8a5a1a"))
		"pill":
			canvas.draw_circle(center + Vector2(-9, 0), 7.0, Color("c8463c"))
			canvas.draw_rect(Rect2(center + Vector2(-9, -7), Vector2(9, 14)), Color("c8463c"))
			canvas.draw_circle(center + Vector2(9, 0), 7.0, Color("ece9e0"))
			canvas.draw_rect(Rect2(center + Vector2(0, -7), Vector2(9, 14)), Color("ece9e0"))
		"skull":
			canvas.draw_circle(center + Vector2(0, -3), 12.0, Color("ece9e0"))
			canvas.draw_rect(Rect2(center + Vector2(-7, 5), Vector2(14, 8)), Color("ece9e0"))
			canvas.draw_circle(center + Vector2(-5, -3), 3.0, Color("1a1620"))
			canvas.draw_circle(center + Vector2(5, -3), 3.0, Color("1a1620"))
			canvas.draw_line(center + Vector2(-3, 9), center + Vector2(-3, 13), Color("1a1620"), 1.0)
			canvas.draw_line(center + Vector2(3, 9), center + Vector2(3, 13), Color("1a1620"), 1.0)
		"coin":
			canvas.draw_circle(center, 13.0, Color("e8b830"))
			canvas.draw_circle(center, 9.0, Color("c8962a"))
			canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-4, 5), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff3c0"))
		"dentures":
			canvas.draw_rect(Rect2(center + Vector2(-14, -9), Vector2(28, 18)), Color("e88a9a"))
			for i in 5:
				canvas.draw_rect(Rect2(center + Vector2(-12 + i * 5, -7), Vector2(4, 6)), Color("fbfaf5"))
				canvas.draw_rect(Rect2(center + Vector2(-12 + i * 5, 1), Vector2(4, 6)), Color("fbfaf5"))
		_:
			canvas.draw_circle(center, 10.0, Color("8f8ba0"))


static func _text(canvas: CanvasItem, text: String, at: Vector2, font_size: int, color: Color) -> void:
	canvas.draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
