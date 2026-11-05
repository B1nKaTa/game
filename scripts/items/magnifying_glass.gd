extends ItemEffect

# Magnifying Glass: every secret wall in a room he walks into glints now and then, from across the room,
# until it is blasted open. The glints are room effects, so leaving the room clears them and coming back
# lays them again.


func on_room_enter(ctx: EffectContext, room: Node) -> void:
	if room == null or not room.has_method("secret_walls"):
		return
	var walls: Array = room.secret_walls()
	for wall: Node2D in walls:
		mark(ctx, wall)
	if not walls.is_empty():
		ctx.play_sound("chime")


# Lays one glint on a wall.
func mark(ctx: EffectContext, wall: Node2D) -> void:
	ctx.add_fx(ItemFx.make_glint(wall), wall.global_position)
