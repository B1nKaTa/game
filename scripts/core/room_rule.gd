class_name RoomRule
extends RefCounted

# The afterlife's petty rules. Each forbids an action Harold already has; he has no run.

const NO_CANE := "no_cane"
const NO_HORSEPLAY := "no_horseplay"
const TEETH_IN := "teeth_in"
const NO_EXPLOSIVES := "no_explosives"
const NO_FOOD := "no_food"
const EXHIBITS := "exhibits"
const NO_LOITERING := "no_loitering"
const ALL: Array[String] = [NO_CANE, NO_HORSEPLAY, TEETH_IN, NO_EXPLOSIVES, NO_FOOD, EXHIBITS, NO_LOITERING]
# Leave Canes at Reception posts only where he can fairly fight this many or fewer without the cane.
const MAX_NO_CANE_ENEMIES := 6

# What Harold did, as the RuleKeeper reports it.
const ACTION_SWING := "swing"
const ACTION_DODGE := "dodge"
const ACTION_THROW := "throw"
const ACTION_BOMB := "bomb"
const ACTION_POTION := "potion"
const ACTION_BREAK := "break"
const ACTION_LOITER := "loiter"

const _SIGNS := {
	NO_CANE: "LEAVE CANES AT RECEPTION",
	NO_HORSEPLAY: "NO HORSEPLAY",
	TEETH_IN: "KEEP YOUR TEETH IN",
	NO_EXPLOSIVES: "NO EXPLOSIVES",
	NO_FOOD: "NO FOOD OR DRINK",
	EXHIBITS: "DO NOT TOUCH THE EXHIBITS",
	NO_LOITERING: "NO LOITERING",
}
const _ACTIONS := {
	NO_CANE: ACTION_SWING, NO_HORSEPLAY: ACTION_DODGE, TEETH_IN: ACTION_THROW, NO_EXPLOSIVES: ACTION_BOMB,
	NO_FOOD: ACTION_POTION, EXHIBITS: ACTION_BREAK, NO_LOITERING: ACTION_LOITER,
}
# The input action whose press is about to break it, for the icon's pulse. "" when no button does.
const _BUTTONS := {
	NO_CANE: "attack", NO_HORSEPLAY: "dodge", TEETH_IN: "throw", NO_EXPLOSIVES: "bomb", NO_FOOD: "potion",
	EXHIBITS: "", NO_LOITERING: "",
}
# How often each is picked, among the rules that can apply.
const WEIGHTS := {
	NO_CANE: 2.0, NO_HORSEPLAY: 3.0, TEETH_IN: 3.0, NO_EXPLOSIVES: 1.0, NO_FOOD: 1.0, EXHIBITS: 2.0, NO_LOITERING: 2.0,
}


static func sign_text(rule: String) -> String:
	return _SIGNS.get(rule, "")


static func action_of(rule: String) -> String:
	return _ACTIONS.get(rule, "")


static func button_of(rule: String) -> String:
	return _BUTTONS.get(rule, "")


# ready: {"has_bomb": bool, "has_potion": bool, "has_breakables": bool, "enemy_count": int}, read as
# Harold enters. A dict without "enemy_count" counts as a small fight.
static func can_apply(rule: String, ready: Dictionary) -> bool:
	match rule:
		NO_CANE:
			return int(ready.get("enemy_count", 0)) <= MAX_NO_CANE_ENEMIES
		NO_EXPLOSIVES:
			return ready.get("has_bomb", false)
		NO_FOOD:
			return ready.get("has_potion", false)
		EXHIBITS:
			return ready.get("has_breakables", false)
	return ALL.has(rule)
