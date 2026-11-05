extends ItemEffect

# Kettle Whistle: a Thermos going off stuns every enemy its blast reached for a second, with the
# whistle over the spot.

const STUN := 1.0
const STEAM := Color("f2f6ff")
const TEXT := "WHEEE!"


func on_bomb(ctx: EffectContext, at: Vector2) -> void:
	stun_reached(ctx, at)
	ctx.add_fx(ItemFx.make_pop(TEXT, STEAM), at)


# Stuns each living enemy whose body the blast reached. Returns how many.
func stun_reached(ctx: EffectContext, at: Vector2) -> int:
	var run := ctx.run()
	var reach := run.stats.blast_radius if run != null else PlayerStats.BASE_BLAST_RADIUS
	var count := 0
	for enemy in ctx.enemies():
		var body := enemy.body_rect()
		if at.distance_to(MeleeArc.closest_point(body, at)) <= reach:
			ctx.stun(enemy, STUN)
			count += 1
	return count
