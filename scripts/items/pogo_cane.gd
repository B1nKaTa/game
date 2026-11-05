extends ItemEffect

# Pogo Cane: a close-call dodge makes the dodge ready again at once.

var resets := 0


func on_close_call(ctx: EffectContext) -> void:
	resets += 1
	if ctx.has_player():
		ctx.player.refund_dodge()
	ctx.add_fx(ItemFx.make_pop("Boing!", Color("9fdcff")), ctx.feet())


# How many dodges it made ready.
func save_state() -> Dictionary:
	return state_of(["resets"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["resets"])
