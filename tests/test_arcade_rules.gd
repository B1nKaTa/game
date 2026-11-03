extends TestCase


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _card(rank: int, suit := 0) -> int:
	return rank * 4 + suit


func test_a_deck_holds_52_different_cards_and_the_same_seed_deals_the_same() -> void:
	var a := CardDeck.new(_rng(5))
	var b := CardDeck.new(_rng(5))
	var seen := {}
	for i in 52:
		var card := a.draw()
		assert_eq(card, b.draw())
		seen[card] = true
	assert_eq(seen.size(), 52)


func test_cards_name_their_rank_and_suit() -> void:
	assert_eq(CardDeck.rank(_card(12, 1)), 12)
	assert_eq(CardDeck.suit(_card(12, 1)), 1)
	assert_eq(CardDeck.label(_card(12, 1)), "Q♥")
	assert_eq(CardDeck.label(_card(10, 0)), "10♠")
	assert_true(CardDeck.is_red(_card(5, 2)))
	assert_false(CardDeck.is_red(_card(5, 3)))


func test_aces_count_high_until_they_would_bust() -> void:
	assert_eq(Blackjack.hand_value([_card(14), _card(13)]), 21)
	assert_eq(Blackjack.hand_value([_card(14), _card(14), _card(9)]), 21)
	assert_eq(Blackjack.hand_value([_card(10), _card(9), _card(5)]), 24)
	assert_true(Blackjack.is_blackjack([_card(14), _card(12)]))


func test_blackjack_payouts() -> void:
	assert_eq(Blackjack.payout("win", 10), 20)
	assert_eq(Blackjack.payout("blackjack", 10), 25)
	assert_eq(Blackjack.payout("push", 10), 10)
	assert_eq(Blackjack.payout("lose", 10), 0)


func test_the_dealer_stands_on_a_soft_17() -> void:
	var deck := CardDeck.new(_rng(1))
	# Dealt in turn: Grandpa 10, dealer ace, Grandpa 8, dealer 6, then a 5 waiting on top.
	deck.stack([_card(10), _card(14), _card(8), _card(6), _card(5)])
	var game := Blackjack.new(deck)
	game.deal()
	assert_false(game.is_over)
	game.stand()
	assert_eq(game.dealer.size(), 2, "a soft 17 draws nothing")
	assert_eq(game.outcome(), "win")


func test_a_bust_ends_the_hand_and_loses() -> void:
	var deck := CardDeck.new(_rng(1))
	deck.stack([_card(10), _card(9), _card(6), _card(9), _card(13)])
	var game := Blackjack.new(deck)
	game.deal()
	game.hit()
	assert_true(game.is_over)
	assert_eq(game.outcome(), "bust")


func test_poker_hands_are_ranked() -> void:
	assert_eq(DrawPoker.rank_hand([_card(10, 1), _card(11, 1), _card(12, 1), _card(13, 1), _card(14, 1)]), "royal_flush")
	assert_eq(DrawPoker.rank_hand([_card(11), _card(11, 1), _card(3), _card(5, 2), _card(9)]), "jacks_or_better")
	assert_eq(DrawPoker.rank_hand([_card(10), _card(10, 1), _card(3), _card(5, 2), _card(9)]), "nothing", "tens are not enough")
	assert_eq(DrawPoker.rank_hand([_card(14), _card(2, 1), _card(3), _card(4, 2), _card(5)]), "straight", "the ace plays low")


func test_more_poker_hands_and_the_table_ends() -> void:
	assert_eq(DrawPoker.rank_hand([_card(9), _card(9, 1), _card(9, 2), _card(4), _card(4, 1)]), "full_house")
	assert_eq(DrawPoker.rank_hand([_card(2, 3), _card(7, 3), _card(9, 3), _card(11, 3), _card(13, 3)]), "flush")
	assert_eq(DrawPoker.rank_hand([_card(5), _card(5, 1), _card(5, 2), _card(5, 3), _card(13)]), "four_of_a_kind")
	assert_eq(DrawPoker.payout("jacks_or_better", 10), 10)
	assert_eq(DrawPoker.payout("royal_flush", 10), 500)
	assert_eq(DrawPoker.payout("nothing", 50), 0)


func test_a_poker_draw_keeps_the_held_cards_and_happens_once() -> void:
	var deck := CardDeck.new(_rng(3))
	var game := DrawPoker.new(deck)
	var first := game.deal().duplicate()
	var held: Array[bool] = [true, false, true, false, false]
	var after := game.draw(held).duplicate()
	assert_eq(after[0], first[0])
	assert_eq(after[2], first[2])
	assert_true(after[1] != first[1] and after[3] != first[3] and after[4] != first[4], "the rest are new cards")
	var none: Array[bool] = [false, false, false, false, false]
	assert_eq(game.draw(none), after, "only one draw")


func test_three_skulls_give_an_item_and_three_pills_a_full_heal() -> void:
	assert_true(SlotMachine.payout(["skull", "skull", "skull"], 10)["item"])
	assert_true(SlotMachine.payout(["pill", "pill", "pill"], 10)["full_heal"])
	assert_eq(SlotMachine.payout(["bell", "bell", "cherry"], 10)["pension"], 10, "a pair returns the bet")
	assert_eq(SlotMachine.payout(["coin", "coin", "coin"], 10)["pension"], 50)
	assert_eq(SlotMachine.payout(["coin", "bell", "cherry"], 10)["pension"], 0)


func test_a_spin_lands_three_known_symbols() -> void:
	var rng := _rng(4)
	for i in 50:
		var reels := SlotMachine.spin(rng)
		assert_eq(reels.size(), 3)
		for symbol in reels:
			assert_true(SlotMachine.SYMBOLS.has(symbol), symbol)


func test_each_game_returns_about_ninety_percent() -> void:
	# Item and heal wins count at the Pension a shop charges for them, so the slot's return is comparable.
	for game in ["slot", "blackjack", "poker"]:
		var back := ArcadeOdds.simulated_return(game, 20000, _rng(9))
		assert_true(back > 0.85 and back < 0.95, "%s returns %f" % [game, back])
