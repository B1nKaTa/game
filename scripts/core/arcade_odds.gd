class_name ArcadeOdds
extends RefCounted

# Plays each Arcade game many times with a simple player, to measure how much of the bets comes back.
# The games are set so that this lands near 90%.
# - Slot: an item counts at what a shop asks for one, and a full heal at a little more than a heal.
# - Blackjack: the player hits below 17 and stands from 17 up.
# - Poker: the player keeps any pair or better, else four to a flush, else draws five new cards.
const SLOT := "slot"
const BLACKJACK := "blackjack"
const POKER := "poker"
const ITEM_VALUE := 60
const FULL_HEAL_VALUE := 30
const PLAYER_STANDS_ON := 17
const MADE_HANDS: Array[String] = [DrawPoker.STRAIGHT, DrawPoker.FLUSH, DrawPoker.FULL_HOUSE, DrawPoker.FOUR_OF_A_KIND, DrawPoker.STRAIGHT_FLUSH, DrawPoker.ROYAL_FLUSH]


# How much of the every-table bonus (Lucky Seat Ticket) each game takes. Blackjack already returns about 94%
# and poker hands win often, so they take half: with the dice and Card Shark together every game still
# keeps a share of the bets, at most about 97% coming back (test_items_batch3).
const DICE_SHARE := {SLOT: 1.0, BLACKJACK: 0.5, POKER: 0.5}


# What a win pays once an item's bonus is counted: the bonus is a share of the winnings, the Pension
# above the bet, in whole Pension rounded down. A push or a loss pays as it was.
static func boosted(payout: int, bet: int, bonus: float) -> int:
	if bonus <= 0.0 or payout <= bet:
		return payout
	return payout + floori((payout - bet) * bonus + 0.0001)


# The bonus a game's wins get: its share of every table's (Lucky Seat Ticket), and the poker table's own
# (Card Shark).
static func win_bonus(game: String, every_table: float, poker_table: float) -> float:
	return every_table * float(DICE_SHARE.get(game, 0.0)) + (poker_table if game == POKER else 0.0)


# What came back divided by what was bet, over the given number of rounds at the smallest bet.
# bonus is a win bonus, as win_bonus gives, and bet_index picks the bet of the card games.
static func simulated_return(game: String, rounds: int, rng: RandomNumberGenerator, bonus := 0.0, bet_index := 0) -> float:
	if rounds <= 0:
		return 0.0
	var bet: int = SlotMachine.BET if game == SLOT else Blackjack.BETS[bet_index]
	var back := 0
	var deck := CardDeck.new(rng)
	for i in rounds:
		match game:
			SLOT:
				back += _slot_round(rng, bet, bonus)
			BLACKJACK:
				deck.shuffle()
				back += boosted(_blackjack_round(deck, bet), bet, bonus)
			POKER:
				deck.shuffle()
				back += boosted(_poker_round(deck, bet), bet, bonus)
	return float(back) / float(bet * rounds)


static func _slot_round(rng: RandomNumberGenerator, bet: int, bonus := 0.0) -> int:
	var won := SlotMachine.payout(SlotMachine.spin(rng), bet)
	var value: int = boosted(won["pension"], bet, bonus)
	if won["item"]:
		value += ITEM_VALUE
	if won["full_heal"]:
		value += FULL_HEAL_VALUE
	return value


static func _blackjack_round(deck: CardDeck, bet: int) -> int:
	var game := Blackjack.new(deck)
	game.deal()
	while not game.is_over and Blackjack.hand_value(game.player) < PLAYER_STANDS_ON:
		game.hit()
	game.stand()
	return Blackjack.payout(game.outcome(), bet)


static func _poker_round(deck: CardDeck, bet: int) -> int:
	var game := DrawPoker.new(deck)
	var hand := game.deal()
	game.draw(simple_holds(hand))
	return DrawPoker.payout(DrawPoker.rank_hand(game.hand), bet)


# Which cards the simple poker player keeps.
static func simple_holds(hand: Array) -> Array[bool]:
	var held: Array[bool] = []
	held.resize(hand.size())
	held.fill(false)
	if MADE_HANDS.has(DrawPoker.rank_hand(hand)):
		held.fill(true)
		return held
	var rank_counts := {}
	var suit_counts := {}
	for card in hand:
		var card_rank := CardDeck.rank(card)
		var card_suit := CardDeck.suit(card)
		rank_counts[card_rank] = int(rank_counts.get(card_rank, 0)) + 1
		suit_counts[card_suit] = int(suit_counts.get(card_suit, 0)) + 1
	var kept_any := false
	for i in hand.size():
		if int(rank_counts[CardDeck.rank(hand[i])]) >= 2:
			held[i] = true
			kept_any = true
	if kept_any:
		return held
	for i in hand.size():
		if int(suit_counts[CardDeck.suit(hand[i])]) == DrawPoker.HAND_SIZE - 1:
			held[i] = true
	return held
