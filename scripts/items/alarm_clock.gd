extends ItemEffect

# Alarm Clock: walking into a fight room rings it, and every enemy there is stunned for STUN once the
# room's usual wait is over. The full loop times that wait, so there it only rings.

const STUN := 1.0


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	var enemies := ctx.enemies()
	if enemies.is_empty():
		return
	ctx.add_fx(ItemFx.make_alarm(), ctx.feet())
	ctx.play_sound("alarm")
	if ctx.counting_exact:
		return
	for enemy in enemies:
		ctx.stun(enemy, STUN)
