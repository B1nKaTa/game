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
	"glue_gun": "Throw at the big one. The teeth hang on while you work.",
	"spare_set": "Two sets, two lanes. Throw down the middle of a pair.",
	"boomerang_bite": "Throw past them and step aside. The teeth bite coming home.",
	"gold_fillings": "Every bite might pay. Keep the teeth busy.",
	"fizzy_tablet": "Bite the fast ones first. The fizz takes the hurry out of them.",
	"windup_teeth": "Drop the teeth in a doorway. Let them come to you.",
	"overbite": "Longer throws. Pick them off from across the room.",
	"shark_tooth": "Bite and back off. The bleeding does the rest.",
	"bad_hip": "Dodge through the pack, not away. The cough slows the ones behind you.",
	"afterimage": "Dodge late and let them swing at the copy. Then hit them from the side.",
	"wheelchair_wheels": "Roll straight through the crowd. Brakes are for people with time.",
	"velcro_shoes": "Two dodges in your pocket. Save the second for getting back out.",
	"hover_round": "Charge while you walk. Circle them till it's full, then let go.",
	"squeaky_shoes": "They hear you coming, so come quick. Speed's the only cure.",
	"pogo_cane": "Dodge right through the swing. Do it right and you can do it again.",
	"banana_peel": "Dodge early in a fight, where they'll walk. Then watch.",
	"bunion_pads": "Dodge round the furniture all you like. Nothing catches your toes now.",
	"gravity_boots": "Decks roll, fans blow, you stand there. Plant your feet and swing.",
	"life_alert_button": "First knock in a room is free. Use it to get in close.",
	"knitted_cardigan": "Fire's half as bad now. Still bad. Don't stand in it for fun.",
	"casserole_dish": "Pick off the weakest first in every room. Supper's on.",
	"sympathy_card": "Clear every room. Someone might send flowers. Or a pill.",
	"pill_crusher": "Bigger heals, but walk right over them. No reaching.",
	"hot_water_bottle": "Find a quiet corner mid-fight and stand still. Don't get hit.",
	"bubble_wrap": "First shot each floor bounces off. Walk into the first one if you must.",
	"thick_skull": "Blasts hurt less. Less. Still keep your head down, son.",
	"second_opinion": "Save the first heal of a floor for when you're really hurt.",
	"hospital_bracelet": "One more pill. Nothing clever. Just don't waste it.",
	"do_not_resuscitate": "One pill, triple damage. Don't get hit. That's the whole plan, son.",
	"eternal_warranty": "Die once and it sends you back to the door. Once. Don't make a habit of it.",
	"hot_soup_thermos": "Throw it where they're going. Let them walk through the soup.",
	"second_thermos_strap": "More Thermoses, more walls. Knock on the ones that sound hollow.",
	"forged_signature": "Spend your Slips. Every so often one comes back for nothing.",
	"pressure_cooker": "Bigger bang, slower fuse. Drop it early and walk away.",
	"tea_cosy": "Your own blasts can't touch you. Drop it at your feet and stand your ground.",
	"rubber_stamps": "Every Slip pays you back. Open every locked thing you find.",
	"kettle_whistle": "The blast stuns them. Wade in while their ears are still ringing.",
	"coupon_booklet": "One more on the shelf. Look in every shop, there's always something.",
	"penny_jar": "Coins come to you now. Keep fighting, the money follows.",
	"lottery_scratcher": "A bit of cash every floor. Go deeper, scratch more.",
	"pension_statement": "The more you've earned, the more it pays. Clear every room.",
	"loaded_dice": "Win more at the tables, pay more at the tills. Gamble, don't shop.",
	"expired_coupon": "One free shop a floor, but you shrink. Buy the heals, son.",
	"hagglers_hat": "Cheapest thing's half off. Look for it first.",
	"collection_plate": "The first few you finish in a room pay a coin. Finish them quick.",
	"inheritance_letter": "Cash up front. Spend it at the next shop, it's no use to you dead.",
	"tax_refund": "Walk out of a shop with nothing and get paid. Sometimes the best buy is none.",
	"night_light": "When the lights go out, you see twice as far. Keep moving.",
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
