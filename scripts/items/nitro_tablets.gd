extends ItemEffect

# Nitroglycerin Tablets: a hit of HEAVY pills or more sets them off, a blast round him that hurts every
# enemy in reach and never him.

const HEAVY := 2
const REACH := 72.0
const DAMAGE := 30.0
const PUSH := 160.0


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills >= HEAVY:
		go_off(ctx)
	return pills


func go_off(ctx: EffectContext) -> void:
	var at := ctx.feet()
	for enemy in ctx.enemies_near(at, REACH):
		ctx.hit_enemy(enemy, DAMAGE, RunEffects.ITEM, at.direction_to(enemy.global_position) * PUSH)
	ctx.add_fx(ItemFx.make_blast(REACH), at)
	ctx.play_sound("explosion")
