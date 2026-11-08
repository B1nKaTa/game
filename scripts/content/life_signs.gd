class_name LifeSigns
extends RefCounted

# The lines on the Flashback Cinema's lobby cards (LifeSign): small true things about Harold's whole
# life, his wife and children, the bus depot, his first car, holidays, hobbies, the long feud with
# Gerald over the hedge and the fence, and Biscuit the dog. Each line belongs to one of the screen's
# films (CinemaScenes), and a card beside a screen only ever shows a line of the film that screen is
# playing, so the card and the picture always tell the same moment.
#
# A line keeps its id from the first cut wherever its words stayed, so a save's life_signs_seen still
# knows it. A line is shown at most once a run, in an order the run's seed sets, and the save remembers
# every line shown (life_signs_seen, stamped in the order they were seen), so a later run starts with
# lines it has not shown before and, once all have been seen, with the ones seen longest ago.
const ALL: Array[Dictionary] = [
	# The hedge, 1974.
	{"id": "hedge_1974", "scene": "hedge_1974", "text": "1974. The hedge went up. Gerald says it's on his side. It isn't."},
	{"id": "gerald_tape", "scene": "hedge_1974", "text": "1975. Gerald bought a tape measure. Harold bought a longer one."},
	{"id": "gerald_trim", "scene": "hedge_1974", "text": "Harold trimmed the hedge to the inch. Gerald trimmed his side to the inch and a quarter."},
	# Fixing the fence.
	{"id": "fence_lean", "scene": "fence_fix", "text": "He mended the fence on Saturday. By Sunday it leaned towards Gerald's. He called that a statement."},
	{"id": "gerald_leaves", "scene": "fence_fix", "text": "Autumn. Gerald's leaves blew over the fence. Harold blew them back. It took all weekend. So did Gerald's."},
	# The prize marrow.
	{"id": "gerald_marrow", "scene": "prize_marrow", "text": "The village show. Gerald's marrow won by half an inch. Harold asked for a recount."},
	{"id": "marrow_talk", "scene": "prize_marrow", "text": "He talked to his marrows every evening. Over the fence, somebody took notes."},
	# Walking Biscuit.
	{"id": "biscuit_seven", "scene": "biscuit_walk", "text": "Biscuit, every morning at seven. Same bench. Same pigeon. Neither of them ever won."},
	{"id": "biscuit_name", "scene": "biscuit_walk", "text": "He wanted to call the dog Rex. The children called him Biscuit. The dog sided with the children."},
	# The pigeon on the bench.
	{"id": "pigeon_crumbs", "scene": "pigeon_bench", "text": "Every Tuesday, a bag of crumbs and the same pigeon. It never came closer. He never stopped trying."},
	{"id": "pigeon_name", "scene": "pigeon_bench", "text": "He named the pigeon Reginald. Reginald never knew, and would not have cared."},
	# His first car.
	{"id": "car_dent", "scene": "first_car", "text": "His first car cost forty pounds and came with a dent. He polished round the dent for six years."},
	{"id": "small_driving_test", "scene": "first_car", "text": "Driving test, third attempt. The examiner shook his hand. Harold still thinks it was relief."},
	# At the wheel of the number 12.
	{"id": "depot_number_12", "scene": "bus_route", "text": "He drove the number 12 for twenty years. He still tells strangers to mind the step."},
	{"id": "bus_wave", "scene": "bus_route", "text": "He waved at every bus coming the other way. Most drivers waved back. The rest got a second wave."},
	# The works do.
	{"id": "works_paper_hat", "scene": "works_do", "text": "The depot Christmas do: one paper hat, two sausage rolls, and the foreman's speech, twice."},
	{"id": "depot_tea", "scene": "works_do", "text": "Tea at ten, tea at two, and tea whenever the foreman was out. Harold kept count. It was a lot."},
	# The retirement cake.
	{"id": "depot_clock", "scene": "retirement_cake", "text": "Forty-one years at the depot. One clock. He was never late. The clock was."},
	{"id": "depot_watch", "scene": "retirement_cake", "text": "They gave him a watch when he retired. It ran four minutes fast. He liked it better that way."},
	# The wedding.
	{"id": "wedding_hat", "scene": "wedding_day", "text": "His wedding day. The wind took his hat on the church steps. She caught it. He knew he'd chosen well."},
	{"id": "wedding_suit", "scene": "wedding_day", "text": "He married in his brother's suit. His brother was taller. The pictures are mostly sleeve."},
	{"id": "wedding_speech", "scene": "wedding_day", "text": "His wedding speech lasted nine seconds. Her mother called it the best she had ever heard."},
	# Learning to dance.
	{"id": "small_foxtrot", "scene": "dance_lesson", "text": "He learned the foxtrot to impress her, and remembered the first four steps for fifty years. It worked anyway."},
	{"id": "dance_toes", "scene": "dance_lesson", "text": "Saturday nights at the dance hall. He trod on her toes, said sorry, and asked her for the next one."},
	# The burnt Sunday roast.
	{"id": "small_roast", "scene": "burnt_roast", "text": "The Sunday roast: crisp outside, raw inside, carved with total confidence."},
	{"id": "roast_alarm", "scene": "burnt_roast", "text": "When the smoke alarm went off, the family took their seats. It meant dinner was ready."},
	# A family Christmas.
	{"id": "christmas_cracker", "scene": "family_christmas", "text": "Christmas. He read every cracker joke out loud, then explained it. Then explained it again."},
	{"id": "christmas_turkey", "scene": "family_christmas", "text": "The year Biscuit got the turkey, they had cheese on toast and called it a tradition."},
	# The bike lesson.
	{"id": "bike_got_you", "scene": "bike_lesson", "text": "Bike lessons. He ran behind holding the saddle, shouting 'I've got you!' He hadn't. They were fine."},
	{"id": "bike_puncture", "scene": "bike_lesson", "text": "He could mend anyone's puncture in four minutes. His own took forty, and he blamed a tree."},
	# A day at the seaside.
	{"id": "seaside_gull", "scene": "seaside_day", "text": "A day at the seaside: one ice cream, one gull, and one very short ice cream."},
	{"id": "seaside_hanky", "scene": "seaside_day", "text": "A knotted hanky on his head and trousers rolled to the knee. He called it his summer suit."},
	# The caravan holiday.
	{"id": "caravan_rain", "scene": "caravan_holiday", "text": "A week in a caravan by the sea. It rained for eight days. He called it a cracking week."},
	{"id": "caravan_windbreak", "scene": "caravan_holiday", "text": "He put the windbreak up every morning. The wind took it every afternoon. Neither of them gave in."},
	# The fishing trip.
	{"id": "fishing_boot", "scene": "fishing_trip", "text": "Thirty years of Sunday fishing: one boot, two bicycles, no fish. He called it a hobby."},
	{"id": "fishing_flask", "scene": "fishing_trip", "text": "He went fishing for the peace and quiet. The flask of tea did most of the work."},
	# Painting the shed.
	{"id": "shed_green", "scene": "shed_painting", "text": "He painted the shed green in 1979. Then green again in 1980, because it was the wrong green."},
	{"id": "shed_sign", "scene": "shed_painting", "text": "The shed had a chair, a radio and a sign saying KEEP OUT. The sign was mostly for Gerald."},
	# The lost umbrella.
	{"id": "small_umbrellas", "scene": "lost_umbrella", "text": "He left seventeen umbrellas on buses. Once he found one. It was not his. He kept it."},
	{"id": "depot_lost_property", "scene": "lost_umbrella", "text": "Lost property at the depot: four hundred umbrellas, some false teeth and a trombone. Nobody came for the trombone."},
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


# The film a line belongs to (a CinemaScenes id), or "" for no such line.
static func scene_of(id: String) -> String:
	for line in ALL:
		if line["id"] == id:
			return line["scene"]
	return ""


# Every line of one film, in the pool's order.
static func lines_of(scene_id: String) -> Array[String]:
	var found: Array[String] = []
	for line in ALL:
		if line["scene"] == scene_id:
			found.append(line["id"])
	return found


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
# every line has been. Given a film (scene_id), only that film's lines are offered, so a card beside a
# screen tells the moment the screen is playing; "" offers every line.
static func next_line(seed_text: String, seen: Dictionary, shown: Array[String], scene_id := "") -> String:
	for id in order(seed_text, seen):
		if shown.has(id):
			continue
		if not scene_id.is_empty() and scene_of(id) != scene_id:
			continue
		return id
	return ""


# Picks a card's line and records it as shown, in the run (shown) and in the save (data), the moment
# it first shows. Returns "" when this run has shown every line (of that film, given one).
static func take(seed_text: String, data: ProgressData, shown: Array[String], scene_id := "") -> String:
	var seen: Dictionary = data.life_signs_seen if data != null else {}
	var id := next_line(seed_text, seen, shown, scene_id)
	if id.is_empty():
		return id
	shown.append(id)
	if data != null:
		data.see_life_sign(id)
	return id
