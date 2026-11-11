extends ItemEffect

# Glass Hip: quick on his feet (its stats), but every hit costs half a pill more: every second hit that
# costs pills costs one pill more. The full loop counts every pill a hit costs.

var _halves := 0


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills <= 0 or ctx.counting_pills:
		return pills
	_halves += 1
	if _halves < 2:
		return pills
	_halves = 0
	return pills + 1


func save_state() -> Dictionary:
	return state_of(["_halves"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["_halves"])
