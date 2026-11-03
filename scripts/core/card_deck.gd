class_name CardDeck
extends RefCounted

# One 52-card deck. A card is an int, rank * 4 + suit, with ranks 2 to 14 (the ace is 14) and suits
# 0 to 3. It shuffles with its own generator, never the global one, so a seed always deals the same.
const RANK_LOW := 2
const RANK_HIGH := 14
const SUITS := 4
const SIZE := 52
const SUIT_LABELS: Array[String] = ["♠", "♥", "♦", "♣"]
const RANK_LABELS := {11: "J", 12: "Q", 13: "K", 14: "A"}
# Hearts and diamonds are drawn red.
const RED_SUITS: Array[int] = [1, 2]

var _rng: RandomNumberGenerator
# The cards still to deal. The next card is the last one, so drawing is cheap.
var _cards: Array[int] = []


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng
	shuffle()


# Gathers all 52 cards back and shuffles them.
func shuffle() -> void:
	_cards.clear()
	for card_rank in range(RANK_LOW, RANK_HIGH + 1):
		for card_suit in SUITS:
			_cards.append(card_rank * SUITS + card_suit)
	for i in range(_cards.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := _cards[i]
		_cards[i] = _cards[j]
		_cards[j] = swap


# Sets the cards to come, first in the list dealt first. For tests and checks that need a known hand.
func stack(cards: Array) -> void:
	_cards.clear()
	for i in range(cards.size() - 1, -1, -1):
		_cards.append(int(cards[i]))


# An empty deck is gathered and shuffled again, so a hand can never run out of cards.
func draw() -> int:
	if _cards.is_empty():
		shuffle()
	return _cards.pop_back()


func cards_left() -> int:
	return _cards.size()


static func rank(card: int) -> int:
	return floori(card / float(SUITS))


static func suit(card: int) -> int:
	return card % SUITS


static func is_red(card: int) -> bool:
	return RED_SUITS.has(suit(card))


static func rank_label(card: int) -> String:
	var card_rank := rank(card)
	return RANK_LABELS.get(card_rank, str(card_rank))


static func label(card: int) -> String:
	return rank_label(card) + SUIT_LABELS[suit(card)]
