class_name NpcVoice
extends RefCounted

# How each person sounds while a line appears: a blip sound from SoundBank and a pitch for it, keyed
# by NpcDef id (and the Waiting Room counters' ids, for the keepers who stand at one). Anyone not
# listed speaks in DEFAULT.

const DEFAULT := {"sound": "blip_plain", "pitch": 1.0}
const VOICES := {
	# Smooth and low, never in a hurry.
	"dealer": {"sound": "blip_smooth", "pitch": 1.0},
	"dealer_back_room": {"sound": "blip_smooth", "pitch": 0.9},
	# Prim and high.
	"deputy_dolores": {"sound": "blip_prim", "pitch": 1.0},
	# Gruff, from the chest.
	"coach_bertram": {"sound": "blip_gruff", "pitch": 1.0},
	"shop_merchant": {"sound": "blip_plain", "pitch": 1.0},
	"crafter": {"sound": "blip_reedy", "pitch": 1.0},
	"agnes": {"sound": "blip_reedy", "pitch": 1.0},
	"potion_merchant": {"sound": "blip_mystic", "pitch": 1.0},
	"madame_murk": {"sound": "blip_mystic", "pitch": 1.0},
	"bomb_merchant": {"sound": "blip_boom", "pitch": 1.0},
	"boom_bernard": {"sound": "blip_boom", "pitch": 1.0},
	"optometrist": {"sound": "blip_nasal", "pitch": 1.0},
	"dr_squint": {"sound": "blip_nasal", "pitch": 1.0},
	# The four keepers of the deep floors' counters.
	"purser": {"sound": "blip_prim", "pitch": 0.85},
	"pro_shop_keeper": {"sound": "blip_plain", "pitch": 1.2},
	"duty_free_clerk": {"sound": "blip_smooth", "pitch": 1.25},
	"severance_clerk": {"sound": "blip_nasal", "pitch": 0.8},
	"gerald": {"sound": "blip_gruff", "pitch": 1.25},
}


static func for_id(id: String) -> Dictionary:
	return VOICES.get(id, DEFAULT)


# Every blip sound any voice uses, for the check that each has a file.
static func sounds() -> Array[String]:
	var found: Array[String] = [DEFAULT["sound"]]
	for voice: Dictionary in VOICES.values():
		if not found.has(voice["sound"]):
			found.append(voice["sound"])
	return found
