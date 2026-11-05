extends RefCounted

# Ending 1, Briefly Alive: he wakes at the foot of the stairs, settles one score with Gerald's ear, goes
# home, and the stairs settle theirs.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y


static func steps(_variant := 0) -> Array:
	return [
		S.stage("fence"),
		S.actor("harold", Vector2(64, G)),
		S.anim("harold", "lie"),
		S.actor("gerald", Vector2(224, G), -1),
		S.fade_in(1.0),
		S.wait(0.6),
		S.anim("harold", "sit_up"),
		S.say("gerald", "Harold?! They said you were dead!"),
		S.say("harold", "They were wrong."),
		S.walk("harold", Vector2(184, G)),
		S.anim("harold", "swing"),
		S.shake(2.0, 0.3),
		S.anim("gerald", "hop"),
		S.say("gerald", "OW! My EAR!"),
		S.say("harold", "Forty years, Gerald. I'm only getting started."),
		S.walk("harold", Vector2(64, G), 55.0),
		S.fade_out(0.4),
		S.stage("stairs_home"),
		S.hide("gerald"),
		S.actor("harold", Vector2(140, G)),
		S.fade_in(0.4),
		S.walk("harold", CutsceneStage.STAIRS_FOOT),
		S.walk("harold", CutsceneStage.STAIRS_TOP + Vector2(-14, 10), 30.0),
		S.say("harold", "Now. Where was I?"),
		S.anim("harold", "faint"),
		S.walk("harold", CutsceneStage.STAIRS_FOOT + Vector2(-20, 0), 150.0, false),
		S.shake(4.0, 0.6),
		S.wait(1.2),
		S.card("Cause of death: stairs. Again."),
		S.fade_out(1.0),
	]
