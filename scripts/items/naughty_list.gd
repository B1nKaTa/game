extends ItemEffect

# The Naughty List: a summoned enemy he finishes leaves a present one time in three: a Slip, a
# Thermos or a small potion. Never more than ROOM_LIMIT a room, since a boss summons without end.

const CHANCE := 1.0 / 3.0
const ROOM_LIMIT := 2
const PRESENTS := [RoomRules.DROP_KEY, RoomRules.DROP_BOMB, RoomRules.DROP_POTION]

var rng := RandomNumberGenerator.new()
var _given := 0


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_given = 0


func on_kill(ctx: EffectContext, enemy: Enemy, _source: String) -> void:
	if not enemy.is_summon or _given >= ROOM_LIMIT:
		return
	if rng.randf() >= CHANCE:
		return
	_given += 1
	ctx.drop(PRESENTS[rng.randi_range(0, PRESENTS.size() - 1)], enemy.global_position)
	ctx.add_fx(ItemFx.make_sparks(Color("3aa05a")), enemy.global_position)
