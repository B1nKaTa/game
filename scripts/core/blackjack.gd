class_name Blackjack
extends RefCounted

# One hand against the dealer. Grandpa hits or stands, and the dealer then draws to 17 and stands on
# every 17, soft ones too. A win hands back 2x the bet, a blackjack 2.5x and a push the bet itself.
const WIN := "win"
const BLACKJACK := "blackjack"
const PUSH := "push"
const LOSE := "lose"
const BUST := "bust"
const BETS: Array[int] = [10, 25, 50]
const DEALER_STANDS_ON := 17
const TWENTY_ONE := 21

var deck: CardDeck
var player: Array[int] = []
var dealer: Array[int] = []
# True once the hand is settled: a blackjack on the deal, a bust, or the dealer done drawing.
var is_over := false


func _init(card_deck: CardDeck) -> void:
	deck = card_deck


# Two cards each. A blackjack on either side settles the hand at once.
func deal() -> void:
	player.clear()
	dealer.clear()
	is_over = false
	player.append(deck.draw())
	dealer.append(deck.draw())
	player.append(deck.draw())
	dealer.append(deck.draw())
	if is_blackjack(player) or is_blackjack(dealer):
		is_over = true


# One more card. Going over 21 ends the hand, and reaching 21 stands for him.
func hit() -> void:
	if is_over or player.is_empty():
		return
	player.append(deck.draw())
	var value := hand_value(player)
	if value > TWENTY_ONE:
		is_over = true
	elif value == TWENTY_ONE:
		stand()


func stand() -> void:
	if is_over or player.is_empty():
		return
	while hand_value(dealer) < DEALER_STANDS_ON:
		dealer.append(deck.draw())
	is_over = true


# Aces count 11 until that would bust the hand, then 1.
static func hand_value(cards: Array) -> int:
	var total := 0
	var soft_aces := 0
	for card in cards:
		var card_rank := CardDeck.rank(card)
		if card_rank == CardDeck.RANK_HIGH:
			total += 11
			soft_aces += 1
		elif card_rank >= 10:
			total += 10
		else:
			total += card_rank
	while total > TWENTY_ONE and soft_aces > 0:
		total -= 10
		soft_aces -= 1
	return total


static func is_blackjack(cards: Array) -> bool:
	return cards.size() == 2 and hand_value(cards) == TWENTY_ONE


# How the hand went, once it is over. Two blackjacks push, and a bust loses whatever the dealer holds.
func outcome() -> String:
	var player_blackjack := is_blackjack(player)
	var dealer_blackjack := is_blackjack(dealer)
	if player_blackjack and dealer_blackjack:
		return PUSH
	if player_blackjack:
		return BLACKJACK
	if dealer_blackjack:
		return LOSE
	var mine := hand_value(player)
	if mine > TWENTY_ONE:
		return BUST
	var theirs := hand_value(dealer)
	if theirs > TWENTY_ONE or mine > theirs:
		return WIN
	if mine == theirs:
		return PUSH
	return LOSE


# What comes back for the bet, the bet included.
static func payout(result: String, bet: int) -> int:
	match result:
		WIN:
			return bet * 2
		BLACKJACK:
			return floori(bet * 2.5)
		PUSH:
			return bet
	return 0
