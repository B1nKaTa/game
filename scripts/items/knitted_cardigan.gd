extends ItemEffect

# Knitted Cardigan: fire and steam cost half the pills. A half left over waits for the next fire hit, so
# of two one-pill burns, only the second costs a pill.

var _halves := 0


func on_hurt(ctx: EffectContext, pills: int, source: String) -> int:
	if source != RunEffects.HURT_FIRE or pills <= 0:
		return pills
	_halves += pills
	var lost := floori(_halves / 2.0)
	_halves %= 2
	if lost < pills:
		ctx.add_fx(ItemFx.make_pop("Toasty", Color("e8a0c8")), ctx.feet())
	return lost


# A half pill of fire waiting for the next burn.
func save_state() -> Dictionary:
	return state_of(["_halves"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["_halves"])
