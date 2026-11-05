extends ItemEffect

# Rubber Stamp Collection: every Slip handed over pays a little Pension, kept or not, with a stamp over
# his head. Slips only open what a floor has locked, so this cannot be farmed.

const PAY := 10
const INK := Color("e0307a")


func on_slip_spent(ctx: EffectContext, _kept: bool) -> void:
	ctx.pay(PAY)
	ctx.add_fx(ItemFx.make_pop("APPROVED +%d" % PAY, INK), ctx.feet())
