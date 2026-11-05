extends RefCounted

# Ending 10, Eternal Feud, the true ending: Harold gloats until Gerald's heart gives out, laughs until
# his own does, and the two of them meet again in the queue.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y


static func steps(_variant := 0) -> Array:
	return [
		S.stage("fence"),
		S.actor("gerald", Vector2(226, G), -1),
		S.actor("harold", Vector2(170, G)),
		S.fade_in(1.0),
		S.say("harold", "I beat the Chairman, Gerald. The Chairman of the BOARD."),
		S.say("harold", "Again and again. I've lost count, which is a win in itself."),
		S.tint("gerald", Color(1.0, 0.55, 0.5)),
		S.say("gerald", "You... you..."),
		S.anim("gerald", "shake_fist"),
		S.say("gerald", "You insufferable... ngh..."),
		S.anim("gerald", "faint"),
		S.shake(2.0, 0.4),
		S.say("harold", "HA! Forty years! Oh, this is the best day of my... ngh."),
		S.anim("harold", "fall"),
		S.wait(0.3),
		S.fade_out(0.6),
		S.stage("waiting_room"),
		S.tint("gerald", Color.WHITE),
		S.anim("gerald", "stand"),
		S.anim("harold", "stand"),
		S.actor("gerald", Vector2(188, G)),
		S.actor("harold", Vector2(120, G)),
		S.actor("ticket", Vector2(196, 106)),
		S.fade_in(0.6),
		S.say("note", "NOW SERVING: NUMBER 1."),
		S.say("gerald", "Number one. Lovely. At least there's no queue."),
		S.face("gerald", -1),
		S.say("harold", "Number two. Finally."),
		S.say("gerald", "Oh, NO."),
		S.card("Some feuds are eternal. Please take a number."),
		S.card("Cause of death: Gerald."),
		S.fade_out(1.0),
	]
