extends RefCounted

# Ending 8, By a Thread: he pulls through in hospital, and Gerald visits with grapes.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y
const BED := CutsceneStage.BED
const MONITOR := Vector2(84, 52)


static func steps(_variant := 0) -> Array:
	return [
		S.stage("hospital"),
		S.actor("monitor", MONITOR),
		S.actor("harold", BED + Vector2(26, 0)),
		S.anim("harold", "lie"),
		S.actor("doctor", Vector2(214, G), -1),
		S.fade_in(1.0),
		S.say("doctor", "You were clinically dead for three minutes, Mr... Harold."),
		S.say("harold", "Only three? I'm slipping."),
		S.walk("doctor", Vector2(350, G), 60.0, false),
		S.actor("gerald", Vector2(350, G), -1),
		S.actor("grapes", Vector2(342, G - 16)),
		S.walk("gerald", Vector2(216, G), 40.0, false),
		S.walk("grapes", Vector2(208, G - 16), 40.0),
		S.say("gerald", "Get well soon. I brought grapes."),
		S.say("note", "Munch."),
		S.say("gerald", "Mm. Seedless."),
		S.say("note", "Munch. Munch. Munch. Munch."),
		S.say("harold", "Those are MY grapes, Gerald."),
		S.hide("grapes"),
		S.actor("grape", Vector2(208, G - 16)),
		S.say("gerald", "Last one. Catch."),
		S.walk("grape", BED + Vector2(-26, -8), 140.0),
		S.hide("grape"),
		S.shake(2.0, 0.6),
		S.hide("monitor"),
		S.actor("monitor_flat", MONITOR),
		S.say("note", "Beeeeeeeeeeeep."),
		S.wait(0.6),
		S.card("Cause of death: grapes."),
		S.fade_out(1.0),
	]
