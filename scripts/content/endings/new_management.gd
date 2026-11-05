extends RefCounted

# Ending 2, Under New Management: the Chairman retires, Harold takes the big chair, and his first act
# is to deny Gerald his rest. He laughs too hard on a swivel chair.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y
const CHAIR := Vector2(283, 106)


static func steps(_variant := 0) -> Array:
	return [
		S.stage("office_top"),
		S.actor("chairman", Vector2(172, G), -1),
		S.actor("harold", Vector2(40, G)),
		S.fade_in(1.0),
		S.walk("harold", Vector2(126, G)),
		S.say("chairman", "Nobody has ever... Nobody has ever even read the forms."),
		S.anim("chairman", "bow"),
		S.say("chairman", "I'm retiring. The firm is yours. So is the gavel."),
		S.actor("gavel", Vector2(162, 112)),
		S.walk("gavel", Vector2(136, 112), 50.0),
		S.say("harold", "Does it come with a stamp?"),
		S.hide("gavel"),
		S.walk("chairman", Vector2(-30, G), 60.0, false),
		S.walk("harold", Vector2(CHAIR.x, G)),
		S.walk("harold", CHAIR, 30.0),
		S.face("harold", -1),
		S.actor("file", Vector2(340, 104)),
		S.walk("file", Vector2(250, 104), 120.0),
		S.say("note", "FORM 27B. GERALD. APPLICATION FOR ETERNAL REST."),
		S.anim("harold", "swing"),
		S.shake(3.0, 0.3),
		S.say("note", "REST DENIED."),
		S.say("harold", "Ha! HA HA HA! Oh, that's the best day of my..."),
		S.anim("harold", "faint"),
		S.walk("harold", Vector2(CHAIR.x + 12, G + 4), 90.0, false),
		S.shake(2.0, 0.4),
		S.wait(1.0),
		S.card("Cause of death: paperwork."),
		S.fade_out(1.0),
	]
