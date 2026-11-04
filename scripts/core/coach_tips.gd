class_name CoachTips
extends RefCounted

# What Coach Bertram, Retired PE Teacher, says in the Training Yard: the basics on a first visit, then
# a tip for each rack item Grandpa holds. test_training_yard checks every recipe has a tip.

const FIRST_VISIT: Array[String] = [
	"Right! Click to swing, hold to charge. Three swings make a combo.",
	"Right click throws the teeth. They come back. Usually.",
	"Space to dodge. Dodging is not running away. It's tactical.",
	"Try anything off the rack. It's free in here. Out there it isn't.",
]

const TIPS := {
	"alert_bracelet": "Two extra pills. Don't let it make you careless.",
	"bifocals": "You'll see it coming earlier. Move before the red, not after.",
	"nitro_tablets": "Big hits. Land the third swing of the combo.",
	"senior_discount": "More Pension. Doesn't help you hit. Hit anyway.",
	"support_stockings": "Quicker dodge. Dodge through, not away.",
	"titanium_hip": "Faster on your feet. Circle them.",
}

const DEFAULT_TIP := "Pick something off the rack and I'll tell you what it's good for."


# The basics on a first visit, else one tip per held item in the order held, else the default.
static func lines_for(held: Array[ItemDef], first_visit: bool) -> Array[String]:
	var lines: Array[String] = []
	if first_visit:
		lines.append_array(FIRST_VISIT)
		return lines
	for item in held:
		if TIPS.has(item.id):
			lines.append(TIPS[item.id])
	if lines.is_empty():
		lines.append(DEFAULT_TIP)
	return lines
