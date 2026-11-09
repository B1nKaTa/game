class_name SeatedLook
extends RefCounted

# What seated Harold wears on the title screen: the same three worn slots as in play, read from the
# save's cosmetics_worn through RunState.look_from, as the Waiting Room and a run read them.
# - Hat: drawn in code by GrandpaLook.draw_hat round the frame's head anchor (TitleFrames.HAROLD_HEAD),
#   facing left, the way he faces in the seated art.
# - Cardigan: an outfit of the seated strip built by tools/art/title_art.py with harold_outfits.py's ramp
#   (art/title/harold_<id>.png), as GrandpaLook.outfit_art picks his strips in play; the Power Tie is
#   drawn by GrandpaLook.draw_tie at the frame's tie anchor (TitleFrames.HAROLD_TIE), as in play.
# - Cane: in play a cane cosmetic colours the code-drawn cane line and swing arc (GrandpaLook.cane_color,
#   with red bands for the candy stripe); seated, his own cane's pixels (art/title/harold_cane.png) take
#   that colour, banded the same way.
# Nothing worn, an unknown id, or no save at all gives his own look.

const ART_DIR := "res://art/title/"
const BASE_ART := "harold"


static func from_worn(worn: Dictionary, defs: Array[CosmeticDef]) -> Dictionary:
	return describe(RunState.look_from(worn, defs))


# The seated look for a look dictionary (slot -> CosmeticDef, as RunState.look holds it):
# art (the strip's path), hat (a GrandpaLook.draw_hat shape, or ""), hat_color, tie (bool), tie_color,
# cane (bool, whether the cane is recoloured), cane_color and stripes.
static func describe(look: Dictionary) -> Dictionary:
	var out := {
		"art": art_path(BASE_ART),
		"hat": "",
		"hat_color": Color.WHITE,
		"tie": false,
		"tie_color": Color.WHITE,
		"cane": false,
		"cane_color": Color.WHITE,
		"stripes": false,
	}
	var hat := look.get(CosmeticDef.SLOT_HAT) as CosmeticDef
	if hat != null:
		out["hat"] = hat.shape
		out["hat_color"] = hat.color
	var cardigan := look.get(CosmeticDef.SLOT_CARDIGAN) as CosmeticDef
	if cardigan != null:
		if cardigan.shape == "tie":
			out["tie"] = true
			out["tie_color"] = cardigan.color
		elif TitleFrames.OUTFITS.has(cardigan.id):
			out["art"] = art_path(BASE_ART + "_" + cardigan.id)
	var cane := look.get(CosmeticDef.SLOT_CANE) as CosmeticDef
	if cane != null:
		out["cane"] = true
		out["cane_color"] = cane.color
		out["stripes"] = cane.shape == "stripe"
	return out


static func art_path(id: String) -> String:
	return ART_DIR + id + ".png"
