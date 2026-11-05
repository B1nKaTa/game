extends ItemEffect

# Forged Signature: one Slip in four opens what it opens and stays in his pocket.

const CHANCE := 0.25
const NOTICE := "Forged Signature: the Slip stays in your pocket."

var rng := RandomNumberGenerator.new()


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func keeps_slip(ctx: EffectContext) -> bool:
	if rng.randf() >= CHANCE:
		return false
	ctx.notice(NOTICE)
	return true
