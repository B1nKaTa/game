class_name SlotMachine
extends RefCounted

# Three reels, each landing on one symbol by weight. A pair returns the bet, three of a kind pays 5x,
# three skulls give a free item instead and three pills a full heal. The weights are set so that,
# counting an item and a heal at what a shop would ask, about 90% of the bets come back.
const SYMBOLS: Array[String] = ["cherry", "bell", "pill", "skull", "coin", "dentures"]
const WEIGHTS: Array[int] = [15, 11, 4, 2, 4, 4]
const REELS := 3
const PULLS_PER_VISIT := 3
const BET := 10
const TRIPLE_MULT := 5
const ITEM_SYMBOL := "skull"
const HEAL_SYMBOL := "pill"


static func spin(rng: RandomNumberGenerator) -> Array[String]:
	var total := 0
	for weight in WEIGHTS:
		total += weight
	var reels: Array[String] = []
	for i in REELS:
		var roll := rng.randi_range(0, total - 1)
		for s in SYMBOLS.size():
			roll -= WEIGHTS[s]
			if roll < 0:
				reels.append(SYMBOLS[s])
				break
	return reels


# What a pull pays: Pension handed back, and whether it won a free item or a full heal.
static func payout(reels: Array, bet: int) -> Dictionary:
	var result := {"pension": 0, "item": false, "full_heal": false}
	var counts := {}
	for symbol in reels:
		counts[symbol] = int(counts.get(symbol, 0)) + 1
	var best := 0
	var best_symbol := ""
	for symbol in counts:
		if counts[symbol] > best:
			best = counts[symbol]
			best_symbol = symbol
	if best >= REELS:
		if best_symbol == ITEM_SYMBOL:
			result["item"] = true
		elif best_symbol == HEAL_SYMBOL:
			result["full_heal"] = true
		else:
			result["pension"] = bet * TRIPLE_MULT
	elif best == 2:
		result["pension"] = bet
	return result
