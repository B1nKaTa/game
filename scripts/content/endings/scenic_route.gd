extends RefCounted

# Ending 9, The Scenic Route: home the long way, sunburnt and in a terrible hat, with photos for Gerald,
# who has never been anywhere. Then the jet lag.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y
const SUNBURN := Color(1.0, 0.72, 0.66)


static func steps(_variant := 0) -> Array:
	return [
		S.stage("airport_home"),
		S.actor("harold", Vector2(340, G), -1),
		S.actor("souvenirs", Vector2(354, G)),
		S.tint("harold", SUNBURN),
		S.hat("harold", "straw"),
		S.fade_in(1.0),
		S.walk("souvenirs", Vector2(184, G), 40.0, false),
		S.walk("harold", Vector2(170, G), 40.0),
		S.say("harold", "Every floor. The long way round. Not one shortcut."),
		S.fade_out(0.5),
		S.stage("fence"),
		S.actor("gerald", Vector2(226, G), -1),
		S.actor("harold", Vector2(178, G), 1),
		S.actor("souvenirs", Vector2(160, G)),
		S.fade_in(0.5),
		S.say("harold", "Gerald! My holiday photos."),
		S.actor("photos", Vector2(202, G - 22)),
		S.say("harold", "That's me in the sea. That's me on a golf course. That's me on a boat."),
		S.say("gerald", "...I've never been anywhere."),
		S.say("harold", "I know."),
		S.say("harold", "And in the second week, we took a little bus up to the..."),
		S.anim("harold", "faint"),
		S.hide("photos"),
		S.actor("zzz", Vector2(166, G - 14)),
		S.wait(1.0),
		S.say("gerald", "Harold?"),
		S.wait(0.8),
		S.card("Cause of death: jet lag."),
		S.fade_out(1.0),
	]
