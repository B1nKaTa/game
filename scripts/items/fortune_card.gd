extends ItemEffect

# Fortune Teller's Card: its stats show the boss rooms on the map with who waits in them, and the first
# attack each boss winds up is shown slowed: time runs at SLOW_SHARE for SLOW_TIME as its warning starts.
# The full loop times warnings, so there nothing is slowed.

const SLOW_SHARE := 0.5
const SLOW_TIME := 0.8
const COLOR := Color("c79bff")
const TEXT := "FORESEEN"

# Instance ids of the bosses whose first attack has been shown.
var _seen := {}


func tick(ctx: EffectContext, _delta: float) -> void:
	for enemy in ctx.enemies():
		watch(ctx, enemy)


# Slows time once, the first time this boss winds up. Returns whether it did now.
func watch(ctx: EffectContext, enemy: Enemy) -> bool:
	if enemy.def == null or not enemy.def.is_boss or enemy.is_summon or not enemy.is_winding_up():
		return false
	var key := enemy.get_instance_id()
	if _seen.has(key):
		return false
	_seen[key] = true
	if ctx.counting_exact:
		return false
	ctx.slow_time(SLOW_SHARE, SLOW_TIME)
	ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), enemy.global_position)
	return true
