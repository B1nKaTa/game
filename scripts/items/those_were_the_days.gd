extends ItemEffect

# Those Were the Days: a flashback ending (its room cleared, not the floor ending it) heals one pill.


func on_event(ctx: EffectContext, event_name: String) -> void:
	if event_name == RunEffects.EVENT_FLASHBACK_END:
		ctx.heal(1)
