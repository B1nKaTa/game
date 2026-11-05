extends ItemEffect

# Lawyer's Business Card: in a boss fight, the first hit that would cost him a pill in each of the boss's
# phases costs nothing. Every boss changes phase at half health, so each boss gives two such hits.

const PHASE_LINE := 0.5
const COLOR := Color("8fb3ff")
const TEXT := "OBJECTION!"

# "<boss instance id>:<phase>" -> true for each phase whose hit has been blocked.
var _used := {}


static func phase_of(boss: Enemy) -> int:
	return 2 if boss.hp <= boss.max_hp() * PHASE_LINE else 1


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	if pills <= 0:
		return pills
	var boss := fighting(ctx)
	if boss == null:
		return pills
	var key := "%d:%d" % [boss.get_instance_id(), phase_of(boss)]
	if _used.has(key):
		return pills
	_used[key] = true
	ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), ctx.feet())
	return 0


# The boss he is fighting in this room, or null. A boss's summons are never it.
static func fighting(ctx: EffectContext) -> Enemy:
	for enemy in ctx.enemies():
		if enemy.def != null and enemy.def.is_boss and not enemy.is_summon:
			return enemy
	return null
