extends ItemEffect

# Bad Hip: every dodge leaves a cough cloud where it began, which slows the enemies whose bodies it
# touches while it hangs about.

const RADIUS := 22.0
const TIME := 2.0
const SHARE := 0.5


func on_dodge(ctx: EffectContext, _direction: Vector2) -> void:
	ctx.add_fx(ItemFx.make_cough(RADIUS, TIME, SHARE), ctx.feet())
