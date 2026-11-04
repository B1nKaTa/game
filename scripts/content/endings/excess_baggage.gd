extends RefCounted

# Ending 5, Excess Baggage: he tries to take everything back with him, sticks in the return door, and
# pops out the other side as a ghost, in Gerald's bathroom.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y


static func steps(_variant := 0) -> Array:
	return [
		S.stage("waiting_room"),
		S.actor("baggage", Vector2(56, G)),
		S.actor("harold", Vector2(64, G)),
		S.actor("clerk", Vector2(134, G), -1),
		S.fade_in(1.0),
		S.say("harold", "Right. Back to the living. With my things."),
		S.anim("harold", "hop"),
		S.shake(1.5, 0.3),
		S.anim("harold", "hop"),
		S.say("clerk", "Sir, there's a weight limit."),
		S.say("harold", "I'm eighty-seven. I AM the weight limit."),
		S.anim("harold", "hop"),
		S.shake(4.0, 0.3),
		S.say("note", "POP!"),
		S.fade_out(0.5),
		S.stage("bathroom"),
		S.hide("clerk"),
		S.hide("baggage"),
		S.actor("gerald", Vector2(116, G), -1),
		S.actor("harold", Vector2(250, G - 4), -1),
		S.tint("harold", Color(0.8, 0.9, 1.0)),
		S.anim("harold", "float", false),
		S.fade_in(0.5),
		S.say("gerald", "Peace and quiet at last. Not a Harold for miles."),
		S.walk("harold", Vector2(150, G - 4), 25.0),
		S.say("harold", "Hellooo, Gerald."),
		S.face("gerald", 1),
		S.anim("gerald", "hop"),
		S.shake(2.0, 0.4),
		S.say("gerald", "AAAAAAAAAAH!"),
		S.card("Harold now haunts Gerald's toilet. Forever."),
		S.card("Cause of death: none. Status: haunting."),
		S.fade_out(1.0),
	]
