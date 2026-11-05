extends RefCounted

# Ending 3, Crashing the Funeral: back so fast he reaches his own funeral in time to hear Gerald's
# eulogy, and not in time to climb out of the coffin.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y
const COFFIN := CutsceneStage.COFFIN


static func steps(_variant := 0) -> Array:
	return [
		S.stage("funeral"),
		S.actor("harold", COFFIN + Vector2(18, 0)),
		S.anim("harold", "lie"),
		S.actor("mourners", Vector2(70, G)),
		S.actor("wreath", Vector2(104, G)),
		S.actor("gerald", Vector2(266, G), -1),
		S.fade_in(1.0),
		S.say("gerald", "We are gathered here to remember Harold."),
		S.say("gerald", "Harold was... adequate."),
		S.wait(0.5),
		S.shake(1.5, 0.6),
		S.say("note", "Creeeeak."),
		S.anim("harold", "sit_up"),
		S.say("harold", "ADEQUATE?!"),
		S.anim("mourners", "faint", false),
		S.anim("gerald", "faint"),
		S.say("harold", "Forty years of feuding, and I get ADEQUATE?"),
		S.walk("harold", Vector2(116, G)),
		S.anim("harold", "hop"),
		S.walk("harold", COFFIN + Vector2(18, 0), 120.0),
		S.anim("harold", "lie"),
		S.actor("coffin_lid", Vector2(COFFIN.x, 84)),
		S.walk("coffin_lid", COFFIN, 120.0),
		S.shake(3.0, 0.4),
		S.wait(1.2),
		S.card("Cause of death: his own funeral."),
		S.fade_out(1.0),
	]
