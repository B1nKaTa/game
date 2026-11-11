extends HitScaleEffect

# Dutch Courage's lasting part: his hits deal BONUS more and every hit on him costs double, until ROOMS
# fight rooms are cleared (the one he is in counts) or the floor ends.

const BONUS := 0.6
const ROOMS := 2
var rooms_left := ROOMS


func bonus(_ctx: EffectContext) -> float:
	return BONUS


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	return pills * 2 if pills > 0 and not ctx.counting_pills else pills


func on_room_clear(_ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	rooms_left -= 1


func on_floor_start(_ctx: EffectContext) -> void:
	rooms_left = 0


func is_spent() -> bool:
	return rooms_left <= 0


func save_state() -> Dictionary:
	return state_of(["rooms_left"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["rooms_left"])
