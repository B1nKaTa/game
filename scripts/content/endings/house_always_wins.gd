extends RefCounted

# Ending 6, The House Always Wins: Harold turns the garage into a casino and takes Gerald for everything,
# until the Dealer takes the casino.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y
const DOOR := Vector2(272, G)


static func steps(_variant := 0) -> Array:
	return [
		S.stage("garage"),
		S.actor("harold", Vector2(84, G)),
		S.actor("gerald", Vector2(140, G), -1),
		S.fade_in(1.0),
		S.say("harold", "Welcome to Harold's Palace. Place your bets."),
		S.say("gerald", "Fine. Ten on red."),
		S.say("harold", "This is blackjack, Gerald."),
		S.anim("harold", "swing"),
		S.wait(0.4),
		S.anim("harold", "swing"),
		S.say("gerald", "That's my watch, my car, and now my cardigan."),
		S.actor("shirt", Vector2(108, 108)),
		S.actor("dealer", Vector2(50, G)),
		S.say("dealer", "Nice place. I'll take it from here."),
		S.face("harold", -1),
		S.say("harold", "Who let YOU out of the Back Room?"),
		S.walk("harold", DOOR, 45.0, false),
		S.walk("dealer", DOOR + Vector2(-44, 0), 45.0),
		S.face("harold", -1),
		S.say("dealer", "The house always wins."),
		S.actor("garage_door", Vector2(DOOR.x, 30)),
		S.walk("garage_door", DOOR, 220.0),
		S.shake(4.0, 0.5),
		S.wait(1.0),
		S.card("Cause of death: the house."),
		S.fade_out(1.0),
	]
