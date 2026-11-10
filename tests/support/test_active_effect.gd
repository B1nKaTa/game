extends ItemEffect

# A test active: counts its uses, and can refuse (allow) or do nothing (does).

@export var allow := true
@export var does := true
var uses := 0


func can_use(_ctx: EffectContext) -> bool:
	return allow


func use(_ctx: EffectContext) -> bool:
	if does:
		uses += 1
	return does


func save_state() -> Dictionary:
	return state_of(["uses"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["uses"])
