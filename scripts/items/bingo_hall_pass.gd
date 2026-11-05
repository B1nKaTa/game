extends ItemEffect

# Bingo Hall Pass: every EVERY rooms he clears earn a pass, and the next fight room he walks into has its
# enemies' health cut by CUT. The full loop measures damage exactly, so there the pass waits unused.

const EVERY := 3
const CUT := 0.15
const COLOR := Color("ffd24a")
const TEXT := "HALL PASS"

var cleared := 0


func on_room_clear(_ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	cleared += 1


func has_pass() -> bool:
	return cleared >= EVERY


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	if not has_pass() or ctx.counting_exact:
		return
	var enemies := ctx.enemies()
	if enemies.is_empty():
		return
	cleared -= EVERY
	for enemy in enemies:
		enemy.hp *= 1.0 - CUT
		enemy.health_changed.emit(enemy.hp)
	ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), ctx.feet())
