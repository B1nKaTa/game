extends ItemEffect

# Smelling Salts' lasting part: the next fight room he walks into, every enemy there is stunned for STUN.

const STUN := 3.0
var spent := false


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	if spent:
		return
	var enemies := ctx.enemies()
	if enemies.is_empty():
		return
	# The full loop times its rooms, so there the salts are spent with no stun.
	if not ctx.counting_exact:
		for enemy in enemies:
			ctx.stun(enemy, STUN)
	spent = true


func is_spent() -> bool:
	return spent


func save_state() -> Dictionary:
	return state_of(["spent"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["spent"])
