class_name DrawPoker
extends RefCounted

# One hand: five cards, hold any, draw once. The table says how many times the bet comes back for
# each hand, so jacks or better hands the bet back and a royal flush 50 times it. Anything less than
# a pair of jacks is "nothing" and pays nothing.
const NOTHING := "nothing"
const JACKS_OR_BETTER := "jacks_or_better"
const TWO_PAIR := "two_pair"
const THREE_OF_A_KIND := "three_of_a_kind"
const STRAIGHT := "straight"
const FLUSH := "flush"
const FULL_HOUSE := "full_house"
const FOUR_OF_A_KIND := "four_of_a_kind"
const STRAIGHT_FLUSH := "straight_flush"
const ROYAL_FLUSH := "royal_flush"
# Best first, as the table is shown.
const HANDS: Array[String] = [ROYAL_FLUSH, STRAIGHT_FLUSH, FOUR_OF_A_KIND, FULL_HOUSE, FLUSH, STRAIGHT, THREE_OF_A_KIND, TWO_PAIR, JACKS_OR_BETTER]
const PAYTABLE := {
	JACKS_OR_BETTER: 1,
	TWO_PAIR: 2,
	THREE_OF_A_KIND: 3,
	STRAIGHT: 4,
	FLUSH: 6,
	FULL_HOUSE: 9,
	FOUR_OF_A_KIND: 25,
	STRAIGHT_FLUSH: 40,
	ROYAL_FLUSH: 50,
}
const NAMES := {
	NOTHING: "Nothing",
	JACKS_OR_BETTER: "Jacks or better",
	TWO_PAIR: "Two pair",
	THREE_OF_A_KIND: "Three of a kind",
	STRAIGHT: "Straight",
	FLUSH: "Flush",
	FULL_HOUSE: "Full house",
	FOUR_OF_A_KIND: "Four of a kind",
	STRAIGHT_FLUSH: "Straight flush",
	ROYAL_FLUSH: "Royal flush",
}
const BETS: Array[int] = [10, 25, 50]
const HAND_SIZE := 5
const LOWEST_PAYING_PAIR := 11

var deck: CardDeck
var hand: Array[int] = []
# True once the one draw has been taken.
var has_drawn := false


func _init(card_deck: CardDeck) -> void:
	deck = card_deck


func deal() -> Array[int]:
	hand.clear()
	has_drawn = false
	for i in HAND_SIZE:
		hand.append(deck.draw())
	return hand


# Every card not held is replaced, once.
func draw(held: Array[bool]) -> Array[int]:
	if has_drawn or hand.size() < HAND_SIZE:
		return hand
	for i in HAND_SIZE:
		var keep := i < held.size() and held[i]
		if not keep:
			hand[i] = deck.draw()
	has_drawn = true
	return hand


static func rank_hand(cards: Array) -> String:
	if cards.size() != HAND_SIZE:
		return NOTHING
	var counts := {}
	var is_flush := true
	var first_suit := CardDeck.suit(cards[0])
	var lowest := CardDeck.RANK_HIGH + 1
	var highest := 0
	for card in cards:
		var card_rank := CardDeck.rank(card)
		counts[card_rank] = int(counts.get(card_rank, 0)) + 1
		lowest = mini(lowest, card_rank)
		highest = maxi(highest, card_rank)
		if CardDeck.suit(card) != first_suit:
			is_flush = false
	var pairs := 0
	var high_pair := false
	var trips := false
	var quads := false
	for counted_rank in counts:
		match int(counts[counted_rank]):
			2:
				pairs += 1
				if int(counted_rank) >= LOWEST_PAYING_PAIR:
					high_pair = true
			3:
				trips = true
			4:
				quads = true
	var is_straight := false
	if counts.size() == HAND_SIZE:
		# The ace also plays low, under a 2, in A-2-3-4-5.
		var wheel := counts.has(14) and counts.has(2) and counts.has(3) and counts.has(4) and counts.has(5)
		is_straight = highest - lowest == HAND_SIZE - 1 or wheel
	if is_straight and is_flush:
		return ROYAL_FLUSH if lowest == 10 else STRAIGHT_FLUSH
	if quads:
		return FOUR_OF_A_KIND
	if trips and pairs == 1:
		return FULL_HOUSE
	if is_flush:
		return FLUSH
	if is_straight:
		return STRAIGHT
	if trips:
		return THREE_OF_A_KIND
	if pairs == 2:
		return TWO_PAIR
	if high_pair:
		return JACKS_OR_BETTER
	return NOTHING


# What comes back for the bet, the bet included.
static func payout(hand_name: String, bet: int) -> int:
	return bet * int(PAYTABLE.get(hand_name, 0))


static func display_name(hand_name: String) -> String:
	return NAMES.get(hand_name, NAMES[NOTHING])
