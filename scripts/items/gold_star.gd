extends ItemEffect

# Gold Star Sticker: a kept rule also drops a one-pill heal by where the reel lands.


func on_event(ctx: EffectContext, event_name: String) -> void:
	if event_name != RunEffects.EVENT_RULE_KEPT:
		return
	var at := ctx.room.last_death_spot() if ctx.has_room() else ctx.feet()
	ctx.drop(RoomRules.DROP_HEAL, at, 1)
