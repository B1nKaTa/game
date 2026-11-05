extends RefCounted

# Ending 7, Back from the Dead (Literally): a cursed ticket brings him back the wrong way, green and
# hungry, with a grievance about a lawnmower.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y


static func steps(_variant := 0) -> Array:
	return [
		S.stage("fence"),
		S.actor("gerald", Vector2(226, G), -1),
		S.actor("harold", Vector2(30, G)),
		S.tint("harold", Color(0.65, 1.0, 0.55)),
		S.fade_in(1.0),
		S.walk("harold", Vector2(110, G), 18.0),
		S.say("harold", "Braaains..."),
		S.say("harold", "...and the lawnmower you borrowed in 1986."),
		S.say("gerald", "PEST CONTROL!"),
		S.walk("gerald", Vector2(262, G), 50.0, false),
		S.actor("exterminator", Vector2(350, G), -1),
		S.walk("exterminator", Vector2(212, G), 70.0),
		S.face("gerald", -1),
		S.say("exterminator", "Right. Where's the infestation?"),
		S.walk("harold", Vector2(184, G), 24.0),
		S.anim("harold", "swing"),
		S.shake(2.0, 0.3),
		S.anim("exterminator", "hop"),
		S.say("exterminator", "He BIT me!"),
		S.anim("exterminator", "swing", false),
		S.actor("spray", Vector2(192, 104)),
		S.wait(1.0),
		S.hide("spray"),
		S.anim("harold", "faint"),
		S.wait(1.2),
		S.card("Cause of death: pest control."),
		S.fade_out(1.0),
	]
