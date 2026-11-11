extends ItemEffect

# Tin of Pet Food's lasting part: pets hit SCALE times as hard until the floor ends.

const SCALE := 2.0
var done := false


func pet_damage_scale(_ctx: EffectContext) -> float:
	return 1.0 if done else SCALE


func on_floor_start(_ctx: EffectContext) -> void:
	done = true


func is_spent() -> bool:
	return done


func save_state() -> Dictionary:
	return state_of(["done"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["done"])
