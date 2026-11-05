class_name LifeSigns
extends RefCounted

# The lines on the Flashback Cinema's lobby cards (LifeSign): small true things about Harold's life,
# the hedge feud with Gerald, Biscuit the dog, forty-one years at the bus depot, and small wins and
# small failures. Each card shows one line when Harold walks up to it. A line is shown at most once a
# run, in an order the run's seed sets, and the save remembers every line shown (life_signs_seen,
# stamped in the order they were seen), so a later run starts with lines it has not shown before and,
# once all have been seen, with the ones seen longest ago.
const ALL: Array[Dictionary] = [
	{"id": "hedge_1974", "text": "1974. The hedge went up. Gerald says it's on his side. It isn't."},
	{"id": "biscuit_seven", "text": "Biscuit, every morning at seven. Same bench. Same pigeon. Neither of them ever won."},
	{"id": "depot_clock", "text": "Forty-one years at the depot. One clock. He was never late. The clock was."},
	{"id": "gerald_tape", "text": "1975. Gerald bought a tape measure. Harold bought a longer one."},
	{"id": "gerald_ladder", "text": "Gerald borrowed the ladder in 1979. Harold has asked for it back eleven times. Gerald is still using it."},
	{"id": "gerald_card", "text": "Every Christmas, one card from Gerald. Unsigned. Harold knew the handwriting."},
	{"id": "gerald_leaves", "text": "Autumn. Gerald's leaves blew over the fence. Harold blew them back. It took all weekend. So did Gerald's."},
	{"id": "gerald_gnome", "text": "The gnome appeared in 1982, facing Harold's kitchen window. Its little smile never changed."},
	{"id": "gerald_bonfire", "text": "Bonfire night. Gerald lit his first. Harold's was bigger. The fire brigade said both were too big."},
	{"id": "gerald_marrow", "text": "The village show. Gerald's marrow won by half an inch. Harold asked for a recount."},
	{"id": "gerald_car_wash", "text": "Sunday mornings: two men washing two cars, ten yards apart, not speaking. Forty years."},
	{"id": "gerald_good_morning", "text": "Once, in 1991, Gerald said good morning first. Harold did not sleep that night."},
	{"id": "gerald_trim", "text": "Harold trimmed the hedge to the inch. Gerald trimmed his side to the inch and a quarter."},
	{"id": "biscuit_name", "text": "He wanted to call the dog Rex. The children called him Biscuit. The dog sided with the children."},
	{"id": "biscuit_socks", "text": "Biscuit ate one sock a week for nine years. Never a pair. He had standards."},
	{"id": "biscuit_rain", "text": "Biscuit would not walk in the rain. Harold carried him round the block inside his coat. Every time."},
	{"id": "biscuit_postman", "text": "Biscuit loved everyone except the postman, and the postman never found out why."},
	{"id": "biscuit_dig", "text": "Biscuit dug under the fence into Gerald's garden exactly once. Harold gave him a sausage."},
	{"id": "biscuit_trick", "text": "Biscuit knew one trick: sit. He did it whenever he liked."},
	{"id": "biscuit_snore", "text": "Biscuit snored louder than Harold. Nobody believed it until the caravan holiday."},
	{"id": "biscuit_vet", "text": "The vet said Biscuit was overweight. Harold said so was the vet. They changed vets."},
	{"id": "depot_spoon", "text": "1968. The depot got its first ticket machine. Harold fixed it with a spoon. Nobody had asked him to."},
	{"id": "depot_tea", "text": "Tea at ten, tea at two, and tea whenever the foreman was out. Harold kept count. It was a lot."},
	{"id": "depot_month", "text": "Employee of the Month, March 1983. Everyone else was off with the flu."},
	{"id": "depot_number_12", "text": "He drove the number 12 for twenty years. He still tells strangers to mind the step."},
	{"id": "depot_lost_property", "text": "Lost property: four hundred umbrellas, one set of false teeth and a trombone. Nobody came for the trombone."},
	{"id": "depot_kettle", "text": "Harold went on strike once, in 1972, for a better kettle. They got the kettle."},
	{"id": "depot_promotion", "text": "Offered a promotion in 1977. Turned it down. The new office had no window onto the yard."},
	{"id": "depot_gate", "text": "He reversed a double-decker into the depot gate once. They moved the gate. The story stayed."},
	{"id": "depot_watch", "text": "They gave him a watch when he retired. It ran four minutes fast. He liked it better that way."},
	{"id": "small_crossword", "text": "He finished the Saturday crossword on a Tuesday in 1988. He kept the newspaper."},
	{"id": "small_wardrobe", "text": "The wardrobe came flat. It stayed mostly flat. The doors were more of a suggestion."},
	{"id": "small_foxtrot", "text": "He learned the foxtrot for one wedding, and remembered the first four steps for fifty years."},
	{"id": "small_driving_test", "text": "Driving test, third attempt. The examiner shook his hand. Harold still thinks it was relief."},
	{"id": "small_tomatoes", "text": "1996, the year of the tomatoes. Hundreds of them. The whole street ate chutney until spring."},
	{"id": "small_bingo", "text": "One line at the church bingo. He shouted so loud the vicar lost count."},
	{"id": "small_shelf", "text": "He put up a shelf in 1971. It is still up. Nothing has ever been put on it."},
	{"id": "small_roast", "text": "The Sunday roast: crisp outside, raw inside, carved with total confidence."},
	{"id": "small_umbrellas", "text": "He left seventeen umbrellas on buses. Once he found one. It was not his. He kept it."},
	{"id": "small_thumb", "text": "Every holiday photo has a thumb in the corner. The same thumb. Thirty years of thumb."},
]


static func ids() -> Array[String]:
	var found: Array[String] = []
	for line in ALL:
		found.append(line["id"])
	return found


static func text_of(id: String) -> String:
	for line in ALL:
		if line["id"] == id:
			return line["text"]
	return ""


# Every line in the order a run with this seed offers them: lines the save has never seen first, in
# an order of the seed's own, then the seen ones, those seen longest ago first. A line keeps its place
# among the unseen however many others are seen meanwhile.
static func order(seed_text: String, seen: Dictionary) -> Array[String]:
	var fresh: Array[String] = []
	var old: Array[String] = []
	for id in ids():
		if seen.has(id):
			old.append(id)
		else:
			fresh.append(id)
	fresh.sort_custom(func(a: String, b: String) -> bool: return _rank(seed_text, a) < _rank(seed_text, b))
	old.sort_custom(func(a: String, b: String) -> bool: return int(seen[a]) < int(seen[b]) or (int(seen[a]) == int(seen[b]) and _rank(seed_text, a) < _rank(seed_text, b)))
	fresh.append_array(old)
	return fresh


static func _rank(seed_text: String, id: String) -> int:
	return (seed_text + ":" + id).hash()


# The next line a card shows this run: the first in the run's order not yet shown this run, or "" once
# every line has been.
static func next_line(seed_text: String, seen: Dictionary, shown: Array[String]) -> String:
	for id in order(seed_text, seen):
		if not shown.has(id):
			return id
	return ""


# Picks a card's line and records it as shown, in the run (shown) and in the save (data), the moment
# it first shows. Returns "" when this run has shown every line.
static func take(seed_text: String, data: ProgressData, shown: Array[String]) -> String:
	var seen: Dictionary = data.life_signs_seen if data != null else {}
	var id := next_line(seed_text, seen, shown)
	if id.is_empty():
		return id
	shown.append(id)
	if data != null:
		data.see_life_sign(id)
	return id
