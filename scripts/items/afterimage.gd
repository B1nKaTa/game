extends ItemEffect

# Afterimage: a pale copy of Grandpa stays where a dodge began for TIME, and every enemy in the room
# but a boss walks and strikes at it instead of him. It takes their blows for nothing. When it goes they
# turn back to him (ItemFx.FxAfterimage does both).

const TIME := 1.0


func on_dodge(ctx: EffectContext, _direction: Vector2) -> void:
	var player: Player = ctx.player if ctx.has_player() else null
	var sprite: Sprite2D = player.afterimage_sprite() if player != null else null
	var at := player.global_position if player != null else ctx.feet()
	var ghost := ctx.add_fx(ItemFx.make_afterimage(player, sprite, TIME), at) as ItemFx.FxAfterimage
	if ghost != null:
		ghost.lure_all(ctx.enemies())
