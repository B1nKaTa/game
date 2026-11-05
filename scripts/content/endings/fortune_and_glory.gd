extends RefCounted

# Ending 4, Fortune and Glory: Harold buys Gerald's house out from under him, and the post brings the
# bill for owning a house.

const S := preload("res://scripts/core/cutscene_steps.gd")
const G := S.GROUND_Y


static func steps(_variant := 0) -> Array:
	return [
		S.stage("gerald_house"),
		S.actor("gerald", Vector2(270, G), -1),
		S.actor("harold", Vector2(120, G)),
		S.actor("cheque", Vector2(134, 104)),
		S.fade_in(1.0),
		S.say("harold", "Sold! To the man with the cane!"),
		S.say("gerald", "You can't buy my house! It's MY house!"),
		S.say("harold", "Not since nine o'clock this morning."),
		S.hide("cheque"),
		S.actor("movers", Vector2(350, G), -1),
		S.walk("movers", Vector2(270, G), 70.0),
		S.actor("gerald", Vector2(270, G - 8), -1),
		S.walk("movers", Vector2(-60, G), 55.0, false),
		S.walk("gerald", Vector2(-60, G - 8), 55.0, false),
		S.anim("gerald", "shake_fist"),
		S.say("gerald", "Put me down! I have ROSES!"),
		S.wait(2.0),
		S.say("harold", "Mine. All mine."),
		S.actor("letter", CutsceneStage.SLOT),
		S.walk("letter", Vector2(CutsceneStage.SLOT.x + 8, G - 2), 30.0),
		S.walk("harold", Vector2(72, G)),
		S.say("note", "PROPERTY TAX DUE: 41,000 PENSION. PAYABLE TODAY."),
		S.wait(0.4),
		S.anim("harold", "fall"),
		S.shake(2.0, 0.4),
		S.wait(1.0),
		S.card("Cause of death: property tax."),
		S.fade_out(1.0),
	]
