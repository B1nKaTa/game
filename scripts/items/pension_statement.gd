extends ItemEffect

# Pension Fund Statement: each fight room cleared pays a small share of what the run has earned so
# far, never more than MOST at a time. Each room clears once, so it cannot be farmed. The spec's 2%
# and 20 added about 37% to a full clear, since the deep floors' rooms all paid the full 20; 1% and 5
# keep it near a tenth (income_probe, 2026-11-05).

const SHARE := 0.01
const MOST := 5
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
