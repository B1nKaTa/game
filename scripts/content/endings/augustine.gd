extends RefCounted

# Not an ending: Augustine, Head of Departures, stamps Harold's pass for eternal rest on every win
# over him, and Harold tears it up. Variant 0 is the whole scene, shown the first time; variant 1 is just
# the stamp and the tear, for every win after.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y
const STAMP := "ETERNAL REST. ONE WAY."
const TEAR := "I'm not resting. I have business."


static func steps(variant := 0) -> Array:
	if variant == 1:
		return [
			S.stage("departures_desk"),
			S.actor("augustine", Vector2(276, G), -1),
			S.actor("harold", Vector2(164, G)),
			S.fade_in(0.4),
			S.anim("augustine", "swing"),
			S.shake(2.0, 0.25),
			S.say("augustine", STAMP),
			S.anim("harold", "swing"),
			S.actor("torn_pass", Vector2(178, 112)),
			S.say("harold", TEAR),
			S.fade_out(0.4),
		]
	return [
		S.stage("departures_desk"),
		S.actor("augustine", Vector2(276, G), -1),
		S.actor("harold", Vector2(50, G)),
		S.fade_in(0.8),
		S.walk("harold", Vector2(164, G)),
		S.say("augustine", "Congratulations, passenger. Your connection is ready."),
		S.say("augustine", "No luggage, no layovers, no coming back."),
		S.actor("boarding_pass", Vector2(258, 104)),
		S.anim("augustine", "swing"),
		S.shake(2.0, 0.25),
		S.say("augustine", STAMP),
		S.walk("boarding_pass", Vector2(178, 106), 60.0),
		S.anim("harold", "swing"),
		S.hide("boarding_pass"),
		S.actor("torn_pass", Vector2(178, 112)),
		S.say("harold", TEAR),
		S.fade_out(0.8),
	]
