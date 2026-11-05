extends ItemEffect

# Funeral Director's Pocket Watch: a close-call dodge slows time to SHARE for SECONDS of real time.

const SHARE := 0.4
const SECONDS := 1.0


func on_close_call(ctx: EffectContext) -> void:
	ctx.slow_time(SHARE, SECONDS)
	ctx.add_fx(ItemFx.make_pop("Tick...", Color("c9c5d6")), ctx.feet())
