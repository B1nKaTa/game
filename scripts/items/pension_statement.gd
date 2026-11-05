extends ItemEffect

# Pension Fund Statement: each fight room cleared pays a small share of what the run has earned so
# far, never more than MOST at a time. Each room clears once, so it cannot be farmed.

const SHARE := 0.02
const MOST := 20
const GOLD := Color("ffd24a")


static func pay_for(earned: int) -> int:
	return clampi(floori(maxi(earned, 0) * SHARE), 0, MOST)


func on_room_clear(ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	var run := ctx.run()
	if run == null:
		return
	var paid := pay_for(run.pension_earned)
	if paid <= 0:
		return
	ctx.pay(paid)
	ctx.add_fx(ItemFx.make_pop("+%d INTEREST" % paid, GOLD), ctx.feet())
