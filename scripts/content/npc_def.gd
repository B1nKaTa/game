class_name NpcDef
extends Resource

# Someone Grandpa can talk to. Drawn from his art in res://art/npcs/<art()>/ (see NpcSprite), or in
# code from color and body_size when there is none. body_size is his reach and placement either way,
# and his art's feet stand on its bottom edge.
@export var id: String = ""
@export var display_name: String = ""
@export var color := Color("8a6a4a")
@export var body_size := Vector2(20, 28)
# Said one at a time, in order, starting over after the last. Each run opens on the next one.
@export var lines: Array[String] = []
# A line for a moment, by key, said once when it comes. The Dealer has win, loss and out; Deputy
# Dolores has paid and take:<bounty id>; Coach Bertram and the deep floors' keepers have died and
# boss_win.
@export var moments: Dictionary = {}
# Drawn as this ActorLook instead of the shopkeeper placeholder when he has no art, as Gerald. Empty
# for the placeholder.
@export var look: String = ""
# Whose art he wears, when not his own id's: the Dealer's back room keeps the Dealer's.
@export var art_id: String = ""

const DIED := "died"
const BOSS_WIN := "boss_win"


func art() -> String:
	return art_id if not art_id.is_empty() else id


func moment(key: String) -> String:
	return str(moments.get(key, ""))


# The moment that greets Grandpa after the run just played, as Progress.last_run tells it: a death
# first, then a boss beaten, or "" when neither happened or this NpcDef has no line for it.
func greeting_key(last_run: Dictionary) -> String:
	if last_run.get("died", false) and not moment(DIED).is_empty():
		return DIED
	if int(last_run.get("bosses", 0)) > 0 and not moment(BOSS_WIN).is_empty():
		return BOSS_WIN
	return ""
