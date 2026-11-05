extends ItemEffect

# Lottery Scratcher: each new floor (not a landing) pays a random 0 to 100 Pension, and says so. That
# is at most five tickets a run, about 250 Pension on average.

const MOST := 100

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
