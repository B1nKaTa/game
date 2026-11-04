extends RefCounted

# Ending 11, Repeat Customer: once the feud is over Harold still escapes, for the sake of it, and dies
# at home again within seconds, one of five everyday ways (variant 1 to 5, EndingRules.REPEAT_CAUSES).
# No story and no Gerald: he stands at home, one moment, the card, and back to the queue.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y


static func steps(variant := 1) -> Array:
	var death := clampi(variant, 1, EndingRules.REPEAT_DEATHS)
	var middle: Array
	match death:
		1:
			middle = [
				S.stage("stairs_home"),
				S.actor("harold", CutsceneStage.STAIRS_TOP + Vector2(-14, 10), -1),
				S.fade_in(0.4),
				S.wait(0.3),
				S.anim("harold", "fall"),
				S.walk("harold", CutsceneStage.STAIRS_FOOT + Vector2(-20, 0), 150.0),
				S.shake(3.0, 0.4),
				S.wait(0.4),
			]
		2:
			middle = [
				S.stage("kitchen"),
				S.actor("harold", Vector2(126, G)),
				S.actor("sandwich", Vector2(150, 105)),
				S.fade_in(0.4),
				S.wait(0.3),
				S.walk("sandwich", Vector2(132, 96), 80.0),
				S.hide("sandwich"),
				S.tint("harold", Color(0.75, 0.8, 1.0)),
				S.anim("harold", "shake_fist"),
				S.anim("harold", "fall"),
				S.wait(0.4),
			]
		3:
			middle = [
				S.stage("bathroom"),
				S.actor("harold", Vector2(150, G)),
				S.fade_in(0.4),
				S.walk("harold", Vector2(186, G)),
				S.anim("harold", "hop"),
				S.anim("harold", "faint"),
				S.shake(2.0, 0.3),
				S.wait(0.4),
			]
		4:
			middle = [
				S.stage("living_room"),
				S.actor("ladder", Vector2(CutsceneStage.LADDER_TOP.x, G)),
				S.actor("harold", CutsceneStage.LADDER_TOP),
				S.fade_in(0.4),
				S.wait(0.4),
				S.anim("harold", "hop"),
				S.anim("harold", "fall"),
				S.walk("harold", Vector2(CutsceneStage.LADDER_TOP.x + 16, G), 120.0),
				S.shake(3.0, 0.3),
				S.wait(0.3),
			]
		_:
			middle = [
				S.stage("living_room"),
				S.actor("harold", CutsceneStage.ARMCHAIR),
				S.fade_in(0.4),
				S.wait(0.6),
				S.actor("zzz", CutsceneStage.ARMCHAIR + Vector2(8, -40)),
				S.wait(1.4),
				S.hide("zzz"),
				S.wait(0.8),
			]
	return middle + [S.card(EndingRules.repeat_cause(death)), S.fade_out(0.5)]
