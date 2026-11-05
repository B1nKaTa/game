extends ItemEffect

# Lottery Scratcher: each new floor (not a landing) pays a random 0 to MOST Pension, and says so. That
# is five tickets a run, about 150 Pension on average, near a tenth of a full clear. The spec's 0 to
# 100 added about 17% (income_probe, 2026-11-05).

const MOST := 60

var rng := RandomNumberGenerator.new()


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func on_floor_start(ctx: EffectContext) -> void:
	if ctx.is_landing():
		return
	scratch(ctx)


func scratch(ctx: EffectContext) -> int:
	var won := rng.randi_range(0, MOST)
	ctx.pay(won)
	ctx.notice(notice_for(won))
	return won


static func notice_for(won: int) -> String:
	if won <= 0:
		return "Lottery Scratcher: not a winner. Better luck next floor."
	return "Lottery Scratcher: you win %d Pension!" % won


# A resumed run never hears on_gain, so the dice are shuffled here instead.
func load_state(_state: Dictionary) -> void:
	rng.randomize()
