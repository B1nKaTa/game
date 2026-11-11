extends ItemEffect

# Old Soldier (set): every combo finisher sends a shockwave forward, as the Cane Sword's. The full loop
# counts damage exactly, so there it sends none.

const DAMAGE := 18.0
const DISTANCE := 150.0
const AHEAD := 18.0


func on_swing(ctx: EffectContext, swing: SwingAttack) -> void:
	if not swing.finisher or swing.from_era or ctx.counting_exact:
		return
	var run := ctx.run()
	var damage := DAMAGE * (run.damage_mult() if run != null else 1.0)
	ctx.add_fx(ItemFx.make_wave(ctx, swing.direction, damage, DISTANCE), ctx.feet() + swing.direction * AHEAD)
