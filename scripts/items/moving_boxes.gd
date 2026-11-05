extends ItemEffect

# Moving Boxes: leaving a room, the cheapest small pickup still lying on its floor (a heal, a Slip, a
# Thermos or a small potion) comes along and is set down a couple of cells into the next room. Coins,
# items and shop wares stay where they are. The full loop counts every pickup, so there nothing moves.

const COLOR := Color("c9a46a")

# What is in the box between rooms: {"kind", "amount"}, or empty.
var carried := {}


func on_room_leave(ctx: EffectContext, room: Node) -> void:
	carried = {}
	if ctx.counting_pills or ctx.counting_exact or room == null or not room.has_method("take_leftover"):
		return
	carried = room.take_leftover()


func on_room_enter(ctx: EffectContext, room: Node) -> void:
	if carried.is_empty():
		return
	var box := carried
	carried = {}
	var at := ctx.feet()
	if room != null and room.has_method("spot_inside"):
		at = room.spot_inside(at)
	ctx.drop(box["kind"], at, int(box["amount"]))
	ctx.add_fx(ItemFx.make_pop("MOVED IN", COLOR), at)
	ctx.play_sound("thermos_pickup")
