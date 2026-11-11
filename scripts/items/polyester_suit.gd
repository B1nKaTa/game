extends ItemEffect

# Polyester Suit: its stats add to his cane damage, but static: each swing has CHANCE to spark and hold
# him for STUN. The full loop times his swings and walks, so there it never sparks.

const CHANCE := 0.1
const STUN := 0.5
const SPARK := Color("8fd8ff")
const TEXT := "ZAP!"

var rng := RandomNumberGenerator.new()


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func on_swing(ctx: EffectContext, _swing: SwingAttack) -> void:
	if ctx.counting_exact or rng.randf() >= CHANCE:
		return
	spark(ctx)


# Holds him a moment, with sparks and a word over him.
func spark(ctx: EffectContext) -> void:
	if is_instance_valid(ctx.player):
		ctx.player.stun_self(STUN)
	ctx.add_fx(ItemFx.make_sparks(SPARK, 16.0), ctx.feet() + Vector2(0, -12))
	ctx.add_fx(ItemFx.make_pop(TEXT, SPARK), ctx.feet())
	ctx.play_sound("small_blast")


# A resumed run never hears on_gain, so the dice are shuffled here instead.
func load_state(_state: Dictionary) -> void:
	rng.randomize()
