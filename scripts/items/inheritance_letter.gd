extends ItemEffect

# Inheritance Letter: a lump of Pension the moment it is taken. Nothing pays in the Training Yard,
# whose run has no bank, so trying it there pays nothing.

const PAY := 60


func on_gain(ctx: EffectContext) -> void:
	ctx.pay(PAY)
	ctx.notice("Inheritance Letter: +%d Pension" % PAY)
	ctx.play_sound("coin")
