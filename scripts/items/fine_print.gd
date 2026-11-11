extends ItemEffect

# Fine Print: the first rule broken on each floor is let off with a warning, so no Auditor comes. It still
# counts as broken.

var used := false


func on_floor_start(_ctx: EffectContext) -> void:
	used = false


# The full loop breaks rules to check the Auditor walks in, so there nothing is let off.
func excuses_rule_break(ctx: EffectContext) -> bool:
	if used or ctx.counting_exact:
		return false
	used = true
	return true


func save_state() -> Dictionary:
	return state_of(["used"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["used"])
