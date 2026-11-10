extends ItemEffect

# A test potion part that lasts `rooms` fight-room clears.

@export var rooms := 1
var left := -1


func on_drink(ctx: EffectContext) -> void:
	left = rooms
	ctx.notice("drunk")


func on_room_clear(_ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	left -= 1


func is_spent() -> bool:
	return left == 0


func save_state() -> Dictionary:
	return state_of(["left"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["left"])
