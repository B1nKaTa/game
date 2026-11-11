extends ItemEffect

# Fizzy Cleaning Tablet: a bite slows the bitten enemy for TIME seconds and leaves a fizz on the floor that
# slows anything standing in it while it lasts.

const RADIUS := 20.0
const TIME := 2.0
const SHARE := 0.5


func on_bite(ctx: EffectContext, enemy: Enemy) -> void:
	if not enemy.is_dead():
		enemy.slow(SHARE, TIME)
	var feet := enemy.global_position + Vector2(0.0, enemy.def.body_size.y / 2.0 - 4.0)
	ctx.add_fx(ItemFx.make_fizz(RADIUS, TIME, SHARE), feet)
