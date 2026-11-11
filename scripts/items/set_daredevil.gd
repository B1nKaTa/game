extends ItemEffect

# Daredevil (set): the first kill in each room heals half a pill.

var _healed := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_healed = false


func on_kill(ctx: EffectContext, _enemy: Enemy, _source: String) -> void:
	if _healed:
		return
	_healed = true
	ctx.heal_half()
