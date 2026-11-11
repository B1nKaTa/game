extends ItemEffect

# Second Brew: when one of his Thermoses explodes, Bomblet.COUNT little bombs fly out and burst a moment
# later for half its damage, enemies only. Bomblets are no Thermos to the other items and never make
# bomblets. The full loop measures each blast, so there none fly.


func on_bomb(ctx: EffectContext, at: Vector2) -> void:
	if ctx.counting_exact:
		return
	var run := ctx.run()
	var damage := Thermos.DAMAGE * (run.stats.thermos_damage_mult if run != null else 1.0) * Bomblet.SHARE
	for spot in Bomblet.spots(at, randf() * TAU):
		ctx.add_fx(Bomblet.make(ctx, spot, damage), spot)
