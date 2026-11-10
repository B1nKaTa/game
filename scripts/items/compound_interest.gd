extends ItemEffect

# Compound Interest: every floor start (never a landing) pays SHARE of the purse, rounded down.

const SHARE := 0.15
const GOLD := Color("ffd24a")


func on_floor_start(ctx: EffectContext) -> void:
	if ctx.is_landing() or ctx.counting_exact:
		return
	var pay := floori(ctx.purse() * SHARE)
	if pay <= 0:
		return
	ctx.pay(pay)
	ctx.add_fx(ItemFx.make_pop("+%d INTEREST" % pay, GOLD), ctx.feet())
	ctx.play_sound("coin")
