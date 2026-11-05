class_name CoachTips
extends RefCounted

# What Coach Bertram, Retired PE Teacher, says in the Training Yard: the basics on a first visit, then
# a tip for each rack item Grandpa holds. test_training_yard checks every item has a tip.

const FIRST_VISIT: Array[String] = [
	"Right! Click to swing, hold to charge. Three swings make a combo.",
	"Right click throws the teeth. They come back. Usually.",
	"Space to dodge. Dodging is not running away. It's tactical.",
	"Try anything off the rack. It's free in here. Out there it isn't.",
]

const TIPS := {
	"alert_bracelet": "One more pill, and an alarm when you're down to your last. Use the stun to get out, not in.",
	"bifocals": "See their health? Good. Finish the weak ones first, that's where it hits hardest.",
	"bingo_card": "Every fifth coin's a big one. Pick them all up. Every one counts.",
	"comfort_care_lanyard": "Every heal gives a bit extra. Take hits early, heal late.",
	"dentures": "Line them up and throw through the lot. Teeth first, questions later.",
	"golden_parachute": "A soft landing for your Pension. Not for you. Don't test it.",
	"hearing_aid": "Watch the edge of the screen. The arrows tell you who's waiting round the corner.",
	"life_jacket": "It saves you once a floor. Twice is asking a lot of a jacket.",
	"lucky_tee": "Lucky swings come when they come. Keep swinging, that's the trick.",
	"naughty_list": "Bosses who call friends bring presents. Clear the friends.",
	"neck_pillow": "One more pill, and a full rest on every landing. Get to the stairs.",
	"nitro_tablets": "Big hits. But big hits on you go bang too. Stand where the bang helps.",
	"pill_organizer": "Full up? Take the heal anyway. It waits in the box for the next knock.",
	"pocket_watch": "Dodge late, through the swing. Time slows and you get a free look.",
	"prune_juice": "Dodge all you like. Just know every one costs you. Mind the purse.",
	"senior_discount": "A quarter off in every shop. Spend it, that's what it's for.",
	"slippers": "Wet floor? Not for you. Fight on the wet, let them slide.",
	"support_stockings": "Sand and sedatives can't stop you now. Walk right through.",
	"titanium_hip": "Dodge through them, not around them. The hip does the rest.",
	"undertakers_gloves": "What you finish stays finished. No bangs, no boxes. Go in close.",
	"walker_tennis_balls": "Knock them back and keep them back. Space is your friend, son.",
	"cane_sword": "Hold the charge all the way. The wave goes further than you can reach.",
	"bingo_dabber": "Same target, five hits. Pick one and stick with it.",
	"rusty_hinge": "Finish the combo every time. The third one sticks them.",
	"reading_glasses": "Let them bunch up, then swing through the lot. Dodge's yours again.",
	"rocking_chair": "Dodge in, swing at once. Rock and roll, that's the rhythm.",
	"rubber_ferrule": "Quicker swings, lighter taps. Keep swinging, it adds up.",
	"knitting_needles": "Every swing throws a stitch. Swing even when they're out of reach.",
	"shoe_horn": "When they wind up, you wade in. Hit them mid-breath.",
	"brass_topper": "Surrounded? Finish a combo. The topper hits all round.",
	"rolling_pin": "Slow, but it hits both ways. Stand in the middle and let them come.",
	"reapers_scythe": "Charge it up in a crowd. One sweep, all round, nobody left.",
}

const DEFAULT_TIP := "Pick something off the rack and I'll tell you what it's good for."


# The basics on a first visit, else the opener and one tip per held item in the order held, else the
# opener and the default.
static func lines_for(held: Array[ItemDef], first_visit: bool, opener := "") -> Array[String]:
	var lines: Array[String] = []
	if first_visit:
		lines.append_array(FIRST_VISIT)
		return lines
	if not opener.is_empty():
		lines.append(opener)
	for item in held:
		if TIPS.has(item.id):
			lines.append(TIPS[item.id])
	if lines.size() == (0 if opener.is_empty() else 1):
		lines.append(DEFAULT_TIP)
	return lines


# What he opens with: a word on a death or a boss beaten in the run just played, else the next of his
# lines, one per run.
static func opener(coach: NpcDef, last_run: Dictionary, run_number: int) -> String:
	if coach == null:
		return ""
	if last_run.get("died", false) and not coach.moment("died").is_empty():
		return coach.moment("died")
	if int(last_run.get("bosses", 0)) > 0 and not coach.moment("boss_win").is_empty():
		return coach.moment("boss_win")
	if coach.lines.is_empty():
		return ""
	return coach.lines[posmod(run_number, coach.lines.size())]
