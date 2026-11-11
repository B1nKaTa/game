extends ItemEffect

# Piggy Bank: a hit that would cost pills costs COST Pension a pill from the purse instead, while the purse
# covers the whole hit. The full loop counts every pill a hit costs, so there it pays nothing.

const COST := 20
const COLOR := Color("ff9fc0")


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills <= 0 or ctx.counting_pills:
		return pills
	if not ctx.spend_from_purse(COST * pills):
		return pills
	ctx.add_fx(ItemFx.make_pop("-%d" % (COST * pills), COLOR), ctx.feet())
	ctx.play_sound("coin")
	return 0
