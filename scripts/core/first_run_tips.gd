class_name FirstRunTips
extends RefCounted

# The control tips of a save's first run: one at a time, each when it is needed, each done once per save
# (ProgressData.tips_done). Text reuses Coach Bertram's first-visit lines where they fit (CoachTips).

const RULE := "rule"
const REEL := "reel"
const MOVE := "move"
const SWING := "swing"
const DODGE := "dodge"
const THROW := "throw"
const CHARGE := "charge"
const POTION := "potion"
const INTERACT := "interact"
const THERMOS := "thermos"
const USE_ITEM := "use_item"
const MAP := "map"
# The first that applies shows. The rule and the reel come first: they are over soon.
const ORDER: Array[String] = [RULE, REEL, MOVE, SWING, DODGE, CHARGE, THROW, POTION, USE_ITEM, INTERACT, THERMOS, MAP]
const QUIET_ROOMS: Array[String] = [RoomLayout.TYPE_ITEM, RoomLayout.TYPE_SHOP, RoomLayout.TYPE_TREASURE]
# The button each tip names ("" for none; MOVE names the four walk keys).
const ACTIONS := {
	REEL: "flashback", SWING: "attack", DODGE: "dodge", THROW: "throw", CHARGE: "attack", POTION: "potion",
	USE_ITEM: "use_item", INTERACT: "interact", THERMOS: "bomb", MAP: "map",
}
const TEXTS := {
	RULE: "Keep the room's rule for a film reel. Break it and the Auditor comes.",
	REEL: "Relive a memory: be young for this room.",
	MOVE: "Walk around the room.",
	SWING: "Swing the cane. Three swings make a combo.",
	DODGE: "Dodge. It's not running away. It's tactical.",
	THROW: "Throw the teeth. They come back. Usually.",
	CHARGE: "Hold to charge a big swing.",
	POTION: "Drink your potion.",
	USE_ITEM: "Use the item in your top slot.",
	INTERACT: "Pick up, open, talk.",
	THERMOS: "Put down a Thermos. It blows up rocks and cracked walls.",
	MAP: "Open the map.",
}
const PAD_MOVE := "Left stick"
# Not shown while he relives an era (RunState.era).
const ERA_BLOCKED: Array[String] = [SWING, CHARGE, THROW]
# The running TipCoach's note_done, set by it; empty when none runs (so the hooks cost nothing).
static var listener := Callable()


# facts: fighting, room_type, rule_on, announcing, has_reel, has_potion, has_active, hurt, has_bomb, swings, cleared_one.
# skipped: tips given up for this run (shown long enough, not done); they count as passed over.
# A tip withheld (see withheld) is passed over too, but neither done nor given up: it comes back later.
static func next_tip(done: Dictionary, facts: Dictionary, skipped := {}) -> String:
	var held := withheld(facts)
	var passed := done.merged(skipped).merged(held)
	for id in ORDER:
		if not done.has(id) and not skipped.has(id) and not held.has(id) and _applies(id, passed, facts):
			return id
	return ""


# The tips that must not show now: those whose action the room's active rule forbids (facts "forbidden",
# from forbidden_by), and those that make no sense in a flashback (facts "era": no charged swing, no
# teeth, and his cane is another cane).
static func withheld(facts: Dictionary) -> Dictionary:
	var held := {}
	for id in facts.get("forbidden", []):
		held[id] = true
	if facts.get("era", false):
		for id in ERA_BLOCKED:
			held[id] = true
	return held


# The tips an active room rule would have him break by following them.
static func forbidden_by(rule: String) -> Array[String]:
	var out: Array[String] = []
	match RoomRule.action_of(rule):
		RoomRule.ACTION_SWING:
			out.assign([SWING, CHARGE])
		RoomRule.ACTION_DODGE:
			out.assign([DODGE])
		RoomRule.ACTION_THROW:
			out.assign([THROW])
		RoomRule.ACTION_BOMB:
			out.assign([THERMOS])
		RoomRule.ACTION_POTION:
			out.assign([POTION])
	return out


static func _applies(id: String, done: Dictionary, facts: Dictionary) -> bool:
	var fighting: bool = facts.get("fighting", false)
	match id:
		RULE:
			return facts.get("rule_on", false) and not facts.get("announcing", false)
		REEL:
			return facts.get("has_reel", false) and fighting
		MOVE:
			return true
		SWING:
			return fighting
		DODGE:
			return fighting and done.has(SWING)
		THROW:
			return fighting and done.has(DODGE)
		CHARGE:
			return fighting and done.has(SWING)
		POTION:
			return facts.get("has_potion", false) and facts.get("hurt", false)
		USE_ITEM:
			return facts.get("has_active", false)
		INTERACT:
			return QUIET_ROOMS.has(str(facts.get("room_type", "")))
		THERMOS:
			return facts.get("has_bomb", false) and not fighting and facts.get("cleared_one", false)
		MAP:
			return facts.get("cleared_one", false) and not fighting
	return false


# Whether the floor scene makes a TipCoach: only for a real player (not a dev run, a script run or the
# full loop) whose save still has tips left.
static func should_coach(dev_run: bool, done_count: int, script_run: bool, smoke: bool) -> bool:
	return not dev_run and not script_run and not smoke and done_count < ORDER.size()


# Tells the coach, if one is running, that he really took, opened or talked to something (not that he
# pressed the key at nothing). Called by the pickup, chest, NPC, key door and Arcade table.
static func interacted(_from: Node) -> void:
	if listener.is_valid():
		listener.call(INTERACT)


# The line for a tip, naming the bound key or pad button as every prompt does.
static func text_for(id: String, pad: bool, family: String) -> String:
	var text: String = TEXTS.get(id, "")
	if text.is_empty():
		return ""
	if id == MOVE:
		var keys: String = PAD_MOVE if pad else "%s%s%s%s" % [KeyBindings.label_for("move_up"), KeyBindings.label_for("move_left"), KeyBindings.label_for("move_down"), KeyBindings.label_for("move_right")]
		return "%s: %s" % [tr_static(keys), tr_static(text)]
	var action: String = ACTIONS.get(id, "")
	if action.is_empty():
		return tr_static(text)
	return KeyBindings.with_device(action, tr_static(text), pad, family)


# tr() outside a node: TranslationServer, as menus do for static text.
static func tr_static(text: String) -> String:
	return TranslationServer.translate(text)
