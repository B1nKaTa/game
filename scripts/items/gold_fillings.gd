extends ItemEffect

# Gold Fillings: a bite knocks a one-Pension coin loose one time in five. Only enemies that pay at all
# drop one (never summons), and never more than ROOM_LIMIT a room, since a boss can be bitten for long.

const CHANCE := 0.2
const ROOM_LIMIT := 6
const GOLD := Color("ffd24a")

var rng := RandomNumberGenerator.new()
var _dropped := 0


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_dropped = 0


func on_bite(ctx: EffectContext, enemy: Enemy) -> void:
	if rng.randf() < CHANCE:
		knock_out(ctx, enemy)


func knock_out(ctx: EffectContext, enemy: Enemy) -> bool:
	if _dropped >= ROOM_LIMIT or enemy.coin_value() <= 0:
		return false
	_dropped += 1
	ctx.drop(RoomRules.DROP_COIN, enemy.global_position, 1)
	ctx.add_fx(ItemFx.make_sparks(GOLD), enemy.global_position)
	return true
