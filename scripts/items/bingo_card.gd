extends ItemEffect

# Lucky Bingo Card: every fifth Pension pickup pays five times over, with a BINGO pop.

const EVERY := 5
const MULT := 5
const POP := "BINGO!"

var _count := 0


func on_pickup(ctx: EffectContext, kind: String, amount: int) -> int:
	if kind != RunEffects.PENSION or amount <= 0:
		return amount
	_count += 1
	if _count < EVERY:
		return amount
	_count = 0
	ctx.add_fx(ItemFx.make_pop(POP), ctx.feet())
	ctx.play_sound("bingo")
	ctx.event(RunEffects.EVENT_BINGO)
	return amount * MULT
